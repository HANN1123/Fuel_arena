-- BMW X-series generation audit.
-- Maps X1/X3/X5/X7 model years to official-source generation rows.
-- X7 did not exist before 2019, so legacy placeholder rows are retained only
-- as deprecated/non-selectable records if they already exist in a database.

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
    'generation-bmw-x1-e84',
    'model-bmw-057-x1',
    1,
    '1세대',
    'First generation',
    'E84',
    'E84',
    2010,
    2,
    2015,
    null,
    '2010.2~2015',
    false,
    false,
    'KR',
    'verified_admin',
    0.76,
    'BMW Korea PressClub X1 launch',
    'https://www.press.bmwgroup.com/korea/article/detail/T0077953KO/%EC%84%B8%EA%B3%84-%EC%B5%9C%EC%B4%88-%ED%94%84%EB%A6%AC%EB%AF%B8%EC%97%84-%EC%BB%B4%ED%8C%A9%ED%8A%B8-sav-bmw-%EC%BD%94%EB%A6%AC%EC%95%84-bmw-x1-%EC%B6%9C%EC%8B%9C?language=ko',
    null,
    '2026-06-12',
    true,
    false,
    now()
  ),
  (
    'generation-bmw-x1-f48',
    'model-bmw-057-x1',
    2,
    '2세대',
    'Second generation',
    'F48',
    'F48',
    2016,
    2,
    2022,
    null,
    '2016.2~2022',
    false,
    false,
    'KR',
    'verified_admin',
    0.78,
    'BMW Korea PressClub 2nd generation X1 launch',
    'https://www.press.bmwgroup.com/korea/article/detail/T0258265KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-2%EC%84%B8%EB%8C%80-%EB%89%B4-x1-%EA%B3%B5%EC%8B%9D-%EC%B6%9C%EC%8B%9C?language=ko',
    null,
    '2026-06-12',
    true,
    false,
    now()
  ),
  (
    'generation-bmw-x1-u11',
    'model-bmw-057-x1',
    3,
    '3세대',
    'Third generation',
    'U11',
    'U11',
    2023,
    3,
    null,
    null,
    '2023.3~현재',
    true,
    false,
    'KR',
    'verified_admin',
    0.78,
    'BMW Korea PressClub New X1 and iX1 launch',
    'https://www.press.bmwgroup.com/korea/article/detail/T0412647KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-%ED%94%84%EB%A6%AC%EB%AF%B8%EC%97%84-%EC%86%8C%ED%98%95-sav-%EB%89%B4-x1-%EB%B0%8F-%EB%89%B4-ix1-%EA%B3%B5%EC%8B%9D-%EC%B6%9C%EC%8B%9C?language=ko',
    null,
    '2026-06-12',
    true,
    false,
    now()
  ),
  (
    'generation-bmw-x3-f25',
    'model-bmw-058-x3',
    2,
    '2세대',
    'Second generation',
    'F25',
    'F25',
    2011,
    null,
    2017,
    null,
    '2011~2017',
    false,
    false,
    'KR',
    'verified_admin',
    0.76,
    'BMW Korea PressClub New X3 launch note',
    'https://www.press.bmwgroup.com/korea/article/detail/T0192351KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-%EB%89%B4-x3-%EA%B3%B5%EC%8B%9D-%EC%B6%9C%EC%8B%9C?language=ko',
    null,
    '2026-06-12',
    true,
    false,
    now()
  ),
  (
    'generation-bmw-x3-g01',
    'model-bmw-058-x3',
    3,
    '3세대',
    'Third generation',
    'G01',
    'G01',
    2017,
    11,
    2024,
    null,
    '2017.11~2024',
    false,
    false,
    'KR',
    'verified_admin',
    0.78,
    'BMW Korea PressClub 3rd generation X3 launch',
    'https://www.press.bmwgroup.com/korea/article/detail/T0276123KO/bmw-%EA%B7%B8%EB%A3%B9-%EC%BD%94%EB%A6%AC%EC%95%84-3%EC%84%B8%EB%8C%80-%EB%89%B4-x3-%EA%B3%B5%EC%8B%9D-%EC%B6%9C%EC%8B%9C?language=ko',
    null,
    '2026-06-12',
    true,
    false,
    now()
  ),
  (
    'generation-bmw-x3-g45',
    'model-bmw-058-x3',
    4,
    '4세대',
    'Fourth generation',
    'G45',
    'G45',
    2024,
    11,
    null,
    null,
    '2024.11~현재',
    true,
    false,
    'KR',
    'verified_admin',
    0.78,
    'BMW Korea PressClub 4th generation X3 launch',
    'https://www.press.bmwgroup.com/korea/article/detail/T0446603KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-4%EC%84%B8%EB%8C%80-%EC%99%84%EC%A0%84%EB%B3%80%EA%B2%BD-bmw-%EB%89%B4-x3%E2%80%99-%EA%B3%B5%EC%8B%9D-%EC%B6%9C%EC%8B%9C?language=ko',
    null,
    '2026-06-12',
    true,
    false,
    now()
  ),
  (
    'generation-bmw-x5-f15',
    'model-bmw-059-x5',
    3,
    '3세대',
    'Third generation',
    'F15',
    'F15',
    2013,
    11,
    2018,
    null,
    '2013.11~2018',
    false,
    false,
    'KR',
    'verified_admin',
    0.78,
    'BMW Korea PressClub 3rd generation X5 launch',
    'https://www.press.bmwgroup.com/korea/article/detail/T0156364KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-%EB%89%B4-x5-%EA%B3%B5%EC%8B%9D-%EC%B6%9C%EC%8B%9C?language=ko',
    null,
    '2026-06-12',
    true,
    false,
    now()
  ),
  (
    'generation-bmw-x5-g05',
    'model-bmw-059-x5',
    4,
    '4세대',
    'Fourth generation',
    'G05',
    'G05',
    2018,
    11,
    null,
    null,
    '2018.11~현재',
    true,
    false,
    'KR',
    'verified_admin',
    0.78,
    'BMW Korea PressClub 4th generation X5 pre-order',
    'https://www.press.bmwgroup.com/korea/article/detail/T0287123KO/bmw-%EA%B7%B8%EB%A3%B9-%EC%BD%94%EB%A6%AC%EC%95%84-4%EC%84%B8%EB%8C%80-%EB%89%B4-x5-%EC%82%AC%EC%A0%84-%EC%98%88%EC%95%BD-%EC%8B%A4%EC%8B%9C?language=ko',
    null,
    '2026-06-12',
    true,
    false,
    now()
  ),
  (
    'generation-bmw-x7-g07',
    'model-bmw-060-x7',
    1,
    '1세대',
    'First generation',
    'G07',
    'G07',
    2019,
    null,
    null,
    null,
    '2019~현재',
    true,
    false,
    'KR',
    'verified_admin',
    0.76,
    'BMW Korea PressClub X7 LCI launch note',
    'https://www.press.bmwgroup.com/korea/article/detail/T0407081KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-%ED%95%9C%EC%B8%B5-%EC%A7%84%EB%B3%B4%ED%95%9C-%ED%94%8C%EB%9E%98%EA%B7%B8%EC%8B%AD-sav-%EB%89%B4-x7%E2%80%99-%EA%B5%AD%EB%82%B4-%EA%B3%B5%EC%8B%9D-%EC%B6%9C%EC%8B%9C?language=ko',
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
  generation_id = 'generation-bmw-x1-e84',
  production_year_label = '2010.2~2015'
where model_id = 'model-bmw-057-x1'
  and year = 2015;

update public.vehicle_model_years
set
  generation_id = 'generation-bmw-x1-f48',
  production_year_label = '2016.2~2022'
where model_id = 'model-bmw-057-x1'
  and year between 2016 and 2022;

update public.vehicle_model_years
set
  generation_id = 'generation-bmw-x1-u11',
  production_year_label = '2023.3~현재'
where model_id = 'model-bmw-057-x1'
  and year between 2023 and 2026;

update public.vehicle_model_years
set
  generation_id = 'generation-bmw-x3-f25',
  production_year_label = '2011~2017'
where model_id = 'model-bmw-058-x3'
  and year between 2015 and 2017;

update public.vehicle_model_years
set
  generation_id = 'generation-bmw-x3-g01',
  production_year_label = '2017.11~2024'
where model_id = 'model-bmw-058-x3'
  and year between 2018 and 2024;

update public.vehicle_model_years
set
  generation_id = 'generation-bmw-x3-g45',
  production_year_label = '2024.11~현재'
where model_id = 'model-bmw-058-x3'
  and year between 2025 and 2026;

update public.vehicle_model_years
set
  generation_id = 'generation-bmw-x5-f15',
  production_year_label = '2013.11~2018'
where model_id = 'model-bmw-059-x5'
  and year between 2015 and 2018;

update public.vehicle_model_years
set
  generation_id = 'generation-bmw-x5-g05',
  production_year_label = '2018.11~현재'
where model_id = 'model-bmw-059-x5'
  and year between 2019 and 2026;

update public.vehicle_model_years
set
  generation_id = 'generation-bmw-x7-g07',
  production_year_label = '2019~현재'
where model_id = 'model-bmw-060-x7'
  and year between 2019 and 2026;

update public.vehicle_model_years
set
  generation_id = null,
  production_year_label = null
where model_id = 'model-bmw-060-x7'
  and year < 2019;

insert into public.vehicle_generation_years (
  generation_id,
  model_year_id,
  year
)
select generation_id, id, year
from public.vehicle_model_years
where generation_id in (
  'generation-bmw-x1-e84',
  'generation-bmw-x1-f48',
  'generation-bmw-x1-u11',
  'generation-bmw-x3-f25',
  'generation-bmw-x3-g01',
  'generation-bmw-x3-g45',
  'generation-bmw-x5-f15',
  'generation-bmw-x5-g05',
  'generation-bmw-x7-g07'
)
on conflict (generation_id, model_year_id) do nothing;

delete from public.vehicle_generation_years vgy
using public.vehicle_model_years vmy
where vgy.model_year_id = vmy.id
  and vmy.model_id = 'model-bmw-060-x7'
  and vmy.year < 2019;

update public.vehicle_variants vv
set
  generation_id = vmy.generation_id,
  drivetrain = case
    when vv.drivetrain = 'FWD' then 'AWD'
    else vv.drivetrain
  end
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.model_id in (
    'model-bmw-057-x1',
    'model-bmw-058-x3',
    'model-bmw-059-x5',
    'model-bmw-060-x7'
  )
  and vmy.generation_id in (
    'generation-bmw-x1-e84',
    'generation-bmw-x1-f48',
    'generation-bmw-x1-u11',
    'generation-bmw-x3-f25',
    'generation-bmw-x3-g01',
    'generation-bmw-x3-g45',
    'generation-bmw-x5-f15',
    'generation-bmw-x5-g05',
    'generation-bmw-x7-g07'
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
  and vmy.model_id = 'model-bmw-060-x7'
  and vmy.year < 2019;
