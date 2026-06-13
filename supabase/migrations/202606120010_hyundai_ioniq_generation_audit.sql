-- Hyundai IONIQ generation audit.
-- Adds official-source generation rows for IONIQ 5 and IONIQ 6, and marks
-- legacy pre-launch placeholder variants as deprecated if they already exist.

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
    'generation-hyundai-ioniq5-ne',
    'model-hyundai-009-5',
    1,
    '1세대',
    'First generation',
    'NE/NE PE',
    'E-GMP',
    2021,
    2,
    null,
    null,
    '2021.2~현재',
    true,
    false,
    'KR',
    'verified_admin',
    0.76,
    'Hyundai Motor IONIQ 5 world premiere',
    'https://www.hyundai.com/worldwide/en/newsroom/detail/hyundai-ioniq-5-redefines-electric-mobility-lifestyle-0000000551',
    null,
    '2026-06-12',
    true,
    false,
    now()
  ),
  (
    'generation-hyundai-ioniq6-ce',
    'model-hyundai-010-6',
    1,
    '1세대',
    'First generation',
    'CE/CE PE',
    'E-GMP',
    2022,
    7,
    null,
    null,
    '2022.7~현재',
    true,
    false,
    'KR',
    'verified_admin',
    0.76,
    'Hyundai Motor IONIQ 6 world premiere',
    'https://www.hyundai.com/worldwide/en/newsroom/detail/hyundai-motor-debuts-ioniq-6-electrified-streamliner-with-610km-range-and-innovative-personal-space--0000016850',
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
  generation_id = 'generation-hyundai-ioniq5-ne',
  production_year_label = '2021.2~현재'
where model_id = 'model-hyundai-009-5'
  and year between 2021 and 2026;

update public.vehicle_model_years
set
  generation_id = 'generation-hyundai-ioniq6-ce',
  production_year_label = '2022.7~현재'
where model_id = 'model-hyundai-010-6'
  and year between 2022 and 2026;

update public.vehicle_model_years
set
  generation_id = null,
  production_year_label = null
where (
    model_id = 'model-hyundai-009-5'
    and year < 2021
  )
  or (
    model_id = 'model-hyundai-010-6'
    and year < 2022
  );

insert into public.vehicle_generation_years (
  generation_id,
  model_year_id,
  year
)
select generation_id, id, year
from public.vehicle_model_years
where generation_id in (
  'generation-hyundai-ioniq5-ne',
  'generation-hyundai-ioniq6-ce'
)
on conflict (generation_id, model_year_id) do nothing;

delete from public.vehicle_generation_years vgy
using public.vehicle_model_years vmy
where vgy.model_year_id = vmy.id
  and (
    (
      vmy.model_id = 'model-hyundai-009-5'
      and vmy.year < 2021
    )
    or (
      vmy.model_id = 'model-hyundai-010-6'
      and vmy.year < 2022
    )
  );

update public.vehicle_variants vv
set generation_id = vmy.generation_id
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.generation_id in (
    'generation-hyundai-ioniq5-ne',
    'generation-hyundai-ioniq6-ce'
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
    (
      vmy.model_id = 'model-hyundai-009-5'
      and vmy.year < 2021
    )
    or (
      vmy.model_id = 'model-hyundai-010-6'
      and vmy.year < 2022
    )
  );
