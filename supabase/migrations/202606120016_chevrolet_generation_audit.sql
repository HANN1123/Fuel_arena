-- Chevrolet generation audit.
-- Adds pending-review generation rows for Chevrolet seed models and deprecates
-- pre-launch / post-discontinuation placeholder variants.

with chevrolet_generations (
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
    ('generation-chevrolet-spark-m400', 'model-chevrolet-034-kr', 2, 'M400', 'M400 generation', 'M400', 'Gamma II', 2015, 2022, '2015~2022', false, 0.58),
    ('generation-chevrolet-malibu-v300', 'model-chevrolet-035-kr', 8, '8세대', 'Eighth generation', 'V300', 'Epsilon II', 2011, 2016, '2011~2016', false, 0.55),
    ('generation-chevrolet-malibu-v400', 'model-chevrolet-035-kr', 9, '9세대', 'Ninth generation', 'V400', 'E2XX', 2016, 2022, '2016~2022', false, 0.58),
    ('generation-chevrolet-trax-u200', 'model-chevrolet-036-kr', 1, '1세대', 'First generation', 'U200', 'Gamma II', 2013, 2022, '2013~2022', false, 0.58),
    ('generation-chevrolet-trax-crossover-9bqc', 'model-chevrolet-036-kr', 2, '트랙스 크로스오버', 'Trax Crossover', '9BQC', 'VSS-F', 2023, null, '2023~현재', true, 0.58),
    ('generation-chevrolet-trailblazer-vss-f', 'model-chevrolet-037-kr', 1, '1세대', 'First generation', 'VSS-F', 'VSS-F', 2020, null, '2020~현재', true, 0.58),
    ('generation-chevrolet-traverse-c1xx', 'model-chevrolet-038-kr', 2, '2세대', 'Second generation', 'C1XX', 'C1XX', 2019, 2024, '2019~2024', false, 0.56),
    ('generation-chevrolet-tahoe-t1xx', 'model-chevrolet-039-kr', 5, '5세대', 'Fifth generation', 'T1XX', 'GMT1YC', 2022, 2025, '2022~2025', false, 0.55),
    ('generation-chevrolet-colorado-rg', 'model-chevrolet-040-kr', 2, '2세대', 'Second generation', 'RG', '31XX', 2019, 2023, '2019~2023', false, 0.58),
    ('generation-chevrolet-colorado-31xx-2', 'model-chevrolet-040-kr', 3, '3세대', 'Third generation', '31XX-2', '31XX-2', 2024, null, '2024~현재', true, 0.58),
    ('generation-chevrolet-bolt-ev-g2cx', 'model-chevrolet-041-ev', 1, '1세대', 'First generation', 'G2CX', 'BEV2', 2017, 2023, '2017~2023', false, 0.56)
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
  'Chevrolet Korea newsroom and type-price pages',
  'https://www.chevrolet.co.kr/finance/type-price',
  null,
  null,
  true,
  false,
  now()
from chevrolet_generations
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
    ('model-chevrolet-034-kr', 2015, 2022, 'generation-chevrolet-spark-m400', '2015~2022'),
    ('model-chevrolet-035-kr', 2015, 2015, 'generation-chevrolet-malibu-v300', '2011~2016'),
    ('model-chevrolet-035-kr', 2016, 2022, 'generation-chevrolet-malibu-v400', '2016~2022'),
    ('model-chevrolet-036-kr', 2015, 2022, 'generation-chevrolet-trax-u200', '2013~2022'),
    ('model-chevrolet-036-kr', 2023, 2026, 'generation-chevrolet-trax-crossover-9bqc', '2023~현재'),
    ('model-chevrolet-037-kr', 2020, 2026, 'generation-chevrolet-trailblazer-vss-f', '2020~현재'),
    ('model-chevrolet-038-kr', 2019, 2024, 'generation-chevrolet-traverse-c1xx', '2019~2024'),
    ('model-chevrolet-039-kr', 2022, 2025, 'generation-chevrolet-tahoe-t1xx', '2022~2025'),
    ('model-chevrolet-040-kr', 2019, 2023, 'generation-chevrolet-colorado-rg', '2019~2023'),
    ('model-chevrolet-040-kr', 2024, 2026, 'generation-chevrolet-colorado-31xx-2', '2024~현재'),
    ('model-chevrolet-041-ev', 2017, 2023, 'generation-chevrolet-bolt-ev-g2cx', '2017~2023')
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
  'generation-chevrolet-spark-m400',
  'generation-chevrolet-malibu-v300',
  'generation-chevrolet-malibu-v400',
  'generation-chevrolet-trax-u200',
  'generation-chevrolet-trax-crossover-9bqc',
  'generation-chevrolet-trailblazer-vss-f',
  'generation-chevrolet-traverse-c1xx',
  'generation-chevrolet-tahoe-t1xx',
  'generation-chevrolet-colorado-rg',
  'generation-chevrolet-colorado-31xx-2',
  'generation-chevrolet-bolt-ev-g2cx'
)
on conflict (generation_id, model_year_id) do nothing;

update public.vehicle_variants vv
set generation_id = vmy.generation_id
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.generation_id in (
    'generation-chevrolet-spark-m400',
    'generation-chevrolet-malibu-v300',
    'generation-chevrolet-malibu-v400',
    'generation-chevrolet-trax-u200',
    'generation-chevrolet-trax-crossover-9bqc',
    'generation-chevrolet-trailblazer-vss-f',
    'generation-chevrolet-traverse-c1xx',
    'generation-chevrolet-tahoe-t1xx',
    'generation-chevrolet-colorado-rg',
    'generation-chevrolet-colorado-31xx-2',
    'generation-chevrolet-bolt-ev-g2cx'
  );

delete from public.vehicle_generation_years vgy
using public.vehicle_model_years vmy
where vgy.model_year_id = vmy.id
  and (
    (vmy.model_id = 'model-chevrolet-034-kr' and vmy.year > 2022)
    or (vmy.model_id = 'model-chevrolet-035-kr' and vmy.year > 2022)
    or (vmy.model_id = 'model-chevrolet-037-kr' and vmy.year < 2020)
    or (vmy.model_id = 'model-chevrolet-038-kr' and (vmy.year < 2019 or vmy.year > 2024))
    or (vmy.model_id = 'model-chevrolet-039-kr' and (vmy.year < 2022 or vmy.year > 2025))
    or (vmy.model_id = 'model-chevrolet-040-kr' and vmy.year < 2019)
    or (vmy.model_id = 'model-chevrolet-041-ev' and (vmy.year < 2017 or vmy.year > 2023))
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
    (vmy.model_id = 'model-chevrolet-034-kr' and vmy.year > 2022)
    or (vmy.model_id = 'model-chevrolet-035-kr' and vmy.year > 2022)
    or (vmy.model_id = 'model-chevrolet-037-kr' and vmy.year < 2020)
    or (vmy.model_id = 'model-chevrolet-038-kr' and (vmy.year < 2019 or vmy.year > 2024))
    or (vmy.model_id = 'model-chevrolet-039-kr' and (vmy.year < 2022 or vmy.year > 2025))
    or (vmy.model_id = 'model-chevrolet-040-kr' and vmy.year < 2019)
    or (vmy.model_id = 'model-chevrolet-041-ev' and (vmy.year < 2017 or vmy.year > 2023))
  );

update public.vehicle_model_years
set
  generation_id = null,
  production_year_label = null
where (
    model_id = 'model-chevrolet-034-kr'
    and year > 2022
  )
  or (
    model_id = 'model-chevrolet-035-kr'
    and year > 2022
  )
  or (
    model_id = 'model-chevrolet-037-kr'
    and year < 2020
  )
  or (
    model_id = 'model-chevrolet-038-kr'
    and (year < 2019 or year > 2024)
  )
  or (
    model_id = 'model-chevrolet-039-kr'
    and (year < 2022 or year > 2025)
  )
  or (
    model_id = 'model-chevrolet-040-kr'
    and year < 2019
  )
  or (
    model_id = 'model-chevrolet-041-ev'
    and (year < 2017 or year > 2023)
  );
