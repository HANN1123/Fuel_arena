-- Lexus Korea official model-page missing model audit.
-- Adds live official Korea model-page entries absent from the seed catalog.
-- Powertrain placeholders stay non-selectable until official domestic specs are audited.

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
  ('model-lexus-lc-kr', 'm-lexus', 'LC', 'LC 500', '스포츠 쿠페', '{"가솔린"}', false, 80),
  ('model-lexus-rc-kr', 'm-lexus', 'RC', 'RC 300 F SPORT', '스포츠 쿠페', '{"가솔린"}', false, 90)
on conflict (id) do update set
  manufacturer_id = excluded.manufacturer_id,
  name_ko = excluded.name_ko,
  name_en = excluded.name_en,
  body_type = excluded.body_type,
  available_fuel_types = excluded.available_fuel_types,
  is_popular = excluded.is_popular,
  sort_order = excluded.sort_order;

with official_model_page_generations (
  id,
  model_id,
  generation_name_ko,
  generation_name_en,
  confidence_score,
  source_name,
  source_url
) as (
  values
    ('generation-lexus-lc-official-model-page', 'model-lexus-lc-kr', '공식 모델 페이지', 'Official model page', 0.58, 'Lexus Korea official LC 500 model page', 'https://www.lexus.co.kr/models/LC-500/'),
    ('generation-lexus-rc-official-model-page', 'model-lexus-rc-kr', '공식 모델 페이지', 'Official model page', 0.56, 'Lexus Korea official RC 300 F SPORT model page', 'https://www.lexus.co.kr/models/RC-300-F-SPORT/')
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
  generation_name_ko,
  generation_name_en,
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
  confidence_score,
  source_name,
  source_url,
  null,
  '2026-06-13',
  true,
  false,
  now()
from official_model_page_generations
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

with official_model_page_years (
  model_id,
  generation_id
) as (
  values
    ('model-lexus-lc-kr', 'generation-lexus-lc-official-model-page'),
    ('model-lexus-rc-kr', 'generation-lexus-rc-official-model-page')
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
from official_model_page_years
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
  'generation-lexus-lc-official-model-page',
  'generation-lexus-rc-official-model-page'
)
on conflict (generation_id, model_year_id) do nothing;

with official_model_page_powertrains (
  model_id,
  fuel_type,
  efficiency_unit,
  vehicle_class,
  fuel_league,
  sort_order
) as (
  values
    ('model-lexus-lc-kr', '가솔린', 'km/L', '스포츠', 'gasoline', 10),
    ('model-lexus-rc-kr', '가솔린', 'km/L', '스포츠', 'gasoline', 10)
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
  '공식 제원 검수 대기',
  'Pending official specification review',
  p.fuel_type,
  null::integer,
  null::numeric,
  '검수 대기',
  '검수 대기',
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
from official_model_page_powertrains p
join public.vehicle_model_years vmy on vmy.model_id = p.model_id and vmy.year = 2026
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

delete from public.vehicle_generation_years vgy
using public.vehicle_model_years vmy
where vgy.model_year_id = vmy.id
  and vmy.model_id in (
    'model-lexus-lc-kr',
    'model-lexus-rc-kr'
  )
  and vmy.year < 2026;

delete from public.vehicle_variants vv
using public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.model_id in (
    'model-lexus-lc-kr',
    'model-lexus-rc-kr'
  )
  and vmy.year < 2026;

delete from public.vehicle_model_years vmy
where vmy.model_id in (
    'model-lexus-lc-kr',
    'model-lexus-rc-kr'
  )
  and vmy.year < 2026;
