-- Tesla/Jeep/Polestar/Peugeot official homepage gap audit.
-- Adds official Korea/current-page model rows only where the manufacturer
-- exposes the model, and keeps unaudited specs non-selectable.

update public.vehicle_models
set available_fuel_types = '{"가솔린","디젤","하이브리드"}'
where id = 'model-peugeot-145-308';

update public.vehicle_models
set available_fuel_types = '{"가솔린","디젤","플러그인 하이브리드","하이브리드"}'
where id = 'model-peugeot-147-3008';

update public.vehicle_models
set available_fuel_types = '{"가솔린","디젤","하이브리드"}'
where id = 'model-peugeot-148-5008';

update public.vehicle_models
set available_fuel_types = '{"가솔린","하이브리드"}'
where id = 'model-peugeot-408-kr';

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
  ('model-tesla-cybertruck-kr', 'm-tesla', 'Cybertruck', 'Cybertruck', '픽업', '{"전기차"}', false, 50),
  ('model-jeep-avenger-kr', 'm-jeep', '어벤저', 'Avenger', '전기 SUV', '{"전기차"}', false, 80),
  ('model-polestar-5-kr', 'm-polestar', 'Polestar 5', 'Polestar 5', '전기 세단', '{"전기차"}', false, 40)
on conflict (id) do update set
  manufacturer_id = excluded.manufacturer_id,
  name_ko = excluded.name_ko,
  name_en = excluded.name_en,
  body_type = excluded.body_type,
  available_fuel_types = excluded.available_fuel_types,
  is_popular = excluded.is_popular,
  sort_order = excluded.sort_order;

with official_gap_generations (
  id,
  model_id,
  start_year,
  display_period,
  is_current,
  is_upcoming,
  is_selectable,
  confidence_score,
  source_name,
  source_url
) as (
  values
    ('generation-tesla-cybertruck-official-lineup', 'model-tesla-cybertruck-kr', 2026, '2026~현재', true, false, true, 0.62, 'Tesla Korea official Cybertruck page', 'https://www.tesla.com/ko_kr/cybertruck'),
    ('generation-jeep-avenger-official-lineup', 'model-jeep-avenger-kr', 2024, '2024~현재', true, false, true, 0.64, 'Jeep Korea official Avenger model and battery pages', 'https://www.jeep.co.kr/JL/Avenger.html'),
    ('generation-polestar-5-official-lineup', 'model-polestar-5-kr', 2026, '2026년 국내 출시 예정', false, true, false, 0.60, 'Polestar Korea official Polestar 5 page', 'https://www.polestar.com/kr/polestar-5/')
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
  start_year,
  null,
  null,
  null,
  display_period,
  is_current,
  is_upcoming,
  'KR',
  'pending_review',
  confidence_score,
  source_name,
  source_url,
  null,
  '2026-06-13',
  is_selectable,
  false,
  now()
from official_gap_generations
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

with official_gap_years (
  model_id,
  generation_id,
  first_year,
  last_year,
  production_year_label
) as (
  values
    ('model-tesla-cybertruck-kr', 'generation-tesla-cybertruck-official-lineup', 2026, 2026, '2026~현재'),
    ('model-jeep-avenger-kr', 'generation-jeep-avenger-official-lineup', 2024, 2026, '2024~현재'),
    ('model-polestar-5-kr', 'generation-polestar-5-official-lineup', 2026, 2026, '2026년 국내 출시 예정')
)
insert into public.vehicle_model_years (
  id,
  model_id,
  year,
  generation_id,
  production_year_label
)
select
  replace(model_id, 'model-', 'year-') || '-' || year_value::text,
  model_id,
  year_value,
  generation_id,
  production_year_label
from official_gap_years
cross join lateral generate_series(first_year, last_year) as year_value
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
  'generation-tesla-cybertruck-official-lineup',
  'generation-jeep-avenger-official-lineup',
  'generation-polestar-5-official-lineup'
)
on conflict (generation_id, model_year_id) do nothing;

with official_gap_powertrains (
  model_id,
  generation_id,
  fuel_type,
  efficiency_unit,
  vehicle_class,
  fuel_league,
  source_name,
  source_url,
  sort_order
) as (
  values
    ('model-tesla-cybertruck-kr', 'generation-tesla-cybertruck-official-lineup', '전기차', 'km/kWh', '픽업', 'electric', 'Tesla Korea official Cybertruck page', 'https://www.tesla.com/ko_kr/cybertruck', 50),
    ('model-jeep-avenger-kr', 'generation-jeep-avenger-official-lineup', '전기차', 'km/kWh', '소형 SUV', 'electric', 'Jeep Korea official Avenger model and battery pages', 'https://www.jeep.co.kr/JL/Avenger.html', 50),
    ('model-polestar-5-kr', 'generation-polestar-5-official-lineup', '전기차', 'km/kWh', '대형', 'electric', 'Polestar Korea official Polestar 5 page', 'https://www.polestar.com/kr/polestar-5/', 50)
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
  'variant-' || replace(vmy.id, 'year-', '') || '-' || fuel_league,
  vmy.id,
  ogp.generation_id,
  '공식 제원 검수 대기',
  'Pending official specification review',
  ogp.fuel_type,
  null,
  null,
  '검수 대기',
  '검수 대기',
  null,
  ogp.efficiency_unit,
  ogp.vehicle_class,
  ogp.fuel_league,
  false,
  'pending_review',
  ogp.source_name,
  ogp.source_url,
  '2026-06-13',
  0.62,
  false,
  false,
  ogp.sort_order
from public.vehicle_model_years vmy
join official_gap_powertrains ogp on ogp.model_id = vmy.model_id
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

update public.vehicle_generations
set
  source_name = 'Peugeot Korea official SMART HYBRID model lineup',
  source_url = 'https://www.epeugeot.co.kr/car-selector/peugeot-range.html',
  source_status = 'pending_review',
  updated_at = now()
where id in (
  'generation-peugeot-308-official-lineup',
  'generation-peugeot-3008-official-lineup',
  'generation-peugeot-5008-official-lineup',
  'generation-peugeot-408-official-lineup'
);

with peugeot_smart_hybrid_powertrains (
  model_year_id,
  generation_id,
  variant_id,
  engine_name,
  vehicle_class
) as (
  values
    ('year-peugeot-145-308-2026', 'generation-peugeot-308-official-lineup', 'variant-peugeot-308-2026-smart-hybrid-pending', 'Pending official Peugeot 308 SMART HYBRID specification review', '준중형'),
    ('year-peugeot-147-3008-2026', 'generation-peugeot-3008-official-lineup', 'variant-peugeot-3008-2026-smart-hybrid-pending', 'Pending official Peugeot 3008 SMART HYBRID specification review', 'SUV'),
    ('year-peugeot-148-5008-2026', 'generation-peugeot-5008-official-lineup', 'variant-peugeot-5008-2026-smart-hybrid-pending', 'Pending official Peugeot 5008 SMART HYBRID specification review', '대형 SUV'),
    ('year-peugeot-408-kr-2026', 'generation-peugeot-408-official-lineup', 'variant-peugeot-408-2026-smart-hybrid-pending', 'Pending official Peugeot 408 SMART HYBRID specification review', '중형')
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
  variant_id,
  model_year_id,
  generation_id,
  'SMART HYBRID 공식 제원 검수 대기',
  engine_name,
  '하이브리드',
  null,
  null,
  '검수 대기',
  '검수 대기',
  null,
  'km/L',
  vehicle_class,
  'hybrid',
  false,
  'pending_review',
  'Peugeot Korea official SMART HYBRID model lineup',
  'https://www.epeugeot.co.kr/car-selector/peugeot-range.html',
  '2026-06-13',
  0.62,
  false,
  false,
  20
from peugeot_smart_hybrid_powertrains
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
