alter table series add column thumbnail_url text not null default '';
alter table series add column genre text not null default 'Drama';
alter table series add column target_episode_count integer not null default 15 check (target_episode_count between 1 and 500);
alter table series add column target_episode_seconds integer not null default 60 check (target_episode_seconds between 10 and 600);
alter table episodes add column title text not null default '';
alter table episodes add column description text not null default '';
alter table episodes add column thumbnail_url text not null default '';
alter table episodes add column duration_seconds integer not null default 60 check (duration_seconds between 1 and 3600);
update episodes e set title = p.title, description = p.premise from projects p where p.id = e.project_id;

create table episode_views (
  id uuid primary key default gen_random_uuid(),
  episode_id uuid not null references episodes(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  session_id uuid not null,
  watched_seconds integer not null check (watched_seconds >= 10),
  created_at timestamptz not null default now(),
  unique(episode_id, user_id, session_id)
);
create table episode_likes (
  episode_id uuid not null references episodes(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(episode_id, user_id)
);
create table series_ratings (
  series_id uuid not null references series(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  created_at timestamptz not null default now(),
  primary key(series_id, user_id)
);
create table episode_comments (
  id uuid primary key default gen_random_uuid(),
  episode_id uuid not null references episodes(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  body text not null check (char_length(trim(body)) between 1 and 2000),
  is_hidden boolean not null default false,
  created_at timestamptz not null default now()
);
alter table episode_views enable row level security;
alter table episode_likes enable row level security;
alter table series_ratings enable row level security;
alter table episode_comments enable row level security;
create index episode_comments_created_idx on episode_comments(created_at desc);
create index episode_views_created_idx on episode_views(created_at desc);
create unique index episode_views_daily_unique on episode_views(episode_id, user_id, ((created_at at time zone 'UTC')::date));

create view episode_metrics as
select e.*,
  (select count(*) from episode_views v where v.episode_id = e.id) as views,
  (select count(*) from episode_likes l where l.episode_id = e.id) as likes,
  (select count(*) from episode_comments c where c.episode_id = e.id and not c.is_hidden) as comments
from episodes e;

create view series_metrics as
select s.*,
  (select count(*) from episodes e where e.series_id = s.id) as episode_count,
  (select count(*) from episodes e join projects p on p.id = e.project_id where e.series_id = s.id and p.status = 'published') as published_episodes,
  coalesce((select sum(duration_seconds) from episodes e where e.series_id = s.id), 0) as duration_seconds,
  (select count(*) from episode_views v join episodes e on e.id = v.episode_id where e.series_id = s.id) as views,
  (select count(*) from episode_likes l join episodes e on e.id = l.episode_id where e.series_id = s.id) as likes,
  (select count(*) from episode_comments c join episodes e on e.id = c.episode_id where e.series_id = s.id and not c.is_hidden) as comments,
  (select round(avg(r.rating), 2) from series_ratings r where r.series_id = s.id) as rating,
  (select count(*) from series_ratings r where r.series_id = s.id) as rating_count
from series s;

revoke all on episode_metrics, series_metrics from anon, authenticated;
grant select on episode_metrics, series_metrics to service_role;

create view platform_summary as select
  (select count(*) from series) as series_count,
  (select count(*) from episodes) as episode_count,
  (select count(*) from episodes e join projects p on p.id = e.project_id where p.status = 'published') as published_episodes,
  (select count(*) from episode_views) as views,
  (select count(*) from episode_likes) as likes,
  (select count(*) from episode_comments where not is_hidden) as comments,
  (select round(avg(rating), 2) from series_ratings) as rating,
  (select count(*) from series_ratings) as rating_count;
create view daily_engagement as select
  (created_at at time zone 'UTC')::date as day, count(*) as views
from episode_views group by (created_at at time zone 'UTC')::date;
revoke all on platform_summary, daily_engagement from anon, authenticated;
grant select on platform_summary, daily_engagement to service_role;
