-- KGM Korean model-list gap audit.
-- The official Korean model list exposes Rexton Summit, Torres Van, and
-- Torres EVX Van as visible cards. Keep them pending/non-selectable until
-- row-level domestic fuel economy and specification evidence is audited.

insert into public.vehicle_models (
  id,
  manufacturer_id,
  name_ko,
  name_en,
  body_type,
  available_fuel_types,
  is_popular,
  sort_order
)
values
  ('model-kgm-torres-van-kr', 'm-kgm', '토레스 밴', 'Torres Van', '밴', '{"가솔린"}', false, 66),
  ('model-kgm-torres-evx-van-kr', 'm-kgm', '토레스 EVX 밴', 'Torres EVX Van', '전기 밴', '{"전기차"}', false, 67),
  ('model-kgm-rexton-summit-kr', 'm-kgm', '렉스턴 써밋', 'Rexton Summit', 'SUV', '{"디젤"}', false, 75)
on conflict (id) do update set
  manufacturer_id = excluded.manufacturer_id,
  name_ko = excluded.name_ko,
  name_en = excluded.name_en,
  body_type = excluded.body_type,
  available_fuel_types = excluded.available_fuel_types,
  is_popular = excluded.is_popular,
  sort_order = excluded.sort_order;

with kgm_generations (
  id,
  model_id
) as (
  values
    ('generation-kgm-torres-van-official-lineup', 'model-kgm-torres-van-kr'),
    ('generation-kgm-torres-evx-van-official-lineup', 'model-kgm-torres-evx-van-kr'),
    ('generation-kgm-rexton-summit-official-lineup', 'model-kgm-rexton-summit-kr')
)
insert into public.vehicle_generations (
  id,
  model_id,
  generation_order,
  generation_name_ko,
  generation_name_en,
  generation_code,
  platform_code,
  start_year,
  start_month,
  end_year,
  end_month,
  display_period,
  is_current,
  is_upcoming,
  market_region,
  source_status,
  confidence_score,
  source_name,
  source_url,
  source_file_name,
  last_verified_at,
  is_selectable,
  is_deprecated,
  updated_at
)
select
  id,
  model_id,
  1,
  '공식 라인업',
  'Official lineup',
  '',
  '',
  2026,
  null,
  null,
  null,
  '2026~현재',
  true,
  false,
  'KR',
  'pending_review',
  0.64,
  'KGM official Korean model list',
  'https://www.kg-mobility.com/pr/model',
  null,
  '2026-06-13',
  true,
  false,
  now()
from kgm_generations
on conflict (id) do update set
  model_id = excluded.model_id,
  generation_order = excluded.generation_order,
  generation_name_ko = excluded.generation_name_ko,
  generation_name_en = excluded.generation_name_en,
  generation_code = excluded.generation_code,
  platform_code = excluded.platform_code,
  start_year = excluded.start_year,
  start_month = excluded.start_month,
  end_year = excluded.end_year,
  end_month = excluded.end_month,
  display_period = excluded.display_period,
  is_current = excluded.is_current,
  is_upcoming = excluded.is_upcoming,
  market_region = excluded.market_region,
  source_status = excluded.source_status,
  confidence_score = excluded.confidence_score,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  source_file_name = excluded.source_file_name,
  last_verified_at = excluded.last_verified_at,
  is_selectable = excluded.is_selectable,
  is_deprecated = excluded.is_deprecated,
  updated_at = now();

with kgm_years (
  model_id,
  generation_id,
  year
) as (
  values
    ('model-kgm-torres-van-kr', 'generation-kgm-torres-van-official-lineup', 2026),
    ('model-kgm-torres-evx-van-kr', 'generation-kgm-torres-evx-van-official-lineup', 2026),
    ('model-kgm-rexton-summit-kr', 'generation-kgm-rexton-summit-official-lineup', 2026)
)
insert into public.vehicle_model_years (
  id,
  model_id,
  year,
  generation_id,
  production_year_label
)
select
  replace(model_id, 'model-', 'year-') || '-' || year::text,
  model_id,
  year,
  generation_id,
  '2026~현재'
from kgm_years
on conflict (id) do update set
  model_id = excluded.model_id,
  year = excluded.year,
  generation_id = excluded.generation_id,
  production_year_label = excluded.production_year_label;

insert into public.vehicle_generation_years (
  generation_id,
  model_year_id,
  year
)
select generation_id, id, year
from public.vehicle_model_years
where generation_id in (
  'generation-kgm-torres-van-official-lineup',
  'generation-kgm-torres-evx-van-official-lineup',
  'generation-kgm-rexton-summit-official-lineup'
)
on conflict (generation_id, model_year_id) do nothing;

with pending_variants (
  id,
  model_year_id,
  generation_id,
  engine_name,
  fuel_type,
  efficiency_unit,
  vehicle_class,
  fuel_league,
  sort_order
) as (
  values
    (
      'variant-kgm-torres-van-2026-gasoline-pending',
      'year-kgm-torres-van-kr-2026',
      'generation-kgm-torres-van-official-lineup',
      'Pending official Torres Van specification review',
      '가솔린',
      'km/L',
      '상용',
      'gasoline',
      10
    ),
    (
      'variant-kgm-torres-evx-van-2026-electric-pending',
      'year-kgm-torres-evx-van-kr-2026',
      'generation-kgm-torres-evx-van-official-lineup',
      'Pending official Torres EVX Van specification review',
      '전기차',
      'km/kWh',
      '상용',
      'electric',
      10
    ),
    (
      'variant-kgm-rexton-summit-2026-diesel-pending',
      'year-kgm-rexton-summit-kr-2026',
      'generation-kgm-rexton-summit-official-lineup',
      'Pending official Rexton Summit specification review',
      '디젤',
      'km/L',
      '대형 SUV',
      'diesel',
      10
    )
)
insert into public.vehicle_variants (
  id,
  model_year_id,
  generation_id,
  trim_name,
  engine_name,
  fuel_type,
  displacement_cc,
  battery_kwh,
  drivetrain,
  transmission,
  official_efficiency,
  efficiency_unit,
  vehicle_class,
  fuel_league,
  is_verified,
  source_status,
  source_name,
  source_url,
  last_verified_at,
  confidence_score,
  is_selectable,
  is_deprecated,
  sort_order
)
select
  id,
  model_year_id,
  generation_id,
  '공식 제원 검수 대기',
  engine_name,
  fuel_type,
  null::integer,
  null::numeric,
  '검수 대기',
  '검수 대기',
  null,
  efficiency_unit,
  vehicle_class,
  fuel_league,
  false,
  'pending_review',
  'KGM official Korean model list',
  'https://www.kg-mobility.com/pr/model',
  '2026-06-13',
  0.64,
  false,
  false,
  sort_order
from pending_variants
on conflict (id) do update set
  model_year_id = excluded.model_year_id,
  generation_id = excluded.generation_id,
  trim_name = excluded.trim_name,
  engine_name = excluded.engine_name,
  fuel_type = excluded.fuel_type,
  displacement_cc = excluded.displacement_cc,
  battery_kwh = excluded.battery_kwh,
  drivetrain = excluded.drivetrain,
  transmission = excluded.transmission,
  official_efficiency = excluded.official_efficiency,
  efficiency_unit = excluded.efficiency_unit,
  vehicle_class = excluded.vehicle_class,
  fuel_league = excluded.fuel_league,
  is_verified = excluded.is_verified,
  source_status = excluded.source_status,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  last_verified_at = excluded.last_verified_at,
  confidence_score = excluded.confidence_score,
  is_selectable = excluded.is_selectable,
  is_deprecated = excluded.is_deprecated,
  sort_order = excluded.sort_order;

-- kgm official korean model list gap audit
