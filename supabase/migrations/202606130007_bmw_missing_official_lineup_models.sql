-- BMW official-lineup missing model audit.
-- Adds current official BMW Korea model-page entries that were absent from the
-- seed catalog. These rows remain pending_review and non-selectable at the
-- powertrain level until domestic specification sheets are audited.

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
  ('model-bmw-x2-kr', 'm-bmw', 'X2', 'X2', 'SUV', '{"가솔린"}', false, 80),
  ('model-bmw-x4-kr', 'm-bmw', 'X4', 'X4', 'SUV', '{"가솔린"}', false, 100),
  ('model-bmw-x6-kr', 'm-bmw', 'X6', 'X6', 'SUV', '{"가솔린"}', false, 120),
  ('model-bmw-xm-kr', 'm-bmw', 'XM', 'XM', 'SUV', '{"플러그인 하이브리드"}', false, 140),
  ('model-bmw-z4-kr', 'm-bmw', 'Z4', 'Z4', '컨버터블', '{"가솔린"}', false, 150),
  ('model-bmw-i7-kr', 'm-bmw', 'i7', 'i7', '전기 세단', '{"전기차"}', false, 180),
  ('model-bmw-ix1-kr', 'm-bmw', 'iX1', 'iX1', '전기 SUV', '{"전기차"}', false, 210),
  ('model-bmw-ix2-kr', 'm-bmw', 'iX2', 'iX2', '전기 SUV', '{"전기차"}', false, 220),
  ('model-bmw-i3-kr', 'm-bmw', 'i3', 'i3', '전기 세단', '{"전기차"}', false, 230)
on conflict (id) do update set
  manufacturer_id = excluded.manufacturer_id,
  name_ko = excluded.name_ko,
  name_en = excluded.name_en,
  body_type = excluded.body_type,
  available_fuel_types = excluded.available_fuel_types,
  is_popular = excluded.is_popular,
  sort_order = excluded.sort_order;

with bmw_missing_generations (
  id,
  model_id,
  source_name,
  source_url
) as (
  values
    ('generation-bmw-x2-official-lineup', 'model-bmw-x2-kr', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html'),
    ('generation-bmw-x4-official-lineup', 'model-bmw-x4-kr', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html'),
    ('generation-bmw-x6-official-lineup', 'model-bmw-x6-kr', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html'),
    ('generation-bmw-xm-official-lineup', 'model-bmw-xm-kr', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html'),
    ('generation-bmw-z4-official-lineup', 'model-bmw-z4-kr', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html'),
    ('generation-bmw-i7-official-lineup', 'model-bmw-i7-kr', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html'),
    ('generation-bmw-ix1-official-lineup', 'model-bmw-ix1-kr', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html'),
    ('generation-bmw-ix2-official-lineup', 'model-bmw-ix2-kr', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html'),
    ('generation-bmw-i3-official-lineup', 'model-bmw-i3-kr', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html')
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
  0.62,
  source_name,
  source_url,
  null,
  '2026-06-13',
  true,
  false,
  now()
from bmw_missing_generations
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

with bmw_missing_years (
  model_id,
  generation_id
) as (
  values
    ('model-bmw-x2-kr', 'generation-bmw-x2-official-lineup'),
    ('model-bmw-x4-kr', 'generation-bmw-x4-official-lineup'),
    ('model-bmw-x6-kr', 'generation-bmw-x6-official-lineup'),
    ('model-bmw-xm-kr', 'generation-bmw-xm-official-lineup'),
    ('model-bmw-z4-kr', 'generation-bmw-z4-official-lineup'),
    ('model-bmw-i7-kr', 'generation-bmw-i7-official-lineup'),
    ('model-bmw-ix1-kr', 'generation-bmw-ix1-official-lineup'),
    ('model-bmw-ix2-kr', 'generation-bmw-ix2-official-lineup'),
    ('model-bmw-i3-kr', 'generation-bmw-i3-official-lineup')
)
insert into public.vehicle_model_years (
  id,
  model_id,
  year,
  generation_id,
  production_year_label
)
select
  replace(model_id, 'model-', 'year-') || '-2026',
  model_id,
  2026,
  generation_id,
  '2026~현재'
from bmw_missing_years
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
  'generation-bmw-x2-official-lineup',
  'generation-bmw-x4-official-lineup',
  'generation-bmw-x6-official-lineup',
  'generation-bmw-xm-official-lineup',
  'generation-bmw-z4-official-lineup',
  'generation-bmw-i7-official-lineup',
  'generation-bmw-ix1-official-lineup',
  'generation-bmw-ix2-official-lineup',
  'generation-bmw-i3-official-lineup'
)
on conflict (generation_id, model_year_id) do nothing;

with bmw_missing_powertrains (
  model_id,
  fuel_type,
  trim_name,
  engine_name,
  displacement_cc,
  battery_kwh,
  drivetrain,
  transmission,
  efficiency_unit,
  vehicle_class,
  fuel_league,
  sort_order
) as (
  values
    ('model-bmw-x2-kr', '가솔린', '1.6 가솔린', '1.6 Gasoline', 1598, null::numeric, 'AWD', '자동', 'km/L', '소형 SUV', 'gasoline', 10),
    ('model-bmw-x4-kr', '가솔린', '2.0 가솔린', '2.0 Gasoline', 1999, null::numeric, 'AWD', '자동', 'km/L', 'SUV', 'gasoline', 10),
    ('model-bmw-x6-kr', '가솔린', '2.5 가솔린', '2.5 Gasoline', 2497, null::numeric, 'AWD', '자동', 'km/L', '대형 SUV', 'gasoline', 10),
    ('model-bmw-xm-kr', '플러그인 하이브리드', '1.6 플러그인 하이브리드', '1.6 PHEV', 1598, null::numeric, 'AWD', '하이브리드 전용 변속기', 'km/L', '대형 SUV', 'plug_in_hybrid', 10),
    ('model-bmw-z4-kr', '가솔린', '2.0 가솔린', '2.0 Gasoline', 1998, null::numeric, 'RWD', '자동', 'km/L', '스포츠', 'gasoline', 10),
    ('model-bmw-i7-kr', '전기차', '전기차', 'Electric Motor', null::integer, 90.0, '전동 구동', '감속기', 'km/kWh', '대형', 'electric', 10),
    ('model-bmw-ix1-kr', '전기차', '전기차', 'Electric Motor', null::integer, 45.0, '전동 구동', '감속기', 'km/kWh', '소형 SUV', 'electric', 10),
    ('model-bmw-ix2-kr', '전기차', '전기차', 'Electric Motor', null::integer, 45.0, '전동 구동', '감속기', 'km/kWh', '소형 SUV', 'electric', 10),
    ('model-bmw-i3-kr', '전기차', '전기차', 'Electric Motor', null::integer, 64.0, '전동 구동', '감속기', 'km/kWh', '중형', 'electric', 10)
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
  confidence_score,
  is_selectable,
  is_deprecated,
  sort_order
)
select
  'variant-' || replace(vmy.id, 'year-', '') || '-' || p.fuel_league,
  vmy.id,
  vmy.generation_id,
  p.trim_name,
  p.engine_name,
  p.fuel_type,
  p.displacement_cc,
  p.battery_kwh,
  p.drivetrain,
  p.transmission,
  null,
  p.efficiency_unit,
  p.vehicle_class,
  p.fuel_league,
  false,
  'pending_review',
  0.1,
  false,
  false,
  p.sort_order
from bmw_missing_powertrains p
join public.vehicle_model_years vmy
  on vmy.model_id = p.model_id
  and vmy.year = 2026
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
  confidence_score = excluded.confidence_score,
  is_selectable = excluded.is_selectable,
  is_deprecated = excluded.is_deprecated,
  sort_order = excluded.sort_order;
