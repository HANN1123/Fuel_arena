-- Porsche Korea electric powertrain boundary audit.
-- Macan Electric and Cayenne Electric are official Porsche Korea model versions
-- for 2026, not separate app model rows. Keep them under Macan/Cayenne and
-- prevent pre-2026 electric placeholders.

update public.vehicle_models
set available_fuel_types = '{"가솔린","전기차"}'
where id = 'model-porsche-136-kr';

update public.vehicle_models
set available_fuel_types = '{"가솔린","플러그인 하이브리드","전기차"}'
where id = 'model-porsche-137-kr';

update public.vehicle_generations
set
  source_name = 'Porsche Korea official Macan model page',
  source_url = 'https://www.porsche.com/korea/ko/models/macan/',
  source_status = 'pending_review',
  updated_at = now()
where id = 'generation-porsche-macan-official-lineup';

update public.vehicle_generations
set
  source_name = 'Porsche Korea official Cayenne model page',
  source_url = 'https://www.porsche.com/korea/ko/models/cayenne/',
  source_status = 'pending_review',
  updated_at = now()
where id = 'generation-porsche-cayenne-official-lineup';

delete from public.vehicle_variants vv
using public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.model_id = 'model-porsche-136-kr'
  and vv.fuel_type = '전기차'
  and vmy.year < 2026;

delete from public.vehicle_variants vv
using public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.model_id = 'model-porsche-137-kr'
  and vv.fuel_type = '전기차'
  and vmy.year < 2026;

delete from public.vehicle_variants vv
using public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.model_id in ('model-porsche-136-kr', 'model-porsche-137-kr')
  and vmy.year = 2026
  and vv.fuel_type = '전기차'
  and vv.id not in (
    'variant-porsche-macan-2026-electric-pending',
    'variant-porsche-cayenne-2026-electric-pending'
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
  confidence_score,
  is_selectable,
  is_deprecated,
  sort_order
)
values
  (
    'variant-porsche-macan-2026-electric-pending',
    'year-porsche-136-kr-2026',
    'generation-porsche-macan-official-lineup',
    '공식 제원 검수 대기',
    'Pending official Macan Electric specification review',
    '전기차',
    null,
    null,
    '검수 대기',
    '검수 대기',
    null,
    'km/kWh',
    'SUV',
    'electric',
    false,
    'pending_review',
    0.58,
    false,
    false,
    70
  ),
  (
    'variant-porsche-cayenne-2026-electric-pending',
    'year-porsche-137-kr-2026',
    'generation-porsche-cayenne-official-lineup',
    '공식 제원 검수 대기',
    'Pending official Cayenne Electric specification review',
    '전기차',
    null,
    null,
    '검수 대기',
    '검수 대기',
    null,
    'km/kWh',
    '대형 SUV',
    'electric',
    false,
    'pending_review',
    0.58,
    false,
    false,
    70
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
  confidence_score = excluded.confidence_score,
  is_selectable = excluded.is_selectable,
  is_deprecated = excluded.is_deprecated,
  sort_order = excluded.sort_order;
