-- BMW 1/2 Series generation audit.
-- Adds official-source generation mapping for 1 Series hatchback and
-- 2 Series Coupe. The existing 2 Series model id is kept, but the visible
-- model name is narrowed to Coupe so it is not confused with Gran Coupe or
-- Active Tourer product lines.

update public.vehicle_models
set
  name_ko = '2시리즈 쿠페',
  name_en = '2 Series Coupe',
  body_type = '쿠페',
  available_fuel_types = array['가솔린']
where id = 'model-bmw-052-2';

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
) values
  (
    'generation-bmw-1series-f20',
    'model-bmw-051-1',
    2,
    '2세대',
    'Second generation',
    'F20',
    'F20',
    2012,
    10,
    2019,
    null,
    '2012.10~2019',
    false,
    false,
    'KR',
    'verified_admin',
    0.78,
    'BMW Korea PressClub 2nd generation 1 Series launch',
    'https://www.press.bmwgroup.com/korea/article/detail/T0133869KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-%EB%89%B4-1%EC%8B%9C%EB%A6%AC%EC%A6%88-%EC%B6%9C%EC%8B%9C?language=ko',
    null,
    '2026-06-12',
    true,
    false,
    now()
  ),
  (
    'generation-bmw-1series-f40',
    'model-bmw-051-1',
    3,
    '3세대',
    'Third generation',
    'F40',
    'F40',
    2020,
    1,
    2024,
    null,
    '2020.1~2024',
    false,
    false,
    'KR',
    'verified_admin',
    0.78,
    'BMW Korea PressClub 3rd generation 1 Series launch',
    'https://www.press.bmwgroup.com/korea/article/detail/T0304413KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-3%EC%84%B8%EB%8C%80-%EB%89%B4-1%EC%8B%9C%EB%A6%AC%EC%A6%88-%EA%B5%AD%EB%82%B4-%EC%B6%9C%EC%8B%9C?language=ko',
    null,
    '2026-06-12',
    true,
    false,
    now()
  ),
  (
    'generation-bmw-1series-f70',
    'model-bmw-051-1',
    4,
    '4세대',
    'Fourth generation',
    'F70',
    'F70',
    2024,
    10,
    null,
    null,
    '2024.10~현재',
    true,
    false,
    'KR',
    'verified_admin',
    0.76,
    'BMW Group/Korea PressClub 4th generation 1 Series launch',
    'https://www.press.bmwgroup.com/global/article/detail/T0443483EN/bmw-1-series-production-launch-at-bmw-group-plant-leipzig?language=en',
    null,
    '2026-06-12',
    true,
    false,
    now()
  ),
  (
    'generation-bmw-2series-coupe-f22',
    'model-bmw-052-2',
    1,
    '1세대',
    'First generation',
    'F22',
    'F22',
    2013,
    null,
    2021,
    null,
    '2013~2021',
    false,
    false,
    'KR',
    'verified_admin',
    0.74,
    'BMW Group PressClub Leipzig production list',
    'https://www.press.bmwgroup.com/global/article/detail/T0448360EN/anniversary%3A-20-years-of-series-production-at-bmw-group-plant-leipzig?language=en',
    null,
    '2026-06-12',
    true,
    false,
    now()
  ),
  (
    'generation-bmw-2series-coupe-g42',
    'model-bmw-052-2',
    2,
    '2세대',
    'Second generation',
    'G42',
    'G42',
    2021,
    7,
    null,
    null,
    '2021.7~현재',
    true,
    false,
    'KR',
    'verified_admin',
    0.78,
    'BMW Group PressClub all-new 2 Series Coupe',
    'https://www.press.bmwgroup.com/global/article/detail/T0336854EN/the-all-new-bmw-2-series-coup%C3%A9?language=en',
    null,
    '2026-06-12',
    true,
    false,
    now()
  )
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

update public.vehicle_model_years
set
  generation_id = 'generation-bmw-1series-f20',
  production_year_label = '2012.10~2019'
where model_id = 'model-bmw-051-1'
  and year between 2015 and 2019;

update public.vehicle_model_years
set
  generation_id = 'generation-bmw-1series-f40',
  production_year_label = '2020.1~2024'
where model_id = 'model-bmw-051-1'
  and year between 2020 and 2024;

update public.vehicle_model_years
set
  generation_id = 'generation-bmw-1series-f70',
  production_year_label = '2024.10~현재'
where model_id = 'model-bmw-051-1'
  and year between 2025 and 2026;

update public.vehicle_model_years
set
  generation_id = 'generation-bmw-2series-coupe-f22',
  production_year_label = '2013~2021'
where model_id = 'model-bmw-052-2'
  and year between 2015 and 2021;

update public.vehicle_model_years
set
  generation_id = 'generation-bmw-2series-coupe-g42',
  production_year_label = '2021.7~현재'
where model_id = 'model-bmw-052-2'
  and year between 2022 and 2026;

insert into public.vehicle_generation_years (
  generation_id,
  model_year_id,
  year
)
select generation_id, id, year
from public.vehicle_model_years
where generation_id in (
  'generation-bmw-1series-f20',
  'generation-bmw-1series-f40',
  'generation-bmw-1series-f70',
  'generation-bmw-2series-coupe-f22',
  'generation-bmw-2series-coupe-g42'
)
on conflict (generation_id, model_year_id) do nothing;

update public.vehicle_variants vv
set
  generation_id = vmy.generation_id,
  drivetrain = case
    when vmy.model_id = 'model-bmw-051-1' and vmy.year <= 2019 then 'RWD'
    when vmy.model_id = 'model-bmw-052-2' then 'RWD'
    else vv.drivetrain
  end
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.model_id in ('model-bmw-051-1', 'model-bmw-052-2')
  and vmy.generation_id in (
    'generation-bmw-1series-f20',
    'generation-bmw-1series-f40',
    'generation-bmw-1series-f70',
    'generation-bmw-2series-coupe-f22',
    'generation-bmw-2series-coupe-g42'
  );
