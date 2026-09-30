do $$
begin
  alter publication supabase_realtime add table profiles;
exception when duplicate_object then null;
end;
$$;

do $$
begin
  alter publication supabase_realtime add table referral_rewards;
exception when duplicate_object then null;
end;
$$;
