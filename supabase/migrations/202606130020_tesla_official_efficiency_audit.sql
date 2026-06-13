-- Tesla Korea official certified-efficiency audit.
-- Model S/3/X/Y rows are promoted only when present in Tesla Korea's
-- official certified range and efficiency support table.

with current_generation_sources (
  id,
  source_name,
  source_url,
  confidence_score
) as (
  values
    ('generation-tesla-model3-official-lineup', 'Tesla Korea official Model 3 page', 'https://www.tesla.com/ko_kr/model3', 0.72),
    ('generation-tesla-modely-official-lineup', 'Tesla Korea official Model Y page', 'https://www.tesla.com/ko_kr/modely', 0.72),
    ('generation-tesla-models-official-lineup', 'Tesla Korea official Model S page', 'https://www.tesla.com/ko_kr/models', 0.70),
    ('generation-tesla-modelx-official-lineup', 'Tesla Korea official Model X page', 'https://www.tesla.com/ko_kr/modelx', 0.70),
    ('generation-tesla-cybertruck-official-lineup', 'Tesla Korea official Cybertruck page', 'https://www.tesla.com/ko_kr/cybertruck', 0.62)
)
update public.vehicle_generations vg
set
  is_current = true,
  is_selectable = true,
  source_status = 'pending_review',
  source_name = cgs.source_name,
  source_url = cgs.source_url,
  last_verified_at = '2026-06-13',
  confidence_score = cgs.confidence_score,
  updated_at = now()
from current_generation_sources cgs
where vg.id = cgs.id;

with audited_model_ids(id) as (
  values
    ('model-tesla-120-model-3'),
    ('model-tesla-121-model-y'),
    ('model-tesla-122-model-s'),
    ('model-tesla-123-model-x'),
    ('model-tesla-cybertruck-kr')
)
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
join audited_model_ids ami on ami.id = vmy.model_id
where vv.model_year_id = vmy.id
  and vv.id not in (
    'variant-tesla-model-3-2026-standard-rwd',
    'variant-tesla-model-3-2026-premium-long-range-rwd',
    'variant-tesla-model-3-2026-performance',
    'variant-tesla-model-y-2026-premium-rwd',
    'variant-tesla-model-y-2026-premium-long-range-awd',
    'variant-tesla-model-y-2026-l-pending',
    'variant-tesla-model-s-2026-awd',
    'variant-tesla-model-s-2026-plaid',
    'variant-tesla-model-x-2026-awd',
    'variant-tesla-model-x-2026-plaid'
  );

delete from public.vehicle_variants vv
using public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.model_id in (
    'model-tesla-120-model-3',
    'model-tesla-121-model-y',
    'model-tesla-122-model-s',
    'model-tesla-123-model-x'
  )
  and vmy.year = 2026
  and vv.id not in (
    'variant-tesla-model-3-2026-standard-rwd',
    'variant-tesla-model-3-2026-premium-long-range-rwd',
    'variant-tesla-model-3-2026-performance',
    'variant-tesla-model-y-2026-premium-rwd',
    'variant-tesla-model-y-2026-premium-long-range-awd',
    'variant-tesla-model-y-2026-l-pending',
    'variant-tesla-model-s-2026-awd',
    'variant-tesla-model-s-2026-plaid',
    'variant-tesla-model-x-2026-awd',
    'variant-tesla-model-x-2026-plaid'
  );

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
  ('variant-tesla-model-3-2026-standard-rwd', 'year-tesla-120-model-3-2026', 'generation-tesla-model3-official-lineup', 'Model 3 Standard RWD', 'Single Motor RWD', '전기차', null, 62.10, 'RWD', '감속기', 5.4, 'km/kWh', '중형', 'electric', true, 'verified_official', 'Tesla Korea official certified range and efficiency', 'https://www.tesla.com/ko_kr/support/range-calculator-ref', '2026-06-13', 0.90, true, false, 10),
  ('variant-tesla-model-3-2026-premium-long-range-rwd', 'year-tesla-120-model-3-2026', 'generation-tesla-model3-official-lineup', 'Model 3 Premium Long Range RWD', 'Single Motor RWD', '전기차', null, 84.85, 'RWD', '감속기', 5.8, 'km/kWh', '중형', 'electric', true, 'verified_official', 'Tesla Korea official certified range and efficiency', 'https://www.tesla.com/ko_kr/support/range-calculator-ref', '2026-06-13', 0.90, true, false, 20),
  ('variant-tesla-model-3-2026-performance', 'year-tesla-120-model-3-2026', 'generation-tesla-model3-official-lineup', 'Model 3 Performance', 'Dual Motor AWD', '전기차', null, 84.85, 'AWD', '감속기', 4.8, 'km/kWh', '중형', 'electric', true, 'verified_official', 'Tesla Korea official certified range and efficiency', 'https://www.tesla.com/ko_kr/support/range-calculator-ref', '2026-06-13', 0.90, true, false, 30),
  ('variant-tesla-model-y-2026-premium-rwd', 'year-tesla-121-model-y-2026', 'generation-tesla-modely-official-lineup', 'Model Y Premium RWD', 'Single Motor RWD', '전기차', null, 62.10, 'RWD', '감속기', 5.6, 'km/kWh', 'SUV', 'electric', true, 'verified_official', 'Tesla Korea official certified range and efficiency', 'https://www.tesla.com/ko_kr/support/range-calculator-ref', '2026-06-13', 0.90, true, false, 10),
  ('variant-tesla-model-y-2026-premium-long-range-awd', 'year-tesla-121-model-y-2026', 'generation-tesla-modely-official-lineup', 'Model Y Premium Long Range AWD', 'Dual Motor AWD', '전기차', null, 84.85, 'AWD', '감속기', 5.4, 'km/kWh', 'SUV', 'electric', true, 'verified_official', 'Tesla Korea official certified range and efficiency', 'https://www.tesla.com/ko_kr/support/range-calculator-ref', '2026-06-13', 0.90, true, false, 20),
  ('variant-tesla-model-y-2026-l-pending', 'year-tesla-121-model-y-2026', 'generation-tesla-modely-official-lineup', 'Model Y L 공식 공인연비 검수 대기', 'Dual Motor AWD', '전기차', null, null, 'AWD', '검수 대기', null, 'km/kWh', 'SUV', 'electric', false, 'pending_review', 'Tesla Korea official Model Y page', 'https://www.tesla.com/ko_kr/modely', '2026-06-13', 0.62, false, false, 30),
  ('variant-tesla-model-s-2026-awd', 'year-tesla-122-model-s-2026', 'generation-tesla-models-official-lineup', 'Model S AWD', 'Dual Motor AWD', '전기차', null, 104.96, 'AWD', '감속기', 4.8, 'km/kWh', '대형', 'electric', true, 'verified_official', 'Tesla Korea official certified range and efficiency', 'https://www.tesla.com/ko_kr/support/range-calculator-ref', '2026-06-13', 0.90, true, false, 10),
  ('variant-tesla-model-s-2026-plaid', 'year-tesla-122-model-s-2026', 'generation-tesla-models-official-lineup', 'Model S Plaid', 'Tri Motor AWD', '전기차', null, 104.96, 'AWD', '감속기', 4.2, 'km/kWh', '대형', 'electric', true, 'verified_official', 'Tesla Korea official certified range and efficiency', 'https://www.tesla.com/ko_kr/support/range-calculator-ref', '2026-06-13', 0.90, true, false, 20),
  ('variant-tesla-model-x-2026-awd', 'year-tesla-123-model-x-2026', 'generation-tesla-modelx-official-lineup', 'Model X AWD', 'Dual Motor AWD', '전기차', null, 104.96, 'AWD', '감속기', 4.2, 'km/kWh', '대형 SUV', 'electric', true, 'verified_official', 'Tesla Korea official certified range and efficiency', 'https://www.tesla.com/ko_kr/support/range-calculator-ref', '2026-06-13', 0.90, true, false, 10),
  ('variant-tesla-model-x-2026-plaid', 'year-tesla-123-model-x-2026', 'generation-tesla-modelx-official-lineup', 'Model X Plaid', 'Tri Motor AWD', '전기차', null, 104.96, 'AWD', '감속기', 3.8, 'km/kWh', '대형 SUV', 'electric', true, 'verified_official', 'Tesla Korea official certified range and efficiency', 'https://www.tesla.com/ko_kr/support/range-calculator-ref', '2026-06-13', 0.90, true, false, 20)
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
