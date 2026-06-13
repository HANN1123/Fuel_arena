-- Honda/Nissan official Korea status audit.
-- Honda Korea currently exposes Accord Hybrid, CR-V Hybrid, Odyssey, and
-- Pilot in the online showroom. Civic/HR-V remain in the catalog only as
-- non-selectable Korea-unconfirmed placeholders.
-- Nissan Korea officially announced brand withdrawal from Korea at the end
-- of December 2020. Post-2020 Nissan Korea placeholder rows are deprecated.

update public.vehicle_generations
set
  source_name = 'Honda Korea official online showroom current model list',
  source_url = 'https://auto.hondakorea.co.kr/main/',
  display_period = '국내 공식 현재 라인업 미확인',
  is_current = false,
  is_upcoming = false,
  is_selectable = false,
  source_status = 'pending_review',
  confidence_score = 0.44,
  last_verified_at = '2026-06-13',
  updated_at = now()
where id in (
  'generation-honda-civic-official-lineup',
  'generation-honda-hr-v-official-lineup'
);

update public.vehicle_variants vv
set
  generation_id = vmy.generation_id,
  trim_name = '공식 제원 검토 대기',
  engine_name = 'Pending official specification review',
  displacement_cc = null,
  battery_kwh = null,
  drivetrain = '검토 대기',
  transmission = '검토 대기',
  official_efficiency = null,
  is_verified = false,
  source_status = 'pending_review',
  source_name = 'Honda Korea official online showroom current model list',
  source_url = 'https://auto.hondakorea.co.kr/main/',
  last_verified_at = '2026-06-13',
  confidence_score = 0.10,
  is_selectable = false,
  is_deprecated = false
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.model_id in ('model-honda-109-kr', 'model-honda-112-hr-v');

with nissan_generation_status (
  id,
  start_year,
  end_year,
  display_period,
  is_selectable,
  confidence_score,
  source_name,
  source_url
) as (
  values
    ('generation-nissan-altima-official-lineup', 2015, 2020, '2015~2020', true, 0.52, 'Nissan Korea official withdrawal notice', 'https://www.nissan.co.kr/news_and_events/2002_news_b1.html'),
    ('generation-nissan-maxima-official-lineup', 2015, 2020, '2015~2020', true, 0.52, 'Nissan Korea official withdrawal notice', 'https://www.nissan.co.kr/news_and_events/2002_news_b1.html'),
    ('generation-nissan-rogue-official-lineup', 2015, 2020, '2015~2020', true, 0.52, 'Nissan Korea official withdrawal notice', 'https://www.nissan.co.kr/news_and_events/2002_news_b1.html'),
    ('generation-nissan-leaf-official-lineup', 2019, 2020, '2019~2020', true, 0.60, 'Nissan Korea official Leaf launch and withdrawal notices', 'https://www.nissan.co.kr/experience-nissan-im/news_and_events/190318.html'),
    ('generation-nissan-ariya-official-lineup', 2026, null, '국내 공식 판매 미확인', false, 0.34, 'Nissan Korea official withdrawal notice; Ariya Korea sales unconfirmed', 'https://www.nissan.co.kr/news_and_events/2002_news_b1.html')
)
update public.vehicle_generations vg
set
  start_year = ngs.start_year,
  end_year = ngs.end_year,
  display_period = ngs.display_period,
  is_current = false,
  is_upcoming = false,
  is_selectable = ngs.is_selectable,
  source_status = 'pending_review',
  confidence_score = ngs.confidence_score,
  source_name = ngs.source_name,
  source_url = ngs.source_url,
  last_verified_at = '2026-06-13',
  updated_at = now()
from nissan_generation_status ngs
where vg.id = ngs.id;

with nissan_generation_years (
  model_id,
  generation_id,
  first_year,
  last_year,
  production_year_label
) as (
  values
    ('model-nissan-115-kr', 'generation-nissan-altima-official-lineup', 2015, 2020, '2015~2020'),
    ('model-nissan-116-kr', 'generation-nissan-maxima-official-lineup', 2015, 2020, '2015~2020'),
    ('model-nissan-117-kr', 'generation-nissan-rogue-official-lineup', 2015, 2020, '2015~2020'),
    ('model-nissan-118-kr', 'generation-nissan-leaf-official-lineup', 2019, 2020, '2019~2020'),
    ('model-nissan-119-kr', 'generation-nissan-ariya-official-lineup', 2026, 2026, '국내 공식 판매 미확인')
)
update public.vehicle_model_years vmy
set
  generation_id = ngy.generation_id,
  production_year_label = ngy.production_year_label
from nissan_generation_years ngy
where vmy.model_id = ngy.model_id
  and vmy.year between ngy.first_year and ngy.last_year;

insert into public.vehicle_generation_years (
  generation_id,
  model_year_id,
  year
)
select generation_id, id, year
from public.vehicle_model_years
where generation_id in (
  'generation-nissan-altima-official-lineup',
  'generation-nissan-maxima-official-lineup',
  'generation-nissan-rogue-official-lineup',
  'generation-nissan-leaf-official-lineup',
  'generation-nissan-ariya-official-lineup'
)
on conflict (generation_id, model_year_id) do nothing;

update public.vehicle_variants vv
set generation_id = vmy.generation_id
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.generation_id in (
    'generation-nissan-altima-official-lineup',
    'generation-nissan-maxima-official-lineup',
    'generation-nissan-rogue-official-lineup',
    'generation-nissan-leaf-official-lineup',
    'generation-nissan-ariya-official-lineup'
  );

update public.vehicle_variants vv
set
  trim_name = '공식 제원 검토 대기',
  engine_name = 'Pending official specification review',
  displacement_cc = null,
  battery_kwh = null,
  drivetrain = '검토 대기',
  transmission = '검토 대기',
  official_efficiency = null,
  is_verified = false,
  source_status = 'pending_review',
  source_name = 'Nissan Korea official withdrawal notice; Ariya Korea sales unconfirmed',
  source_url = 'https://www.nissan.co.kr/news_and_events/2002_news_b1.html',
  last_verified_at = '2026-06-13',
  confidence_score = 0.10,
  is_selectable = false,
  is_deprecated = false
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and vmy.model_id = 'model-nissan-119-kr'
  and vmy.year = 2026;

delete from public.vehicle_generation_years vgy
using public.vehicle_model_years vmy
where vgy.model_year_id = vmy.id
  and (
    (vmy.model_id in ('model-nissan-115-kr', 'model-nissan-116-kr', 'model-nissan-117-kr') and vmy.year > 2020)
    or (vmy.model_id = 'model-nissan-118-kr' and (vmy.year < 2019 or vmy.year > 2020))
    or (vmy.model_id = 'model-nissan-119-kr' and vmy.year <> 2026)
  );

update public.vehicle_variants vv
set
  generation_id = null,
  source_status = 'deprecated',
  is_verified = false,
  is_selectable = false,
  is_deprecated = true,
  confidence_score = 0
from public.vehicle_model_years vmy
where vv.model_year_id = vmy.id
  and (
    (vmy.model_id in ('model-nissan-115-kr', 'model-nissan-116-kr', 'model-nissan-117-kr') and vmy.year > 2020)
    or (vmy.model_id = 'model-nissan-118-kr' and (vmy.year < 2019 or vmy.year > 2020))
    or (vmy.model_id = 'model-nissan-119-kr' and vmy.year <> 2026)
  );

update public.vehicle_model_years
set
  generation_id = null,
  production_year_label = null
where (
    model_id in ('model-nissan-115-kr', 'model-nissan-116-kr', 'model-nissan-117-kr')
    and year > 2020
  )
  or (
    model_id = 'model-nissan-118-kr'
    and (year < 2019 or year > 2020)
  )
  or (
    model_id = 'model-nissan-119-kr'
    and year <> 2026
  );
