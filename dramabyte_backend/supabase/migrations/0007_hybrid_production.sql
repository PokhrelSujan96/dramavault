create table series_characters (
  id uuid primary key default gen_random_uuid(),
  series_id uuid not null references series(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 80),
  description text not null check (char_length(description) between 20 and 2000),
  reference_key text not null,
  created_at timestamptz not null default now(),
  unique (series_id, name)
);

create table production_runs (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  revision text not null,
  cast_snapshot jsonb not null,
  state text not null default 'planning',
  voice_key text,
  voice_pending boolean not null default false,
  duration_seconds double precision,
  storyboard jsonb,
  master_key text,
  created_at timestamptz not null default now(),
  unique (project_id, revision)
);

create table production_shots (
  id uuid primary key default gen_random_uuid(),
  run_id uuid not null references production_runs(id) on delete cascade,
  shot_index integer not null check (shot_index >= 0),
  kind text not null check (kind in ('motion', 'still')),
  narration text not null,
  prompt text not null,
  character_ids jsonb not null default '[]',
  duration_seconds double precision not null check (duration_seconds > 0),
  image_key text,
  video_key text,
  image_request_id text,
  video_request_id text,
  image_pending boolean not null default false,
  video_pending boolean not null default false,
  approved boolean not null default false,
  image_attempt integer not null default 0 check (image_attempt between 0 and 3),
  image_model text,
  video_model text,
  motion_approved boolean not null default false,
  unique (run_id, shot_index)
);

alter table series_characters enable row level security;
alter table production_runs enable row level security;
alter table production_shots enable row level security;
revoke all on series_characters, production_runs, production_shots from anon, authenticated;
grant all on series_characters, production_runs, production_shots to service_role;
