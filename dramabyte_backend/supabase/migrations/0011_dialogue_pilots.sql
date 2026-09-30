alter table public.projects add column if not exists production_mode text not null default 'narrated' check (production_mode in ('narrated', 'dialogue_pilot'));

create table if not exists public.dialogue_pilots (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null unique references public.projects(id),
  series_id uuid not null references public.series(id),
  owner_id uuid not null references auth.users(id),
  state text not null default 'draft' check (state in ('draft', 'queued', 'voices', 'review', 'video', 'motion_review', 'ready', 'failed')),
  plan jsonb not null,
  cast_snapshot jsonb not null,
  budget_cents integer not null check (budget_cents between 100 and 2000),
  reserved_cents integer not null default 0 check (reserved_cents >= 0 and reserved_cents <= budget_cents),
  assets jsonb not null default '{}'::jsonb,
  requests jsonb not null default '{}'::jsonb,
  approvals jsonb not null default '{}'::jsonb,
  master_key text,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.dialogue_pilots enable row level security;
revoke all on public.dialogue_pilots from anon, authenticated;
grant all on public.dialogue_pilots to service_role;

create index if not exists dialogue_pilots_series_idx on public.dialogue_pilots(series_id, created_at desc);

create or replace function public.create_dialogue_pilot(
  p_owner_id uuid, p_series_id uuid, p_plan jsonb, p_cast jsonb, p_budget_cents integer
) returns jsonb language plpgsql security invoker set search_path = public as $$
declare
  v_project_id uuid;
  v_pilot_id uuid;
begin
  insert into projects(owner_id, title, premise, script, language, aspect_ratio, production_mode)
  values (p_owner_id, p_plan->>'title', 'Private dialogue pilot, not a published episode',
    'Dialogue pilot screenplay', 'en', '9:16', 'dialogue_pilot')
  returning id into v_project_id;
  insert into dialogue_pilots(project_id, series_id, owner_id, plan, cast_snapshot, budget_cents)
  values (v_project_id, p_series_id, p_owner_id, p_plan, p_cast, p_budget_cents)
  returning id into v_pilot_id;
  return jsonb_build_object('id', v_pilot_id, 'project_id', v_project_id);
end;
$$;

revoke all on function public.create_dialogue_pilot(uuid, uuid, jsonb, jsonb, integer) from public, anon, authenticated;
grant execute on function public.create_dialogue_pilot(uuid, uuid, jsonb, jsonb, integer) to service_role;
