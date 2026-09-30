create table watch_history (
  user_id uuid not null references profiles(id) on delete cascade,
  episode_id uuid not null references episodes(id) on delete cascade,
  position_seconds integer not null check (position_seconds >= 0),
  duration_seconds integer not null check (duration_seconds > 0),
  watched_at timestamptz not null default now(),
  primary key (user_id, episode_id),
  check (position_seconds <= duration_seconds)
);

create index watch_history_recent_idx on watch_history(user_id, watched_at desc, episode_id desc);

alter table watch_history enable row level security;

create policy watch_history_owner_read on watch_history for select using (auth.uid() = user_id);

create function record_watch(p_user uuid, p_episode uuid, p_position integer, p_max_rows integer)
returns text language plpgsql security definer set search_path = public as $$
declare
  ep episodes;
begin
  select e.* into ep from episodes e join projects p on p.id = e.project_id
  where e.id = p_episode and p.status = 'published';
  if not found then return 'episode_not_found'; end if;
  perform 1 from profiles where id = p_user and deleted_at is null and not is_suspended;
  if not found then return 'user_unavailable'; end if;
  insert into watch_history (user_id, episode_id, position_seconds, duration_seconds)
  values (p_user, p_episode, least(greatest(p_position, 0), ep.duration_seconds), ep.duration_seconds)
  on conflict (user_id, episode_id) do update
  set position_seconds = excluded.position_seconds,
      duration_seconds = excluded.duration_seconds,
      watched_at = now();
  delete from watch_history
  where user_id = p_user and episode_id in (
    select episode_id from watch_history where user_id = p_user
    order by watched_at desc, episode_id desc offset p_max_rows
  );
  return 'ok';
end;
$$;

create function list_watch_history(
  p_user uuid, p_after_watched timestamptz, p_after_episode uuid, p_limit integer
) returns table (
  episode_id uuid, series_id uuid, series_title text, episode_number integer,
  thumbnail text, position_seconds integer, duration_seconds integer, watched_at timestamptz
) language sql stable security definer set search_path = public as $$
  select h.episode_id, e.series_id, s.title, e.episode_number,
    coalesce(nullif(e.thumbnail_url, ''), s.thumbnail_url),
    h.position_seconds, h.duration_seconds, h.watched_at
  from watch_history h
  join episodes e on e.id = h.episode_id
  join series s on s.id = e.series_id
  join projects p on p.id = e.project_id
  where h.user_id = p_user and p.status = 'published'
    and (p_after_watched is null or (h.watched_at, h.episode_id) < (p_after_watched, p_after_episode))
  order by h.watched_at desc, h.episode_id desc
  limit p_limit
$$;

revoke all on function record_watch(uuid, uuid, integer, integer) from public, anon, authenticated;
revoke all on function list_watch_history(uuid, timestamptz, uuid, integer) from public, anon, authenticated;
grant execute on function record_watch(uuid, uuid, integer, integer) to service_role;
grant execute on function list_watch_history(uuid, timestamptz, uuid, integer) to service_role;

do $$
begin
  alter publication supabase_realtime add table watch_history;
exception when duplicate_object then null;
end;
$$;
