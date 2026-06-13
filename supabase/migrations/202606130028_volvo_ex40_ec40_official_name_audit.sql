-- Volvo EX40 / EC40 official name audit.
-- Volvo Cars Korea states XC40 Recharge and C40 Recharge are renamed to EX40
-- and EC40. Keep the new official-name rows pending/non-selectable until
-- domestic powertrain specs are audited.

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
  ('model-volvo-ex40-kr', 'm-volvo', 'EX40', 'EX40', '전기 SUV', '{"전기차"}', false, 62),
  ('model-volvo-ec40-kr', 'm-volvo', 'EC40', 'EC40', '전기 SUV', '{"전기차"}', false, 64)
on conflict (id) do update set
  manufacturer_id = excluded.manufacturer_id,
  name_ko = excluded.name_ko,
  name_en = excluded.name_en,
  body_type = excluded.body_type,
  available_fuel_types = excluded.available_fuel_types,
  is_popular = excluded.is_popular,
  sort_order = excluded.sort_order;

with official_name_generations (
  id,
  model_id
) as (
  values
    ('generation-volvo-ex40-official-lineup', 'model-volvo-ex40-kr'),
    ('generation-volvo-ec40-official-lineup', 'model-volvo-ec40-kr')
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
  2025,
  null,
  null,
  null,
  '2025~현재',
  true,
  false,
  'KR',
  'pending_review',
  0.62,
  'Volvo Cars Korea official EX40/EC40 rename news and support',
  'https://www.volvocars.com/kr/news/corporate/new-name-new-me-say-hello-to-the-ex40-and-ec40/',
  null,
  '2026-06-13',
  true,
  false,
  now()
from official_name_generations
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

with official_name_years (
  model_id,
  generation_id,
  year
) as (
  values
    ('model-volvo-ex40-kr', 'generation-volvo-ex40-official-lineup', 2025),
    ('model-volvo-ex40-kr', 'generation-volvo-ex40-official-lineup', 2026),
    ('model-volvo-ec40-kr', 'generation-volvo-ec40-official-lineup', 2025),
    ('model-volvo-ec40-kr', 'generation-volvo-ec40-official-lineup', 2026)
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
  '2025~현재'
from official_name_years
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
  'generation-volvo-ex40-official-lineup',
  'generation-volvo-ec40-official-lineup'
)
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
select
  'variant-' || replace(vmy.id, 'year-', '') || '-electric',
  vmy.id,
  vmy.generation_id,
  '공식 제원 검수 대기',
  'Pending official EX40/EC40 electric specification review',
  '전기차',
  null::integer,
  null::numeric,
  '검수 대기',
  '검수 대기',
  null,
  'km/kWh',
  'SUV',
  'electric',
  false,
  'pending_review',
  'Volvo Cars Korea official EX40/EC40 rename news and support',
  'https://www.volvocars.com/kr/news/corporate/new-name-new-me-say-hello-to-the-ex40-and-ec40/',
  '2026-06-13',
  0.62,
  false,
  false,
  10
from public.vehicle_model_years vmy
where vmy.generation_id in (
  'generation-volvo-ex40-official-lineup',
  'generation-volvo-ec40-official-lineup'
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

update public.vehicle_variants vv
set
  is_verified = false,
  source_status = 'pending_review',
  is_selectable = false,
  is_deprecated = true,
  official_efficiency = null,
  battery_kwh = null,
  source_name = 'Volvo Cars Korea official EX40/EC40 rename news and support',
  source_url = 'https://www.volvocars.com/kr/news/corporate/new-name-new-me-say-hello-to-the-ex40-and-ec40/',
  last_verified_at = '2026-06-13',
  confidence_score = 0.62
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and (
    (vmy.model_id = 'model-volvo-129-c40' and vmy.year > 2024)
    or (
      vmy.model_id = 'model-volvo-126-xc40'
      and vmy.year > 2024
      and vv.fuel_league = 'electric'
    )
  );
