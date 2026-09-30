alter table episode_comments add column if not exists parent_id uuid references episode_comments(id) on delete cascade;
alter table episode_comments add column if not exists like_count integer not null default 0 check (like_count >= 0);
alter table episode_comments add column if not exists reply_count integer not null default 0 check (reply_count >= 0);
alter table episode_comments add column if not exists idempotency_key uuid;

create unique index if not exists episode_comments_idempotency_idx
  on episode_comments (user_id, idempotency_key) where idempotency_key is not null;
create index if not exists episode_comments_newest_idx
  on episode_comments (episode_id, created_at desc, id desc)
  where parent_id is null and not is_hidden;
create index if not exists episode_comments_top_idx
  on episode_comments (episode_id, like_count desc, created_at desc, id desc)
  where parent_id is null and not is_hidden;
create index if not exists episode_comments_replies_idx
  on episode_comments (parent_id, created_at, id)
  where parent_id is not null and not is_hidden;
create index if not exists episode_comments_author_idx
  on episode_comments (user_id, created_at desc);

alter table episode_stats add column if not exists comments bigint not null default 0 check (comments >= 0);

update episode_stats st set comments = (
  select count(*) from episode_comments c
  where c.episode_id = st.episode_id and not c.is_hidden
);

create table if not exists comment_likes (
  comment_id uuid not null references episode_comments(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (comment_id, user_id)
);

create index if not exists comment_likes_user_idx on comment_likes(user_id);
alter table comment_likes enable row level security;

create table if not exists comment_reports (
  comment_id uuid not null references episode_comments(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  reason text not null check (char_length(reason) between 1 and 200),
  created_at timestamptz not null default now(),
  primary key (comment_id, user_id)
);

alter table comment_reports enable row level security;

create or replace function sync_comment_counts() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  delta integer;
begin
  if tg_op = 'INSERT' then
    if not new.is_hidden then
      insert into episode_stats (episode_id, comments) values (new.episode_id, 1)
      on conflict (episode_id) do update
      set comments = episode_stats.comments + 1, updated_at = now();
      if new.parent_id is not null then
        update episode_comments set reply_count = reply_count + 1 where id = new.parent_id;
      end if;
    end if;
  elsif tg_op = 'DELETE' then
    if not old.is_hidden then
      update episode_stats set comments = greatest(comments - 1, 0), updated_at = now()
      where episode_id = old.episode_id;
      if old.parent_id is not null then
        update episode_comments set reply_count = greatest(reply_count - 1, 0)
        where id = old.parent_id;
      end if;
    end if;
  elsif old.is_hidden is distinct from new.is_hidden then
    delta := case when new.is_hidden then -1 else 1 end;
    update episode_stats set comments = greatest(comments + delta, 0), updated_at = now()
    where episode_id = new.episode_id;
    if new.parent_id is not null then
      update episode_comments set reply_count = greatest(reply_count + delta, 0)
      where id = new.parent_id;
    end if;
  end if;
  return null;
end;
$$;

drop trigger if exists episode_comments_counts on episode_comments;
create trigger episode_comments_counts
after insert or delete or update of is_hidden on episode_comments
for each row execute function sync_comment_counts();

create or replace function sync_comment_like_count() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    update episode_comments set like_count = like_count + 1 where id = new.comment_id;
  else
    update episode_comments set like_count = greatest(like_count - 1, 0)
    where id = old.comment_id;
  end if;
  return null;
end;
$$;

drop trigger if exists comment_likes_count on comment_likes;
create trigger comment_likes_count after insert or delete on comment_likes
for each row execute function sync_comment_like_count();

create or replace view comment_feed as
select
  c.id, c.episode_id, c.parent_id, c.body, c.created_at,
  c.like_count, c.reply_count, c.is_hidden,
  c.user_id as author_id,
  coalesce(nullif(p.display_name, ''), 'Deleted user') as author_name,
  p.avatar_url as author_avatar
from episode_comments c
left join profiles p on p.id = c.user_id and p.deleted_at is null;

create or replace function comment_json(v comment_feed, p_viewer uuid) returns jsonb
language sql stable set search_path = public as $$
  select jsonb_build_object(
    'id', v.id,
    'episode_id', v.episode_id,
    'parent_id', v.parent_id,
    'body', v.body,
    'created_at', v.created_at,
    'like_count', v.like_count,
    'reply_count', v.reply_count,
    'author_id', v.author_id,
    'author_name', v.author_name,
    'author_avatar', v.author_avatar,
    'liked', exists (
      select 1 from comment_likes l where l.comment_id = v.id and l.user_id = p_viewer
    )
  )
$$;

create or replace function list_comments_new(
  p_viewer uuid, p_episode uuid, p_after_created timestamptz, p_after_id uuid, p_limit integer
) returns setof jsonb language sql stable security definer set search_path = public as $$
  select comment_json(v, p_viewer) from comment_feed v
  where v.episode_id = p_episode and v.parent_id is null and not v.is_hidden
    and (p_after_created is null or (v.created_at, v.id) < (p_after_created, p_after_id))
  order by v.created_at desc, v.id desc
  limit p_limit
$$;

create or replace function list_comments_top(
  p_viewer uuid, p_episode uuid, p_after_likes integer,
  p_after_created timestamptz, p_after_id uuid, p_limit integer
) returns setof jsonb language sql stable security definer set search_path = public as $$
  select comment_json(v, p_viewer) from comment_feed v
  where v.episode_id = p_episode and v.parent_id is null and not v.is_hidden
    and (p_after_likes is null
         or (v.like_count, v.created_at, v.id) < (p_after_likes, p_after_created, p_after_id))
  order by v.like_count desc, v.created_at desc, v.id desc
  limit p_limit
$$;

create or replace function list_comment_replies(
  p_viewer uuid, p_parent uuid, p_after_created timestamptz, p_after_id uuid, p_limit integer
) returns setof jsonb language sql stable security definer set search_path = public as $$
  select comment_json(v, p_viewer) from comment_feed v
  where v.parent_id = p_parent and not v.is_hidden
    and exists (select 1 from episode_comments c where c.id = p_parent and not c.is_hidden)
    and (p_after_created is null or (v.created_at, v.id) > (p_after_created, p_after_id))
  order by v.created_at asc, v.id asc
  limit p_limit
$$;

create or replace function comments_by_ids(p_viewer uuid, p_ids uuid[])
returns setof jsonb language sql stable security definer set search_path = public as $$
  select comment_json(v, p_viewer) from comment_feed v
  where v.id = any (p_ids) and not v.is_hidden
$$;

create or replace function post_comment(
  p_user uuid, p_episode uuid, p_parent uuid, p_body text, p_key uuid,
  p_max_per_minute integer, p_max_length integer
) returns jsonb language plpgsql security definer set search_path = public as $$
declare
  body text := btrim(coalesce(p_body, ''));
  parent_row episode_comments;
  target uuid := p_parent;
  existing uuid;
  recent integer;
  created uuid;
begin
  perform 1 from profiles where id = p_user and deleted_at is null and not is_suspended;
  if not found then return jsonb_build_object('code', 'user_unavailable'); end if;
  if char_length(body) < 1 or char_length(body) > p_max_length then
    return jsonb_build_object('code', 'invalid_body');
  end if;
  perform 1 from episodes e join projects p on p.id = e.project_id
  where e.id = p_episode and p.status = 'published';
  if not found then return jsonb_build_object('code', 'episode_not_found'); end if;
  if p_key is not null then
    select id into existing from episode_comments
    where user_id = p_user and idempotency_key = p_key;
    if found then return jsonb_build_object('code', 'ok', 'id', existing); end if;
  end if;
  select count(*) into recent from episode_comments
  where user_id = p_user and created_at > now() - interval '1 minute';
  if recent >= p_max_per_minute then return jsonb_build_object('code', 'rate_limited'); end if;
  if p_parent is not null then
    select * into parent_row from episode_comments
    where id = p_parent and episode_id = p_episode and not is_hidden;
    if not found then return jsonb_build_object('code', 'parent_not_found'); end if;
    if parent_row.parent_id is not null then target := parent_row.parent_id; end if;
  end if;
  insert into episode_comments (episode_id, user_id, parent_id, body, idempotency_key)
  values (p_episode, p_user, target, body, p_key)
  on conflict (user_id, idempotency_key) where idempotency_key is not null do nothing
  returning id into created;
  if created is null then
    select id into created from episode_comments
    where user_id = p_user and idempotency_key = p_key;
  end if;
  return jsonb_build_object('code', 'ok', 'id', created);
end;
$$;

create or replace function toggle_comment_like(p_user uuid, p_comment uuid, p_liked boolean)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  total integer;
begin
  perform 1 from profiles where id = p_user and deleted_at is null and not is_suspended;
  if not found then return jsonb_build_object('code', 'user_unavailable'); end if;
  perform 1 from episode_comments where id = p_comment and not is_hidden;
  if not found then return jsonb_build_object('code', 'comment_not_found'); end if;
  if p_liked then
    insert into comment_likes (comment_id, user_id) values (p_comment, p_user)
    on conflict do nothing;
  else
    delete from comment_likes where comment_id = p_comment and user_id = p_user;
  end if;
  select like_count into total from episode_comments where id = p_comment;
  return jsonb_build_object('code', 'ok', 'like_count', total);
end;
$$;

create or replace function delete_comment(p_user uuid, p_comment uuid)
returns text language plpgsql security definer set search_path = public as $$
begin
  delete from episode_comments where id = p_comment and user_id = p_user;
  if not found then return 'comment_not_found'; end if;
  return 'ok';
end;
$$;

create or replace function report_comment(p_user uuid, p_comment uuid, p_reason text)
returns text language plpgsql security definer set search_path = public as $$
begin
  perform 1 from profiles where id = p_user and deleted_at is null and not is_suspended;
  if not found then return 'user_unavailable'; end if;
  perform 1 from episode_comments where id = p_comment;
  if not found then return 'comment_not_found'; end if;
  insert into comment_reports (comment_id, user_id, reason)
  values (p_comment, p_user, left(btrim(p_reason), 200))
  on conflict do nothing;
  return 'ok';
end;
$$;

revoke all on comment_feed from anon, authenticated;
grant select on comment_feed to service_role;
revoke all on function sync_comment_counts() from public, anon, authenticated;
revoke all on function sync_comment_like_count() from public, anon, authenticated;
revoke all on function comment_json(comment_feed, uuid) from public, anon, authenticated;
revoke all on function list_comments_new(uuid, uuid, timestamptz, uuid, integer) from public, anon, authenticated;
revoke all on function list_comments_top(uuid, uuid, integer, timestamptz, uuid, integer) from public, anon, authenticated;
revoke all on function list_comment_replies(uuid, uuid, timestamptz, uuid, integer) from public, anon, authenticated;
revoke all on function comments_by_ids(uuid, uuid[]) from public, anon, authenticated;
revoke all on function post_comment(uuid, uuid, uuid, text, uuid, integer, integer) from public, anon, authenticated;
revoke all on function toggle_comment_like(uuid, uuid, boolean) from public, anon, authenticated;
revoke all on function delete_comment(uuid, uuid) from public, anon, authenticated;
revoke all on function report_comment(uuid, uuid, text) from public, anon, authenticated;
grant execute on function comment_json(comment_feed, uuid) to service_role;
grant execute on function list_comments_new(uuid, uuid, timestamptz, uuid, integer) to service_role;
grant execute on function list_comments_top(uuid, uuid, integer, timestamptz, uuid, integer) to service_role;
grant execute on function list_comment_replies(uuid, uuid, timestamptz, uuid, integer) to service_role;
grant execute on function comments_by_ids(uuid, uuid[]) to service_role;
grant execute on function post_comment(uuid, uuid, uuid, text, uuid, integer, integer) to service_role;
grant execute on function toggle_comment_like(uuid, uuid, boolean) to service_role;
grant execute on function delete_comment(uuid, uuid) to service_role;
grant execute on function report_comment(uuid, uuid, text) to service_role;
