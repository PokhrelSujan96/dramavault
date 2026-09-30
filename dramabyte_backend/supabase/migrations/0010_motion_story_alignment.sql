alter table production_runs add column alignment jsonb;
alter table production_shots add column start_seconds double precision;
alter table production_shots add column end_seconds double precision;
alter table production_shots add column scene_spec jsonb not null default '{}'::jsonb;
alter table production_shots add constraint valid_shot_interval check (
  (start_seconds is null and end_seconds is null) or
  (start_seconds >= 0 and end_seconds > start_seconds)
);
