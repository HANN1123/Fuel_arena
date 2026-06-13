-- Audi generation audit.
-- Adds generation rows for Audi seed models and deprecates legacy
-- pre-launch / post-discontinuation placeholder variants.

with audi_generations (
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
  confidence_score
) as (
  values
    ('generation-audi-a3-8v', 'model-audi-077-a3', 3, '3세대', 'Third generation', '8V', 'MQB', 2012, 2020, '2012~2020', false, 0.70),
    ('generation-audi-a3-8y', 'model-audi-077-a3', 4, '4세대', 'Fourth generation', '8Y/8Y PA', 'MQB Evo', 2020, null, '2020~현재', true, 0.70),
    ('generation-audi-a4-b9-8w', 'model-audi-078-a4', 5, '5세대', 'Fifth generation', 'B9/8W', 'MLB Evo', 2015, 2024, '2015~2024', false, 0.70),
    ('generation-audi-a5-8t', 'model-audi-079-a5', 1, '1세대', 'First generation', '8T/8F', 'MLB', 2007, 2016, '2007~2016', false, 0.70),
    ('generation-audi-a5-f5', 'model-audi-079-a5', 2, '2세대', 'Second generation', 'F5', 'MLB Evo', 2016, 2024, '2016~2024', false, 0.70),
    ('generation-audi-a5-b10', 'model-audi-079-a5', 3, '3세대', 'Third generation', 'B10', 'PPC', 2024, null, '2024~현재', true, 0.70),
    ('generation-audi-a6-c7-4g', 'model-audi-080-a6', 7, '7세대', 'Seventh generation', 'C7/4G', 'MLB', 2011, 2018, '2011~2018', false, 0.70),
    ('generation-audi-a6-c8-4a', 'model-audi-080-a6', 8, '8세대', 'Eighth generation', 'C8/4A', 'MLB Evo', 2018, 2025, '2018~2025', false, 0.70),
    ('generation-audi-a6-c9', 'model-audi-080-a6', 9, '9세대', 'Ninth generation', 'C9', 'PPC', 2025, null, '2025~현재', true, 0.70),
    ('generation-audi-a7-4g8', 'model-audi-081-a7', 1, '1세대', 'First generation', '4G8', 'MLB', 2010, 2017, '2010~2017', false, 0.70),
    ('generation-audi-a7-4k8', 'model-audi-081-a7', 2, '2세대', 'Second generation', '4K8', 'MLB Evo', 2017, 2025, '2017~2025', false, 0.70),
    ('generation-audi-a8-d4-4h', 'model-audi-082-a8', 3, '3세대', 'Third generation', 'D4/4H', 'MLB', 2010, 2017, '2010~2017', false, 0.70),
    ('generation-audi-a8-d5-4n', 'model-audi-082-a8', 4, '4세대', 'Fourth generation', 'D5/4N', 'MLB Evo', 2017, null, '2017~현재', true, 0.70),
    ('generation-audi-q3-8u', 'model-audi-083-q3', 1, '1세대', 'First generation', '8U', 'PQ35', 2011, 2018, '2011~2018', false, 0.70),
    ('generation-audi-q3-f3', 'model-audi-083-q3', 2, '2세대', 'Second generation', 'F3', 'MQB', 2018, 2025, '2018~2025', false, 0.70),
    ('generation-audi-q3-2025', 'model-audi-083-q3', 3, '3세대', 'Third generation', '2025 generation', 'MQB Evo', 2025, null, '2025~현재', true, 0.66),
    ('generation-audi-q5-8r', 'model-audi-084-q5', 1, '1세대', 'First generation', '8R', 'MLB', 2008, 2017, '2008~2017', false, 0.70),
    ('generation-audi-q5-fy', 'model-audi-084-q5', 2, '2세대', 'Second generation', 'FY', 'MLB Evo', 2017, 2024, '2017~2024', false, 0.70),
    ('generation-audi-q5-2025', 'model-audi-084-q5', 3, '3세대', 'Third generation', '2025 generation', 'PPC', 2024, null, '2024~현재', true, 0.66),
    ('generation-audi-q7-4m', 'model-audi-085-q7', 2, '2세대', 'Second generation', '4M/4M PA', 'MLB Evo', 2015, null, '2015~현재', true, 0.70),
    ('generation-audi-q8-4m', 'model-audi-086-q8', 1, '1세대', 'First generation', '4M', 'MLB Evo', 2018, null, '2018~현재', true, 0.70),
    ('generation-audi-e-tron-ge', 'model-audi-087-e-tron', 1, '1세대', 'First generation', 'GE', 'MLB Evo', 2018, 2022, '2018~2022', false, 0.70),
    ('generation-audi-q8-e-tron-ge', 'model-audi-087-e-tron', 2, 'Q8 e-tron', 'Q8 e-tron facelift', 'GE PE', 'MLB Evo', 2023, 2025, '2023~2025', false, 0.70),
    ('generation-audi-q4-e-tron-f4', 'model-audi-088-q4-e-tron', 1, '1세대', 'First generation', 'F4', 'MEB', 2021, null, '2021~현재', true, 0.70)
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
  'verified_admin',
  confidence_score,
  'Audi official rescue sheets and MediaCenter pages',
  'https://www.audi.com/en/rescue/',
  null,
  '2026-06-12',
  true,
  false,
  now()
from audi_generations
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
    ('model-audi-077-a3', 2015, 2019, 'generation-audi-a3-8v', '2012~2020'),
    ('model-audi-077-a3', 2020, 2026, 'generation-audi-a3-8y', '2020~현재'),
    ('model-audi-078-a4', 2015, 2024, 'generation-audi-a4-b9-8w', '2015~2024'),
    ('model-audi-079-a5', 2015, 2015, 'generation-audi-a5-8t', '2007~2016'),
    ('model-audi-079-a5', 2016, 2023, 'generation-audi-a5-f5', '2016~2024'),
    ('model-audi-079-a5', 2024, 2026, 'generation-audi-a5-b10', '2024~현재'),
    ('model-audi-080-a6', 2015, 2018, 'generation-audi-a6-c7-4g', '2011~2018'),
    ('model-audi-080-a6', 2019, 2024, 'generation-audi-a6-c8-4a', '2018~2025'),
    ('model-audi-080-a6', 2025, 2026, 'generation-audi-a6-c9', '2025~현재'),
    ('model-audi-081-a7', 2015, 2017, 'generation-audi-a7-4g8', '2010~2017'),
    ('model-audi-081-a7', 2018, 2025, 'generation-audi-a7-4k8', '2017~2025'),
    ('model-audi-082-a8', 2015, 2017, 'generation-audi-a8-d4-4h', '2010~2017'),
    ('model-audi-082-a8', 2018, 2026, 'generation-audi-a8-d5-4n', '2017~현재'),
    ('model-audi-083-q3', 2015, 2018, 'generation-audi-q3-8u', '2011~2018'),
    ('model-audi-083-q3', 2019, 2024, 'generation-audi-q3-f3', '2018~2025'),
    ('model-audi-083-q3', 2025, 2026, 'generation-audi-q3-2025', '2025~현재'),
    ('model-audi-084-q5', 2015, 2016, 'generation-audi-q5-8r', '2008~2017'),
    ('model-audi-084-q5', 2017, 2024, 'generation-audi-q5-fy', '2017~2024'),
    ('model-audi-084-q5', 2025, 2026, 'generation-audi-q5-2025', '2024~현재'),
    ('model-audi-085-q7', 2015, 2026, 'generation-audi-q7-4m', '2015~현재'),
    ('model-audi-086-q8', 2018, 2026, 'generation-audi-q8-4m', '2018~현재'),
    ('model-audi-087-e-tron', 2018, 2022, 'generation-audi-e-tron-ge', '2018~2022'),
    ('model-audi-087-e-tron', 2023, 2025, 'generation-audi-q8-e-tron-ge', '2023~2025'),
    ('model-audi-088-q4-e-tron', 2021, 2026, 'generation-audi-q4-e-tron-f4', '2021~현재')
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
  'generation-audi-a3-8v',
  'generation-audi-a3-8y',
  'generation-audi-a4-b9-8w',
  'generation-audi-a5-8t',
  'generation-audi-a5-f5',
  'generation-audi-a5-b10',
  'generation-audi-a6-c7-4g',
  'generation-audi-a6-c8-4a',
  'generation-audi-a6-c9',
  'generation-audi-a7-4g8',
  'generation-audi-a7-4k8',
  'generation-audi-a8-d4-4h',
  'generation-audi-a8-d5-4n',
  'generation-audi-q3-8u',
  'generation-audi-q3-f3',
  'generation-audi-q3-2025',
  'generation-audi-q5-8r',
  'generation-audi-q5-fy',
  'generation-audi-q5-2025',
  'generation-audi-q7-4m',
  'generation-audi-q8-4m',
  'generation-audi-e-tron-ge',
  'generation-audi-q8-e-tron-ge',
  'generation-audi-q4-e-tron-f4'
)
on conflict (generation_id, model_year_id) do nothing;

update public.vehicle_variants vv
set generation_id = vmy.generation_id
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.generation_id in (
    'generation-audi-a3-8v',
    'generation-audi-a3-8y',
    'generation-audi-a4-b9-8w',
    'generation-audi-a5-8t',
    'generation-audi-a5-f5',
    'generation-audi-a5-b10',
    'generation-audi-a6-c7-4g',
    'generation-audi-a6-c8-4a',
    'generation-audi-a6-c9',
    'generation-audi-a7-4g8',
    'generation-audi-a7-4k8',
    'generation-audi-a8-d4-4h',
    'generation-audi-a8-d5-4n',
    'generation-audi-q3-8u',
    'generation-audi-q3-f3',
    'generation-audi-q3-2025',
    'generation-audi-q5-8r',
    'generation-audi-q5-fy',
    'generation-audi-q5-2025',
    'generation-audi-q7-4m',
    'generation-audi-q8-4m',
    'generation-audi-e-tron-ge',
    'generation-audi-q8-e-tron-ge',
    'generation-audi-q4-e-tron-f4'
  );

delete from public.vehicle_generation_years vgy
using public.vehicle_model_years vmy
where vgy.model_year_id = vmy.id
  and (
    (vmy.model_id = 'model-audi-078-a4' and vmy.year > 2024)
    or (vmy.model_id = 'model-audi-081-a7' and vmy.year > 2025)
    or (vmy.model_id = 'model-audi-086-q8' and vmy.year < 2018)
    or (vmy.model_id = 'model-audi-087-e-tron' and (vmy.year < 2018 or vmy.year > 2025))
    or (vmy.model_id = 'model-audi-088-q4-e-tron' and vmy.year < 2021)
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
    (vmy.model_id = 'model-audi-078-a4' and vmy.year > 2024)
    or (vmy.model_id = 'model-audi-081-a7' and vmy.year > 2025)
    or (vmy.model_id = 'model-audi-086-q8' and vmy.year < 2018)
    or (vmy.model_id = 'model-audi-087-e-tron' and (vmy.year < 2018 or vmy.year > 2025))
    or (vmy.model_id = 'model-audi-088-q4-e-tron' and vmy.year < 2021)
  );

update public.vehicle_model_years
set
  generation_id = null,
  production_year_label = null
where (
    model_id = 'model-audi-078-a4'
    and year > 2024
  )
  or (
    model_id = 'model-audi-081-a7'
    and year > 2025
  )
  or (
    model_id = 'model-audi-086-q8'
    and year < 2018
  )
  or (
    model_id = 'model-audi-087-e-tron'
    and (year < 2018 or year > 2025)
  )
  or (
    model_id = 'model-audi-088-q4-e-tron'
    and year < 2021
  );
