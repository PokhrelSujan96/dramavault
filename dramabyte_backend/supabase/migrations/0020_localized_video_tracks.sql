drop function if exists discover_feed(timestamptz, uuid, integer);

create function discover_feed(p_after_created timestamptz, p_after_id uuid, p_limit integer)
returns table (
  series_id uuid, series_title text, series_description text, genre text,
  series_thumbnail text, series_created_at timestamptz,
  episode_id uuid, episode_number integer, episode_title text,
  episode_description text, episode_thumbnail text, duration_seconds integer,
  aspect_ratio text, video_key text, published_count integer, likes integer,
  video_revision text, video_width integer, video_height integer,
  video_variants jsonb
) language sql stable security definer set search_path = public as $$
  select
    s.id, s.title, s.description, s.genre, s.thumbnail_url, s.created_at,
    e.id, e.episode_number, e.title, e.description, e.thumbnail_url, e.duration_seconds,
    p.aspect_ratio, j.video_key,
    (select count(*)::integer from episodes e2 join projects p2 on p2.id = e2.project_id
      where e2.series_id = s.id and p2.status = 'published'),
    (select count(*)::integer from episode_likes l where l.episode_id = e.id),
    j.video_revision, j.video_width, j.video_height, j.video_variants
  from series s
  cross join lateral (
    select e1.* from episodes e1 join projects p1 on p1.id = e1.project_id
    where e1.series_id = s.id and p1.status = 'published'
    order by e1.episode_number limit 1
  ) e
  join projects p on p.id = e.project_id
  cross join lateral (
    select g.output->>'key' as video_key,
      g.output->>'revision' as video_revision,
      coalesce((g.output->>'width')::integer, 1080) as video_width,
      coalesce((g.output->>'height')::integer, 1920) as video_height,
      coalesce(g.output->'audio_tracks', '{}'::jsonb) as video_variants
    from generation_jobs g
    where g.project_id = e.project_id and g.provider = 'dramabyte-published'
      and g.status = 'completed' and g.output ? 'key'
    order by g.created_at desc limit 1
  ) j
  where p_after_created is null or (s.created_at, s.id) < (p_after_created, p_after_id)
  order by s.created_at desc, s.id desc
  limit p_limit
$$;

revoke all on function discover_feed(timestamptz, uuid, integer) from public, anon, authenticated;
grant execute on function discover_feed(timestamptz, uuid, integer) to service_role;
