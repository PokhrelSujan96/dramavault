alter table profiles add column is_suspended boolean not null default false;
alter table profiles add column deleted_at timestamptz;

create table series (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 160),
  description text not null default '',
  created_at timestamptz not null default now()
);

create table episodes (
  id uuid primary key default gen_random_uuid(),
  series_id uuid not null references series(id) on delete cascade,
  project_id uuid not null unique references projects(id) on delete cascade,
  episode_number integer not null check (episode_number > 0),
  unique (series_id, episode_number)
);

create table coin_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id),
  admin_id uuid not null references auth.users(id),
  amount integer not null check (amount <> 0),
  reason text not null,
  request_id uuid not null unique,
  balance_after integer not null,
  created_at timestamptz not null default now()
);

alter table series enable row level security;
alter table episodes enable row level security;
alter table coin_transactions enable row level security;

create function admin_adjust_coins(
  target_id uuid, actor_id uuid, delta integer, note text, operation_id uuid
) returns jsonb language plpgsql security definer set search_path = public as $$
declare
  balance integer;
  previous coin_transactions;
begin
  if delta = 0 or char_length(trim(note)) < 3 then
    raise exception 'A non-zero amount and reason are required';
  end if;
  perform 1 from profiles where id = target_id and deleted_at is null for update;
  if not found then raise exception 'User not found'; end if;
  select * into previous from coin_transactions where request_id = operation_id;
  if found then
    if previous.user_id <> target_id or previous.amount <> delta or previous.admin_id <> actor_id then
      raise exception 'Request identifier already used';
    end if;
    return to_jsonb(previous);
  end if;
  update profiles set coins = coins + delta where id = target_id and coins + delta >= 0 returning coins into balance;
  if not found then raise exception 'Insufficient coin balance'; end if;
  insert into coin_transactions(user_id, admin_id, amount, reason, request_id, balance_after)
  values(target_id, actor_id, delta, note, operation_id, balance) returning * into previous;
  return to_jsonb(previous);
end;
$$;

revoke all on function admin_adjust_coins(uuid, uuid, integer, text, uuid) from public, anon, authenticated;
grant execute on function admin_adjust_coins(uuid, uuid, integer, text, uuid) to service_role;
