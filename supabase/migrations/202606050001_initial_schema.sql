create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  nickname text not null,
  avatar_url text,
  tier text not null default 'Bronze I',
  total_score integer not null default 0,
  season_score integer not null default 0,
  current_streak integer not null default 0,
  best_streak integer not null default 0,
  representative_vehicle_id uuid,
  representative_vehicle_name text,
  is_premium boolean not null default false,
  is_admin boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.app_consents (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  terms_accepted boolean not null default false,
  privacy_accepted boolean not null default false,
  location_accepted boolean not null default false,
  personalized_ads_accepted boolean not null default false,
  marketing_accepted boolean not null default false,
  updated_at timestamptz not null default now()
);

create table if not exists public.vehicles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  manufacturer text not null,
  model_name text not null,
  model_year integer not null,
  fuel_type text not null,
  displacement integer,
  vehicle_class text not null,
  nickname text not null,
  image_url text,
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.drive_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  vehicle_id uuid not null references public.vehicles(id) on delete restrict,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  distance_km numeric(10,2) not null default 0,
  duration_seconds integer not null default 0,
  fuel_used_liters numeric(10,2) not null default 0,
  average_efficiency numeric(10,2) not null default 0,
  source_type text not null default 'geolocator',
  drive_context text not null default 'commute',
  status text not null default 'recording',
  coarse_region text,
  created_at timestamptz not null default now()
);

create table if not exists public.drive_points (
  id uuid primary key default gen_random_uuid(),
  drive_session_id uuid not null references public.drive_sessions(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  latitude double precision not null,
  longitude double precision not null,
  speed_kmh numeric(8,2) not null default 0,
  accuracy numeric(8,2) not null default 0,
  recorded_at timestamptz not null default now()
);

create table if not exists public.drive_scores (
  id uuid primary key default gen_random_uuid(),
  drive_session_id uuid not null references public.drive_sessions(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  total_score integer not null,
  efficiency_score integer not null,
  stability_score integer not null,
  class_percentile integer not null,
  fuel_efficiency_score integer not null,
  acceleration_penalty integer not null default 0,
  braking_penalty integer not null default 0,
  idle_penalty integer not null default 0,
  distance_bonus integer not null default 0,
  consistency_bonus integer not null default 0,
  verification_status text not null default 'pending_review',
  created_at timestamptz not null default now()
);

create table if not exists public.rankings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  vehicle_class text not null,
  fuel_type text not null,
  tier text not null,
  score integer not null,
  rank integer not null,
  previous_rank integer not null,
  percentile integer not null,
  period text not null default 'season',
  created_at timestamptz not null default now()
);

create table if not exists public.battles (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references public.profiles(id) on delete cascade,
  battle_type text not null,
  title text not null,
  rule_type text not null,
  start_at timestamptz not null,
  end_at timestamptz not null,
  status text not null default 'waiting',
  wager_template text not null default 'non_cash_reward',
  reward_summary text not null default '시즌 XP',
  created_at timestamptz not null default now()
);

create table if not exists public.battle_participants (
  battle_id uuid not null references public.battles(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  score integer not null default 0,
  result text not null default 'pending',
  primary key (battle_id, user_id)
);

create table if not exists public.seasons (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  start_at timestamptz not null,
  end_at timestamptz not null,
  status text not null default 'active',
  theme text not null default 'neon_efficiency'
);

create table if not exists public.season_missions (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  title text not null,
  description text not null,
  target integer not null,
  reward_xp integer not null,
  is_weekly boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.mission_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  mission_id uuid not null references public.season_missions(id) on delete cascade,
  progress integer not null default 0,
  reward_claimed boolean not null default false,
  updated_at timestamptz not null default now(),
  unique (user_id, mission_id)
);

create table if not exists public.badges (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null,
  rarity text not null
);

create table if not exists public.user_badges (
  user_id uuid not null references public.profiles(id) on delete cascade,
  badge_id uuid not null references public.badges(id) on delete cascade,
  earned_at timestamptz not null default now(),
  equipped boolean not null default false,
  primary key (user_id, badge_id)
);

create table if not exists public.achievements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  target integer not null
);

create table if not exists public.user_achievements (
  user_id uuid not null references public.profiles(id) on delete cascade,
  achievement_id uuid not null references public.achievements(id) on delete cascade,
  progress integer not null default 0,
  completed boolean not null default false,
  primary key (user_id, achievement_id)
);

create table if not exists public.crews (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.crew_members (
  crew_id uuid not null references public.crews(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member',
  weekly_contribution integer not null default 0,
  joined_at timestamptz not null default now(),
  primary key (crew_id, user_id)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.sponsors (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  logo_url text,
  description text,
  is_active boolean not null default true
);

create table if not exists public.sponsor_challenges (
  id uuid primary key default gen_random_uuid(),
  sponsor_id uuid references public.sponsors(id) on delete set null,
  title text not null,
  description text not null,
  reward_summary text not null,
  starts_at timestamptz not null default now(),
  ends_at timestamptz not null,
  is_active boolean not null default true
);

create table if not exists public.advertisements (
  id uuid primary key default gen_random_uuid(),
  ad_type text not null,
  placement text not null,
  title text not null,
  description text,
  sponsor_id uuid references public.sponsors(id) on delete set null,
  image_url text,
  cta_label text,
  is_active boolean not null default true,
  starts_at timestamptz,
  ends_at timestamptz
);

create table if not exists public.ad_rewards (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  ad_id uuid references public.advertisements(id) on delete set null,
  reward_type text not null,
  claimed_at timestamptz not null default now()
);

create table if not exists public.coupons (
  id uuid primary key default gen_random_uuid(),
  sponsor_id uuid references public.sponsors(id) on delete set null,
  title text not null,
  description text not null,
  expires_at timestamptz not null
);

create table if not exists public.user_coupons (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  coupon_id uuid not null references public.coupons(id) on delete cascade,
  status text not null default 'issued',
  issued_at timestamptz not null default now(),
  used_at timestamptz
);

create table if not exists public.subscription_plans (
  id text primary key,
  title text not null,
  description text not null,
  price_text text not null,
  plan_type text not null,
  benefits jsonb not null default '[]'::jsonb,
  product_id text not null
);

create table if not exists public.user_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  plan_id text not null references public.subscription_plans(id),
  status text not null default 'active',
  started_at timestamptz not null default now(),
  renews_at timestamptz
);

create table if not exists public.fraud_reviews (
  id uuid primary key default gen_random_uuid(),
  drive_session_id uuid not null references public.drive_sessions(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null,
  status text not null default 'pending_review',
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);

create table if not exists public.report_items (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null,
  target_id uuid not null,
  reason text not null,
  status text not null default 'open',
  created_at timestamptz not null default now()
);

drop view if exists public.public_rankings;

create or replace view public.public_rankings as
select
  r.id,
  r.rank,
  r.previous_rank,
  r.score,
  r.percentile,
  r.period,
  p.id as user_id,
  p.nickname,
  p.avatar_url,
  p.tier,
  r.vehicle_class,
  r.fuel_type
from public.rankings r
join public.profiles p on p.id = r.user_id;

alter table public.profiles enable row level security;
alter table public.app_consents enable row level security;
alter table public.vehicles enable row level security;
alter table public.drive_sessions enable row level security;
alter table public.drive_points enable row level security;
alter table public.drive_scores enable row level security;
alter table public.rankings enable row level security;
alter table public.battles enable row level security;
alter table public.battle_participants enable row level security;
alter table public.seasons enable row level security;
alter table public.season_missions enable row level security;
alter table public.mission_progress enable row level security;
alter table public.user_badges enable row level security;
alter table public.user_achievements enable row level security;
alter table public.notifications enable row level security;
alter table public.user_coupons enable row level security;
alter table public.user_subscriptions enable row level security;
alter table public.fraud_reviews enable row level security;
alter table public.report_items enable row level security;

drop policy if exists "profiles_select_self" on public.profiles;
create policy "profiles_select_self" on public.profiles
  for select using (auth.uid() = id);
drop policy if exists "profiles_update_self" on public.profiles;
create policy "profiles_update_self" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "consents_self" on public.app_consents;
create policy "consents_self" on public.app_consents
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "vehicles_self" on public.vehicles;
create policy "vehicles_self" on public.vehicles
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "drive_sessions_self" on public.drive_sessions;
create policy "drive_sessions_self" on public.drive_sessions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "drive_points_private_self" on public.drive_points;
create policy "drive_points_private_self" on public.drive_points
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "drive_scores_self" on public.drive_scores;
create policy "drive_scores_self" on public.drive_scores
  for select using (auth.uid() = user_id);

drop policy if exists "rankings_read_all" on public.rankings;
create policy "rankings_read_all" on public.rankings
  for select using (true);

drop policy if exists "battles_read_all" on public.battles;
create policy "battles_read_all" on public.battles
  for select using (true);
drop policy if exists "battles_create_auth" on public.battles;
create policy "battles_create_auth" on public.battles
  for insert with check (auth.uid() = created_by);

drop policy if exists "battle_participants_member" on public.battle_participants;
create policy "battle_participants_member" on public.battle_participants
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "seasons_read_all" on public.seasons;
create policy "seasons_read_all" on public.seasons
  for select using (true);
drop policy if exists "season_missions_read_all" on public.season_missions;
create policy "season_missions_read_all" on public.season_missions
  for select using (true);

drop policy if exists "mission_progress_self" on public.mission_progress;
create policy "mission_progress_self" on public.mission_progress
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "user_badges_self" on public.user_badges;
create policy "user_badges_self" on public.user_badges
  for select using (auth.uid() = user_id);
drop policy if exists "user_achievements_self" on public.user_achievements;
create policy "user_achievements_self" on public.user_achievements
  for select using (auth.uid() = user_id);

drop policy if exists "notifications_self" on public.notifications;
create policy "notifications_self" on public.notifications
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "user_coupons_self" on public.user_coupons;
create policy "user_coupons_self" on public.user_coupons
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "subscriptions_self" on public.user_subscriptions;
create policy "subscriptions_self" on public.user_subscriptions
  for select using (auth.uid() = user_id);

drop policy if exists "fraud_reviews_self" on public.fraud_reviews;
create policy "fraud_reviews_self" on public.fraud_reviews
  for select using (auth.uid() = user_id);

drop policy if exists "reports_create_self" on public.report_items;
create policy "reports_create_self" on public.report_items
  for insert with check (auth.uid() = reporter_id);
drop policy if exists "reports_read_self" on public.report_items;
create policy "reports_read_self" on public.report_items
  for select using (auth.uid() = reporter_id);
