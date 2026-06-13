-- Vehicle generation catalog layer.
-- Existing catalog IDs are text, so generation IDs follow the same convention.

create table if not exists public.vehicle_generations (
  id text primary key,
  model_id text not null references public.vehicle_models(id) on delete cascade,
  generation_order integer,
  generation_name_ko text not null,
  generation_name_en text,
  generation_code text,
  platform_code text,
  start_year integer,
  start_month integer,
  end_year integer,
  end_month integer,
  display_period text,
  is_current boolean not null default false,
  is_upcoming boolean not null default false,
  market_region text not null default 'KR',
  source_status text not null default 'unverified',
  confidence_score numeric not null default 0,
  source_name text,
  source_url text,
  source_file_name text,
  last_verified_at timestamptz,
  is_selectable boolean not null default true,
  is_deprecated boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint vehicle_generations_month_range check (
    (start_month is null or start_month between 1 and 12) and
    (end_month is null or end_month between 1 and 12)
  ),
  constraint vehicle_generations_year_range check (
    start_year is null or end_year is null or start_year <= end_year
  ),
  constraint vehicle_generations_verified_source check (
    source_status not in ('verified_official', 'verified_admin') or
    coalesce(source_name, source_url, source_file_name) is not null
  )
);

alter table public.vehicle_model_years
  add column if not exists generation_id text references public.vehicle_generations(id) on delete set null,
  add column if not exists production_year_label text;

alter table public.vehicle_variants
  add column if not exists generation_id text references public.vehicle_generations(id) on delete set null,
  add column if not exists valid_from_year integer,
  add column if not exists valid_to_year integer,
  add column if not exists valid_from_month integer,
  add column if not exists valid_to_month integer,
  add column if not exists applies_to_years integer[];

create table if not exists public.vehicle_generation_years (
  id uuid primary key default gen_random_uuid(),
  generation_id text not null references public.vehicle_generations(id) on delete cascade,
  model_year_id text not null references public.vehicle_model_years(id) on delete cascade,
  year integer not null,
  created_at timestamptz not null default now(),
  unique (generation_id, model_year_id)
);

create index if not exists idx_vehicle_generations_model_id
  on public.vehicle_generations(model_id);
create index if not exists idx_vehicle_model_years_generation_id
  on public.vehicle_model_years(generation_id);
create index if not exists idx_vehicle_variants_generation_id
  on public.vehicle_variants(generation_id);
create index if not exists idx_vehicle_generation_years_generation_id
  on public.vehicle_generation_years(generation_id);

alter table public.vehicle_generations enable row level security;
alter table public.vehicle_generation_years enable row level security;

drop policy if exists "vehicle_generations_read_all" on public.vehicle_generations;
create policy "vehicle_generations_read_all" on public.vehicle_generations
  for select using (true);

drop policy if exists "vehicle_generation_years_read_all" on public.vehicle_generation_years;
create policy "vehicle_generation_years_read_all" on public.vehicle_generation_years
  for select using (true);

drop policy if exists "vehicle_generations_admin_write" on public.vehicle_generations;
create policy "vehicle_generations_admin_write" on public.vehicle_generations
  for all using (public.is_admin_user()) with check (public.is_admin_user());

drop policy if exists "vehicle_generation_years_admin_write" on public.vehicle_generation_years;
create policy "vehicle_generation_years_admin_write" on public.vehicle_generation_years
  for all using (public.is_admin_user()) with check (public.is_admin_user());

create or replace view public.vehicle_generation_filter_view as
select
  vmf.id as manufacturer_id,
  vm.id as model_id,
  vg.id as generation_id,
  vg.generation_order,
  vg.generation_name_ko,
  vg.generation_name_en,
  vg.generation_code,
  vg.platform_code,
  vg.display_period,
  vg.start_year,
  vg.start_month,
  vg.end_year,
  vg.end_month,
  vg.is_current,
  vg.is_upcoming,
  vg.market_region,
  vg.source_status as generation_source_status,
  vg.confidence_score as generation_confidence_score,
  vv.fuel_type,
  vv.fuel_league,
  vv.vehicle_class,
  vm.body_type,
  count(distinct vv.id) filter (
    where vv.is_selectable = true and vv.is_deprecated = false
  ) as matching_powertrain_count,
  count(distinct vv.id) filter (
    where vv.is_verified = true and vv.is_selectable = true and vv.is_deprecated = false
  ) as verified_powertrain_count,
  case
    when bool_or(vv.source_status = 'conflict') then 'conflict'
    when vg.source_status in ('verified_official', 'verified_admin') then vg.source_status
    when bool_or(vv.is_verified = false) then 'pending_review'
    else vg.source_status
  end as source_status_summary
from public.vehicle_generations vg
join public.vehicle_models vm on vm.id = vg.model_id
join public.vehicle_manufacturers vmf on vmf.id = vm.manufacturer_id
left join public.vehicle_model_years vmy on vmy.generation_id = vg.id
left join public.vehicle_generation_years vgy on vgy.generation_id = vg.id
left join public.vehicle_variants vv on vv.model_year_id = coalesce(vmy.id, vgy.model_year_id)
where vg.is_selectable = true and vg.is_deprecated = false
group by
  vmf.id,
  vm.id,
  vg.id,
  vg.generation_order,
  vg.generation_name_ko,
  vg.generation_name_en,
  vg.generation_code,
  vg.platform_code,
  vg.display_period,
  vg.start_year,
  vg.start_month,
  vg.end_year,
  vg.end_month,
  vg.is_current,
  vg.is_upcoming,
  vg.market_region,
  vg.source_status,
  vg.confidence_score,
  vv.fuel_type,
  vv.fuel_league,
  vv.vehicle_class,
  vm.body_type;
