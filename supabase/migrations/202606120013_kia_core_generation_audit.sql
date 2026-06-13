-- Kia core generation audit.
-- Adds generation rows for all Kia seed models and deprecates legacy
-- pre-launch placeholder variants for late-launch models.

with kia_generations (
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
  is_current
) as (
  values
    ('generation-kia-k5-jf', 'model-kia-014-k5', 2, '2세대', 'Second generation', 'JF/JF PE', 'JF', 2015, 2019, '2015~2019', false),
    ('generation-kia-k5-dl3', 'model-kia-014-k5', 3, '3세대', 'Third generation', 'DL3/DL3 PE', 'DL3', 2019, null, '2019~현재', true),
    ('generation-kia-k8-gl3', 'model-kia-015-k8', 1, '1세대', 'First generation', 'GL3/GL3 PE', 'GL3', 2021, null, '2021~현재', true),
    ('generation-kia-k9-kh', 'model-kia-016-k9', 1, '1세대', 'First generation', 'KH/KH PE', 'KH', 2012, 2018, '2012~2018', false),
    ('generation-kia-k9-rj', 'model-kia-016-k9', 2, '2세대', 'Second generation', 'RJ/RJ PE', 'RJ', 2018, null, '2018~현재', true),
    ('generation-kia-morning-ta', 'model-kia-017-kr', 2, '2세대', 'Second generation', 'TA/TA PE', 'TA', 2011, 2017, '2011~2017', false),
    ('generation-kia-morning-ja', 'model-kia-017-kr', 3, '3세대', 'Third generation', 'JA/JA PE', 'JA', 2017, null, '2017~현재', true),
    ('generation-kia-ray-tam', 'model-kia-018-kr', 1, '1세대', 'First generation', 'TAM/TAM PE', 'TAM', 2011, null, '2011~현재', true),
    ('generation-kia-seltos-sp2', 'model-kia-019-kr', 1, '1세대', 'First generation', 'SP2/SP2 PE', 'SP2', 2019, null, '2019~현재', true),
    ('generation-kia-niro-de', 'model-kia-020-kr', 1, '1세대', 'First generation', 'DE/DE PE', 'DE', 2016, 2021, '2016~2021', false),
    ('generation-kia-niro-sg2', 'model-kia-020-kr', 2, '2세대', 'Second generation', 'SG2/SG2 PE', 'SG2', 2022, null, '2022~현재', true),
    ('generation-kia-sportage-ql', 'model-kia-021-kr', 4, '4세대', 'Fourth generation', 'QL/QL PE', 'QL', 2015, 2021, '2015~2021', false),
    ('generation-kia-sportage-nq5', 'model-kia-021-kr', 5, '5세대', 'Fifth generation', 'NQ5/NQ5 PE', 'NQ5', 2021, null, '2021~현재', true),
    ('generation-kia-sorento-um', 'model-kia-022-kr', 3, '3세대', 'Third generation', 'UM/UM PE', 'UM', 2014, 2020, '2014~2020', false),
    ('generation-kia-sorento-mq4', 'model-kia-022-kr', 4, '4세대', 'Fourth generation', 'MQ4/MQ4 PE', 'MQ4', 2020, null, '2020~현재', true),
    ('generation-kia-carnival-yp', 'model-kia-023-kr', 3, '3세대', 'Third generation', 'YP/YP PE', 'YP', 2014, 2020, '2014~2020', false),
    ('generation-kia-carnival-ka4', 'model-kia-023-kr', 4, '4세대', 'Fourth generation', 'KA4/KA4 PE', 'KA4', 2020, null, '2020~현재', true),
    ('generation-kia-ev3-sv1', 'model-kia-024-ev3', 1, '1세대', 'First generation', 'SV1', 'E-GMP', 2024, null, '2024~현재', true),
    ('generation-kia-ev6-cv', 'model-kia-025-ev6', 1, '1세대', 'First generation', 'CV/CV PE', 'E-GMP', 2021, null, '2021~현재', true),
    ('generation-kia-ev9-mv1', 'model-kia-026-ev9', 1, '1세대', 'First generation', 'MV1', 'E-GMP', 2023, null, '2023~현재', true),
    ('generation-kia-bongo-pu', 'model-kia-027-kr', 4, '4세대', 'Fourth generation', 'PU/PU PE', 'PU', 2004, null, '2004~현재', true)
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
  0.74,
  'Kia software version list',
  'https://update.kia.com/KR/KO/updateNoticeView/software-version',
  null,
  '2026-06-12',
  true,
  false,
  now()
from kia_generations
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
    ('model-kia-014-k5', 2015, 2018, 'generation-kia-k5-jf', '2015~2019'),
    ('model-kia-014-k5', 2019, 2026, 'generation-kia-k5-dl3', '2019~현재'),
    ('model-kia-015-k8', 2021, 2026, 'generation-kia-k8-gl3', '2021~현재'),
    ('model-kia-016-k9', 2015, 2017, 'generation-kia-k9-kh', '2012~2018'),
    ('model-kia-016-k9', 2018, 2026, 'generation-kia-k9-rj', '2018~현재'),
    ('model-kia-017-kr', 2015, 2016, 'generation-kia-morning-ta', '2011~2017'),
    ('model-kia-017-kr', 2017, 2026, 'generation-kia-morning-ja', '2017~현재'),
    ('model-kia-018-kr', 2015, 2026, 'generation-kia-ray-tam', '2011~현재'),
    ('model-kia-019-kr', 2019, 2026, 'generation-kia-seltos-sp2', '2019~현재'),
    ('model-kia-020-kr', 2016, 2021, 'generation-kia-niro-de', '2016~2021'),
    ('model-kia-020-kr', 2022, 2026, 'generation-kia-niro-sg2', '2022~현재'),
    ('model-kia-021-kr', 2015, 2021, 'generation-kia-sportage-ql', '2015~2021'),
    ('model-kia-021-kr', 2022, 2026, 'generation-kia-sportage-nq5', '2021~현재'),
    ('model-kia-022-kr', 2015, 2019, 'generation-kia-sorento-um', '2014~2020'),
    ('model-kia-022-kr', 2020, 2026, 'generation-kia-sorento-mq4', '2020~현재'),
    ('model-kia-023-kr', 2015, 2020, 'generation-kia-carnival-yp', '2014~2020'),
    ('model-kia-023-kr', 2021, 2026, 'generation-kia-carnival-ka4', '2020~현재'),
    ('model-kia-024-ev3', 2024, 2026, 'generation-kia-ev3-sv1', '2024~현재'),
    ('model-kia-025-ev6', 2021, 2026, 'generation-kia-ev6-cv', '2021~현재'),
    ('model-kia-026-ev9', 2023, 2026, 'generation-kia-ev9-mv1', '2023~현재'),
    ('model-kia-027-kr', 2015, 2026, 'generation-kia-bongo-pu', '2004~현재')
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
  'generation-kia-k5-jf',
  'generation-kia-k5-dl3',
  'generation-kia-k8-gl3',
  'generation-kia-k9-kh',
  'generation-kia-k9-rj',
  'generation-kia-morning-ta',
  'generation-kia-morning-ja',
  'generation-kia-ray-tam',
  'generation-kia-seltos-sp2',
  'generation-kia-niro-de',
  'generation-kia-niro-sg2',
  'generation-kia-sportage-ql',
  'generation-kia-sportage-nq5',
  'generation-kia-sorento-um',
  'generation-kia-sorento-mq4',
  'generation-kia-carnival-yp',
  'generation-kia-carnival-ka4',
  'generation-kia-ev3-sv1',
  'generation-kia-ev6-cv',
  'generation-kia-ev9-mv1',
  'generation-kia-bongo-pu'
)
on conflict (generation_id, model_year_id) do nothing;

update public.vehicle_variants vv
set generation_id = vmy.generation_id
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.generation_id in (
    'generation-kia-k5-jf',
    'generation-kia-k5-dl3',
    'generation-kia-k8-gl3',
    'generation-kia-k9-kh',
    'generation-kia-k9-rj',
    'generation-kia-morning-ta',
    'generation-kia-morning-ja',
    'generation-kia-ray-tam',
    'generation-kia-seltos-sp2',
    'generation-kia-niro-de',
    'generation-kia-niro-sg2',
    'generation-kia-sportage-ql',
    'generation-kia-sportage-nq5',
    'generation-kia-sorento-um',
    'generation-kia-sorento-mq4',
    'generation-kia-carnival-yp',
    'generation-kia-carnival-ka4',
    'generation-kia-ev3-sv1',
    'generation-kia-ev6-cv',
    'generation-kia-ev9-mv1',
    'generation-kia-bongo-pu'
  );

delete from public.vehicle_generation_years vgy
using public.vehicle_model_years vmy
where vgy.model_year_id = vmy.id
  and (
    (vmy.model_id = 'model-kia-015-k8' and vmy.year < 2021)
    or (vmy.model_id = 'model-kia-019-kr' and vmy.year < 2019)
    or (vmy.model_id = 'model-kia-020-kr' and vmy.year < 2016)
    or (vmy.model_id = 'model-kia-024-ev3' and vmy.year < 2024)
    or (vmy.model_id = 'model-kia-025-ev6' and vmy.year < 2021)
    or (vmy.model_id = 'model-kia-026-ev9' and vmy.year < 2023)
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
    (vmy.model_id = 'model-kia-015-k8' and vmy.year < 2021)
    or (vmy.model_id = 'model-kia-019-kr' and vmy.year < 2019)
    or (vmy.model_id = 'model-kia-020-kr' and vmy.year < 2016)
    or (vmy.model_id = 'model-kia-024-ev3' and vmy.year < 2024)
    or (vmy.model_id = 'model-kia-025-ev6' and vmy.year < 2021)
    or (vmy.model_id = 'model-kia-026-ev9' and vmy.year < 2023)
  );

update public.vehicle_model_years
set
  generation_id = null,
  production_year_label = null
where (
    model_id = 'model-kia-015-k8'
    and year < 2021
  )
  or (
    model_id = 'model-kia-019-kr'
    and year < 2019
  )
  or (
    model_id = 'model-kia-020-kr'
    and year < 2016
  )
  or (
    model_id = 'model-kia-024-ev3'
    and year < 2024
  )
  or (
    model_id = 'model-kia-025-ev6'
    and year < 2021
  )
  or (
    model_id = 'model-kia-026-ev9'
    and year < 2023
  );
