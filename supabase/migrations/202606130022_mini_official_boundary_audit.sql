-- MINI official homepage boundary audit.
-- MINI Korea home/model range confirms the visible model groups, but the pages
-- do not provide a stable domestic certified efficiency/spec table suitable for
-- competition scoring. Keep every MINI powertrain pending and non-selectable
-- until model-specific official spec sheets are audited.

with mini_generation_sources (
  id,
  source_name,
  source_url,
  confidence_score
) as (
  values
    ('generation-mini-hatch-official-lineup', 'MINI Korea official model range', 'https://www.mini.co.kr/ko_KR/home.html', 0.56),
    ('generation-mini-countryman-official-lineup', 'MINI Korea official model range', 'https://www.mini.co.kr/ko_KR/home.html', 0.56),
    ('generation-mini-clubman-official-lineup', 'MINI Korea official model range/archive', 'https://www.mini.co.kr/ko_KR/home/faqs.html', 0.52),
    ('generation-mini-cooper-se-official-lineup', 'MINI Korea official model range', 'https://www.mini.co.kr/ko_KR/home.html', 0.56),
    ('generation-mini-convertible-official-lineup', 'MINI Korea official model range', 'https://www.mini.co.kr/ko_KR/home.html', 0.56),
    ('generation-mini-aceman-official-lineup', 'MINI Korea official Aceman model page', 'https://www.mini.co.kr/ko_KR/home/range/all-electric-mini-aceman.html', 0.62),
    ('generation-mini-cooper-5-door-official-lineup', 'MINI Korea official model range', 'https://www.mini.co.kr/ko_KR/home.html', 0.62),
    ('generation-mini-electric-cooper-official-lineup', 'MINI Korea official model range', 'https://www.mini.co.kr/ko_KR/home.html', 0.62),
    ('generation-mini-electric-countryman-official-lineup', 'MINI Korea official model range', 'https://www.mini.co.kr/ko_KR/home.html', 0.62),
    ('generation-mini-jcw-official-lineup', 'MINI Korea official John Cooper Works page', 'https://www.mini.co.kr/ko_KR/home/range/john-cooper-works.html', 0.62)
)
update public.vehicle_generations vg
set
  source_status = 'pending_review',
  confidence_score = mgs.confidence_score,
  source_name = mgs.source_name,
  source_url = mgs.source_url,
  source_file_name = null,
  last_verified_at = '2026-06-13',
  is_deprecated = false,
  updated_at = now()
from mini_generation_sources mgs
where vg.id = mgs.id;

with mini_model_ids(id) as (
  values
    ('model-mini-139-kr'),
    ('model-mini-140-kr'),
    ('model-mini-141-kr'),
    ('model-mini-142-se'),
    ('model-mini-143-kr'),
    ('model-mini-aceman-kr'),
    ('model-mini-cooper-5-door-kr'),
    ('model-mini-electric-cooper-kr'),
    ('model-mini-electric-countryman-kr'),
    ('model-mini-jcw-kr')
)
update public.vehicle_variants vv
set
  trim_name = '공식 제원 검수 대기',
  engine_name = 'Pending official specification review',
  displacement_cc = null,
  battery_kwh = null,
  drivetrain = '검수 대기',
  transmission = '검수 대기',
  official_efficiency = null,
  is_verified = false,
  source_status = 'pending_review',
  source_name = 'MINI Korea official model range boundary audit',
  source_url = 'https://www.mini.co.kr/ko_KR/home.html',
  source_file_name = null,
  last_verified_at = '2026-06-13',
  confidence_score = 0.10,
  is_selectable = false,
  is_deprecated = false
from public.vehicle_model_years vmy
join mini_model_ids mmi on mmi.id = vmy.model_id
where vv.model_year_id = vmy.id;

with mini_model_ids(id) as (
  values
    ('model-mini-139-kr'),
    ('model-mini-140-kr'),
    ('model-mini-141-kr'),
    ('model-mini-142-se'),
    ('model-mini-143-kr'),
    ('model-mini-aceman-kr'),
    ('model-mini-cooper-5-door-kr'),
    ('model-mini-electric-cooper-kr'),
    ('model-mini-electric-countryman-kr'),
    ('model-mini-jcw-kr')
)
delete from public.vehicle_powertrain_sources vps
using public.vehicle_variants vv,
  public.vehicle_model_years vmy,
  mini_model_ids mmi
where vps.powertrain_id = vv.id
  and vv.model_year_id = vmy.id
  and vmy.model_id = mmi.id
  and vv.source_status not in ('verified_official', 'verified_admin');
