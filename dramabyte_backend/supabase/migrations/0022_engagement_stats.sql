create table if not exists episode_stats (
  episode_id uuid primary key references episodes(id) on delete cascade,
  views bigint not null default 0 check (views >= 0),
  likes bigint not null default 0 check (likes >= 0),
  updated_at timestamptz not null default now()
);

alter table episode_stats enable row level security;

insert into episode_stats (episode_id, views, likes)
select e.id,
  (select count(*) from episode_views v where v.episode_id = e.id),
  (select count(*) from episode_likes l where l.episode_id = e.id)
from episodes e
on conflict (episode_id) do nothing;

create or replace function create_episode_stats() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into episode_stats (episode_id) values (new.id) on conflict do nothing;
  return null;
end;
$$;

drop trigger if exists episodes_create_stats on episodes;
create trigger episodes_create_stats after insert on episodes
for each row execute function create_episode_stats();

create or replace function sync_episode_like_count() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    insert into episode_stats (episode_id, likes) values (new.episode_id, 1)
    on conflict (episode_id) do update
    set likes = episode_stats.likes + 1, updated_at = now();
  else
    update episode_stats set likes = greatest(likes - 1, 0), updated_at = now()
    where episode_id = old.episode_id;
  end if;
  return null;
end;
$$;

drop trigger if exists episode_likes_count on episode_likes;
create trigger episode_likes_count after insert or delete on episode_likes
for each row execute function sync_episode_like_count();

create table if not exists view_batches (
  batch_id uuid primary key,
  user_id uuid not null references profiles(id) on delete cascade,
  total integer not null check (total > 0),
  created_at timestamptz not null default now()
);

create index if not exists view_batches_user_idx on view_batches(user_id, created_at desc);
create index if not exists view_batches_created_idx on view_batches(created_at);
alter table view_batches enable row level security;

create table if not exists daily_view_counts (
  day date not null,
  shard smallint not null check (shard between 0 and 15),
  views bigint not null default 0 check (views >= 0),
  primary key (day, shard)
);

alter table daily_view_counts enable row level security;

insert into daily_view_counts (day, shard, views)
select (created_at at time zone 'UTC')::date, 0, count(*)
from episode_views group by 1
on conflict (day, shard) do nothing;

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
    insert into daily_view_counts (day, shard, views)
    values ((now() at time zone 'UTC')::date, floor(random() * 16)::smallint, applied)
    on conflict (day, shard) do update
    set views = daily_view_counts.views + excluded.views;
  end if;
  if random() < 0.01 then
    delete from view_batches where created_at < now() - interval '7 days';
  end if;
  return 'ok';
end;
$$;

drop view if exists episode_metrics;

create view episode_metrics as
select e.*,
  coalesce(st.views, 0)::bigint as views,
  coalesce(st.likes, 0)::bigint as likes,
  (select count(*) from episode_comments c where c.episode_id = e.id and not c.is_hidden) as comments
from episodes e
left join episode_stats st on st.episode_id = e.id;

drop view if exists series_metrics;

create view series_metrics as
select s.*,
  (select count(*) from episodes e where e.series_id = s.id) as episode_count,
  (select count(*) from episodes e join projects p on p.id = e.project_id where e.series_id = s.id and p.status = 'published') as published_episodes,
  coalesce((select sum(duration_seconds) from episodes e where e.series_id = s.id), 0) as duration_seconds,
  (select coalesce(sum(st.views), 0)::bigint from episode_stats st join episodes e on e.id = st.episode_id where e.series_id = s.id) as views,
  (select coalesce(sum(st.likes), 0)::bigint from episode_stats st join episodes e on e.id = st.episode_id where e.series_id = s.id) as likes,
  (select count(*) from episode_comments c join episodes e on e.id = c.episode_id where e.series_id = s.id and not c.is_hidden) as comments,
  (select round(avg(r.rating), 2) from series_ratings r where r.series_id = s.id) as rating,
  (select count(*) from series_ratings r where r.series_id = s.id) as rating_count
from series s;

create or replace view platform_summary as select
  (select count(*) from series) as series_count,
  (select count(*) from episodes) as episode_count,
  (select count(*) from episodes e join projects p on p.id = e.project_id where p.status = 'published') as published_episodes,
  (select coalesce(sum(views), 0)::bigint from episode_stats) as views,
  (select coalesce(sum(likes), 0)::bigint from episode_stats) as likes,
  (select count(*) from episode_comments where not is_hidden) as comments,
  (select round(avg(rating), 2) from series_ratings) as rating,
  (select count(*) from series_ratings) as rating_count;

create or replace view daily_engagement as select
  day, sum(views)::bigint as views
from daily_view_counts group by day;

revoke all on episode_metrics, series_metrics from anon, authenticated;
grant select on episode_metrics, series_metrics to service_role;

revoke all on function create_episode_stats() from public, anon, authenticated;
revoke all on function sync_episode_like_count() from public, anon, authenticated;
revoke all on function record_views(uuid, uuid, jsonb, integer, integer, integer) from public, anon, authenticated;
grant execute on function record_views(uuid, uuid, jsonb, integer, integer, integer) to service_role;
