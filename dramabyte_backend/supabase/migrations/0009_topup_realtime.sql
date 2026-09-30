do $$
begin
  alter publication supabase_realtime add table coin_packages;
exception when duplicate_object then null;
end;
$$;
