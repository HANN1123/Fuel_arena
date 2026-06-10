-- 1. vehicle_manufacturers 컬럼 추가
alter table public.vehicle_manufacturers
  add column if not exists source_status text not null default 'unverified',
  add column if not exists market_region text not null default 'KR';

-- 2. vehicle_models 컬럼 추가
alter table public.vehicle_models
  add column if not exists market_region text not null default 'KR',
  add column if not exists source_status text not null default 'unverified';

-- 3. vehicle_model_years 컬럼 추가
alter table public.vehicle_model_years
  add column if not exists generation_name text,
  add column if not exists facelift_label text,
  add column if not exists source_status text not null default 'unverified';

-- 4. vehicle_variants 컬럼 추가
alter table public.vehicle_variants
  add column if not exists source_status text not null default 'unverified',
  add column if not exists confidence_score numeric not null default 0,
  add column if not exists is_selectable boolean not null default true,
  add column if not exists is_deprecated boolean not null default false,
  add column if not exists engine_code text,
  add column if not exists variant_name text,
  add column if not exists cylinders integer,
  add column if not exists aspiration text,
  add column if not exists motor_power_kw numeric(8,2),
  add column if not exists motor_power_ps numeric(8,2),
  add column if not exists engine_power_ps numeric(8,2),
  add column if not exists system_power_ps numeric(8,2),
  add column if not exists electric_range_km numeric(6,2),
  add column if not exists hydrogen_tank_kg numeric(6,2),
  add column if not exists official_efficiency_city numeric(6,2),
  add column if not exists official_efficiency_highway numeric(6,2),
  add column if not exists co2_g_km numeric(6,2),
  add column if not exists energy_grade text,
  add column if not exists market_region text not null default 'KR',
  add column if not exists valid_from date,
  add column if not exists valid_to date;

-- 5. vehicle_data_sources 테이블 생성
create table if not exists public.vehicle_data_sources (
  id uuid primary key default gen_random_uuid(),
  source_type text not null, -- 'public_api', 'public_csv', 'manufacturer_spec', 'manual_admin', 'user_submitted'
  source_name text not null,
  source_url text,
  source_file_name text,
  published_at date,
  imported_at timestamptz not null default now(),
  license_note text,
  reliability_level integer not null default 0,
  created_at timestamptz not null default now()
);

-- 6. vehicle_powertrain_sources 테이블 생성
create table if not exists public.vehicle_powertrain_sources (
  id uuid primary key default gen_random_uuid(),
  powertrain_id text not null references public.vehicle_variants(id) on delete cascade,
  source_id uuid not null references public.vehicle_data_sources(id) on delete cascade,
  field_name text, -- null 이면 전체 레코드 출처, 특정 필드명 지정 가능
  source_value text,
  normalized_value text,
  confidence_score numeric not null default 0,
  created_at timestamptz not null default now()
);

-- 7. vehicle_catalog_import_jobs 테이블 생성
create table if not exists public.vehicle_catalog_import_jobs (
  id uuid primary key default gen_random_uuid(),
  source_id uuid references public.vehicle_data_sources(id) on delete set null,
  import_type text not null,
  status text not null, -- 'pending', 'running', 'completed', 'failed'
  total_rows integer not null default 0,
  inserted_rows integer not null default 0,
  updated_rows integer not null default 0,
  skipped_rows integer not null default 0,
  conflict_rows integer not null default 0,
  error_rows integer not null default 0,
  started_at timestamptz,
  finished_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  summary jsonb,
  created_at timestamptz not null default now()
);

-- 8. vehicle_catalog_conflicts 테이블 생성
create table if not exists public.vehicle_catalog_conflicts (
  id uuid primary key default gen_random_uuid(),
  import_job_id uuid references public.vehicle_catalog_import_jobs(id) on delete cascade,
  entity_type text not null, -- 'manufacturer', 'model', 'model_year', 'variant'
  entity_id text,
  conflict_type text not null, -- 'specification_mismatch', 'invalid_unit', 'hierarchy_broken'
  existing_value jsonb,
  incoming_value jsonb,
  status text not null default 'open', -- 'open', 'resolved_keep_existing', 'resolved_overwrite', 'resolved_manual'
  resolved_by uuid references auth.users(id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now()
);

-- 9. custom_vehicle_requests 링킹 컬럼 추가
alter table public.custom_vehicle_requests
  add column if not exists linked_powertrain_id text references public.vehicle_variants(id) on delete set null;

-- 10. RLS 활성화 및 보안 설정
alter table public.vehicle_data_sources enable row level security;
alter table public.vehicle_powertrain_sources enable row level security;
alter table public.vehicle_catalog_import_jobs enable row level security;
alter table public.vehicle_catalog_conflicts enable row level security;

-- Policies
drop policy if exists "vehicle_data_sources_read_all" on public.vehicle_data_sources;
create policy "vehicle_data_sources_read_all" on public.vehicle_data_sources
  for select using (true);

drop policy if exists "vehicle_data_sources_admin" on public.vehicle_data_sources;
create policy "vehicle_data_sources_admin" on public.vehicle_data_sources
  for all using (public.is_admin_user()) with check (public.is_admin_user());

drop policy if exists "vehicle_powertrain_sources_read_all" on public.vehicle_powertrain_sources;
create policy "vehicle_powertrain_sources_read_all" on public.vehicle_powertrain_sources
  for select using (true);

drop policy if exists "vehicle_powertrain_sources_admin" on public.vehicle_powertrain_sources;
create policy "vehicle_powertrain_sources_admin" on public.vehicle_powertrain_sources
  for all using (public.is_admin_user()) with check (public.is_admin_user());

drop policy if exists "vehicle_catalog_import_jobs_admin" on public.vehicle_catalog_import_jobs;
create policy "vehicle_catalog_import_jobs_admin" on public.vehicle_catalog_import_jobs
  for all using (public.is_admin_user()) with check (public.is_admin_user());

drop policy if exists "vehicle_catalog_conflicts_admin" on public.vehicle_catalog_conflicts;
create policy "vehicle_catalog_conflicts_admin" on public.vehicle_catalog_conflicts
  for all using (public.is_admin_user()) with check (public.is_admin_user());

-- 11. SQL Views 생성 및 갱신

-- view 1: vehicle_catalog_selectable_view (유저가 선택 가능한 검증된 차량 목록)
create or replace view public.vehicle_catalog_selectable_view as
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
  vv.efficiency_unit,
  vv.vehicle_class,
  vv.fuel_league,
  vv.source_status,
  vv.confidence_score,
  vv.is_selectable,
  vv.is_deprecated
from public.vehicle_variants vv
join public.vehicle_model_years vmy on vmy.id = vv.model_year_id
join public.vehicle_models vm on vm.id = vmy.model_id
join public.vehicle_manufacturers vmf on vmf.id = vm.manufacturer_id
where vv.is_selectable = true and vv.is_deprecated = false;

-- view 2: vehicle_powertrain_public_view (출처 및 세부 정보를 포함한 공개용 뷰)
create or replace view public.vehicle_powertrain_public_view as
select
  vv.id,
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
  vv.efficiency_unit,
  vv.vehicle_class,
  vv.fuel_league,
  vv.source_status,
  vv.confidence_score,
  vds.source_name,
  vds.source_url,
  vds.reliability_level
from public.vehicle_variants vv
join public.vehicle_model_years vmy on vmy.id = vv.model_year_id
join public.vehicle_models vm on vm.id = vmy.model_id
join public.vehicle_manufacturers vmf on vmf.id = vm.manufacturer_id
left join public.vehicle_powertrain_sources vps on vps.powertrain_id = vv.id and vps.field_name is null
left join public.vehicle_data_sources vds on vds.id = vps.source_id;

-- view 3: vehicle_catalog_quality_view (데이터 품질 진단용 뷰)
create or replace view public.vehicle_catalog_quality_view as
select
  vv.id,
  vmf.name_ko as manufacturer_name,
  vm.name_ko as model_name,
  vmy.year,
  vv.trim_name,
  vv.fuel_type,
  vv.official_efficiency,
  vv.displacement_cc,
  vv.battery_kwh,
  vv.source_status,
  case when vv.official_efficiency is null then true else false end as is_efficiency_missing,
  case when vv.fuel_league = 'electric' and vv.displacement_cc is not null then true else false end as is_electric_with_cc,
  case when vv.fuel_league != 'electric' and vv.battery_kwh is not null and vv.fuel_league != 'plug_in_hybrid' then true else false end as is_ice_with_battery,
  case when vv.source_status = 'verified_official' and not exists (
    select 1 from public.vehicle_powertrain_sources vps where vps.powertrain_id = vv.id
  ) then true else false end as is_verified_without_source
from public.vehicle_variants vv
join public.vehicle_model_years vmy on vmy.id = vv.model_year_id
join public.vehicle_models vm on vm.id = vmy.model_id
join public.vehicle_manufacturers vmf on vmf.id = vm.manufacturer_id;

drop view if exists public.public_user_primary_vehicle_view;
drop view if exists public.user_primary_vehicle_view;
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
  vv.efficiency_unit,
  vv.vehicle_class,
  vv.fuel_league,
  vv.is_verified,
  vv.source_status,
  vv.confidence_score,
  vv.is_selectable,
  vv.is_deprecated,
  lower(vmf.name_ko || ' ' || vmf.name_en || ' ' || vm.name_ko || ' ' || vm.name_en || ' ' || vmy.year || ' ' || vv.trim_name || ' ' || vv.fuel_type || ' ' || vv.vehicle_class) as search_text
from public.vehicle_variants vv
join public.vehicle_model_years vmy on vmy.id = vv.model_year_id
join public.vehicle_models vm on vm.id = vmy.model_id
join public.vehicle_manufacturers vmf on vmf.id = vm.manufacturer_id;

-- view 4: vehicle_catalog_conflict_view (출처 충돌 분석용 뷰)
create or replace view public.vehicle_catalog_conflict_view as
select
  vcc.id as conflict_id,
  vcc.import_job_id,
  vcc.entity_type,
  vcc.entity_id,
  vcc.conflict_type,
  vcc.existing_value,
  vcc.incoming_value,
  vcc.status,
  vcc.created_at,
  vj.import_type,
  vds.source_name as incoming_source_name
from public.vehicle_catalog_conflicts vcc
join public.vehicle_catalog_import_jobs vj on vj.id = vcc.import_job_id
left join public.vehicle_data_sources vds on vds.id = vj.source_id;

-- view 5: admin_vehicle_catalog_integrity_view (계층 및 정합성 위반 탐지용 뷰)
create or replace view public.admin_vehicle_catalog_integrity_view as
select
  'model_without_year' as issue_type,
  vm.id as entity_id,
  vm.name_ko as entity_name,
  'Model has no years mapped' as description
from public.vehicle_models vm
where not exists (select 1 from public.vehicle_model_years vmy where vmy.model_id = vm.id)
union all
select
  'year_without_variant' as issue_type,
  vmy.id as entity_id,
  vmy.year::text as entity_name,
  'Year has no variants mapped' as description
from public.vehicle_model_years vmy
where not exists (select 1 from public.vehicle_variants vv where vv.model_year_id = vmy.id);

-- view 6: user_primary_vehicle_view (유저의 대표 차량 제원 및 출처 등급을 포함한 뷰)
create or replace view public.user_primary_vehicle_view as
select
  uv.id as user_vehicle_id,
  uv.user_id,
  uv.nickname,
  uv.is_primary,
  uv.verification_status,
  uv.fuel_type,
  uv.fuel_league,
  uv.vehicle_class,
  vv.id as variant_id,
  vv.manufacturer_name,
  vv.model_name,
  vv.year,
  vv.trim_name,
  vv.source_status as variant_source_status,
  vv.official_efficiency,
  vv.efficiency_unit
from public.user_vehicles uv
left join public.vehicle_catalog_view vv on vv.id = uv.vehicle_variant_id
where uv.is_primary = true;

-- view 7: league_rankings_view (검증된 파워트레인을 가진 유저만 순위에 노출되게 통제하는 리그 랭킹 뷰)
create or replace view public.league_rankings_view as
select
  r.id as ranking_id,
  r.user_id,
  r.score,
  r.rank,
  r.percentile,
  r.tier,
  r.vehicle_class,
  r.fuel_type,
  r.fuel_league,
  uv.id as user_vehicle_id,
  vv.source_status as vehicle_source_status
from public.rankings r
join public.user_vehicles uv on uv.id = r.user_vehicle_id
join public.vehicle_variants vv on vv.id = uv.vehicle_variant_id
where vv.source_status in ('verified_official', 'verified_admin', 'imported_public');
