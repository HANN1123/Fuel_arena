-- BMW 5 Series generation audit.
-- Adds official-source G30/G60 generation mapping while keeping model_years
-- and pending-review placeholder powertrains for later detailed sourcing.

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
    'generation-bmw-5series-g30',
    'model-bmw-055-5',
    7,
    '7세대',
    'Seventh generation',
    'G30',
    'G30',
    2017,
    null,
    2023,
    null,
    '2017~2023',
    false,
    false,
    'KR',
    'verified_admin',
    0.72,
    'BMW Group PressClub 2017 5 Series release',
    'https://www.press.bmwgroup.com/usa/article/detail/T0264802EN_US/the-all-new-2017-bmw-5-series%3A-performance-redefined?language=en_US',
    null,
    '2026-06-12',
    true,
    false,
    now()
  ),
  (
    'generation-bmw-5series-g60',
    'model-bmw-055-5',
    8,
    '8세대',
    'Eighth generation',
    'G60',
    'G60',
    2023,
    10,
    null,
    null,
    '2023.10~현재',
    true,
    false,
    'KR',
    'verified_admin',
    0.78,
    'BMW Korea PressClub 5 Series G60 release',
    'https://www.press.bmwgroup.com/korea/photo/detail/P90526770/BMW-Korea-to-release-the-next-generation-premium-sedan-the-new-BMW-5-Series-for-the-first-time-in-the?forceSitePreference=DESKTOP',
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
  generation_id = 'generation-bmw-5series-g30',
  production_year_label = '2017~2023'
where model_id = 'model-bmw-055-5'
  and year between 2017 and 2023;

update public.vehicle_model_years
set
  generation_id = 'generation-bmw-5series-g60',
  production_year_label = '2023.10~현재'
where model_id = 'model-bmw-055-5'
  and year between 2024 and 2026;

insert into public.vehicle_generation_years (
  generation_id,
  model_year_id,
  year
)
select generation_id, id, year
from public.vehicle_model_years
where generation_id in (
  'generation-bmw-5series-g30',
  'generation-bmw-5series-g60'
)
on conflict (generation_id, model_year_id) do nothing;

update public.vehicle_variants vv
set
  generation_id = vmy.generation_id,
  drivetrain = case
    when vv.drivetrain = 'FWD' then 'RWD'
    else vv.drivetrain
  end
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.model_id = 'model-bmw-055-5'
  and vmy.generation_id in (
    'generation-bmw-5series-g30',
    'generation-bmw-5series-g60'
  );

update public.vehicle_variants vv
set drivetrain = 'RWD'
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.model_id = 'model-bmw-055-5'
  and vv.drivetrain = 'FWD';
