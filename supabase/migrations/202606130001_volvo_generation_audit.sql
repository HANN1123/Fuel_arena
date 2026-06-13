-- Volvo generation audit.
-- Adds pending-review generation rows for Volvo seed models, adds the current
-- V60 Cross Country Korea lineup row, and deprecates impossible placeholder
-- years/powertrains before users can select them.

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
values (
  'model-volvo-v60-cross-country-kr',
  'm-volvo',
  'V60 Cross Country',
  'V60 Cross Country',
  '크로스컨트리',
  '{"가솔린"}',
  false,
  90
)
on conflict (id) do update set
  manufacturer_id = excluded.manufacturer_id,
  name_ko = excluded.name_ko,
  name_en = excluded.name_en,
  body_type = excluded.body_type,
  available_fuel_types = excluded.available_fuel_types,
  is_popular = excluded.is_popular,
  sort_order = excluded.sort_order;

with volvo_generations (
  id,
  model_id,
  generation_order,
  generation_name_ko,
  generation_name_en,
  generation_code,
  platform_code,
  start_year,
  end_year,
  display_period,
  is_current,
  confidence_score,
  source_url
) as (
  values
    ('generation-volvo-s60-p3', 'model-volvo-124-s60', 2, '2세대', 'Second generation', 'P3', 'P3', 2010, 2018, '2010~2018', false, 0.56, 'https://www.volvocars.com/us/media/press-releases/4DA080AF252FD9FF/'),
    ('generation-volvo-s60-spa', 'model-volvo-124-s60', 3, '3세대', 'Third generation', 'SPA', 'SPA', 2018, 2025, '2018~2025', false, 0.64, 'https://www.volvocars.com/us/media/press-releases/221545E8824EBEFC/'),
    ('generation-volvo-s90-spa', 'model-volvo-125-s90', 1, '1세대', 'First generation', 'SPA', 'SPA', 2016, null, '2016~현재', true, 0.64, 'https://www.volvocars.com/us/media/press-releases/42E0670260E4D00D/'),
    ('generation-volvo-xc40-cma', 'model-volvo-126-xc40', 1, '1세대', 'First generation', 'CMA', 'CMA', 2017, null, '2017~현재', true, 0.64, 'https://www.volvocars.com/us/media/press-releases/217972/'),
    ('generation-volvo-xc60-p3', 'model-volvo-127-xc60', 1, '1세대', 'First generation', 'P3', 'P3', 2008, 2017, '2008~2017', false, 0.56, 'https://www.volvocars.com/us/media/press-releases/184814/'),
    ('generation-volvo-xc60-spa', 'model-volvo-127-xc60', 2, '2세대', 'Second generation', 'SPA', 'SPA', 2017, null, '2017~현재', true, 0.64, 'https://www.volvocars.com/us/media/press-releases/184814/'),
    ('generation-volvo-xc90-spa', 'model-volvo-128-xc90', 2, '2세대', 'Second generation', 'SPA', 'SPA', 2014, null, '2014~현재', true, 0.60, 'https://www.volvocars.com/kr/'),
    ('generation-volvo-c40-cma', 'model-volvo-129-c40', 1, '1세대', 'First generation', 'C40', 'CMA', 2021, 2024, '2021~2024', false, 0.58, 'https://www.volvocars.com/us/media/press-releases/277409/'),
    ('generation-volvo-ex30', 'model-volvo-130-ex30', 1, '1세대', 'First generation', 'EX30', '', 2025, null, '2025~현재', true, 0.58, 'https://www.volvocars.com/us/media/models/ex30/2025/press-releases/'),
    ('generation-volvo-ex90', 'model-volvo-131-ex90', 1, '1세대', 'First generation', 'EX90', '', 2026, null, '2026~현재', true, 0.54, 'https://www.volvocars.com/kr/'),
    ('generation-volvo-v60-cross-country-spa', 'model-volvo-v60-cross-country-kr', 2, '2세대', 'Second generation', 'SPA', 'SPA', 2018, null, '2018~현재', true, 0.62, 'https://www.volvocars.com/us/media/press-releases/240100/')
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
  null,
  end_year,
  null,
  display_period,
  is_current,
  false,
  'KR',
  'pending_review',
  confidence_score,
  'Volvo Cars media and Volvo Korea current lineup',
  source_url,
  null,
  '2026-06-13',
  true,
  false,
  now()
from volvo_generations
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

with v60_years (year) as (
  values (2019), (2020), (2021), (2022), (2023), (2024), (2025), (2026)
)
insert into public.vehicle_model_years (
  id,
  model_id,
  year,
  generation_id,
  production_year_label
)
select
  'year-volvo-v60-cross-country-kr-' || year,
  'model-volvo-v60-cross-country-kr',
  year,
  'generation-volvo-v60-cross-country-spa',
  '2018~현재'
from v60_years
on conflict (id) do update set
  model_id = excluded.model_id,
  year = excluded.year,
  generation_id = excluded.generation_id,
  production_year_label = excluded.production_year_label;

with v60_years (year) as (
  values (2019), (2020), (2021), (2022), (2023), (2024), (2025), (2026)
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
  'variant-volvo-v60-cross-country-' || year || '-gasoline',
  'year-volvo-v60-cross-country-kr-' || year,
  'generation-volvo-v60-cross-country-spa',
  '2.0 가솔린',
  '2.0 가솔린',
  '가솔린',
  1999,
  null,
  'AWD',
  '자동',
  null,
  'km/L',
  '중형',
  'gasoline',
  false,
  'unverified',
  0,
  true,
  false,
  10
from v60_years
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

with generation_year_mapping (
  model_id,
  year_start,
  year_end,
  generation_id,
  production_year_label
) as (
  values
    ('model-volvo-124-s60', 2015, 2018, 'generation-volvo-s60-p3', '2010~2018'),
    ('model-volvo-124-s60', 2019, 2025, 'generation-volvo-s60-spa', '2018~2025'),
    ('model-volvo-125-s90', 2016, 2026, 'generation-volvo-s90-spa', '2016~현재'),
    ('model-volvo-126-xc40', 2018, 2026, 'generation-volvo-xc40-cma', '2017~현재'),
    ('model-volvo-127-xc60', 2015, 2017, 'generation-volvo-xc60-p3', '2008~2017'),
    ('model-volvo-127-xc60', 2018, 2026, 'generation-volvo-xc60-spa', '2017~현재'),
    ('model-volvo-128-xc90', 2015, 2026, 'generation-volvo-xc90-spa', '2014~현재'),
    ('model-volvo-129-c40', 2022, 2024, 'generation-volvo-c40-cma', '2021~2024'),
    ('model-volvo-130-ex30', 2025, 2026, 'generation-volvo-ex30', '2025~현재'),
    ('model-volvo-131-ex90', 2026, 2026, 'generation-volvo-ex90', '2026~현재'),
    ('model-volvo-v60-cross-country-kr', 2019, 2026, 'generation-volvo-v60-cross-country-spa', '2018~현재')
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
  'generation-volvo-s60-p3',
  'generation-volvo-s60-spa',
  'generation-volvo-s90-spa',
  'generation-volvo-xc40-cma',
  'generation-volvo-xc60-p3',
  'generation-volvo-xc60-spa',
  'generation-volvo-xc90-spa',
  'generation-volvo-c40-cma',
  'generation-volvo-ex30',
  'generation-volvo-ex90',
  'generation-volvo-v60-cross-country-spa'
)
on conflict (generation_id, model_year_id) do nothing;

update public.vehicle_variants vv
set generation_id = vmy.generation_id
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.generation_id in (
    'generation-volvo-s60-p3',
    'generation-volvo-s60-spa',
    'generation-volvo-s90-spa',
    'generation-volvo-xc40-cma',
    'generation-volvo-xc60-p3',
    'generation-volvo-xc60-spa',
    'generation-volvo-xc90-spa',
    'generation-volvo-c40-cma',
    'generation-volvo-ex30',
    'generation-volvo-ex90',
    'generation-volvo-v60-cross-country-spa'
  );

delete from public.vehicle_generation_years vgy
using public.vehicle_model_years vmy
where vgy.model_year_id = vmy.id
  and (
    (vmy.model_id = 'model-volvo-124-s60' and vmy.year > 2025)
    or (vmy.model_id = 'model-volvo-125-s90' and vmy.year < 2016)
    or (vmy.model_id = 'model-volvo-126-xc40' and vmy.year < 2018)
    or (vmy.model_id = 'model-volvo-129-c40' and (vmy.year < 2022 or vmy.year > 2024))
    or (vmy.model_id = 'model-volvo-130-ex30' and vmy.year < 2025)
    or (vmy.model_id = 'model-volvo-131-ex90' and vmy.year < 2026)
    or (vmy.model_id = 'model-volvo-v60-cross-country-kr' and vmy.year < 2019)
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
    (vmy.model_id = 'model-volvo-124-s60' and vmy.year > 2025)
    or (vmy.model_id = 'model-volvo-125-s90' and vmy.year < 2016)
    or (vmy.model_id = 'model-volvo-126-xc40' and vmy.year < 2018)
    or (vmy.model_id = 'model-volvo-126-xc40' and vv.fuel_type = '전기차' and (vmy.year < 2021 or vmy.year > 2024))
    or (vmy.model_id = 'model-volvo-129-c40' and (vmy.year < 2022 or vmy.year > 2024))
    or (vmy.model_id = 'model-volvo-130-ex30' and vmy.year < 2025)
    or (vmy.model_id = 'model-volvo-131-ex90' and vmy.year < 2026)
    or (vmy.model_id = 'model-volvo-v60-cross-country-kr' and vmy.year < 2019)
  );

update public.vehicle_model_years
set
  generation_id = null,
  production_year_label = null
where (
    model_id = 'model-volvo-124-s60'
    and year > 2025
  )
  or (
    model_id = 'model-volvo-125-s90'
    and year < 2016
  )
  or (
    model_id = 'model-volvo-126-xc40'
    and year < 2018
  )
  or (
    model_id = 'model-volvo-129-c40'
    and (year < 2022 or year > 2024)
  )
  or (
    model_id = 'model-volvo-130-ex30'
    and year < 2025
  )
  or (
    model_id = 'model-volvo-131-ex90'
    and year < 2026
  )
  or (
    model_id = 'model-volvo-v60-cross-country-kr'
    and year < 2019
  );
