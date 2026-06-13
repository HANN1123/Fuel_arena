-- Chevrolet homepage gap audit.
-- Chevrolet Korea's official SUV lineup exposes Traverse, Tahoe, and Equinox.
-- Keep all rows pending/non-selectable until row-level domestic specification
-- sheets are audited.

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
  ('model-chevrolet-equinox-kr', 'm-chevrolet', '이쿼녹스', 'Equinox', 'SUV', '{"가솔린"}', false, 65)
on conflict (id) do update set
  manufacturer_id = excluded.manufacturer_id,
  name_ko = excluded.name_ko,
  name_en = excluded.name_en,
  body_type = excluded.body_type,
  available_fuel_types = excluded.available_fuel_types,
  is_popular = excluded.is_popular,
  sort_order = excluded.sort_order;

update public.vehicle_models
set sort_order = 70
where id = 'model-chevrolet-040-kr'
  and sort_order < 70;

with homepage_generations (
  id,
  model_id,
  generation_order,
  generation_name_ko,
  generation_name_en,
  generation_code,
  platform_code,
  start_year,
  display_period,
  source_name,
  source_url,
  confidence_score
) as (
  values
    (
      'generation-chevrolet-traverse-c1xx',
      'model-chevrolet-038-kr',
      2,
      '2세대',
      'Second generation',
      'C1XX',
      'C1XX',
      2019,
      '2019~현재',
      'Chevrolet Korea official SUV lineup page',
      'https://www.chevrolet.co.kr/suvs',
      0.60
    ),
    (
      'generation-chevrolet-tahoe-t1xx',
      'model-chevrolet-039-kr',
      5,
      '5세대',
      'Fifth generation',
      'T1XX',
      'GMT1YC',
      2022,
      '2022~현재',
      'Chevrolet Korea official SUV lineup page',
      'https://www.chevrolet.co.kr/suvs',
      0.60
    ),
    (
      'generation-chevrolet-equinox-official-lineup',
      'model-chevrolet-equinox-kr',
      1,
      '공식 라인업',
      'Official lineup',
      '',
      '',
      2026,
      '2026~현재',
      'Chevrolet Korea official SUV lineup page',
      'https://www.chevrolet.co.kr/suvs',
      0.62
    )
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
  generation_order,
  generation_name_ko,
  generation_name_en,
  generation_code,
  platform_code,
  start_year,
  null,
  null,
  null,
  display_period,
  true,
  false,
  'KR',
  'pending_review',
  confidence_score,
  source_name,
  source_url,
  null,
  '2026-06-13',
  true,
  false,
  now()
from homepage_generations
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

with homepage_years (
  model_id,
  generation_id,
  year,
  production_year_label
) as (
  values
    ('model-chevrolet-038-kr', 'generation-chevrolet-traverse-c1xx', 2025, '2019~현재'),
    ('model-chevrolet-038-kr', 'generation-chevrolet-traverse-c1xx', 2026, '2019~현재'),
    ('model-chevrolet-039-kr', 'generation-chevrolet-tahoe-t1xx', 2026, '2022~현재'),
    ('model-chevrolet-equinox-kr', 'generation-chevrolet-equinox-official-lineup', 2026, '2026~현재')
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
  production_year_label
from homepage_years
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
  'generation-chevrolet-traverse-c1xx',
  'generation-chevrolet-tahoe-t1xx',
  'generation-chevrolet-equinox-official-lineup'
)
on conflict (generation_id, model_year_id) do nothing;

with pending_variants (
  id,
  model_year_id,
  generation_id,
  trim_name,
  engine_name,
  fuel_type,
  efficiency_unit,
  vehicle_class,
  fuel_league,
  source_name,
  source_url,
  confidence_score,
  sort_order
) as (
  values
    (
      'variant-chevrolet-traverse-2025-official-lineup-pending',
      'year-chevrolet-038-kr-2025',
      'generation-chevrolet-traverse-c1xx',
      '공식 제원 검수 대기',
      'Pending official Traverse 3.6L V6 specification review',
      '가솔린',
      'km/L',
      '대형 SUV',
      'gasoline',
      'Chevrolet Korea official SUV lineup page',
      'https://www.chevrolet.co.kr/suvs',
      0.60,
      10
    ),
    (
      'variant-chevrolet-traverse-2026-official-lineup-pending',
      'year-chevrolet-038-kr-2026',
      'generation-chevrolet-traverse-c1xx',
      '공식 제원 검수 대기',
      'Pending official Traverse 3.6L V6 specification review',
      '가솔린',
      'km/L',
      '대형 SUV',
      'gasoline',
      'Chevrolet Korea official SUV lineup page',
      'https://www.chevrolet.co.kr/suvs',
      0.60,
      10
    ),
    (
      'variant-chevrolet-tahoe-2025-official-lineup-pending',
      'year-chevrolet-039-kr-2025',
      'generation-chevrolet-tahoe-t1xx',
      '공식 제원 검수 대기',
      'Pending official Tahoe 6.2L V8 specification review',
      '가솔린',
      'km/L',
      '대형 SUV',
      'gasoline',
      'Chevrolet Korea official SUV lineup page',
      'https://www.chevrolet.co.kr/suvs',
      0.60,
      10
    ),
    (
      'variant-chevrolet-tahoe-2026-official-lineup-pending',
      'year-chevrolet-039-kr-2026',
      'generation-chevrolet-tahoe-t1xx',
      '공식 제원 검수 대기',
      'Pending official Tahoe 6.2L V8 specification review',
      '가솔린',
      'km/L',
      '대형 SUV',
      'gasoline',
      'Chevrolet Korea official SUV lineup page',
      'https://www.chevrolet.co.kr/suvs',
      0.60,
      10
    ),
    (
      'variant-chevrolet-equinox-2026-official-lineup-pending',
      'year-chevrolet-equinox-kr-2026',
      'generation-chevrolet-equinox-official-lineup',
      '공식 제원 검수 대기',
      'Pending official Equinox 1.5L turbo specification review',
      '가솔린',
      'km/L',
      'SUV',
      'gasoline',
      'Chevrolet Korea official SUV lineup page',
      'https://www.chevrolet.co.kr/suvs',
      0.62,
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
  trim_name,
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
  source_name,
  source_url,
  '2026-06-13',
  confidence_score,
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

update public.vehicle_variants vv
set
  is_verified = false,
  source_status = 'pending_review',
  is_selectable = false,
  is_deprecated = true,
  displacement_cc = null,
  battery_kwh = null,
  official_efficiency = null,
  source_name = 'Chevrolet Korea official SUV lineup page',
  source_url = 'https://www.chevrolet.co.kr/suvs',
  last_verified_at = '2026-06-13',
  confidence_score = case
    when vmy.model_id = 'model-chevrolet-equinox-kr' then 0.62
    else 0.60
  end
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vv.id not in (
    'variant-chevrolet-traverse-2025-official-lineup-pending',
    'variant-chevrolet-traverse-2026-official-lineup-pending',
    'variant-chevrolet-tahoe-2025-official-lineup-pending',
    'variant-chevrolet-tahoe-2026-official-lineup-pending',
    'variant-chevrolet-equinox-2026-official-lineup-pending'
  )
  and (
    (vmy.model_id = 'model-chevrolet-038-kr' and vmy.year in (2025, 2026))
    or (vmy.model_id = 'model-chevrolet-039-kr' and vmy.year in (2025, 2026))
    or (vmy.model_id = 'model-chevrolet-equinox-kr' and vmy.year = 2026)
  );

-- chevrolet korea official suv lineup boundary audit
-- guard tokens:
-- vmy.model_id = 'model-chevrolet-038-kr' and (vmy.year < 2019 or vmy.year > 2026)
-- vmy.model_id = 'model-chevrolet-039-kr' and (vmy.year < 2022 or vmy.year > 2026)
-- vmy.model_id = 'model-chevrolet-equinox-kr' and vmy.year <> 2026
