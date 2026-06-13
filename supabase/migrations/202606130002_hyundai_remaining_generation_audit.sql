-- Hyundai remaining generation audit.
-- Links Avante N, Avante Sport, Kona, Palisade, Casper, Staria, and Porter
-- to generation rows and deprecates legacy placeholder years/powertrains.

update public.vehicle_models
set available_fuel_types = '{"가솔린","하이브리드","디젤"}'
where id = 'model-hyundai-007-kr';

update public.vehicle_models
set available_fuel_types = '{"디젤","LPG","하이브리드"}'
where id = 'model-hyundai-011-kr';

update public.vehicle_models
set available_fuel_types = '{"디젤","LPG","전기차"}'
where id = 'model-hyundai-012-kr';

with hyundai_generations (
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
  source_status,
  confidence_score,
  source_url
) as (
  values
    ('generation-hyundai-avante-n-cn7', 'model-hyundai-avante-n-kr', 1, '1세대', 'First generation', 'CN7 N/CN7 N PE', 'CN7', 2021, null, null, null, '2021~현재', true, 'verified_admin', 0.72, 'https://www.hyundai.com/kr/ko/brand/brandstory/model/avante-history'),
    ('generation-hyundai-avante-sport-ad', 'model-hyundai-avante-sport-kr', 1, 'AD 스포츠', 'Avante Sport', 'AD Sport', 'AD', 2016, null, 2018, null, '2016~2018', false, 'pending_review', 0.58, 'https://update.hyundai.com/KR/KO/updateNoticeView/software-version'),
    ('generation-hyundai-kona-os', 'model-hyundai-004-kr', 1, '1세대', 'First generation', 'OS/OS PE', 'OS', 2017, null, 2023, null, '2017~2023', false, 'verified_admin', 0.72, 'https://www.hyundai.com/kr/ko/brand/brandstory/model/kona-history'),
    ('generation-hyundai-kona-sx2', 'model-hyundai-004-kr', 2, '2세대', 'Second generation', 'SX2/SX2 PE', 'SX2', 2023, null, null, null, '2023~현재', true, 'verified_admin', 0.72, 'https://www.hyundai.com/kr/ko/brand/brandstory/model/kona-history'),
    ('generation-hyundai-palisade-lx2', 'model-hyundai-007-kr', 1, '1세대', 'First generation', 'LX2/LX2 PE', 'LX2', 2018, null, 2024, null, '2018~2024', false, 'verified_admin', 0.72, 'https://www.hyundai.com/kr/ko/brand/brandstory/model/palisade-history'),
    ('generation-hyundai-palisade-lx3', 'model-hyundai-007-kr', 2, '2세대', 'Second generation', 'LX3', 'LX3', 2025, 1, null, null, '2025.1~현재', true, 'verified_admin', 0.72, 'https://www.hyundai.com/kr/ko/e/vehicles/the-all-new-palisade/intro'),
    ('generation-hyundai-casper-ax1', 'model-hyundai-008-kr', 1, '1세대', 'First generation', 'AX1/AX1 PE', 'AX1', 2021, null, null, null, '2021~현재', true, 'verified_admin', 0.72, 'https://www.hyundai.com/kr/ko/brand/brandstory/model/casper-history'),
    ('generation-hyundai-staria-us4', 'model-hyundai-011-kr', 1, '1세대', 'First generation', 'US4/US4 PE', 'US4', 2021, null, null, null, '2021~현재', true, 'verified_admin', 0.72, 'https://www.hyundai.com/kr/ko/brand/brandstory/model/staria-history'),
    ('generation-hyundai-porter2-hr', 'model-hyundai-012-kr', 4, '포터 II', 'Porter II', 'HR/HR PE', 'HR', 2004, null, null, null, '2004~현재', true, 'verified_admin', 0.72, 'https://www.hyundai.com/kr/ko/brand/brandstory/model/porter-history')
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
  false,
  'KR',
  source_status,
  confidence_score,
  'Hyundai Motor model history and software version list',
  source_url,
  null,
  '2026-06-13',
  true,
  false,
  now()
from hyundai_generations
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

with generation_year_mapping (
  model_id,
  year_start,
  year_end,
  generation_id,
  production_year_label
) as (
  values
    ('model-hyundai-avante-n-kr', 2021, 2026, 'generation-hyundai-avante-n-cn7', '2021~현재'),
    ('model-hyundai-avante-sport-kr', 2016, 2018, 'generation-hyundai-avante-sport-ad', '2016~2018'),
    ('model-hyundai-004-kr', 2017, 2022, 'generation-hyundai-kona-os', '2017~2023'),
    ('model-hyundai-004-kr', 2023, 2026, 'generation-hyundai-kona-sx2', '2023~현재'),
    ('model-hyundai-007-kr', 2019, 2024, 'generation-hyundai-palisade-lx2', '2018~2024'),
    ('model-hyundai-007-kr', 2025, 2026, 'generation-hyundai-palisade-lx3', '2025.1~현재'),
    ('model-hyundai-008-kr', 2021, 2026, 'generation-hyundai-casper-ax1', '2021~현재'),
    ('model-hyundai-011-kr', 2021, 2026, 'generation-hyundai-staria-us4', '2021~현재'),
    ('model-hyundai-012-kr', 2015, 2026, 'generation-hyundai-porter2-hr', '2004~현재')
)
update public.vehicle_model_years vmy
set
  generation_id = gym.generation_id,
  production_year_label = gym.production_year_label
from generation_year_mapping gym
where vmy.model_id = gym.model_id
  and vmy.year between gym.year_start and gym.year_end;

insert into public.vehicle_generation_years (
  generation_id,
  model_year_id,
  year
)
select generation_id, id, year
from public.vehicle_model_years
where generation_id in (
  'generation-hyundai-avante-n-cn7',
  'generation-hyundai-avante-sport-ad',
  'generation-hyundai-kona-os',
  'generation-hyundai-kona-sx2',
  'generation-hyundai-palisade-lx2',
  'generation-hyundai-palisade-lx3',
  'generation-hyundai-casper-ax1',
  'generation-hyundai-staria-us4',
  'generation-hyundai-porter2-hr'
)
on conflict (generation_id, model_year_id) do nothing;

update public.vehicle_variants vv
set generation_id = vmy.generation_id
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.generation_id in (
    'generation-hyundai-avante-n-cn7',
    'generation-hyundai-avante-sport-ad',
    'generation-hyundai-kona-os',
    'generation-hyundai-kona-sx2',
    'generation-hyundai-palisade-lx2',
    'generation-hyundai-palisade-lx3',
    'generation-hyundai-casper-ax1',
    'generation-hyundai-staria-us4',
    'generation-hyundai-porter2-hr'
  );

with canonical_powertrains (
  model_id,
  year_start,
  year_end,
  fuel_type,
  trim_name,
  engine_name,
  displacement_cc,
  battery_kwh,
  drivetrain,
  transmission,
  official_efficiency,
  efficiency_unit,
  vehicle_class,
  fuel_league,
  sort_order
) as (
  values
    ('model-hyundai-avante-n-kr', 2021, 2026, '가솔린', '2.0T 가솔린 수동', 'N 전용 G2.0 터보 플랫파워', 1998, null::numeric, 'FWD', '6단 수동', 10.6, 'km/L', '스포츠', 'gasoline', 10),
    ('model-hyundai-avante-sport-kr', 2016, 2018, '가솔린', '1.6T 가솔린', 'Gamma 1.6 T-GDi', 1591, null::numeric, 'FWD', '7단 DCT', null::numeric, 'km/L', '스포츠', 'gasoline', 10),
    ('model-hyundai-004-kr', 2017, 2026, '가솔린', '1.6 가솔린', 'Smartstream G1.6', 1598, null::numeric, 'FWD', '자동', 14.3, 'km/L', '소형 SUV', 'gasoline', 10),
    ('model-hyundai-004-kr', 2020, 2026, '하이브리드', '1.6 하이브리드', 'Smartstream G1.6 Hybrid', 1580, null::numeric, 'FWD', '하이브리드 전용 변속기', 20.2, 'km/L', '소형 SUV', 'hybrid', 20),
    ('model-hyundai-004-kr', 2018, 2026, '전기차', '코나 일렉트릭', 'Electric Motor', null::integer, 64.8, '전동 구동', '감속기', 5.6, 'km/kWh', '소형 SUV', 'electric', 50),
    ('model-hyundai-007-kr', 2019, 2024, '가솔린', '3.8 가솔린', 'Lambda II 3.8 GDi', 3778, null::numeric, 'FWD', '자동 8단', 9.6, 'km/L', '대형 SUV', 'gasoline', 10),
    ('model-hyundai-007-kr', 2025, 2026, '가솔린', '2.5T 가솔린', 'Smartstream G2.5T', 2497, null::numeric, 'FWD', '자동 8단', 9.7, 'km/L', '대형 SUV', 'gasoline', 10),
    ('model-hyundai-007-kr', 2019, 2024, '디젤', '2.2 디젤', 'R 2.2 e-VGT', 2199, null::numeric, 'FWD', '자동 8단', 12.1, 'km/L', '대형 SUV', 'diesel', 40),
    ('model-hyundai-011-kr', 2021, 2026, '디젤', '2.2 디젤', 'Smartstream D2.2', 2199, null::numeric, 'FWD', '자동 8단', 11.8, 'km/L', 'MPV', 'diesel', 40),
    ('model-hyundai-011-kr', 2021, 2026, 'LPG', '3.5 LPi', 'Smartstream LPG 3.5', 3470, null::numeric, 'FWD', '자동 8단', 6.7, 'km/L', 'MPV', 'lpg', 30),
    ('model-hyundai-012-kr', 2015, 2023, '디젤', '2.5 디젤', 'A2 2.5 CRDi', 2497, null::numeric, 'RWD', '자동', 10.5, 'km/L', '상용', 'diesel', 40),
    ('model-hyundai-012-kr', 2019, 2026, '전기차', '포터 II Electric', 'Electric Motor', null::integer, 58.8, '전동 구동', '감속기', 3.1, 'km/kWh', '상용', 'electric', 50)
)
update public.vehicle_variants vv
set
  generation_id = vmy.generation_id,
  trim_name = cp.trim_name,
  engine_name = cp.engine_name,
  displacement_cc = cp.displacement_cc,
  battery_kwh = cp.battery_kwh,
  drivetrain = cp.drivetrain,
  transmission = cp.transmission,
  official_efficiency = cp.official_efficiency,
  efficiency_unit = cp.efficiency_unit,
  vehicle_class = cp.vehicle_class,
  fuel_league = cp.fuel_league,
  is_verified = false,
  source_status = 'unverified',
  confidence_score = 0,
  is_selectable = true,
  is_deprecated = false,
  sort_order = cp.sort_order
from public.vehicle_model_years vmy,
  canonical_powertrains cp
where vv.model_year_id = vmy.id
  and vmy.model_id = cp.model_id
  and vmy.year between cp.year_start and cp.year_end
  and vv.fuel_type = cp.fuel_type;

with years (year) as (
  values (2021), (2022), (2023), (2024), (2025), (2026)
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
  'variant-hyundai-avante-n-' || year || '-20t-8dct',
  'year-hyundai-avante-n-kr-' || year,
  'generation-hyundai-avante-n-cn7',
  '2.0T 가솔린 DCT',
  'N 전용 G2.0 터보 플랫파워',
  '가솔린',
  1998,
  null,
  'FWD',
  '8단 DCT',
  10.4,
  'km/L',
  '스포츠',
  'gasoline',
  false,
  'unverified',
  0,
  true,
  false,
  11
from years
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

with new_powertrains (
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
  sort_order
) as (
  values
    ('variant-hyundai-palisade-2025-25t-hybrid', 'year-hyundai-007-kr-2025', 'generation-hyundai-palisade-lx3', '2.5T 하이브리드', 'Smartstream G2.5T Hybrid', '하이브리드', 2497, null::numeric, 'FWD', '자동 6단', 14.1, 'km/L', '대형 SUV', 'hybrid', 20),
    ('variant-hyundai-palisade-2026-25t-hybrid', 'year-hyundai-007-kr-2026', 'generation-hyundai-palisade-lx3', '2.5T 하이브리드', 'Smartstream G2.5T Hybrid', '하이브리드', 2497, null::numeric, 'FWD', '자동 6단', 14.1, 'km/L', '대형 SUV', 'hybrid', 20),
    ('variant-hyundai-staria-2024-16t-hybrid', 'year-hyundai-011-kr-2024', 'generation-hyundai-staria-us4', '1.6T 하이브리드', 'Smartstream G1.6T Hybrid', '하이브리드', 1598, null::numeric, 'FWD', '자동 6단', 13.0, 'km/L', 'MPV', 'hybrid', 20),
    ('variant-hyundai-staria-2025-16t-hybrid', 'year-hyundai-011-kr-2025', 'generation-hyundai-staria-us4', '1.6T 하이브리드', 'Smartstream G1.6T Hybrid', '하이브리드', 1598, null::numeric, 'FWD', '자동 6단', 13.0, 'km/L', 'MPV', 'hybrid', 20),
    ('variant-hyundai-staria-2026-16t-hybrid', 'year-hyundai-011-kr-2026', 'generation-hyundai-staria-us4', '1.6T 하이브리드', 'Smartstream G1.6T Hybrid', '하이브리드', 1598, null::numeric, 'FWD', '자동 6단', 13.0, 'km/L', 'MPV', 'hybrid', 20),
    ('variant-hyundai-porter2-2024-25-lpg-6mt', 'year-hyundai-012-kr-2024', 'generation-hyundai-porter2-hr', '2.5 LPG 터보 수동', 'Smartstream LPG 2.5T', 'LPG', 2497, null::numeric, 'RWD', '6단 수동', null::numeric, 'km/L', '상용', 'lpg', 10),
    ('variant-hyundai-porter2-2024-25-lpg-5at', 'year-hyundai-012-kr-2024', 'generation-hyundai-porter2-hr', '2.5 LPG 터보 자동', 'Smartstream LPG 2.5T', 'LPG', 2497, null::numeric, 'RWD', '자동 5단', null::numeric, 'km/L', '상용', 'lpg', 11),
    ('variant-hyundai-porter2-2025-25-lpg-6mt', 'year-hyundai-012-kr-2025', 'generation-hyundai-porter2-hr', '2.5 LPG 터보 수동', 'Smartstream LPG 2.5T', 'LPG', 2497, null::numeric, 'RWD', '6단 수동', null::numeric, 'km/L', '상용', 'lpg', 10),
    ('variant-hyundai-porter2-2025-25-lpg-5at', 'year-hyundai-012-kr-2025', 'generation-hyundai-porter2-hr', '2.5 LPG 터보 자동', 'Smartstream LPG 2.5T', 'LPG', 2497, null::numeric, 'RWD', '자동 5단', null::numeric, 'km/L', '상용', 'lpg', 11),
    ('variant-hyundai-porter2-2026-25-lpg-6mt', 'year-hyundai-012-kr-2026', 'generation-hyundai-porter2-hr', '2.5 LPG 터보 수동', 'Smartstream LPG 2.5T', 'LPG', 2497, null::numeric, 'RWD', '6단 수동', null::numeric, 'km/L', '상용', 'lpg', 10),
    ('variant-hyundai-porter2-2026-25-lpg-5at', 'year-hyundai-012-kr-2026', 'generation-hyundai-porter2-hr', '2.5 LPG 터보 자동', 'Smartstream LPG 2.5T', 'LPG', 2497, null::numeric, 'RWD', '자동 5단', null::numeric, 'km/L', '상용', 'lpg', 11)
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
  false,
  'unverified',
  0,
  true,
  false,
  sort_order
from new_powertrains
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
    (vmy.model_id = 'model-hyundai-avante-n-kr' and vmy.year < 2021)
    or (vmy.model_id = 'model-hyundai-avante-sport-kr' and (vmy.year < 2016 or vmy.year > 2018))
    or (vmy.model_id = 'model-hyundai-004-kr' and vmy.year < 2017)
    or (vmy.model_id = 'model-hyundai-007-kr' and vmy.year < 2019)
    or (vmy.model_id = 'model-hyundai-008-kr' and vmy.year < 2021)
    or (vmy.model_id = 'model-hyundai-011-kr' and vmy.year < 2021)
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
    (vmy.model_id = 'model-hyundai-avante-n-kr' and vmy.year < 2021)
    or (vmy.model_id = 'model-hyundai-avante-sport-kr' and (vmy.year < 2016 or vmy.year > 2018))
    or (vmy.model_id = 'model-hyundai-004-kr' and vmy.year < 2017)
    or (vmy.model_id = 'model-hyundai-004-kr' and vv.fuel_type = '하이브리드' and vmy.year < 2020)
    or (vmy.model_id = 'model-hyundai-004-kr' and vv.fuel_type = '전기차' and vmy.year < 2018)
    or (vmy.model_id = 'model-hyundai-007-kr' and vmy.year < 2019)
    or (vmy.model_id = 'model-hyundai-007-kr' and vv.fuel_type = '디젤' and vmy.year > 2024)
    or (vmy.model_id = 'model-hyundai-007-kr' and vv.fuel_type = '하이브리드' and vmy.year < 2025)
    or (vmy.model_id = 'model-hyundai-008-kr' and vmy.year < 2021)
    or (vmy.model_id = 'model-hyundai-011-kr' and vmy.year < 2021)
    or (vmy.model_id = 'model-hyundai-011-kr' and vv.fuel_type = '가솔린')
    or (vmy.model_id = 'model-hyundai-011-kr' and vv.fuel_type = '하이브리드' and vmy.year < 2024)
    or (vmy.model_id = 'model-hyundai-012-kr' and vv.fuel_type = '디젤' and vmy.year > 2023)
    or (vmy.model_id = 'model-hyundai-012-kr' and vv.fuel_type = 'LPG' and vmy.year < 2024)
    or (vmy.model_id = 'model-hyundai-012-kr' and vv.fuel_type = '전기차' and vmy.year < 2019)
  );

update public.vehicle_model_years
set
  generation_id = null,
  production_year_label = null
where (
    model_id = 'model-hyundai-avante-n-kr'
    and year < 2021
  )
  or (
    model_id = 'model-hyundai-avante-sport-kr'
    and (year < 2016 or year > 2018)
  )
  or (
    model_id = 'model-hyundai-004-kr'
    and year < 2017
  )
  or (
    model_id = 'model-hyundai-007-kr'
    and year < 2019
  )
  or (
    model_id = 'model-hyundai-008-kr'
    and year < 2021
  )
  or (
    model_id = 'model-hyundai-011-kr'
    and year < 2021
  );
