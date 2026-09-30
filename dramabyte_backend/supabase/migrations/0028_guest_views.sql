create table guest_view_events (
  event_id uuid primary key,
  episode_id uuid not null references episodes(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table guest_view_events enable row level security;
create index guest_view_events_created_idx on guest_view_events(created_at);
revoke all on guest_view_events from public, anon, authenticated;

create function record_guest_view(p_episode uuid, p_event uuid) returns text
language plpgsql security definer set search_path = public as $$
begin
  if not exists (
    select 1 from episodes e join projects p on p.id = e.project_id
    where e.id = p_episode and e.episode_number between 1 and 2
      and p.status = 'published'
  ) then return 'unavailable'; end if;
  insert into guest_view_events(event_id, episode_id) values (p_event, p_episode)
  on conflict do nothing;
  if not found then return 'duplicate'; end if;
  insert into episode_stats(episode_id, views) values (p_episode, 1)
  on conflict (episode_id) do update
    set views = episode_stats.views + 1, updated_at = now();
  insert into daily_view_counts(day, shard, views)
    values ((now() at time zone 'UTC')::date, 0, 1)
  on conflict (day, shard) do update set views = daily_view_counts.views + 1;
  return 'ok';
end;
$$;
revoke all on function record_guest_view(uuid, uuid) from public, anon, authenticated;
grant execute on function record_guest_view(uuid, uuid) to service_role;
