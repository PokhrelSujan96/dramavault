create table coin_packages (
  id text primary key check (id ~ '^[a-z0-9_]{3,40}$'),
  product_id text not null unique,
  coins integer not null check (coins > 0),
  bonus_coins integer not null default 0 check (bonus_coins >= 0),
  price_cents integer not null check (price_cents > 0),
  currency text not null default 'USD' check (currency ~ '^[A-Z]{3}$'),
  sort_order integer not null default 0,
  active boolean not null default true
);

insert into coin_packages (id, product_id, coins, bonus_coins, price_cents, sort_order) values
  ('coins_60', 'com.dramabyte.app.coins_60', 60, 0, 99, 1),
  ('coins_300', 'com.dramabyte.app.coins_300', 300, 20, 499, 2),
  ('coins_700', 'com.dramabyte.app.coins_700', 700, 70, 999, 3),
  ('coins_1500', 'com.dramabyte.app.coins_1500', 1500, 200, 1999, 4),
  ('coins_4000', 'com.dramabyte.app.coins_4000', 4000, 700, 4999, 5);

create table topup_orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id),
  package_id text not null references coin_packages(id),
  product_id text not null,
  coins integer not null check (coins > 0),
  bonus_coins integer not null check (bonus_coins >= 0),
  price_cents integer not null check (price_cents > 0),
  currency text not null,
  status text not null default 'pending'
    check (status in ('pending', 'completed', 'expired', 'refunded')),
  idempotency_key text not null check (idempotency_key ~ '^[A-Za-z0-9_-]{16,64}$'),
  provider text,
  provider_ref text unique,
  balance_after integer,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  completed_at timestamptz,
  unique (user_id, idempotency_key),
  check (status <> 'completed' or (provider is not null and provider_ref is not null))
);

create index topup_orders_user_idx on topup_orders(user_id, created_at desc);

alter table coin_packages enable row level security;
alter table topup_orders enable row level security;

create policy coin_packages_public_read on coin_packages for select using (active);
create policy topup_orders_owner_read on topup_orders for select using (auth.uid() = user_id);

create function create_topup_order(
  p_user uuid, p_package text, p_key text, p_ttl_minutes integer, p_max_pending integer
) returns jsonb language plpgsql security definer set search_path = public as $$
declare
  me profiles;
  pack coin_packages;
  existing topup_orders;
  created topup_orders;
begin
  select * into me from profiles
  where id = p_user and deleted_at is null and not is_suspended for update;
  if not found then return jsonb_build_object('code', 'user_unavailable'); end if;
  select * into existing from topup_orders where user_id = p_user and idempotency_key = p_key;
  if found then
    if existing.package_id <> p_package then
      return jsonb_build_object('code', 'key_reused');
    end if;
    return jsonb_build_object('code', 'ok', 'order', to_jsonb(existing));
  end if;
  select * into pack from coin_packages where id = p_package and active;
  if not found then return jsonb_build_object('code', 'package_not_found'); end if;
  if (select count(*) from topup_orders
      where user_id = p_user and status = 'pending' and expires_at > now()) >= p_max_pending then
    return jsonb_build_object('code', 'too_many_pending');
  end if;
  insert into topup_orders (
    user_id, package_id, product_id, coins, bonus_coins, price_cents, currency,
    idempotency_key, expires_at
  ) values (
    p_user, pack.id, pack.product_id, pack.coins, pack.bonus_coins, pack.price_cents,
    pack.currency, p_key, now() + make_interval(mins => p_ttl_minutes)
  ) returning * into created;
  return jsonb_build_object('code', 'ok', 'order', to_jsonb(created));
end;
$$;

create function complete_topup(
  p_order uuid, p_user uuid, p_provider text, p_provider_ref text, p_referral_reward integer
) returns jsonb language plpgsql security definer set search_path = public as $$
declare
  o topup_orders;
  me profiles;
  new_balance integer;
begin
  select * into o from topup_orders where id = p_order and user_id = p_user for update;
  if not found then return jsonb_build_object('code', 'order_not_found'); end if;
  if o.status = 'completed' then
    return jsonb_build_object('code', 'ok', 'order', to_jsonb(o));
  end if;
  if o.status <> 'pending' then return jsonb_build_object('code', 'invalid_state'); end if;
  if o.expires_at <= now() then
    update topup_orders set status = 'expired' where id = o.id;
    return jsonb_build_object('code', 'expired');
  end if;
  select * into me from profiles
  where id = o.user_id and deleted_at is null and not is_suspended for update;
  if not found then return jsonb_build_object('code', 'user_unavailable'); end if;
  begin
    update topup_orders
    set status = 'completed', provider = p_provider, provider_ref = p_provider_ref,
        completed_at = now()
    where id = o.id;
  exception when unique_violation then
    return jsonb_build_object('code', 'payment_reused');
  end;
  update profiles
  set coins = coins + o.coins, bonus_coins = bonus_coins + o.bonus_coins
  where id = o.user_id
  returning coins into new_balance;
  update topup_orders set balance_after = new_balance where id = o.id returning * into o;
  perform record_first_purchase(o.user_id, o.id::text, p_referral_reward);
  return jsonb_build_object('code', 'ok', 'order', to_jsonb(o));
end;
$$;

create function refund_topup(p_order uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  o topup_orders;
begin
  select * into o from topup_orders where id = p_order for update;
  if not found then return jsonb_build_object('code', 'order_not_found'); end if;
  if o.status <> 'completed' then return jsonb_build_object('code', 'invalid_state'); end if;
  perform 1 from profiles where id = o.user_id for update;
  update profiles
  set coins = greatest(coins - o.coins, 0), bonus_coins = greatest(bonus_coins - o.bonus_coins, 0)
  where id = o.user_id;
  update topup_orders set status = 'refunded' where id = o.id returning * into o;
  return jsonb_build_object('code', 'ok', 'order', to_jsonb(o));
end;
$$;

revoke all on function create_topup_order(uuid, text, text, integer, integer) from public, anon, authenticated;
revoke all on function complete_topup(uuid, uuid, text, text, integer) from public, anon, authenticated;
revoke all on function refund_topup(uuid) from public, anon, authenticated;
grant execute on function create_topup_order(uuid, text, text, integer, integer) to service_role;
grant execute on function complete_topup(uuid, uuid, text, text, integer) to service_role;
grant execute on function refund_topup(uuid) to service_role;
