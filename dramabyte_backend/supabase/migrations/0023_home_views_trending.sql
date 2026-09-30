create table if not exists episode_daily_views (
  episode_id uuid not null references episodes(id) on delete cascade,
  day date not null,
  views bigint not null default 0 check (views >= 0),
  primary key (episode_id, day)
);

create index if not exists episode_daily_views_day_idx on episode_daily_views(day);
alter table episode_daily_views enable row level security;

insert into episode_daily_views (episode_id, day, views)
select episode_id, (created_at at time zone 'UTC')::date, count(*)
from episode_views group by 1, 2
on conflict (episode_id, day) do nothing;

create or replace function record_views(
  p_user uuid, p_batch uuid, p_items jsonb,
  p_max_items integer, p_max_item_count integer, p_max_per_minute integer
) returns text language plpgsql security definer set search_path = public as $$
declare
  requested integer;
  recent integer;
  applied bigint;
  valid_items jsonb;
begin
  if jsonb_typeof(p_items) <> 'array'
     or jsonb_array_length(p_items) = 0
     or jsonb_array_length(p_items) > p_max_items then
    return 'invalid';
  end if;
  perform 1 from profiles where id = p_user and deleted_at is null and not is_suspended;
  if not found then return 'user_unavailable'; end if;
  if exists (select 1 from view_batches where batch_id = p_batch) then
    return 'duplicate';
  end if;
  select coalesce(sum(least(greatest((i->>'count')::integer, 0), p_max_item_count)), 0)
  into requested from jsonb_array_elements(p_items) i;
  if requested = 0 then return 'invalid'; end if;
  select coalesce(sum(total), 0) into recent from view_batches
  where user_id = p_user and created_at > now() - interval '1 minute';
  if recent + requested > p_max_per_minute then return 'rate_limited'; end if;
  insert into view_batches (batch_id, user_id, total)
  values (p_batch, p_user, requested) on conflict (batch_id) do nothing;
  if not found then return 'duplicate'; end if;
  select coalesce(jsonb_agg(jsonb_build_object('e', v.episode_id, 'n', v.n) order by v.episode_id), '[]'::jsonb)
  into valid_items
  from (
    select it.episode_id, sum(it.n)::bigint as n
    from (
      select (i->>'episode_id')::uuid as episode_id,
             least(greatest((i->>'count')::integer, 0), p_max_item_count) as n
      from jsonb_array_elements(p_items) i
    ) it
    join episodes e on e.id = it.episode_id
    join projects p on p.id = e.project_id
    where p.status = 'published'
    group by it.episode_id
    having sum(it.n) > 0
  ) v;
  select coalesce(sum((x->>'n')::bigint), 0) into applied
  from jsonb_array_elements(valid_items) x;
  if applied > 0 then
    insert into episode_stats (episode_id, views)
    select (x->>'e')::uuid, (x->>'n')::bigint
    from jsonb_array_elements(valid_items) x
    order by 1
    on conflict (episode_id) do update
    set views = episode_stats.views + excluded.views, updated_at = now();
    insert into episode_daily_views (episode_id, day, views)
    select (x->>'e')::uuid, (now() at time zone 'UTC')::date, (x->>'n')::bigint
    from jsonb_array_elements(valid_items) x
    order by 1
    on conflict (episode_id, day) do update
    set views = episode_daily_views.views + excluded.views;
    insert into daily_view_counts (day, shard, views)
    values ((now() at time zone 'UTC')::date, floor(random() * 16)::smallint, applied)
    on conflict (day, shard) do update
    set views = daily_view_counts.views + excluded.views;
  end if;
  if random() < 0.01 then
    delete from view_batches where created_at < now() - interval '7 days';
    delete from episode_daily_views where day < (now() at time zone 'UTC')::date - 30;
  end if;
  return 'ok';
end;
$$;

revoke all on function record_views(uuid, uuid, jsonb, integer, integer, integer) from public, anon, authenticated;
grant execute on function record_views(uuid, uuid, jsonb, integer, integer, integer) to service_role;

drop function if exists home_feed(integer);

create function home_feed(p_limit integer) returns jsonb
language sql stable security definer set search_path = public as $$
  with catalog as (
    select
      s.id as series_id, s.title, s.description, s.genre, s.created_at,
      s.free_episode_count,
      coalesce(
        nullif(s.thumbnail_url, ''),
        (select nullif(e2.thumbnail_url, '')
           from episodes e2 join projects p2 on p2.id = e2.project_id
          where e2.series_id = s.id and p2.status = 'published' and e2.thumbnail_url <> ''
          order by e2.episode_number limit 1),
        ''
      ) as thumbnail_url,
      (select count(*)::integer from episodes e join projects p on p.id = e.project_id
        where e.series_id = s.id and p.status = 'published') as episode_count,
      (select coalesce(sum(st.views), 0)::bigint from episode_stats st
        join episodes e on e.id = st.episode_id join projects p on p.id = e.project_id
        where e.series_id = s.id and p.status = 'published') as views,
      (select coalesce(sum(d.views), 0)::bigint from episode_daily_views d
        join episodes e on e.id = d.episode_id
        where e.series_id = s.id
          and d.day >= (now() at time zone 'UTC')::date - 6) as recent_views
    from series s
  ), live as (
    select * from catalog where episode_count > 0
  ), top_genres as (
    select genre from live group by genre order by count(*) desc, genre limit 6
  )
  select jsonb_build_object(
    'featured', coalesce((
      select jsonb_agg(to_jsonb(t) order by t.created_at desc)
      from (select * from live order by created_at desc limit 5) t
    ), '[]'::jsonb),
    'trending', coalesce((
      select jsonb_agg(to_jsonb(t) order by t.recent_views desc, t.created_at desc)
      from (select * from live order by recent_views desc, created_at desc limit p_limit) t
    ), '[]'::jsonb),
    'genres', coalesce((
      select jsonb_agg(jsonb_build_object('genre', g.genre, 'items', (
        select coalesce(jsonb_agg(to_jsonb(t) order by t.created_at desc), '[]'::jsonb)
        from (select * from live l where l.genre = g.genre order by l.created_at desc limit p_limit) t
      )))
      from top_genres g
    ), '[]'::jsonb)
  )
$$;

revoke all on function home_feed(integer) from public, anon, authenticated;
grant execute on function home_feed(integer) to service_role;
