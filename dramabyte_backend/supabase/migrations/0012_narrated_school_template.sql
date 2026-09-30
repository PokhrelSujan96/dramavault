create table public.story_template_drafts (
  owner_id uuid not null references auth.users(id),
  request_id uuid not null,
  series_id uuid not null references public.series(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  primary key (owner_id, request_id)
);

alter table public.story_template_drafts enable row level security;
revoke all on public.story_template_drafts from anon, authenticated;
grant all on public.story_template_drafts to service_role;

alter table public.production_runs
  add column environment_assets jsonb not null default '{}'::jsonb,
  add column environment_requests jsonb not null default '{}'::jsonb;

create or replace function public.create_school_story_draft(
  p_owner_id uuid, p_request_id uuid, p_script text
) returns jsonb language plpgsql security invoker set search_path = public as $$
declare
  v_series_id uuid;
  v_project_id uuid;
begin
  perform pg_advisory_xact_lock(hashtextextended(p_owner_id::text || p_request_id::text, 0));
  select series_id, project_id into v_series_id, v_project_id
    from story_template_drafts where owner_id = p_owner_id and request_id = p_request_id;
  if found then
    return jsonb_build_object('series_id', v_series_id, 'project_id', v_project_id);
  end if;
  insert into series(title, description, genre, target_episode_count, target_episode_seconds)
    values ('The Last Seat', 'A new student witnesses school bullying and discovers Mia has a secret.',
      'School drama', 15, 90) returning id into v_series_id;
  insert into projects(owner_id, title, premise, script, language, aspect_ratio, production_mode)
    values (p_owner_id, 'Episode 1 · The Girl in the Last Seat',
      'Ellie narrates her first school day, witnessing Mia being bullied in a crowded corridor and classroom. A hidden secret ends the episode on a cliffhanger.',
      p_script, 'en', '9:16', 'narrated') returning id into v_project_id;
  insert into episodes(series_id, project_id, episode_number, title, description, duration_seconds)
    values (v_series_id, v_project_id, 1, 'The Girl in the Last Seat',
      'Ellie sees Mia being bullied and notices her silent tears. What secret is everyone hiding?', 90);
  insert into story_template_drafts(owner_id, request_id, series_id, project_id)
    values (p_owner_id, p_request_id, v_series_id, v_project_id);
  return jsonb_build_object('series_id', v_series_id, 'project_id', v_project_id);
end;
$$;

revoke all on function public.create_school_story_draft(uuid, uuid, text) from public, anon, authenticated;
grant execute on function public.create_school_story_draft(uuid, uuid, text) to service_role;
