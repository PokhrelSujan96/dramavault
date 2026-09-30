create function home_feed(p_limit integer) returns jsonb
language sql stable security definer set search_path = public as $$
  with catalog as (
    select
      s.id as series_id, s.title, s.description, s.genre, s.created_at,
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
      (select count(*)::integer from episode_views v join episodes e on e.id = v.episode_id
        where e.series_id = s.id and v.created_at > now() - interval '7 days') as recent_views
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
