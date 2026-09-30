create table library_items (
  user_id uuid not null references profiles(id) on delete cascade,
  series_id uuid not null references series(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, series_id)
);

create index library_items_recent_idx on library_items(user_id, created_at desc);

alter table library_items enable row level security;

create policy library_items_owner_read on library_items
for select using (auth.uid() = user_id);

create function add_to_library(p_user uuid, p_series uuid, p_max integer)
returns text language plpgsql security definer set search_path = public as $$
begin
  perform 1 from profiles
  where id = p_user and deleted_at is null and not is_suspended for update;
  if not found then return 'user_unavailable'; end if;
  if not exists (
    select 1 from episodes e join projects p on p.id = e.project_id
    where e.series_id = p_series and p.status = 'published'
  ) then
    return 'series_not_found';
  end if;
  if exists (select 1 from library_items where user_id = p_user and series_id = p_series) then
    return 'ok';
  end if;
  if (select count(*) from library_items where user_id = p_user) >= p_max then
    return 'library_full';
  end if;
  insert into library_items (user_id, series_id) values (p_user, p_series)
  on conflict do nothing;
  return 'ok';
end;
$$;

create function list_library(p_user uuid, p_limit integer)
returns table (
  series_id uuid, title text, description text, genre text, thumbnail_url text,
  episode_count integer, free_episode_count integer, saved_at timestamptz
) language sql stable security definer set search_path = public as $$
  select
    s.id, s.title, s.description, s.genre,
    coalesce(
      nullif(s.thumbnail_url, ''),
      (select nullif(e2.thumbnail_url, '')
         from episodes e2 join projects p2 on p2.id = e2.project_id
        where e2.series_id = s.id and p2.status = 'published' and e2.thumbnail_url <> ''
        order by e2.episode_number limit 1),
      ''
    ),
    (select count(*)::integer from episodes e join projects p on p.id = e.project_id
      where e.series_id = s.id and p.status = 'published'),
    s.free_episode_count,
    l.created_at
  from library_items l
  join series s on s.id = l.series_id
  where l.user_id = p_user
    and exists (
      select 1 from episodes e join projects p on p.id = e.project_id
      where e.series_id = s.id and p.status = 'published'
    )
  order by l.created_at desc
  limit p_limit
$$;

revoke all on function add_to_library(uuid, uuid, integer) from public, anon, authenticated;
revoke all on function list_library(uuid, integer) from public, anon, authenticated;
grant execute on function add_to_library(uuid, uuid, integer) to service_role;
grant execute on function list_library(uuid, integer) to service_role;

do $$
begin
  alter publication supabase_realtime add table library_items;
exception when duplicate_object then null;
end;
$$;
