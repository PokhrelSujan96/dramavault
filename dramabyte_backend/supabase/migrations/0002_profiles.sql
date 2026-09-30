create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text not null default '',
  avatar_url text,
  auth_provider text not null default 'email',
  country text,
  language text not null default 'en',
  coins integer not null default 0 check (coins >= 0),
  bonus_coins integer not null default 0 check (bonus_coins >= 0),
  vip_expires_at timestamptz,
  is_onboarded boolean not null default false,
  last_login_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, email, display_name, avatar_url, auth_provider)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(coalesce(new.email, ''), '@', 1)),
    coalesce(new.raw_user_meta_data->>'avatar_url', new.raw_user_meta_data->>'picture'),
    coalesce(new.raw_app_meta_data->>'provider', 'email')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function handle_new_user();

create function touch_updated_at() returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_touch_updated_at
before update on profiles
for each row execute function touch_updated_at();

alter table profiles enable row level security;

create policy profiles_owner_read on profiles
for select using (auth.uid() = id);
