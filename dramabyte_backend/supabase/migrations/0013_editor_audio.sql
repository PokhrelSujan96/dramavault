create or replace function public.editor_audio_ready()
returns boolean language sql security invoker set search_path = public
as $$ select true $$;

create or replace function public.commit_editor_audio(
    audio_job uuid, expected_preview uuid, expected_editor uuid,
    preview_output jsonb, editor_output jsonb
) returns void language plpgsql security invoker set search_path = public
as $$
declare
    target uuid;
    current_preview uuid;
    current_editor uuid;
begin
    select project_id into target from generation_jobs
    where id = audio_job and provider = 'dramabyte-editor-audio'
    and status = 'processing' for update;
    if target is null then raise exception 'Audio operation is not active'; end if;
    perform id from projects where id = target for update;
    if not exists (select 1 from projects where id = target
                   and status in ('ready', 'published')) then
        raise exception 'Project changed during voice replacement';
    end if;
    select id into current_preview from generation_jobs
    where project_id = target and provider = 'cloudflare-r2-preview'
    order by created_at desc limit 1;
    select id into current_editor from generation_jobs
    where project_id = target and provider = 'dramabyte-editor'
    order by created_at desc limit 1;
    if current_preview is distinct from expected_preview
       or current_editor is distinct from expected_editor then
        raise exception 'Editor changed during voice replacement. Original retained';
    end if;
    insert into generation_jobs (project_id, stage, provider, status, output)
    values (target, 'publish', 'cloudflare-r2-preview', 'completed', preview_output),
           (target, 'subtitles', 'dramabyte-editor', 'completed', editor_output);
    update generation_jobs set status = 'completed', output = preview_output
    where id = audio_job;
end;
$$;

revoke all on function public.editor_audio_ready() from public, anon, authenticated;
revoke all on function public.commit_editor_audio(uuid, uuid, uuid, jsonb, jsonb)
from public, anon, authenticated;
grant execute on function public.editor_audio_ready() to service_role;
grant execute on function public.commit_editor_audio(uuid, uuid, uuid, jsonb, jsonb)
to service_role;
