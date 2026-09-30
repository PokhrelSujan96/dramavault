alter table series_ratings drop constraint if exists series_ratings_rating_check;

do $$
begin
  alter table series_ratings
    add constraint series_ratings_rating_range check (rating between 1 and 10);
exception when duplicate_object then null;
end;
$$;

alter table series_ratings add column if not exists updated_at timestamptz not null default now();
create index if not exists series_ratings_user_idx on series_ratings(user_id, updated_at desc);

create table if not exists episode_ratings (
  episode_id uuid not null references episodes(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  rating integer not null check (rating between 1 and 10),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (episode_id, user_id)
);

create index if not exists episode_ratings_user_idx on episode_ratings(user_id, updated_at desc);
alter table episode_ratings enable row level security;

create table if not exists series_rating_stats (
  series_id uuid primary key references series(id) on delete cascade,
  rating_sum bigint not null default 0 check (rating_sum >= 0),
  rating_count integer not null default 0 check (rating_count >= 0),
  updated_at timestamptz not null default now()
);

alter table series_rating_stats enable row level security;
alter table episode_stats add column if not exists rating_sum bigint not null default 0 check (rating_sum >= 0);
alter table episode_stats add column if not exists rating_count integer not null default 0 check (rating_count >= 0);

insert into series_rating_stats (series_id, rating_sum, rating_count)
select series_id, sum(rating), count(*) from series_ratings group by series_id
on conflict (series_id) do update
set rating_sum = excluded.rating_sum, rating_count = excluded.rating_count, updated_at = now();

update episode_stats st set rating_sum = r.total, rating_count = r.votes
from (
  select episode_id, sum(rating) as total, count(*)::integer as votes
  from episode_ratings group by episode_id
) r
where r.episode_id = st.episode_id;

create or replace function sync_series_rating_stats() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    insert into series_rating_stats (series_id, rating_sum, rating_count)
    values (new.series_id, new.rating, 1)
    on conflict (series_id) do update
    set rating_sum = series_rating_stats.rating_sum + new.rating,
        rating_count = series_rating_stats.rating_count + 1,
        updated_at = now();
  elsif tg_op = 'UPDATE' then
    update series_rating_stats
    set rating_sum = greatest(rating_sum + new.rating - old.rating, 0), updated_at = now()
    where series_id = new.series_id;
  else
    update series_rating_stats
    set rating_sum = greatest(rating_sum - old.rating, 0),
        rating_count = greatest(rating_count - 1, 0), updated_at = now()
    where series_id = old.series_id;
  end if;
  return null;
end;
$$;

drop trigger if exists series_ratings_stats on series_ratings;
create trigger series_ratings_stats
after insert or update of rating or delete on series_ratings
for each row execute function sync_series_rating_stats();

create or replace function sync_episode_rating_stats() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    insert into episode_stats (episode_id, rating_sum, rating_count)
    values (new.episode_id, new.rating, 1)
    on conflict (episode_id) do update
    set rating_sum = episode_stats.rating_sum + new.rating,
        rating_count = episode_stats.rating_count + 1,
        updated_at = now();
  elsif tg_op = 'UPDATE' then
    update episode_stats
    set rating_sum = greatest(rating_sum + new.rating - old.rating, 0), updated_at = now()
    where episode_id = new.episode_id;
  else
    update episode_stats
    set rating_sum = greatest(rating_sum - old.rating, 0),
        rating_count = greatest(rating_count - 1, 0), updated_at = now()
    where episode_id = old.episode_id;
  end if;
  return null;
end;
$$;

drop trigger if exists episode_ratings_stats on episode_ratings;
create trigger episode_ratings_stats
after insert or update of rating or delete on episode_ratings
for each row execute function sync_episode_rating_stats();

create or replace function rate_item(
  p_user uuid, p_kind text, p_target uuid, p_rating integer, p_max_per_minute integer
) returns jsonb language plpgsql security definer set search_path = public as $$
declare
  recent integer;
  total_sum bigint;
  total_count integer;
begin
  if p_kind not in ('series', 'episode') then
    return jsonb_build_object('code', 'invalid_kind');
  end if;
  if p_rating is null or p_rating < 1 or p_rating > 10 then
    return jsonb_build_object('code', 'invalid_rating');
  end if;
  perform 1 from profiles where id = p_user and deleted_at is null and not is_suspended;
  if not found then return jsonb_build_object('code', 'user_unavailable'); end if;
  if p_kind = 'series' then
    perform 1 from episodes e join projects p on p.id = e.project_id
    where e.series_id = p_target and p.status = 'published';
  else
    perform 1 from episodes e join projects p on p.id = e.project_id
    where e.id = p_target and p.status = 'published';
  end if;
  if not found then return jsonb_build_object('code', 'not_found'); end if;
  select
    (select count(*) from series_ratings
      where user_id = p_user and updated_at > now() - interval '1 minute')
    + (select count(*) from episode_ratings
      where user_id = p_user and updated_at > now() - interval '1 minute')
  into recent;
  if recent >= p_max_per_minute then
    return jsonb_build_object('code', 'rate_limited');
  end if;
  if p_kind = 'series' then
    insert into series_ratings (series_id, user_id, rating)
    values (p_target, p_user, p_rating)
    on conflict (series_id, user_id) do update
    set rating = excluded.rating, updated_at = now();
    select rating_sum, rating_count into total_sum, total_count
    from series_rating_stats where series_id = p_target;
  else
    insert into episode_ratings (episode_id, user_id, rating)
    values (p_target, p_user, p_rating)
    on conflict (episode_id, user_id) do update
    set rating = excluded.rating, updated_at = now();
    select rating_sum, rating_count into total_sum, total_count
    from episode_stats where episode_id = p_target;
  end if;
  return jsonb_build_object(
    'code', 'ok', 'sum', coalesce(total_sum, 0),
    'count', coalesce(total_count, 0), 'my', p_rating
  );
end;
$$;

create or replace function clear_rating(p_user uuid, p_kind text, p_target uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  total_sum bigint;
  total_count integer;
begin
  if p_kind = 'series' then
    delete from series_ratings where series_id = p_target and user_id = p_user;
    select rating_sum, rating_count into total_sum, total_count
    from series_rating_stats where series_id = p_target;
  elsif p_kind = 'episode' then
    delete from episode_ratings where episode_id = p_target and user_id = p_user;
    select rating_sum, rating_count into total_sum, total_count
    from episode_stats where episode_id = p_target;
  else
    return jsonb_build_object('code', 'invalid_kind');
  end if;
  return jsonb_build_object(
    'code', 'ok', 'sum', coalesce(total_sum, 0),
    'count', coalesce(total_count, 0), 'my', null
  );
end;
$$;

revoke all on function sync_series_rating_stats() from public, anon, authenticated;
revoke all on function sync_episode_rating_stats() from public, anon, authenticated;
revoke all on function rate_item(uuid, text, uuid, integer, integer) from public, anon, authenticated;
revoke all on function clear_rating(uuid, text, uuid) from public, anon, authenticated;
grant execute on function rate_item(uuid, text, uuid, integer, integer) to service_role;
grant execute on function clear_rating(uuid, text, uuid) to service_role;
