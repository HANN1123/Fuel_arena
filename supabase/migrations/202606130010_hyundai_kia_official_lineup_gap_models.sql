-- Hyundai/Kia official-lineup missing model audit.
-- Adds current official Korea model-page entries that were absent from the
-- seed catalog. Powertrain placeholders are intentionally non-selectable until
-- domestic specification sheets are audited.

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
    when lower(coalesce(fuel_type, '')) in ('hydrogen', 'fuel_cell', '수소', '수소차', '수소전기', '수소전기차') then 'hydrogen'
    when lower(coalesce(fuel_type, '')) in ('lpg', 'lpi', 'lp_i') then 'lpg'
    when lower(replace(coalesce(fuel_type, ''), '-', '_')) in ('phev', 'plug_in_hybrid', 'plugin_hybrid', '플러그인_하이브리드') then 'plug_in_hybrid'
    else 'other'
  end;
$$;

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
  ('model-hyundai-venue-kr', 'm-hyundai', '베뉴', 'Venue', 'SUV', '{"가솔린"}', false, 41),
  ('model-hyundai-casper-electric-kr', 'm-hyundai', '캐스퍼 Electric', 'CASPER Electric', '전기 SUV', '{"전기차"}', false, 81),
  ('model-hyundai-ioniq5-n-kr', 'm-hyundai', '아이오닉 5 N', 'IONIQ 5 N', '고성능 전기 SUV', '{"전기차"}', false, 91),
  ('model-hyundai-ioniq6-n-kr', 'm-hyundai', '아이오닉 6 N', 'IONIQ 6 N', '고성능 전기 세단', '{"전기차"}', false, 101),
  ('model-hyundai-ioniq9-kr', 'm-hyundai', '아이오닉 9', 'IONIQ 9', '전기 SUV', '{"전기차"}', false, 102),
  ('model-hyundai-nexo-kr', 'm-hyundai', '넥쏘', 'NEXO', '수소 SUV', '{"수소전기차"}', false, 103),
  ('model-hyundai-staria-electric-kr', 'm-hyundai', '스타리아 Electric', 'STARIA Electric', '전기 MPV', '{"전기차"}', false, 111),
  ('model-hyundai-st1-kr', 'm-hyundai', 'ST1', 'ST1', '상용 전기차', '{"전기차"}', false, 121),
  ('model-kia-ev4-kr', 'm-kia', 'EV4', 'EV4', '전기 세단', '{"전기차"}', false, 121),
  ('model-kia-ev5-kr', 'm-kia', 'EV5', 'EV5', '전기 SUV', '{"전기차"}', false, 122),
  ('model-kia-pv5-kr', 'm-kia', 'PV5', 'PV5', 'PBV', '{"전기차"}', false, 141),
  ('model-kia-tasman-kr', 'm-kia', '타스만', 'Tasman', '픽업', '{"가솔린"}', false, 142)
on conflict (id) do update set
  manufacturer_id = excluded.manufacturer_id,
  name_ko = excluded.name_ko,
  name_en = excluded.name_en,
  body_type = excluded.body_type,
  available_fuel_types = excluded.available_fuel_types,
  is_popular = excluded.is_popular,
  sort_order = excluded.sort_order;

with official_lineup_generations (
  id,
  model_id,
  confidence_score,
  source_name,
  source_url
) as (
  values
    ('generation-hyundai-venue-official-lineup', 'model-hyundai-venue-kr', 0.62, 'Hyundai Motor Korea official Venue model page', 'https://www.hyundai.com/kr/ko/e/vehicles/venue/intro'),
    ('generation-hyundai-casper-electric-official-lineup', 'model-hyundai-casper-electric-kr', 0.64, 'Hyundai Casper official CASPER Electric page', 'https://casper.hyundai.com/vehicles/electric/highlight'),
    ('generation-hyundai-ioniq5-n-official-lineup', 'model-hyundai-ioniq5-n-kr', 0.62, 'Hyundai Motor Korea official IONIQ 5 N model page', 'https://www.hyundai.com/kr/ko/e/vehicles/ioniq5-n/intro'),
    ('generation-hyundai-ioniq6-n-official-lineup', 'model-hyundai-ioniq6-n-kr', 0.62, 'Hyundai Motor Korea official IONIQ 6 N model page', 'https://www.hyundai.com/kr/ko/e/vehicles/ioniq6-n/intro'),
    ('generation-hyundai-ioniq9-official-lineup', 'model-hyundai-ioniq9-kr', 0.62, 'Hyundai Motor Korea official IONIQ 9 model page', 'https://www.hyundai.com/kr/ko/e/vehicles/ioniq9/intro'),
    ('generation-hyundai-nexo-official-lineup', 'model-hyundai-nexo-kr', 0.62, 'Hyundai Motor Korea official all-new NEXO model page', 'https://www.hyundai.com/kr/ko/e/vehicles/the-all-new-nexo/intro'),
    ('generation-hyundai-staria-electric-official-lineup', 'model-hyundai-staria-electric-kr', 0.62, 'Hyundai Motor Korea official STARIA Electric model page', 'https://www.hyundai.com/kr/ko/e/vehicles/the-new-staria-electric/intro'),
    ('generation-hyundai-st1-official-lineup', 'model-hyundai-st1-kr', 0.62, 'Hyundai Motor Korea official ST1 model page', 'https://www.hyundai.com/kr/ko/e/vehicles/st1/intro'),
    ('generation-kia-ev4-official-lineup', 'model-kia-ev4-kr', 0.64, 'Kia Korea official EV4 model page', 'https://www.kia.com/kr/vehicles/ev4/features'),
    ('generation-kia-ev5-official-lineup', 'model-kia-ev5-kr', 0.64, 'Kia Korea official EV5 model page', 'https://www.kia.com/kr/vehicles/ev5/features'),
    ('generation-kia-pv5-official-lineup', 'model-kia-pv5-kr', 0.62, 'Kia Korea official EV/PBV lineup page', 'https://www.kia.com/kr/vehicles/kia-ev/vehicles/ev-line-up'),
    ('generation-kia-tasman-official-lineup', 'model-kia-tasman-kr', 0.64, 'Kia Korea official Tasman model page', 'https://www.kia.com/kr/vehicles/tasman/features')
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
  confidence_score,
  source_name,
  source_url,
  null,
  '2026-06-13',
  true,
  false,
  now()
from official_lineup_generations
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

with official_lineup_years (
  model_id,
  generation_id
) as (
  values
    ('model-hyundai-venue-kr', 'generation-hyundai-venue-official-lineup'),
    ('model-hyundai-casper-electric-kr', 'generation-hyundai-casper-electric-official-lineup'),
    ('model-hyundai-ioniq5-n-kr', 'generation-hyundai-ioniq5-n-official-lineup'),
    ('model-hyundai-ioniq6-n-kr', 'generation-hyundai-ioniq6-n-official-lineup'),
    ('model-hyundai-ioniq9-kr', 'generation-hyundai-ioniq9-official-lineup'),
    ('model-hyundai-nexo-kr', 'generation-hyundai-nexo-official-lineup'),
    ('model-hyundai-staria-electric-kr', 'generation-hyundai-staria-electric-official-lineup'),
    ('model-hyundai-st1-kr', 'generation-hyundai-st1-official-lineup'),
    ('model-kia-ev4-kr', 'generation-kia-ev4-official-lineup'),
    ('model-kia-ev5-kr', 'generation-kia-ev5-official-lineup'),
    ('model-kia-pv5-kr', 'generation-kia-pv5-official-lineup'),
    ('model-kia-tasman-kr', 'generation-kia-tasman-official-lineup')
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
from official_lineup_years
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
  'generation-hyundai-venue-official-lineup',
  'generation-hyundai-casper-electric-official-lineup',
  'generation-hyundai-ioniq5-n-official-lineup',
  'generation-hyundai-ioniq6-n-official-lineup',
  'generation-hyundai-ioniq9-official-lineup',
  'generation-hyundai-nexo-official-lineup',
  'generation-hyundai-staria-electric-official-lineup',
  'generation-hyundai-st1-official-lineup',
  'generation-kia-ev4-official-lineup',
  'generation-kia-ev5-official-lineup',
  'generation-kia-pv5-official-lineup',
  'generation-kia-tasman-official-lineup'
)
on conflict (generation_id, model_year_id) do nothing;

with official_lineup_powertrains (
  model_id,
  fuel_type,
  efficiency_unit,
  vehicle_class,
  fuel_league,
  sort_order
) as (
  values
    ('model-hyundai-venue-kr', '가솔린', 'km/L', '소형 SUV', 'gasoline', 10),
    ('model-hyundai-casper-electric-kr', '전기차', 'km/kWh', '경형', 'electric', 10),
    ('model-hyundai-ioniq5-n-kr', '전기차', 'km/kWh', '스포츠', 'electric', 10),
    ('model-hyundai-ioniq6-n-kr', '전기차', 'km/kWh', '스포츠', 'electric', 10),
    ('model-hyundai-ioniq9-kr', '전기차', 'km/kWh', '대형 SUV', 'electric', 10),
    ('model-hyundai-nexo-kr', '수소전기차', 'km/kg', 'SUV', 'hydrogen', 10),
    ('model-hyundai-staria-electric-kr', '전기차', 'km/kWh', 'MPV', 'electric', 10),
    ('model-hyundai-st1-kr', '전기차', 'km/kWh', '상용', 'electric', 10),
    ('model-kia-ev4-kr', '전기차', 'km/kWh', '중형', 'electric', 10),
    ('model-kia-ev5-kr', '전기차', 'km/kWh', 'SUV', 'electric', 10),
    ('model-kia-pv5-kr', '전기차', 'km/kWh', '상용', 'electric', 10),
    ('model-kia-tasman-kr', '가솔린', 'km/L', '픽업', 'gasoline', 10)
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
from official_lineup_powertrains p
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

delete from public.vehicle_generation_years vgy
using public.vehicle_model_years vmy
where vgy.model_year_id = vmy.id
  and (
    vmy.model_id in (
      'model-hyundai-venue-kr',
      'model-hyundai-casper-electric-kr',
      'model-hyundai-ioniq5-n-kr',
      'model-hyundai-ioniq6-n-kr',
      'model-hyundai-ioniq9-kr',
      'model-hyundai-nexo-kr',
      'model-hyundai-staria-electric-kr',
      'model-hyundai-st1-kr',
      'model-kia-ev4-kr',
      'model-kia-ev5-kr',
      'model-kia-pv5-kr',
      'model-kia-tasman-kr'
    )
    and vmy.year < 2026
  );

update public.vehicle_variants vv
set
  generation_id = null,
  source_status = 'deprecated',
  is_verified = false,
  is_selectable = false,
  is_deprecated = true
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and (
    vmy.model_id in (
      'model-hyundai-venue-kr',
      'model-hyundai-casper-electric-kr',
      'model-hyundai-ioniq5-n-kr',
      'model-hyundai-ioniq6-n-kr',
      'model-hyundai-ioniq9-kr',
      'model-hyundai-nexo-kr',
      'model-hyundai-staria-electric-kr',
      'model-hyundai-st1-kr',
      'model-kia-ev4-kr',
      'model-kia-ev5-kr',
      'model-kia-pv5-kr',
      'model-kia-tasman-kr'
    )
    and vmy.year < 2026
  );

update public.vehicle_model_years
set
  generation_id = null,
  production_year_label = null
where model_id in (
    'model-hyundai-venue-kr',
    'model-hyundai-casper-electric-kr',
    'model-hyundai-ioniq5-n-kr',
    'model-hyundai-ioniq6-n-kr',
    'model-hyundai-ioniq9-kr',
    'model-hyundai-nexo-kr',
    'model-hyundai-staria-electric-kr',
    'model-hyundai-st1-kr',
    'model-kia-ev4-kr',
    'model-kia-ev5-kr',
    'model-kia-pv5-kr',
    'model-kia-tasman-kr'
  )
  and year < 2026;
