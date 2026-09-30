alter table series add column free_episode_count integer check (free_episode_count >= 0);

create function series_details(p_series uuid) returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'series_id', s.id,
    'title', s.title,
    'description', s.description,
    'genre', s.genre,
    'free_episode_count', s.free_episode_count,
    'thumbnail_url', coalesce(
      nullif(s.thumbnail_url, ''),
      (select nullif(e2.thumbnail_url, '')
         from episodes e2 join projects p2 on p2.id = e2.project_id
        where e2.series_id = s.id and p2.status = 'published' and e2.thumbnail_url <> ''
        order by e2.episode_number limit 1),
      ''
    ),
    'episodes', coalesce((
      select jsonb_agg(jsonb_build_object(
        'episode_id', e.id,
        'episode_number', e.episode_number,
        'title', e.title,
        'duration_seconds', e.duration_seconds,
        'thumbnail_url', e.thumbnail_url
      ) order by e.episode_number)
      from episodes e join projects p on p.id = e.project_id
      where e.series_id = s.id and p.status = 'published'
    ), '[]'::jsonb)
  )
  from series s where s.id = p_series
$$;

create function series_playlist(p_series uuid)
returns table (
  series_id uuid, series_title text, series_description text, genre text,
  series_thumbnail text, episode_id uuid, episode_number integer, episode_title text,
  episode_description text, episode_thumbnail text, duration_seconds integer,
  aspect_ratio text, video_key text, video_revision text, video_width integer,
  video_height integer, published_count integer, likes integer
) language sql stable security definer set search_path = public as $$
  select
    s.id, s.title, s.description, s.genre, s.thumbnail_url,
    e.id, e.episode_number, e.title, e.description, e.thumbnail_url, e.duration_seconds,
    p.aspect_ratio, j.video_key, j.video_revision, j.video_width, j.video_height,
    (select count(*)::integer from episodes e2 join projects p2 on p2.id = e2.project_id
      where e2.series_id = s.id and p2.status = 'published'),
    (select count(*)::integer from episode_likes l where l.episode_id = e.id)
  from series s
  join episodes e on e.series_id = s.id
  join projects p on p.id = e.project_id
  cross join lateral (
    select g.output->>'key' as video_key,
      g.output->>'revision' as video_revision,
      coalesce((g.output->>'width')::integer, 1080) as video_width,
      coalesce((g.output->>'height')::integer, 1920) as video_height
    from generation_jobs g
    where g.project_id = e.project_id and g.provider = 'dramabyte-published'
      and g.status = 'completed' and g.output ? 'key'
    order by g.created_at desc limit 1
  ) j
  where s.id = p_series and p.status = 'published'
    and (s.free_episode_count is null or e.episode_number <= s.free_episode_count)
  order by e.episode_number
$$;

revoke all on function series_details(uuid) from public, anon, authenticated;
revoke all on function series_playlist(uuid) from public, anon, authenticated;
grant execute on function series_details(uuid) to service_role;
grant execute on function series_playlist(uuid) to service_role;
