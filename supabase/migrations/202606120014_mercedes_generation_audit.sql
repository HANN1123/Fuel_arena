-- Mercedes-Benz generation audit.
-- Adds generation rows for Mercedes-Benz seed models and deprecates
-- legacy pre-launch placeholder variants for EQ models.

with mercedes_generations (
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
    ('generation-benz-a-class-w176', 'model-benz-065-a-class', 3, '3세대', 'Third generation', 'W176', 'W176', 2012, 2018, '2012~2018', false),
    ('generation-benz-a-class-w177', 'model-benz-065-a-class', 4, '4세대', 'Fourth generation', 'W177/V177', 'W177', 2018, null, '2018~현재', true),
    ('generation-benz-c-class-w205', 'model-benz-066-c-class', 4, '4세대', 'Fourth generation', 'W205/S205/C205/A205', 'W205', 2014, 2021, '2014~2021', false),
    ('generation-benz-c-class-w206', 'model-benz-066-c-class', 5, '5세대', 'Fifth generation', 'W206/S206', 'W206', 2021, null, '2021~현재', true),
    ('generation-benz-e-class-w212', 'model-benz-067-e-class', 4, '4세대', 'Fourth generation', 'W212/S212/C207/A207', 'W212', 2009, 2016, '2009~2016', false),
    ('generation-benz-e-class-w213', 'model-benz-067-e-class', 5, '5세대', 'Fifth generation', 'W213/S213/C238/A238', 'W213', 2016, 2023, '2016~2023', false),
    ('generation-benz-e-class-w214', 'model-benz-067-e-class', 6, '6세대', 'Sixth generation', 'W214/S214', 'W214', 2023, null, '2023~현재', true),
    ('generation-benz-s-class-w222', 'model-benz-068-s-class', 6, '6세대', 'Sixth generation', 'W222/V222/X222', 'W222', 2013, 2020, '2013~2020', false),
    ('generation-benz-s-class-w223', 'model-benz-068-s-class', 7, '7세대', 'Seventh generation', 'W223/V223/Z223', 'W223', 2020, null, '2020~현재', true),
    ('generation-benz-gla-x156', 'model-benz-069-gla', 1, '1세대', 'First generation', 'X156', 'X156', 2014, 2020, '2014~2020', false),
    ('generation-benz-gla-h247', 'model-benz-069-gla', 2, '2세대', 'Second generation', 'H247', 'H247', 2020, null, '2020~현재', true),
    ('generation-benz-glc-x253', 'model-benz-070-glc', 1, '1세대', 'First generation', 'X253/C253', 'X253', 2015, 2022, '2015~2022', false),
    ('generation-benz-glc-x254', 'model-benz-070-glc', 2, '2세대', 'Second generation', 'X254/C254', 'X254', 2022, null, '2022~현재', true),
    ('generation-benz-gle-w166', 'model-benz-071-gle', 1, '1세대', 'First generation', 'W166/C292', 'W166', 2015, 2019, '2015~2019', false),
    ('generation-benz-gle-v167', 'model-benz-071-gle', 2, '2세대', 'Second generation', 'V167/C167', 'V167', 2019, null, '2019~현재', true),
    ('generation-benz-gls-x166', 'model-benz-072-gls', 1, '1세대', 'First generation', 'X166', 'X166', 2015, 2019, '2015~2019', false),
    ('generation-benz-gls-x167', 'model-benz-072-gls', 2, '2세대', 'Second generation', 'X167', 'X167', 2019, null, '2019~현재', true),
    ('generation-benz-eqa-h243', 'model-benz-073-eqa', 1, '1세대', 'First generation', 'H243', 'H243', 2021, null, '2021~현재', true),
    ('generation-benz-eqb-x243', 'model-benz-074-eqb', 1, '1세대', 'First generation', 'X243', 'X243', 2021, null, '2021~현재', true),
    ('generation-benz-eqe-v295', 'model-benz-075-eqe', 1, '1세대', 'First generation', 'V295/X294', 'EVA2', 2022, null, '2022~현재', true),
    ('generation-benz-eqs-v297', 'model-benz-076-eqs', 1, '1세대', 'First generation', 'V297/X296', 'EVA2', 2021, null, '2021~현재', true)
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
  0.72,
  'Mercedes-Benz official rescue sheets and media pages',
  'https://rk.mb-qr.com/en/',
  null,
  '2026-06-12',
  true,
  false,
  now()
from mercedes_generations
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
    ('model-benz-065-a-class', 2015, 2017, 'generation-benz-a-class-w176', '2012~2018'),
    ('model-benz-065-a-class', 2018, 2026, 'generation-benz-a-class-w177', '2018~현재'),
    ('model-benz-066-c-class', 2015, 2020, 'generation-benz-c-class-w205', '2014~2021'),
    ('model-benz-066-c-class', 2021, 2026, 'generation-benz-c-class-w206', '2021~현재'),
    ('model-benz-067-e-class', 2015, 2015, 'generation-benz-e-class-w212', '2009~2016'),
    ('model-benz-067-e-class', 2016, 2023, 'generation-benz-e-class-w213', '2016~2023'),
    ('model-benz-067-e-class', 2024, 2026, 'generation-benz-e-class-w214', '2023~현재'),
    ('model-benz-068-s-class', 2015, 2020, 'generation-benz-s-class-w222', '2013~2020'),
    ('model-benz-068-s-class', 2021, 2026, 'generation-benz-s-class-w223', '2020~현재'),
    ('model-benz-069-gla', 2015, 2019, 'generation-benz-gla-x156', '2014~2020'),
    ('model-benz-069-gla', 2020, 2026, 'generation-benz-gla-h247', '2020~현재'),
    ('model-benz-070-glc', 2015, 2022, 'generation-benz-glc-x253', '2015~2022'),
    ('model-benz-070-glc', 2023, 2026, 'generation-benz-glc-x254', '2022~현재'),
    ('model-benz-071-gle', 2015, 2018, 'generation-benz-gle-w166', '2015~2019'),
    ('model-benz-071-gle', 2019, 2026, 'generation-benz-gle-v167', '2019~현재'),
    ('model-benz-072-gls', 2015, 2019, 'generation-benz-gls-x166', '2015~2019'),
    ('model-benz-072-gls', 2020, 2026, 'generation-benz-gls-x167', '2019~현재'),
    ('model-benz-073-eqa', 2021, 2026, 'generation-benz-eqa-h243', '2021~현재'),
    ('model-benz-074-eqb', 2022, 2026, 'generation-benz-eqb-x243', '2021~현재'),
    ('model-benz-075-eqe', 2022, 2026, 'generation-benz-eqe-v295', '2022~현재'),
    ('model-benz-076-eqs', 2021, 2026, 'generation-benz-eqs-v297', '2021~현재')
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
  'generation-benz-a-class-w176',
  'generation-benz-a-class-w177',
  'generation-benz-c-class-w205',
  'generation-benz-c-class-w206',
  'generation-benz-e-class-w212',
  'generation-benz-e-class-w213',
  'generation-benz-e-class-w214',
  'generation-benz-s-class-w222',
  'generation-benz-s-class-w223',
  'generation-benz-gla-x156',
  'generation-benz-gla-h247',
  'generation-benz-glc-x253',
  'generation-benz-glc-x254',
  'generation-benz-gle-w166',
  'generation-benz-gle-v167',
  'generation-benz-gls-x166',
  'generation-benz-gls-x167',
  'generation-benz-eqa-h243',
  'generation-benz-eqb-x243',
  'generation-benz-eqe-v295',
  'generation-benz-eqs-v297'
)
on conflict (generation_id, model_year_id) do nothing;

update public.vehicle_variants vv
set generation_id = vmy.generation_id
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.generation_id in (
    'generation-benz-a-class-w176',
    'generation-benz-a-class-w177',
    'generation-benz-c-class-w205',
    'generation-benz-c-class-w206',
    'generation-benz-e-class-w212',
    'generation-benz-e-class-w213',
    'generation-benz-e-class-w214',
    'generation-benz-s-class-w222',
    'generation-benz-s-class-w223',
    'generation-benz-gla-x156',
    'generation-benz-gla-h247',
    'generation-benz-glc-x253',
    'generation-benz-glc-x254',
    'generation-benz-gle-w166',
    'generation-benz-gle-v167',
    'generation-benz-gls-x166',
    'generation-benz-gls-x167',
    'generation-benz-eqa-h243',
    'generation-benz-eqb-x243',
    'generation-benz-eqe-v295',
    'generation-benz-eqs-v297'
  );

delete from public.vehicle_generation_years vgy
using public.vehicle_model_years vmy
where vgy.model_year_id = vmy.id
  and (
    (vmy.model_id = 'model-benz-073-eqa' and vmy.year < 2021)
    or (vmy.model_id = 'model-benz-074-eqb' and vmy.year < 2022)
    or (vmy.model_id = 'model-benz-075-eqe' and vmy.year < 2022)
    or (vmy.model_id = 'model-benz-076-eqs' and vmy.year < 2021)
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
    (vmy.model_id = 'model-benz-073-eqa' and vmy.year < 2021)
    or (vmy.model_id = 'model-benz-074-eqb' and vmy.year < 2022)
    or (vmy.model_id = 'model-benz-075-eqe' and vmy.year < 2022)
    or (vmy.model_id = 'model-benz-076-eqs' and vmy.year < 2021)
  );

update public.vehicle_model_years
set
  generation_id = null,
  production_year_label = null
where (
    model_id = 'model-benz-073-eqa'
    and year < 2021
  )
  or (
    model_id = 'model-benz-074-eqb'
    and year < 2022
  )
  or (
    model_id = 'model-benz-075-eqe'
    and year < 2022
  )
  or (
    model_id = 'model-benz-076-eqs'
    and year < 2021
  );
