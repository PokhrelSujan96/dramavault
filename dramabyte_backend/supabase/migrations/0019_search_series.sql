create function search_series(p_query text, p_limit integer)
returns table (
  series_id uuid, title text, description text, genre text, thumbnail_url text,
  episode_count integer, free_episode_count integer
) language sql stable security definer set search_path = public as $$
  with q as (
    select
      lower(trim(p_query)) as term,
      replace(replace(replace(lower(trim(p_query)), '\', '\\'), '%', '\%'), '_', '\_') as escaped
  )
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
    s.free_episode_count
  from series s, q
  where (
      lower(s.title) like '%' || q.escaped || '%' escape '\'
      or lower(s.genre) like '%' || q.escaped || '%' escape '\'
      or lower(s.description) like '%' || q.escaped || '%' escape '\'
    )
    and exists (
      select 1 from episodes e join projects p on p.id = e.project_id
      where e.series_id = s.id and p.status = 'published'
    )
  order by
    case
      when lower(s.title) = q.term then 0
      when lower(s.title) like q.escaped || '%' escape '\' then 1
      when lower(s.title) like '%' || q.escaped || '%' escape '\' then 2
      when lower(s.genre) like '%' || q.escaped || '%' escape '\' then 3
      else 4
    end,
    s.created_at desc
  limit p_limit
$$;

revoke all on function search_series(text, integer) from public, anon, authenticated;
grant execute on function search_series(text, integer) to service_role;
