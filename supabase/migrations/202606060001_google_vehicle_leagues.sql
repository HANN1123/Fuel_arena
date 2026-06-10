create or replace function public.fuel_league_for_type(fuel_type text)
returns text
language sql
immutable
as $$
  select case
    when lower(coalesce(fuel_type, '')) in ('gasoline', 'gas', '가솔린') then 'gasoline'
    when lower(coalesce(fuel_type, '')) in ('diesel', '디젤') then 'diesel'
    when lower(coalesce(fuel_type, '')) in ('hybrid', '하이브리드') then 'hybrid'
    when lower(coalesce(fuel_type, '')) in ('electric', 'ev', '전기', '전기차') then 'electric'
    when lower(coalesce(fuel_type, '')) in ('lpg', 'lpi', 'lp_i') then 'lpg'
    when lower(replace(coalesce(fuel_type, ''), '-', '_')) in ('phev', 'plug_in_hybrid', 'plugin_hybrid', '플러그인_하이브리드') then 'plug_in_hybrid'
    else 'other'
  end;
$$;

alter table public.profiles
  add column if not exists auth_provider text not null default 'google',
  add column if not exists onboarding_completed boolean not null default false,
  add column if not exists consent_completed boolean not null default false,
  add column if not exists additional_setup_completed boolean not null default false,
  add column if not exists vehicle_setup_completed boolean not null default false,
  add column if not exists selected_fuel_league text not null default '',
  add column if not exists selected_vehicle_class text not null default '';

alter table public.vehicles
  add column if not exists fuel_league text not null default 'other',
  add column if not exists vehicle_variant_id text;

update public.vehicles
set fuel_league = public.fuel_league_for_type(fuel_type)
where fuel_league = 'other' or fuel_league is null;

create table if not exists public.fuel_leagues (
  key text primary key,
  name_ko text not null,
  description text not null,
  fuel_type text not null,
  is_active boolean not null default true,
  sort_order integer not null default 0
);

insert into public.fuel_leagues (
  key,
  name_ko,
  description,
  fuel_type,
  is_active,
  sort_order
)
values
  ('gasoline', '가솔린', '가솔린 차량 리그', 'gasoline', true, 10),
  ('diesel', '디젤', '디젤 차량 리그', 'diesel', true, 20),
  ('hybrid', '하이브리드', '하이브리드 차량 리그', 'hybrid', true, 30),
  ('plug_in_hybrid', '플러그인 하이브리드', 'PHEV 차량 리그', 'plug_in_hybrid', true, 40),
  ('electric', '전기차', '전기차 리그', 'electric', true, 50),
  ('lpg', 'LPG', 'LPG/LPI 차량 리그', 'lpg', true, 60),
  ('hydrogen', '수소전기', '수소전기차 리그', 'hydrogen', true, 70),
  ('other', '기타', '기타 연료 리그', 'other', true, 90)
on conflict (key) do update
  set name_ko = excluded.name_ko,
      description = excluded.description,
      fuel_type = excluded.fuel_type,
      is_active = excluded.is_active,
      sort_order = excluded.sort_order;

create table if not exists public.vehicle_manufacturers (
  id text primary key,
  name_ko text not null,
  name_en text not null default '',
  country text not null default '',
  logo_url text not null default '',
  is_popular boolean not null default false,
  sort_order integer not null default 0
);

create table if not exists public.vehicle_models (
  id text primary key,
  manufacturer_id text not null references public.vehicle_manufacturers(id) on delete cascade,
  name_ko text not null,
  name_en text not null default '',
  body_type text not null default '',
  available_fuel_types text[] not null default '{}',
  is_popular boolean not null default false,
  sort_order integer not null default 0
);

create table if not exists public.vehicle_model_years (
  id text primary key,
  model_id text not null references public.vehicle_models(id) on delete cascade,
  year integer not null,
  unique (model_id, year)
);

create table if not exists public.vehicle_variants (
  id text primary key,
  model_year_id text not null references public.vehicle_model_years(id) on delete cascade,
  trim_name text not null,
  engine_name text not null default '',
  fuel_type text not null,
  displacement_cc integer,
  battery_kwh numeric(6,2),
  drivetrain text not null default '',
  transmission text not null default '',
  official_efficiency numeric(6,2),
  efficiency_unit text not null default 'km/L',
  vehicle_class text not null,
  fuel_league text not null references public.fuel_leagues(key),
  is_verified boolean not null default true,
  sort_order integer not null default 0
);

create table if not exists public.user_vehicles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  vehicle_variant_id text references public.vehicle_variants(id) on delete set null,
  nickname text not null default '',
  is_primary boolean not null default false,
  verification_status text not null default 'verified',
  fuel_type text not null,
  fuel_league text not null references public.fuel_leagues(key),
  vehicle_class text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists user_vehicles_one_primary_per_user
  on public.user_vehicles (user_id)
  where is_primary;

create table if not exists public.league_memberships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  user_vehicle_id uuid not null references public.user_vehicles(id) on delete cascade,
  fuel_league text not null references public.fuel_leagues(key),
  vehicle_class text not null,
  season_id uuid references public.seasons(id) on delete set null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, user_vehicle_id, fuel_league, vehicle_class)
);

create unique index if not exists league_memberships_one_active_per_user
  on public.league_memberships (user_id)
  where is_active;

alter table public.rankings
  add column if not exists fuel_league text not null default 'other',
  add column if not exists user_vehicle_id uuid references public.user_vehicles(id) on delete set null;

update public.rankings
set fuel_league = public.fuel_league_for_type(fuel_type)
where fuel_league = 'other' or fuel_league is null;

alter table public.battles
  add column if not exists required_fuel_league text references public.fuel_leagues(key),
  add column if not exists required_vehicle_class text,
  add column if not exists is_friendly_cross_league boolean not null default false;

drop view if exists public.vehicle_catalog_view;

create or replace view public.vehicle_catalog_view as
select
  vv.id,
  vv.model_year_id,
  vmf.name_ko as manufacturer_name,
  vm.name_ko as model_name,
  vmy.year,
  vv.trim_name,
  vv.engine_name,
  vv.fuel_type,
  vv.displacement_cc,
  vv.battery_kwh,
  vv.drivetrain,
  vv.transmission,
  vv.official_efficiency,
  vv.vehicle_class,
  vv.fuel_league,
  vv.is_verified,
  lower(vmf.name_ko || ' ' || vmf.name_en || ' ' || vm.name_ko || ' ' || vm.name_en || ' ' || vmy.year || ' ' || vv.trim_name || ' ' || vv.fuel_type || ' ' || vv.vehicle_class) as search_text
from public.vehicle_variants vv
join public.vehicle_model_years vmy on vmy.id = vv.model_year_id
join public.vehicle_models vm on vm.id = vmy.model_id
join public.vehicle_manufacturers vmf on vmf.id = vm.manufacturer_id;

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
  r.fuel_type,
  r.fuel_league
from public.rankings r
join public.profiles p on p.id = r.user_id;

alter table public.fuel_leagues enable row level security;
alter table public.vehicle_manufacturers enable row level security;
alter table public.vehicle_models enable row level security;
alter table public.vehicle_model_years enable row level security;
alter table public.vehicle_variants enable row level security;
alter table public.user_vehicles enable row level security;
alter table public.league_memberships enable row level security;

drop policy if exists "profiles_insert_self" on public.profiles;
create policy "profiles_insert_self" on public.profiles
  for insert with check (auth.uid() = id);

drop policy if exists "fuel_leagues_read_all" on public.fuel_leagues;
create policy "fuel_leagues_read_all" on public.fuel_leagues
  for select using (true);

drop policy if exists "vehicle_manufacturers_read_all" on public.vehicle_manufacturers;
create policy "vehicle_manufacturers_read_all" on public.vehicle_manufacturers
  for select using (true);

drop policy if exists "vehicle_models_read_all" on public.vehicle_models;
create policy "vehicle_models_read_all" on public.vehicle_models
  for select using (true);

drop policy if exists "vehicle_model_years_read_all" on public.vehicle_model_years;
create policy "vehicle_model_years_read_all" on public.vehicle_model_years
  for select using (true);

drop policy if exists "vehicle_variants_read_all" on public.vehicle_variants;
create policy "vehicle_variants_read_all" on public.vehicle_variants
  for select using (true);

drop policy if exists "user_vehicles_self" on public.user_vehicles;
create policy "user_vehicles_self" on public.user_vehicles
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "league_memberships_self" on public.league_memberships;
create policy "league_memberships_self" on public.league_memberships
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
