-- Land Rover Korea official 2026 powertrain boundary audit.
-- 2026 Land Rover price pages expose model engine codes, but not enough fuel
-- economy/spec detail for verified competition rows. Keep all Land Rover
-- audited powertrains pending/non-selectable and remove generated fake specs.

update public.vehicle_models
set available_fuel_types = '{"가솔린","플러그인 하이브리드"}'
where id = 'model-landrover-range-rover-velar-kr';

with audited_model_ids(id) as (
  values
    ('model-landrover-154-kr'),
    ('model-landrover-155-kr'),
    ('model-landrover-156-kr'),
    ('model-landrover-157-kr'),
    ('model-landrover-158-kr'),
    ('model-landrover-discovery-sport-kr'),
    ('model-landrover-range-rover-velar-kr')
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
  and vmy.year <> 2026;

delete from public.vehicle_variants vv
using public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.model_id in (
    'model-landrover-154-kr',
    'model-landrover-155-kr',
    'model-landrover-156-kr',
    'model-landrover-157-kr',
    'model-landrover-158-kr',
    'model-landrover-discovery-sport-kr',
    'model-landrover-range-rover-velar-kr'
  )
  and vmy.year = 2026
  and vv.id not in (
    'variant-landrover-defender-2026-d250-pending',
    'variant-landrover-defender-2026-d300-pending',
    'variant-landrover-defender-2026-p300-pending',
    'variant-landrover-defender-2026-p400-pending',
    'variant-landrover-defender-2026-p635-pending',
    'variant-landrover-discovery-2026-d350-pending',
    'variant-landrover-discovery-2026-p300-pending',
    'variant-landrover-discovery-2026-p360-pending',
    'variant-landrover-range-rover-2026-p530-pending',
    'variant-landrover-range-rover-2026-p615-pending',
    'variant-landrover-range-rover-2026-p550e-pending',
    'variant-landrover-range-rover-sport-2026-p360-pending',
    'variant-landrover-range-rover-sport-2026-p400-pending',
    'variant-landrover-range-rover-sport-2026-p635-pending',
    'variant-landrover-range-rover-sport-2026-p550e-pending',
    'variant-landrover-evoque-2026-p250-pending',
    'variant-landrover-discovery-sport-2026-p250-pending',
    'variant-landrover-velar-2026-p250-pending',
    'variant-landrover-velar-2026-p400-pending',
    'variant-landrover-velar-2026-p400e-pending'
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
  ('variant-landrover-defender-2026-d250-pending', 'year-landrover-154-kr-2026', 'generation-landrover-defender-official-lineup', 'Defender D250 공식 제원 검수 대기', 'Defender D250 official specification review pending', '디젤', null, null, '검수 대기', '검수 대기', null, 'km/L', '대형 SUV', 'diesel', false, 'pending_review', 'Land Rover Korea official 2026 price page', 'https://www.landroverkorea.co.kr/defender/defender-110/price-and-spec.html', '2026-06-13', 0.60, false, false, 10),
  ('variant-landrover-defender-2026-d300-pending', 'year-landrover-154-kr-2026', 'generation-landrover-defender-official-lineup', 'Defender D300 공식 제원 검수 대기', 'Defender D300 official specification review pending', '디젤', null, null, '검수 대기', '검수 대기', null, 'km/L', '대형 SUV', 'diesel', false, 'pending_review', 'Land Rover Korea official 2026 price page', 'https://www.landroverkorea.co.kr/defender/defender-110/price-and-spec.html', '2026-06-13', 0.60, false, false, 20),
  ('variant-landrover-defender-2026-p300-pending', 'year-landrover-154-kr-2026', 'generation-landrover-defender-official-lineup', 'Defender P300 공식 제원 검수 대기', 'Defender P300 official specification review pending', '가솔린', null, null, '검수 대기', '검수 대기', null, 'km/L', '대형 SUV', 'gasoline', false, 'pending_review', 'Land Rover Korea official 2026 price page', 'https://www.landroverkorea.co.kr/defender/defender-110/price-and-spec.html', '2026-06-13', 0.60, false, false, 30),
  ('variant-landrover-defender-2026-p400-pending', 'year-landrover-154-kr-2026', 'generation-landrover-defender-official-lineup', 'Defender P400 공식 제원 검수 대기', 'Defender P400 official specification review pending', '가솔린', null, null, '검수 대기', '검수 대기', null, 'km/L', '대형 SUV', 'gasoline', false, 'pending_review', 'Land Rover Korea official 2026 price page', 'https://www.landroverkorea.co.kr/defender/defender-110/price-and-spec.html', '2026-06-13', 0.60, false, false, 40),
  ('variant-landrover-defender-2026-p635-pending', 'year-landrover-154-kr-2026', 'generation-landrover-defender-official-lineup', 'Defender P635 OCTA 공식 제원 검수 대기', 'Defender P635 OCTA official specification review pending', '가솔린', null, null, '검수 대기', '검수 대기', null, 'km/L', '대형 SUV', 'gasoline', false, 'pending_review', 'Land Rover Korea official 2026 price page', 'https://www.landroverkorea.co.kr/defender/defender-110/price-and-spec.html', '2026-06-13', 0.60, false, false, 50),
  ('variant-landrover-discovery-2026-d350-pending', 'year-landrover-155-kr-2026', 'generation-landrover-discovery-official-lineup', 'Discovery D350 공식 제원 검수 대기', 'Discovery D350 official specification review pending', '디젤', null, null, '검수 대기', '검수 대기', null, 'km/L', '대형 SUV', 'diesel', false, 'pending_review', 'Land Rover Korea official 2026 price page', 'https://www.landroverkorea.co.kr/discovery/discovery/price-and-spec.html', '2026-06-13', 0.60, false, false, 10),
  ('variant-landrover-discovery-2026-p300-pending', 'year-landrover-155-kr-2026', 'generation-landrover-discovery-official-lineup', 'Discovery P300 공식 제원 검수 대기', 'Discovery P300 official specification review pending', '가솔린', null, null, '검수 대기', '검수 대기', null, 'km/L', '대형 SUV', 'gasoline', false, 'pending_review', 'Land Rover Korea official 2026 price page', 'https://www.landroverkorea.co.kr/discovery/discovery/price-and-spec.html', '2026-06-13', 0.60, false, false, 20),
  ('variant-landrover-discovery-2026-p360-pending', 'year-landrover-155-kr-2026', 'generation-landrover-discovery-official-lineup', 'Discovery P360 공식 제원 검수 대기', 'Discovery P360 official specification review pending', '가솔린', null, null, '검수 대기', '검수 대기', null, 'km/L', '대형 SUV', 'gasoline', false, 'pending_review', 'Land Rover Korea official 2026 price page', 'https://www.landroverkorea.co.kr/discovery/discovery/price-and-spec.html', '2026-06-13', 0.60, false, false, 30),
  ('variant-landrover-range-rover-2026-p530-pending', 'year-landrover-156-kr-2026', 'generation-landrover-range-rover-official-lineup', 'Range Rover P530 공식 제원 검수 대기', 'Range Rover P530 official specification review pending', '가솔린', null, null, '검수 대기', '검수 대기', null, 'km/L', '대형 SUV', 'gasoline', false, 'pending_review', 'Land Rover Korea official 2026 price page', 'https://www.landroverkorea.co.kr/range-rover/range-rover/price-and-spec.html', '2026-06-13', 0.60, false, false, 10),
  ('variant-landrover-range-rover-2026-p615-pending', 'year-landrover-156-kr-2026', 'generation-landrover-range-rover-official-lineup', 'Range Rover P615 SV 공식 제원 검수 대기', 'Range Rover P615 SV official specification review pending', '가솔린', null, null, '검수 대기', '검수 대기', null, 'km/L', '대형 SUV', 'gasoline', false, 'pending_review', 'Land Rover Korea official 2026 price page', 'https://www.landroverkorea.co.kr/range-rover/range-rover/price-and-spec.html', '2026-06-13', 0.60, false, false, 20),
  ('variant-landrover-range-rover-2026-p550e-pending', 'year-landrover-156-kr-2026', 'generation-landrover-range-rover-official-lineup', 'Range Rover P550e 공식 제원 검수 대기', 'Range Rover P550e official specification review pending', '플러그인 하이브리드', null, null, '검수 대기', '검수 대기', null, 'km/L', '대형 SUV', 'plug_in_hybrid', false, 'pending_review', 'Land Rover Korea official 2026 price page', 'https://www.landroverkorea.co.kr/range-rover/range-rover/price-and-spec.html', '2026-06-13', 0.60, false, false, 30),
  ('variant-landrover-range-rover-sport-2026-p360-pending', 'year-landrover-157-kr-2026', 'generation-landrover-range-rover-sport-official-lineup', 'Range Rover Sport P360 공식 제원 검수 대기', 'Range Rover Sport P360 official specification review pending', '가솔린', null, null, '검수 대기', '검수 대기', null, 'km/L', '대형 SUV', 'gasoline', false, 'pending_review', 'Land Rover Korea official 2026 price page', 'https://www.landroverkorea.co.kr/range-rover/range-rover-sport/price-and-spec.html', '2026-06-13', 0.60, false, false, 10),
  ('variant-landrover-range-rover-sport-2026-p400-pending', 'year-landrover-157-kr-2026', 'generation-landrover-range-rover-sport-official-lineup', 'Range Rover Sport P400 공식 제원 검수 대기', 'Range Rover Sport P400 official specification review pending', '가솔린', null, null, '검수 대기', '검수 대기', null, 'km/L', '대형 SUV', 'gasoline', false, 'pending_review', 'Land Rover Korea official 2026 price page', 'https://www.landroverkorea.co.kr/range-rover/range-rover-sport/price-and-spec.html', '2026-06-13', 0.60, false, false, 20),
  ('variant-landrover-range-rover-sport-2026-p635-pending', 'year-landrover-157-kr-2026', 'generation-landrover-range-rover-sport-official-lineup', 'Range Rover Sport P635 SV 공식 제원 검수 대기', 'Range Rover Sport P635 SV official specification review pending', '가솔린', null, null, '검수 대기', '검수 대기', null, 'km/L', '대형 SUV', 'gasoline', false, 'pending_review', 'Land Rover Korea official 2026 price page', 'https://www.landroverkorea.co.kr/range-rover/range-rover-sport/price-and-spec.html', '2026-06-13', 0.60, false, false, 30),
  ('variant-landrover-range-rover-sport-2026-p550e-pending', 'year-landrover-157-kr-2026', 'generation-landrover-range-rover-sport-official-lineup', 'Range Rover Sport P550e 공식 제원 검수 대기', 'Range Rover Sport P550e official specification review pending', '플러그인 하이브리드', null, null, '검수 대기', '검수 대기', null, 'km/L', '대형 SUV', 'plug_in_hybrid', false, 'pending_review', 'Land Rover Korea official 2026 price page', 'https://www.landroverkorea.co.kr/range-rover/range-rover-sport/price-and-spec.html', '2026-06-13', 0.60, false, false, 40),
  ('variant-landrover-evoque-2026-p250-pending', 'year-landrover-158-kr-2026', 'generation-landrover-range-rover-evoque-official-lineup', 'Range Rover Evoque P250 공식 제원 검수 대기', 'Range Rover Evoque P250 official specification review pending', '가솔린', null, null, '검수 대기', '검수 대기', null, 'km/L', 'SUV', 'gasoline', false, 'pending_review', 'Land Rover Korea official 2026 price page', 'https://www.landroverkorea.co.kr/range-rover/range-rover-evoque/price-and-spec.html', '2026-06-13', 0.60, false, false, 10),
  ('variant-landrover-discovery-sport-2026-p250-pending', 'year-landrover-discovery-sport-kr-2026', 'generation-landrover-discovery-sport-official-lineup', 'Discovery Sport P250 공식 제원 검수 대기', 'Discovery Sport P250 official specification review pending', '가솔린', null, null, '검수 대기', '검수 대기', null, 'km/L', 'SUV', 'gasoline', false, 'pending_review', 'Land Rover Korea official 2026 price page', 'https://www.landroverkorea.co.kr/discovery/discovery-sport/price-and-spec.html', '2026-06-13', 0.60, false, false, 10),
  ('variant-landrover-velar-2026-p250-pending', 'year-landrover-range-rover-velar-kr-2026', 'generation-landrover-range-rover-velar-official-lineup', 'Range Rover Velar P250 공식 제원 검수 대기', 'Range Rover Velar P250 official specification review pending', '가솔린', null, null, '검수 대기', '검수 대기', null, 'km/L', 'SUV', 'gasoline', false, 'pending_review', 'Land Rover Korea official 2026 price page', 'https://www.landroverkorea.co.kr/range-rover/range-rover-velar/price-and-spec.html', '2026-06-13', 0.60, false, false, 10),
  ('variant-landrover-velar-2026-p400-pending', 'year-landrover-range-rover-velar-kr-2026', 'generation-landrover-range-rover-velar-official-lineup', 'Range Rover Velar P400 공식 제원 검수 대기', 'Range Rover Velar P400 official specification review pending', '가솔린', null, null, '검수 대기', '검수 대기', null, 'km/L', 'SUV', 'gasoline', false, 'pending_review', 'Land Rover Korea official 2026 price page', 'https://www.landroverkorea.co.kr/range-rover/range-rover-velar/price-and-spec.html', '2026-06-13', 0.60, false, false, 20),
  ('variant-landrover-velar-2026-p400e-pending', 'year-landrover-range-rover-velar-kr-2026', 'generation-landrover-range-rover-velar-official-lineup', 'Range Rover Velar P400e 공식 제원 검수 대기', 'Range Rover Velar P400e official specification review pending', '플러그인 하이브리드', null, null, '검수 대기', '검수 대기', null, 'km/L', 'SUV', 'plug_in_hybrid', false, 'pending_review', 'Land Rover Korea official 2026 price page', 'https://www.landroverkorea.co.kr/range-rover/range-rover-velar/price-and-spec.html', '2026-06-13', 0.60, false, false, 30)
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
