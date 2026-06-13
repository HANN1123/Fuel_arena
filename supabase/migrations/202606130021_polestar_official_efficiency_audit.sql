-- Polestar Korea official 2026 efficiency audit.
-- Polestar 2 and Polestar 4 have official domestic efficiency/spec rows.
-- Polestar 3 and Polestar 5 remain upcoming/pending until certified
-- domestic efficiency rows are published.

with generation_updates (
  id,
  source_name,
  source_url,
  display_period,
  is_current,
  is_upcoming,
  is_selectable,
  confidence_score
) as (
  values
    ('generation-polestar-2-official-lineup', 'Polestar Korea official Polestar 2 specifications page', 'https://www.polestar.com/kr/polestar-2/specifications/', '2026~현재', true, false, true, 0.82),
    ('generation-polestar-3-official-lineup', 'Polestar Korea official Polestar 3 page', 'https://www.polestar.com/kr/polestar-3/', '2026년 2분기 출시 예정', false, true, false, 0.62),
    ('generation-polestar-4-official-lineup', 'Polestar Korea official Polestar 4 specifications page', 'https://www.polestar.com/kr/polestar-4-models/polestar-4-coupe/specifications/', '2026~현재', true, false, true, 0.82),
    ('generation-polestar-5-official-lineup', 'Polestar Korea official Polestar 5 page', 'https://www.polestar.com/kr/polestar-5/', '2026년 국내 출시 예정', false, true, false, 0.60)
)
update public.vehicle_generations vg
set
  start_year = 2026,
  end_year = null,
  display_period = gu.display_period,
  is_current = gu.is_current,
  is_upcoming = gu.is_upcoming,
  is_selectable = gu.is_selectable,
  source_status = 'pending_review',
  source_name = gu.source_name,
  source_url = gu.source_url,
  last_verified_at = '2026-06-13',
  confidence_score = gu.confidence_score,
  updated_at = now()
from generation_updates gu
where vg.id = gu.id;

delete from public.vehicle_generation_years vgy
using public.vehicle_model_years vmy
where vgy.model_year_id = vmy.id
  and vmy.model_id in (
    'model-polestar-159-polestar-2',
    'model-polestar-160-polestar-3',
    'model-polestar-161-polestar-4',
    'model-polestar-5-kr'
  )
  and vmy.year <> 2026;

delete from public.vehicle_variants vv
using public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.model_id in (
    'model-polestar-159-polestar-2',
    'model-polestar-160-polestar-3',
    'model-polestar-161-polestar-4',
    'model-polestar-5-kr'
  )
  and vmy.year <> 2026;

delete from public.vehicle_model_years vmy
where vmy.model_id in (
    'model-polestar-159-polestar-2',
    'model-polestar-160-polestar-3',
    'model-polestar-161-polestar-4',
    'model-polestar-5-kr'
  )
  and vmy.year <> 2026;

update public.vehicle_variants vv
set
  trim_name = '공식 제원 검수 대기',
  engine_name = 'Pending official specification review',
  displacement_cc = null,
  battery_kwh = null,
  drivetrain = '검수 대기',
  transmission = '검수 대기',
  official_efficiency = null,
  is_verified = false,
  source_status = 'pending_review',
  source_name = null,
  source_url = null,
  source_file_name = null,
  last_verified_at = null,
  confidence_score = 0.10,
  is_selectable = false,
  is_deprecated = false
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.model_id in (
    'model-polestar-159-polestar-2',
    'model-polestar-160-polestar-3',
    'model-polestar-161-polestar-4',
    'model-polestar-5-kr'
  )
  and vv.id not in (
    'variant-polestar-2-2026-standard-range-single-motor',
    'variant-polestar-2-2026-long-range-single-motor',
    'variant-polestar-2-2026-long-range-dual-motor',
    'variant-polestar-4-2026-coupe-rear-motor',
    'variant-polestar-4-2026-coupe-dual-motor',
    'variant-polestar-4-2026-coupe-dual-motor-performance'
  );

delete from public.vehicle_variants vv
using public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.model_id in (
    'model-polestar-159-polestar-2',
    'model-polestar-161-polestar-4'
  )
  and vmy.year = 2026
  and vv.id not in (
    'variant-polestar-2-2026-standard-range-single-motor',
    'variant-polestar-2-2026-long-range-single-motor',
    'variant-polestar-2-2026-long-range-dual-motor',
    'variant-polestar-4-2026-coupe-rear-motor',
    'variant-polestar-4-2026-coupe-dual-motor',
    'variant-polestar-4-2026-coupe-dual-motor-performance'
  );

insert into public.vehicle_model_years (
  id,
  model_id,
  year,
  generation_id,
  production_year_label
)
values
  ('year-polestar-159-polestar-2-2026', 'model-polestar-159-polestar-2', 2026, 'generation-polestar-2-official-lineup', '2026~현재'),
  ('year-polestar-160-polestar-3-2026', 'model-polestar-160-polestar-3', 2026, 'generation-polestar-3-official-lineup', '2026년 2분기 출시 예정'),
  ('year-polestar-161-polestar-4-2026', 'model-polestar-161-polestar-4', 2026, 'generation-polestar-4-official-lineup', '2026~현재'),
  ('year-polestar-5-kr-2026', 'model-polestar-5-kr', 2026, 'generation-polestar-5-official-lineup', '2026년 국내 출시 예정')
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
  ('generation-polestar-2-official-lineup', 'year-polestar-159-polestar-2-2026', 2026),
  ('generation-polestar-3-official-lineup', 'year-polestar-160-polestar-3-2026', 2026),
  ('generation-polestar-4-official-lineup', 'year-polestar-161-polestar-4-2026', 2026),
  ('generation-polestar-5-official-lineup', 'year-polestar-5-kr-2026', 2026)
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
  ('variant-polestar-2-2026-standard-range-single-motor', 'year-polestar-159-polestar-2-2026', 'generation-polestar-2-official-lineup', 'Polestar 2 Standard range Single motor', 'Single motor 200 kW', '전기차', null, 69.0, 'RWD', '감속기', 5.2, 'km/kWh', '중형', 'electric', true, 'verified_official', 'Polestar Korea official Polestar 2 specifications page', 'https://www.polestar.com/kr/polestar-2/specifications/', '2026-06-13', 0.90, true, false, 10),
  ('variant-polestar-2-2026-long-range-single-motor', 'year-polestar-159-polestar-2-2026', 'generation-polestar-2-official-lineup', 'Polestar 2 Long range Single motor', 'Single motor 220 kW', '전기차', null, 78.0, 'RWD', '감속기', 5.1, 'km/kWh', '중형', 'electric', true, 'verified_official', 'Polestar Korea official Polestar 2 specifications page', 'https://www.polestar.com/kr/polestar-2/specifications/', '2026-06-13', 0.90, true, false, 20),
  ('variant-polestar-2-2026-long-range-dual-motor', 'year-polestar-159-polestar-2-2026', 'generation-polestar-2-official-lineup', 'Polestar 2 Long range Dual motor', 'Dual motor 310 kW', '전기차', null, 78.0, 'AWD', '감속기', 4.3, 'km/kWh', '중형', 'electric', true, 'verified_official', 'Polestar Korea official Polestar 2 specifications page', 'https://www.polestar.com/kr/polestar-2/specifications/', '2026-06-13', 0.90, true, false, 30),
  ('variant-polestar-4-2026-coupe-rear-motor', 'year-polestar-161-polestar-4-2026', 'generation-polestar-4-official-lineup', 'Polestar 4 coupé Rear motor', 'Rear motor', '전기차', null, 100.0, 'RWD', '감속기', 4.6, 'km/kWh', 'SUV', 'electric', true, 'verified_official', 'Polestar Korea official Polestar 4 specifications page', 'https://www.polestar.com/kr/polestar-4-models/polestar-4-coupe/specifications/', '2026-06-13', 0.90, true, false, 10),
  ('variant-polestar-4-2026-coupe-dual-motor', 'year-polestar-161-polestar-4-2026', 'generation-polestar-4-official-lineup', 'Polestar 4 coupé Dual motor (20/21인치 휠)', 'Dual motor', '전기차', null, 100.0, 'AWD', '감속기', 4.2, 'km/kWh', 'SUV', 'electric', true, 'verified_official', 'Polestar Korea official Polestar 4 specifications page', 'https://www.polestar.com/kr/polestar-4-models/polestar-4-coupe/specifications/', '2026-06-13', 0.90, true, false, 20),
  ('variant-polestar-4-2026-coupe-dual-motor-performance', 'year-polestar-161-polestar-4-2026', 'generation-polestar-4-official-lineup', 'Polestar 4 coupé Dual motor Performance package (22인치 휠)', 'Dual motor', '전기차', null, 100.0, 'AWD', '감속기', 3.7, 'km/kWh', 'SUV', 'electric', true, 'verified_official', 'Polestar Korea official Polestar 4 specifications page', 'https://www.polestar.com/kr/polestar-4-models/polestar-4-coupe/specifications/', '2026-06-13', 0.90, true, false, 30)
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
