-- Mercedes-Benz/Audi official-lineup missing model audit.
-- Adds current official Korea model-overview entries that were absent from the
-- seed catalog. Powertrain placeholders are intentionally non-selectable until
-- domestic specification sheets are audited.

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
  ('model-benz-s-class-long-kr', 'm-benz', 'S-Class Long', 'S-Class Long', '세단', '{"가솔린","플러그인 하이브리드"}', false, 45),
  ('model-benz-maybach-s-class-kr', 'm-benz', 'Mercedes-Maybach S-Class', 'Mercedes-Maybach S-Class', '세단', '{"가솔린"}', false, 46),
  ('model-benz-eqe-suv-kr', 'm-benz', 'EQE SUV', 'EQE SUV', '전기 SUV', '{"전기차"}', false, 105),
  ('model-benz-maybach-eqs-suv-kr', 'm-benz', 'Mercedes-Maybach EQS SUV', 'Mercedes-Maybach EQS SUV', '전기 SUV', '{"전기차"}', false, 106),
  ('model-benz-glb-kr', 'm-benz', 'GLB', 'GLB', 'SUV', '{"가솔린"}', false, 115),
  ('model-benz-glc-coupe-kr', 'm-benz', 'GLC Coupé', 'GLC Coupé', 'SUV', '{"가솔린"}', false, 116),
  ('model-benz-gle-coupe-kr', 'm-benz', 'GLE Coupé', 'GLE Coupé', 'SUV', '{"가솔린","디젤"}', false, 117),
  ('model-benz-maybach-gls-kr', 'm-benz', 'Mercedes-Maybach GLS', 'Mercedes-Maybach GLS', 'SUV', '{"가솔린"}', false, 118),
  ('model-benz-g-class-kr', 'm-benz', 'G-Class', 'G-Class', 'SUV', '{"가솔린","디젤","전기차"}', false, 119),
  ('model-benz-cla-coupe-kr', 'm-benz', 'CLA Coupé', 'CLA Coupé', '쿠페', '{"가솔린"}', false, 130),
  ('model-benz-cle-coupe-kr', 'm-benz', 'CLE Coupé', 'CLE Coupé', '쿠페', '{"가솔린"}', false, 140),
  ('model-benz-amg-gt-coupe-kr', 'm-benz', 'Mercedes-AMG GT Coupé', 'Mercedes-AMG GT Coupé', '스포츠카', '{"가솔린","플러그인 하이브리드"}', false, 150),
  ('model-benz-amg-gt-4door-coupe-kr', 'm-benz', 'Mercedes-AMG GT 4-Door Coupé', 'Mercedes-AMG GT 4-Door Coupé', '쿠페', '{"가솔린"}', false, 160),
  ('model-benz-cle-cabriolet-kr', 'm-benz', 'CLE Cabriolet', 'CLE Cabriolet', '컨버터블', '{"가솔린"}', false, 170),
  ('model-benz-sl-roadster-kr', 'm-benz', 'SL Roadster', 'SL Roadster', '컨버터블', '{"가솔린"}', false, 180),
  ('model-benz-maybach-sl-monogram-kr', 'm-benz', 'Mercedes-Maybach SL Monogram Series', 'Mercedes-Maybach SL Monogram Series', '컨버터블', '{"가솔린"}', false, 190),
  ('model-audi-e-tron-gt-kr', 'm-audi', 'e-tron GT', 'e-tron GT', '스포츠카', '{"전기차"}', false, 115),
  ('model-audi-a6-e-tron-kr', 'm-audi', 'A6 e-tron', 'A6 e-tron', '전기 세단', '{"전기차"}', false, 116),
  ('model-audi-q6-e-tron-kr', 'm-audi', 'Q6 e-tron', 'Q6 e-tron', '전기 SUV', '{"전기차"}', false, 117)
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
  source_name,
  source_url
) as (
  values
    ('generation-benz-s-class-long-official-lineup', 'model-benz-s-class-long-kr', 'Mercedes-Benz Korea official model overview', 'https://www.mercedes-benz.co.kr/passengercars/models.html'),
    ('generation-benz-maybach-s-class-official-lineup', 'model-benz-maybach-s-class-kr', 'Mercedes-Benz Korea official model overview', 'https://www.mercedes-benz.co.kr/passengercars/models.html'),
    ('generation-benz-eqe-suv-official-lineup', 'model-benz-eqe-suv-kr', 'Mercedes-Benz Korea official model overview', 'https://www.mercedes-benz.co.kr/passengercars/models.html'),
    ('generation-benz-maybach-eqs-suv-official-lineup', 'model-benz-maybach-eqs-suv-kr', 'Mercedes-Benz Korea official model overview', 'https://www.mercedes-benz.co.kr/passengercars/models.html'),
    ('generation-benz-glb-official-lineup', 'model-benz-glb-kr', 'Mercedes-Benz Korea official model overview', 'https://www.mercedes-benz.co.kr/passengercars/models.html'),
    ('generation-benz-glc-coupe-official-lineup', 'model-benz-glc-coupe-kr', 'Mercedes-Benz Korea official model overview', 'https://www.mercedes-benz.co.kr/passengercars/models.html'),
    ('generation-benz-gle-coupe-official-lineup', 'model-benz-gle-coupe-kr', 'Mercedes-Benz Korea official model overview', 'https://www.mercedes-benz.co.kr/passengercars/models.html'),
    ('generation-benz-maybach-gls-official-lineup', 'model-benz-maybach-gls-kr', 'Mercedes-Benz Korea official model overview', 'https://www.mercedes-benz.co.kr/passengercars/models.html'),
    ('generation-benz-g-class-official-lineup', 'model-benz-g-class-kr', 'Mercedes-Benz Korea official model overview', 'https://www.mercedes-benz.co.kr/passengercars/models.html'),
    ('generation-benz-cla-coupe-official-lineup', 'model-benz-cla-coupe-kr', 'Mercedes-Benz Korea official model overview', 'https://www.mercedes-benz.co.kr/passengercars/models.html'),
    ('generation-benz-cle-coupe-official-lineup', 'model-benz-cle-coupe-kr', 'Mercedes-Benz Korea official model overview', 'https://www.mercedes-benz.co.kr/passengercars/models.html'),
    ('generation-benz-amg-gt-coupe-official-lineup', 'model-benz-amg-gt-coupe-kr', 'Mercedes-Benz Korea official model overview', 'https://www.mercedes-benz.co.kr/passengercars/models.html'),
    ('generation-benz-amg-gt-4door-coupe-official-lineup', 'model-benz-amg-gt-4door-coupe-kr', 'Mercedes-Benz Korea official model overview', 'https://www.mercedes-benz.co.kr/passengercars/models.html'),
    ('generation-benz-cle-cabriolet-official-lineup', 'model-benz-cle-cabriolet-kr', 'Mercedes-Benz Korea official model overview', 'https://www.mercedes-benz.co.kr/passengercars/models.html'),
    ('generation-benz-sl-roadster-official-lineup', 'model-benz-sl-roadster-kr', 'Mercedes-Benz Korea official model overview', 'https://www.mercedes-benz.co.kr/passengercars/models.html'),
    ('generation-benz-maybach-sl-monogram-official-lineup', 'model-benz-maybach-sl-monogram-kr', 'Mercedes-Benz Korea official model overview', 'https://www.mercedes-benz.co.kr/passengercars/models.html'),
    ('generation-audi-e-tron-gt-official-lineup', 'model-audi-e-tron-gt-kr', 'Audi Korea official model overview', 'https://www.audi.co.kr/ko/models/'),
    ('generation-audi-a6-e-tron-official-lineup', 'model-audi-a6-e-tron-kr', 'Audi Korea official model overview', 'https://www.audi.co.kr/ko/models/'),
    ('generation-audi-q6-e-tron-official-lineup', 'model-audi-q6-e-tron-kr', 'Audi Korea official model overview', 'https://www.audi.co.kr/ko/models/')
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
    ('model-benz-s-class-long-kr', 'generation-benz-s-class-long-official-lineup'),
    ('model-benz-maybach-s-class-kr', 'generation-benz-maybach-s-class-official-lineup'),
    ('model-benz-eqe-suv-kr', 'generation-benz-eqe-suv-official-lineup'),
    ('model-benz-maybach-eqs-suv-kr', 'generation-benz-maybach-eqs-suv-official-lineup'),
    ('model-benz-glb-kr', 'generation-benz-glb-official-lineup'),
    ('model-benz-glc-coupe-kr', 'generation-benz-glc-coupe-official-lineup'),
    ('model-benz-gle-coupe-kr', 'generation-benz-gle-coupe-official-lineup'),
    ('model-benz-maybach-gls-kr', 'generation-benz-maybach-gls-official-lineup'),
    ('model-benz-g-class-kr', 'generation-benz-g-class-official-lineup'),
    ('model-benz-cla-coupe-kr', 'generation-benz-cla-coupe-official-lineup'),
    ('model-benz-cle-coupe-kr', 'generation-benz-cle-coupe-official-lineup'),
    ('model-benz-amg-gt-coupe-kr', 'generation-benz-amg-gt-coupe-official-lineup'),
    ('model-benz-amg-gt-4door-coupe-kr', 'generation-benz-amg-gt-4door-coupe-official-lineup'),
    ('model-benz-cle-cabriolet-kr', 'generation-benz-cle-cabriolet-official-lineup'),
    ('model-benz-sl-roadster-kr', 'generation-benz-sl-roadster-official-lineup'),
    ('model-benz-maybach-sl-monogram-kr', 'generation-benz-maybach-sl-monogram-official-lineup'),
    ('model-audi-e-tron-gt-kr', 'generation-audi-e-tron-gt-official-lineup'),
    ('model-audi-a6-e-tron-kr', 'generation-audi-a6-e-tron-official-lineup'),
    ('model-audi-q6-e-tron-kr', 'generation-audi-q6-e-tron-official-lineup')
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
  'generation-benz-s-class-long-official-lineup',
  'generation-benz-maybach-s-class-official-lineup',
  'generation-benz-eqe-suv-official-lineup',
  'generation-benz-maybach-eqs-suv-official-lineup',
  'generation-benz-glb-official-lineup',
  'generation-benz-glc-coupe-official-lineup',
  'generation-benz-gle-coupe-official-lineup',
  'generation-benz-maybach-gls-official-lineup',
  'generation-benz-g-class-official-lineup',
  'generation-benz-cla-coupe-official-lineup',
  'generation-benz-cle-coupe-official-lineup',
  'generation-benz-amg-gt-coupe-official-lineup',
  'generation-benz-amg-gt-4door-coupe-official-lineup',
  'generation-benz-cle-cabriolet-official-lineup',
  'generation-benz-sl-roadster-official-lineup',
  'generation-benz-maybach-sl-monogram-official-lineup',
  'generation-audi-e-tron-gt-official-lineup',
  'generation-audi-a6-e-tron-official-lineup',
  'generation-audi-q6-e-tron-official-lineup'
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
    ('model-benz-s-class-long-kr', '가솔린', 'km/L', '대형', 'gasoline', 10),
    ('model-benz-s-class-long-kr', '플러그인 하이브리드', 'km/L', '대형', 'plug_in_hybrid', 30),
    ('model-benz-maybach-s-class-kr', '가솔린', 'km/L', '대형', 'gasoline', 10),
    ('model-benz-eqe-suv-kr', '전기차', 'km/kWh', '대형 SUV', 'electric', 10),
    ('model-benz-maybach-eqs-suv-kr', '전기차', 'km/kWh', '대형 SUV', 'electric', 10),
    ('model-benz-glb-kr', '가솔린', 'km/L', 'SUV', 'gasoline', 10),
    ('model-benz-glc-coupe-kr', '가솔린', 'km/L', 'SUV', 'gasoline', 10),
    ('model-benz-gle-coupe-kr', '가솔린', 'km/L', '대형 SUV', 'gasoline', 10),
    ('model-benz-gle-coupe-kr', '디젤', 'km/L', '대형 SUV', 'diesel', 20),
    ('model-benz-maybach-gls-kr', '가솔린', 'km/L', '대형 SUV', 'gasoline', 10),
    ('model-benz-g-class-kr', '가솔린', 'km/L', '대형 SUV', 'gasoline', 10),
    ('model-benz-g-class-kr', '디젤', 'km/L', '대형 SUV', 'diesel', 20),
    ('model-benz-g-class-kr', '전기차', 'km/kWh', '대형 SUV', 'electric', 30),
    ('model-benz-cla-coupe-kr', '가솔린', 'km/L', '준중형', 'gasoline', 10),
    ('model-benz-cle-coupe-kr', '가솔린', 'km/L', '중형', 'gasoline', 10),
    ('model-benz-amg-gt-coupe-kr', '가솔린', 'km/L', '스포츠', 'gasoline', 10),
    ('model-benz-amg-gt-coupe-kr', '플러그인 하이브리드', 'km/L', '스포츠', 'plug_in_hybrid', 30),
    ('model-benz-amg-gt-4door-coupe-kr', '가솔린', 'km/L', '대형', 'gasoline', 10),
    ('model-benz-cle-cabriolet-kr', '가솔린', 'km/L', '중형', 'gasoline', 10),
    ('model-benz-sl-roadster-kr', '가솔린', 'km/L', '스포츠', 'gasoline', 10),
    ('model-benz-maybach-sl-monogram-kr', '가솔린', 'km/L', '스포츠', 'gasoline', 10),
    ('model-audi-e-tron-gt-kr', '전기차', 'km/kWh', '스포츠', 'electric', 10),
    ('model-audi-a6-e-tron-kr', '전기차', 'km/kWh', '대형', 'electric', 10),
    ('model-audi-q6-e-tron-kr', '전기차', 'km/kWh', 'SUV', 'electric', 10)
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

update public.vehicle_variants
set
  trim_name = '공식 제원 검수 대기',
  engine_name = 'Pending official specification review',
  displacement_cc = null,
  battery_kwh = null,
  drivetrain = '검수 대기',
  transmission = '검수 대기',
  source_status = 'pending_review',
  confidence_score = 0.1,
  is_selectable = false
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
and source_status = 'pending_review';
