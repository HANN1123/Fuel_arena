-- Lexus Korea LX / LS 500 official model audit.
-- The official Lexus Korea navigation/model JSON exposes LX 700h and LS 500.
-- Rows stay pending/non-selectable until full domestic spec-sheet review is done.

update public.vehicle_models
set available_fuel_types = '{"가솔린","하이브리드"}'
where id = 'model-lexus-104-ls';

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
  ('model-lexus-lx-kr', 'm-lexus', 'LX', 'LX 700h', 'SUV', '{"하이브리드"}', false, 75)
on conflict (id) do update set
  manufacturer_id = excluded.manufacturer_id,
  name_ko = excluded.name_ko,
  name_en = excluded.name_en,
  body_type = excluded.body_type,
  available_fuel_types = excluded.available_fuel_types,
  is_popular = excluded.is_popular,
  sort_order = excluded.sort_order;

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
values
  (
    'generation-lexus-lx-official-lineup',
    'model-lexus-lx-kr',
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
    0.68,
    'Lexus Korea official LX model page and model JSON',
    'https://www.lexus.co.kr/models/LX/',
    null,
    '2026-06-13',
    true,
    false,
    now()
  )
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

insert into public.vehicle_model_years (
  id,
  model_id,
  year,
  generation_id,
  production_year_label
)
values
  (
    'year-lexus-lx-kr-2026',
    'model-lexus-lx-kr',
    2026,
    'generation-lexus-lx-official-lineup',
    '2026~현재'
  )
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
values
  ('generation-lexus-lx-official-lineup', 'year-lexus-lx-kr-2026', 2026)
on conflict (generation_id, model_year_id) do nothing;

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
values
  (
    'variant-lexus-ls-2026-500-pending',
    'year-lexus-104-ls-2026',
    'generation-lexus-ls-official-lineup',
    'LS 500 공식 제원 검수 대기',
    'LS 500 gasoline official specification review pending',
    '가솔린',
    3445,
    null,
    '검수 대기',
    '검수 대기',
    null,
    'km/L',
    '대형',
    'gasoline',
    false,
    'pending_review',
    'Lexus Korea official model JSON/model page',
    'https://www.lexus.co.kr/models/LS-500/',
    '2026-06-13',
    0.62,
    false,
    false,
    20
  ),
  (
    'variant-lexus-lx-2026-700h-pending',
    'year-lexus-lx-kr-2026',
    'generation-lexus-lx-official-lineup',
    'LX 700h 공식 제원 검수 대기',
    'LX 700h hybrid official specification review pending',
    '하이브리드',
    3445,
    null,
    '검수 대기',
    '검수 대기',
    null,
    'km/L',
    '대형 SUV',
    'hybrid',
    false,
    'pending_review',
    'Lexus Korea official LX model page and model JSON',
    'https://www.lexus.co.kr/models/LX/',
    '2026-06-13',
    0.68,
    false,
    false,
    10
  )
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
