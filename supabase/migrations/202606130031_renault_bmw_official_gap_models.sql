-- Renault/BMW official homepage gap audit.
-- Adds official homepage/model-list entries that were missing from the seed.
-- Powertrain rows stay pending_review and non-selectable until row-level
-- domestic specification/fuel-economy evidence is audited.

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
  ('model-renault-scenic-e-tech-kr', 'm-renault', '세닉 E-Tech', 'Scenic E-Tech', '전기 SUV', '{"전기차"}', false, 70),
  ('model-bmw-2-series-gran-coupe-kr', 'm-bmw', '2시리즈 그란 쿠페', '2 Series Gran Coupe', '그란 쿠페', '{"가솔린"}', false, 25),
  ('model-bmw-8-series-kr', 'm-bmw', '8시리즈', '8 Series', '쿠페/그란 쿠페', '{"가솔린"}', false, 65),
  ('model-bmw-m2-kr', 'm-bmw', 'M2', 'M2', '고성능 쿠페', '{"가솔린"}', false, 151),
  ('model-bmw-m3-kr', 'm-bmw', 'M3', 'M3', '고성능 세단/투어링', '{"가솔린"}', false, 152),
  ('model-bmw-m4-kr', 'm-bmw', 'M4', 'M4', '고성능 쿠페/컨버터블', '{"가솔린"}', false, 153),
  ('model-bmw-m5-kr', 'm-bmw', 'M5', 'M5', '고성능 세단/투어링', '{"플러그인 하이브리드"}', false, 154),
  ('model-bmw-m8-kr', 'm-bmw', 'M8', 'M8', '고성능 쿠페/그란 쿠페', '{"가솔린"}', false, 155),
  ('model-bmw-x5-m-kr', 'm-bmw', 'X5 M', 'X5 M', '고성능 SUV', '{"가솔린"}', false, 115),
  ('model-bmw-x6-m-kr', 'm-bmw', 'X6 M', 'X6 M', '고성능 SUV', '{"가솔린"}', false, 125)
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
  source_name,
  source_url,
  confidence_score
) as (
  values
    (
      'generation-renault-scenic-e-tech-official-lineup',
      'model-renault-scenic-e-tech-kr',
      2025,
      '2025~현재',
      'Renault Korea official Scenic E-Tech price list',
      'https://www.renault.co.kr/upload/asset/price/price_scenic_202508.pdf',
      0.68
    ),
    ('generation-bmw-2series-gran-coupe-official-lineup', 'model-bmw-2-series-gran-coupe-kr', 2026, '2026~현재', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html', 0.62),
    ('generation-bmw-8series-official-lineup', 'model-bmw-8-series-kr', 2026, '2026~현재', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html', 0.62),
    ('generation-bmw-m2-official-lineup', 'model-bmw-m2-kr', 2026, '2026~현재', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html', 0.62),
    ('generation-bmw-m3-official-lineup', 'model-bmw-m3-kr', 2026, '2026~현재', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html', 0.62),
    ('generation-bmw-m4-official-lineup', 'model-bmw-m4-kr', 2026, '2026~현재', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html', 0.62),
    ('generation-bmw-m5-official-lineup', 'model-bmw-m5-kr', 2026, '2026~현재', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html', 0.62),
    ('generation-bmw-m8-official-lineup', 'model-bmw-m8-kr', 2026, '2026~현재', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html', 0.62),
    ('generation-bmw-x5-m-official-lineup', 'model-bmw-x5-m-kr', 2026, '2026~현재', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html', 0.62),
    ('generation-bmw-x6-m-official-lineup', 'model-bmw-x6-m-kr', 2026, '2026~현재', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html', 0.62)
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
  year,
  production_year_label
) as (
  values
    ('model-renault-scenic-e-tech-kr', 'generation-renault-scenic-e-tech-official-lineup', 2025, '2025~현재'),
    ('model-renault-scenic-e-tech-kr', 'generation-renault-scenic-e-tech-official-lineup', 2026, '2025~현재'),
    ('model-bmw-2-series-gran-coupe-kr', 'generation-bmw-2series-gran-coupe-official-lineup', 2026, '2026~현재'),
    ('model-bmw-8-series-kr', 'generation-bmw-8series-official-lineup', 2026, '2026~현재'),
    ('model-bmw-m2-kr', 'generation-bmw-m2-official-lineup', 2026, '2026~현재'),
    ('model-bmw-m3-kr', 'generation-bmw-m3-official-lineup', 2026, '2026~현재'),
    ('model-bmw-m4-kr', 'generation-bmw-m4-official-lineup', 2026, '2026~현재'),
    ('model-bmw-m5-kr', 'generation-bmw-m5-official-lineup', 2026, '2026~현재'),
    ('model-bmw-m8-kr', 'generation-bmw-m8-official-lineup', 2026, '2026~현재'),
    ('model-bmw-x5-m-kr', 'generation-bmw-x5-m-official-lineup', 2026, '2026~현재'),
    ('model-bmw-x6-m-kr', 'generation-bmw-x6-m-official-lineup', 2026, '2026~현재')
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
from official_gap_years
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
  'generation-renault-scenic-e-tech-official-lineup',
  'generation-bmw-2series-gran-coupe-official-lineup',
  'generation-bmw-8series-official-lineup',
  'generation-bmw-m2-official-lineup',
  'generation-bmw-m3-official-lineup',
  'generation-bmw-m4-official-lineup',
  'generation-bmw-m5-official-lineup',
  'generation-bmw-m8-official-lineup',
  'generation-bmw-x5-m-official-lineup',
  'generation-bmw-x6-m-official-lineup'
)
on conflict (generation_id, model_year_id) do nothing;

with pending_powertrains (
  id,
  model_year_id,
  generation_id,
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
    ('variant-renault-scenic-e-tech-kr-2025-electric', 'year-renault-scenic-e-tech-kr-2025', 'generation-renault-scenic-e-tech-official-lineup', 'Pending official Scenic E-Tech specification review', '전기차', 'km/kWh', 'SUV', 'electric', 'Renault Korea official Scenic E-Tech price list', 'https://www.renault.co.kr/upload/asset/price/price_scenic_202508.pdf', 0.68, 10),
    ('variant-renault-scenic-e-tech-kr-2026-electric', 'year-renault-scenic-e-tech-kr-2026', 'generation-renault-scenic-e-tech-official-lineup', 'Pending official Scenic E-Tech specification review', '전기차', 'km/kWh', 'SUV', 'electric', 'Renault Korea official Scenic E-Tech price list', 'https://www.renault.co.kr/upload/asset/price/price_scenic_202508.pdf', 0.68, 10),
    ('variant-bmw-2-series-gran-coupe-kr-2026-gasoline', 'year-bmw-2-series-gran-coupe-kr-2026', 'generation-bmw-2series-gran-coupe-official-lineup', 'Pending official 2 Series Gran Coupe specification review', '가솔린', 'km/L', '준중형', 'gasoline', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html', 0.62, 10),
    ('variant-bmw-8-series-kr-2026-gasoline', 'year-bmw-8-series-kr-2026', 'generation-bmw-8series-official-lineup', 'Pending official 8 Series specification review', '가솔린', 'km/L', '스포츠', 'gasoline', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html', 0.62, 10),
    ('variant-bmw-m2-kr-2026-gasoline', 'year-bmw-m2-kr-2026', 'generation-bmw-m2-official-lineup', 'Pending official M2 specification review', '가솔린', 'km/L', '스포츠', 'gasoline', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html', 0.62, 10),
    ('variant-bmw-m3-kr-2026-gasoline', 'year-bmw-m3-kr-2026', 'generation-bmw-m3-official-lineup', 'Pending official M3 specification review', '가솔린', 'km/L', '스포츠', 'gasoline', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html', 0.62, 10),
    ('variant-bmw-m4-kr-2026-gasoline', 'year-bmw-m4-kr-2026', 'generation-bmw-m4-official-lineup', 'Pending official M4 specification review', '가솔린', 'km/L', '스포츠', 'gasoline', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html', 0.62, 10),
    ('variant-bmw-m5-kr-2026-plug_in_hybrid', 'year-bmw-m5-kr-2026', 'generation-bmw-m5-official-lineup', 'Pending official M5 hybrid specification review', '플러그인 하이브리드', 'km/L', '스포츠', 'plug_in_hybrid', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html', 0.62, 10),
    ('variant-bmw-m8-kr-2026-gasoline', 'year-bmw-m8-kr-2026', 'generation-bmw-m8-official-lineup', 'Pending official M8 specification review', '가솔린', 'km/L', '스포츠', 'gasoline', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html', 0.62, 10),
    ('variant-bmw-x5-m-kr-2026-gasoline', 'year-bmw-x5-m-kr-2026', 'generation-bmw-x5-m-official-lineup', 'Pending official X5 M specification review', '가솔린', 'km/L', '스포츠', 'gasoline', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html', 0.62, 10),
    ('variant-bmw-x6-m-kr-2026-gasoline', 'year-bmw-x6-m-kr-2026', 'generation-bmw-x6-m-official-lineup', 'Pending official X6 M specification review', '가솔린', 'km/L', '스포츠', 'gasoline', 'BMW Korea official model lineup', 'https://www.bmw.co.kr/ko/all-models.html', 0.62, 10)
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
  source_name,
  source_url,
  '2026-06-13',
  confidence_score,
  false,
  false,
  sort_order
from pending_powertrains
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
