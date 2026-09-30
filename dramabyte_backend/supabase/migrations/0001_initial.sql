create type project_status as enum (
  'draft', 'queued', 'generating', 'review', 'ready', 'published', 'failed'
);

create type pipeline_stage as enum (
  'script', 'storyboard', 'images', 'video', 'voice', 'subtitles', 'render', 'publish'
);

create table projects (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 160),
  premise text not null default '',
  script text not null default '',
  language text not null default 'en',
  aspect_ratio text not null default '9:16',
  status project_status not null default 'draft',
  current_stage pipeline_stage not null default 'script',
  progress smallint not null default 0 check (progress between 0 and 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table generation_jobs (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  stage pipeline_stage not null,
  provider text not null,
  provider_job_id text,
  status text not null,
  attempt smallint not null default 0,
  error_code text,
  error_message text,
  input jsonb not null default '{}'::jsonb,
  output jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index projects_owner_updated_idx on projects(owner_id, updated_at desc);
create index generation_jobs_project_idx on generation_jobs(project_id, created_at);

alter table projects enable row level security;
alter table generation_jobs enable row level security;

create policy projects_owner_access on projects
for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

create policy generation_jobs_owner_access on generation_jobs
for all using (
  exists (
    select 1 from projects
    where projects.id = generation_jobs.project_id
      and projects.owner_id = auth.uid()
  )
);
