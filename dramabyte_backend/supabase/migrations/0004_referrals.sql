create function generate_referral_code() returns text
language plpgsql volatile as $$
declare
  candidate text;
begin
  loop
    candidate := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
    exit when not exists (select 1 from profiles where referral_code = candidate);
  end loop;
  return candidate;
end;
$$;

alter table profiles add column referral_code text unique;
alter table profiles add column first_purchase_at timestamptz;
update profiles set referral_code = generate_referral_code() where referral_code is null;
alter table profiles alter column referral_code set not null;
alter table profiles alter column referral_code set default generate_referral_code();

create table referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_id uuid not null references profiles(id),
  referee_id uuid not null unique references profiles(id),
  status text not null default 'signed_up' check (status in ('signed_up', 'rewarded')),
  purchase_ref text,
  created_at timestamptz not null default now(),
  rewarded_at timestamptz,
  check (referrer_id <> referee_id)
);

create index referrals_referrer_idx on referrals(referrer_id);

create table referral_rewards (
  id uuid primary key default gen_random_uuid(),
  referral_id uuid not null references referrals(id),
  user_id uuid not null references profiles(id),
  kind text not null check (kind in ('signup', 'purchase')),
  role text not null check (role in ('referrer', 'referee')),
  amount integer not null check (amount > 0),
  created_at timestamptz not null default now(),
  unique (referral_id, kind, user_id)
);

create index referral_rewards_user_idx on referral_rewards(user_id);

alter table referrals enable row level security;
alter table referral_rewards enable row level security;

create policy referrals_participant_read on referrals
for select using (auth.uid() = referrer_id or auth.uid() = referee_id);

create policy referral_rewards_owner_read on referral_rewards
for select using (auth.uid() = user_id);

create function grant_referral_reward(
  p_referral uuid, p_user uuid, p_kind text, p_role text, p_amount integer
) returns void language plpgsql security definer set search_path = public as $$
declare
  inserted integer;
begin
  insert into referral_rewards(referral_id, user_id, kind, role, amount)
  values (p_referral, p_user, p_kind, p_role, p_amount)
  on conflict (referral_id, kind, user_id) do nothing;
  get diagnostics inserted = row_count;
  if inserted = 1 then
    update profiles set bonus_coins = bonus_coins + p_amount where id = p_user;
  end if;
end;
$$;

create function redeem_referral(
  p_user uuid, p_code text, p_reward integer, p_max_referrals integer, p_window_hours integer
) returns text language plpgsql security definer set search_path = public as $$
declare
  me profiles;
  sponsor profiles;
  new_referral uuid;
begin
  select * into me from profiles
  where id = p_user and deleted_at is null and not is_suspended for update;
  if not found then return 'user_not_found'; end if;
  if exists (select 1 from referrals where referee_id = p_user) then
    return 'already_redeemed';
  end if;
  if me.first_purchase_at is not null
     or me.created_at < now() - make_interval(hours => p_window_hours) then
    return 'not_eligible';
  end if;
  select * into sponsor from profiles
  where referral_code = upper(trim(p_code)) and deleted_at is null and not is_suspended
  for update;
  if not found or sponsor.id = me.id or sponsor.created_at >= me.created_at then
    return 'invalid_code';
  end if;
  if (select count(*) from referrals where referrer_id = sponsor.id) >= p_max_referrals then
    return 'invalid_code';
  end if;
  insert into referrals(referrer_id, referee_id) values (sponsor.id, me.id)
  returning id into new_referral;
  perform grant_referral_reward(new_referral, sponsor.id, 'signup', 'referrer', p_reward);
  perform grant_referral_reward(new_referral, me.id, 'signup', 'referee', p_reward);
  return 'ok';
end;
$$;

create function record_first_purchase(
  p_user uuid, p_purchase_ref text, p_reward integer
) returns text language plpgsql security definer set search_path = public as $$
declare
  me profiles;
  link referrals;
begin
  select * into me from profiles where id = p_user and deleted_at is null for update;
  if not found then return 'user_not_found'; end if;
  if me.first_purchase_at is not null then return 'not_first'; end if;
  update profiles set first_purchase_at = now() where id = p_user;
  select * into link from referrals
  where referee_id = p_user and status = 'signed_up' for update;
  if not found then return 'no_referral'; end if;
  update referrals set status = 'rewarded', rewarded_at = now(), purchase_ref = p_purchase_ref
  where id = link.id;
  perform grant_referral_reward(link.id, link.referrer_id, 'purchase', 'referrer', p_reward);
  perform grant_referral_reward(link.id, p_user, 'purchase', 'referee', p_reward);
  return 'ok';
end;
$$;

revoke all on function generate_referral_code() from public, anon, authenticated;
revoke all on function grant_referral_reward(uuid, uuid, text, text, integer) from public, anon, authenticated;
revoke all on function redeem_referral(uuid, text, integer, integer, integer) from public, anon, authenticated;
revoke all on function record_first_purchase(uuid, text, integer) from public, anon, authenticated;
grant execute on function redeem_referral(uuid, text, integer, integer, integer) to service_role;
grant execute on function record_first_purchase(uuid, text, integer) to service_role;
