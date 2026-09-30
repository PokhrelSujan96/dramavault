alter table profiles add column if not exists marketing_opt_in boolean not null default false;
alter table profiles add column if not exists analytics_consent boolean not null default false;
alter table profiles add column if not exists personalization_consent boolean not null default false;
alter table profiles add column if not exists consent_updated_at timestamptz;

create table if not exists consent_events (
  id bigint generated always as identity primary key,
  user_id uuid not null,
  purpose text not null check (purpose in ('marketing', 'analytics', 'personalization')),
  granted boolean not null,
  created_at timestamptz not null default now()
);

create index if not exists consent_events_user_idx on consent_events (user_id, created_at desc);
alter table consent_events enable row level security;

create or replace function save_preferences(
  p_user uuid, p_marketing boolean, p_analytics boolean, p_personalization boolean
) returns void
language plpgsql security definer set search_path = public as $$
declare
  old profiles%rowtype;
begin
  select * into old from profiles where id = p_user and deleted_at is null for update;
  if not found then
    return;
  end if;
  if old.marketing_opt_in is distinct from p_marketing then
    insert into consent_events (user_id, purpose, granted) values (p_user, 'marketing', p_marketing);
  end if;
  if old.analytics_consent is distinct from p_analytics then
    insert into consent_events (user_id, purpose, granted) values (p_user, 'analytics', p_analytics);
  end if;
  if old.personalization_consent is distinct from p_personalization then
    insert into consent_events (user_id, purpose, granted) values (p_user, 'personalization', p_personalization);
  end if;
  update profiles
  set marketing_opt_in = p_marketing,
      analytics_consent = p_analytics,
      personalization_consent = p_personalization,
      consent_updated_at = now()
  where id = p_user;
end;
$$;

create or replace function delete_account(p_user uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  update profiles
  set email = null,
      display_name = 'Deleted user',
      avatar_url = null,
      country = null,
      marketing_opt_in = false,
      analytics_consent = false,
      personalization_consent = false,
      deleted_at = now(),
      updated_at = now()
  where id = p_user and deleted_at is null;
  delete from consent_events where user_id = p_user;
end;
$$;

revoke all on function save_preferences(uuid, boolean, boolean, boolean) from public, anon, authenticated;
revoke all on function delete_account(uuid) from public, anon, authenticated;
grant execute on function save_preferences(uuid, boolean, boolean, boolean) to service_role;
grant execute on function delete_account(uuid) to service_role;
