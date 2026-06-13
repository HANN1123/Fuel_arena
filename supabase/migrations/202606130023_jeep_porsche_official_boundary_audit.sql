-- Jeep/Porsche official homepage boundary audit.
-- Official Korea pages confirm model groups, but the remaining generated
-- placeholders do not have model-year specific certified economy/spec sources.
-- Keep them pending and non-selectable until official spec-sheet rows are
-- audited model by model.

with boundary_generation_sources (
  id,
  source_name,
  source_url,
  confidence_score
) as (
  values
    ('generation-porsche-911-official-lineup', 'Porsche Korea official 911 model page', 'https://www.porsche.com/korea/ko/models/911/', 0.56),
    ('generation-porsche-boxster-official-lineup', 'Porsche Korea official 718 model page', 'https://www.porsche.com/korea/ko/models/718/', 0.54),
    ('generation-porsche-cayman-official-lineup', 'Porsche Korea official 718 model page', 'https://www.porsche.com/korea/ko/models/718/', 0.54),
    ('generation-porsche-panamera-official-lineup', 'Porsche Korea official Panamera model page', 'https://www.porsche.com/korea/ko/models/panamera/', 0.56),
    ('generation-porsche-macan-official-lineup', 'Porsche Korea official Macan model page', 'https://www.porsche.com/korea/ko/models/macan/', 0.56),
    ('generation-porsche-cayenne-official-lineup', 'Porsche Korea official Cayenne model page', 'https://www.porsche.com/korea/ko/models/Cayenne/', 0.56),
    ('generation-porsche-taycan-official-lineup', 'Porsche Korea official Taycan model page', 'https://www.porsche.com/korea/ko/models/taycan/', 0.56),
    ('generation-jeep-renegade-official-lineup', 'Jeep Korea official promotion/archive pages', 'https://www.jeep.co.kr/promotion.html', 0.50),
    ('generation-jeep-compass-official-lineup', 'Jeep Korea official Compass page', 'https://www.jeep.co.kr/compass.html', 0.54),
    ('generation-jeep-cherokee-official-lineup', 'Jeep Korea official promotion/archive pages', 'https://www.jeep.co.kr/promotion.html', 0.50),
    ('generation-jeep-wrangler-official-lineup', 'Jeep Korea official Wrangler page', 'https://www.jeep.co.kr/wrangler.html', 0.56),
    ('generation-jeep-grand-cherokee-official-lineup', 'Jeep Korea official model lineup', 'https://www.jeep.co.kr/', 0.54),
    ('generation-jeep-gladiator-official-lineup', 'Jeep Korea official Gladiator page', 'https://www.jeep.co.kr/gladiator.html', 0.56),
    ('generation-jeep-grand-cherokee-l-official-lineup', 'Jeep Korea official Grand Cherokee L page', 'https://www.jeep.co.kr/grand-cherokee-l.html', 0.56),
    ('generation-jeep-avenger-official-lineup', 'Jeep Korea official Avenger and EV battery pages', 'https://www.jeep.co.kr/JL/Avenger.html', 0.54)
)
update public.vehicle_generations vg
set
  source_status = 'pending_review',
  confidence_score = bgs.confidence_score,
  source_name = bgs.source_name,
  source_url = bgs.source_url,
  source_file_name = null,
  last_verified_at = '2026-06-13',
  is_deprecated = false,
  updated_at = now()
from boundary_generation_sources bgs
where vg.id = bgs.id;

with audited_model_ids(id, source_name, source_url) as (
  values
    ('model-porsche-132-911', 'Porsche Korea official model-page boundary audit', 'https://www.porsche.com/korea/ko/models/911/'),
    ('model-porsche-133-kr', 'Porsche Korea official model-page boundary audit', 'https://www.porsche.com/korea/ko/models/718/'),
    ('model-porsche-134-kr', 'Porsche Korea official model-page boundary audit', 'https://www.porsche.com/korea/ko/models/718/'),
    ('model-porsche-135-kr', 'Porsche Korea official model-page boundary audit', 'https://www.porsche.com/korea/ko/models/panamera/'),
    ('model-porsche-136-kr', 'Porsche Korea official model-page boundary audit', 'https://www.porsche.com/korea/ko/models/macan/'),
    ('model-porsche-137-kr', 'Porsche Korea official model-page boundary audit', 'https://www.porsche.com/korea/ko/models/Cayenne/'),
    ('model-porsche-138-kr', 'Porsche Korea official model-page boundary audit', 'https://www.porsche.com/korea/ko/models/taycan/'),
    ('model-jeep-149-kr', 'Jeep Korea official homepage boundary audit', 'https://www.jeep.co.kr/promotion.html'),
    ('model-jeep-150-kr', 'Jeep Korea official homepage boundary audit', 'https://www.jeep.co.kr/compass.html'),
    ('model-jeep-151-kr', 'Jeep Korea official homepage boundary audit', 'https://www.jeep.co.kr/promotion.html'),
    ('model-jeep-152-kr', 'Jeep Korea official homepage boundary audit', 'https://www.jeep.co.kr/wrangler.html'),
    ('model-jeep-153-kr', 'Jeep Korea official homepage boundary audit', 'https://www.jeep.co.kr/'),
    ('model-jeep-gladiator-kr', 'Jeep Korea official homepage boundary audit', 'https://www.jeep.co.kr/gladiator.html'),
    ('model-jeep-grand-cherokee-l-kr', 'Jeep Korea official homepage boundary audit', 'https://www.jeep.co.kr/grand-cherokee-l.html'),
    ('model-jeep-avenger-kr', 'Jeep Korea official homepage boundary audit', 'https://www.jeep.co.kr/JL/Avenger.html')
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
  source_name = ami.source_name,
  source_url = ami.source_url,
  source_file_name = null,
  last_verified_at = '2026-06-13',
  confidence_score = 0.10,
  is_selectable = false,
  is_deprecated = false
from public.vehicle_model_years vmy
join audited_model_ids ami on ami.id = vmy.model_id
where vv.model_year_id = vmy.id;

with audited_model_ids(id) as (
  values
    ('model-porsche-132-911'),
    ('model-porsche-133-kr'),
    ('model-porsche-134-kr'),
    ('model-porsche-135-kr'),
    ('model-porsche-136-kr'),
    ('model-porsche-137-kr'),
    ('model-porsche-138-kr'),
    ('model-jeep-149-kr'),
    ('model-jeep-150-kr'),
    ('model-jeep-151-kr'),
    ('model-jeep-152-kr'),
    ('model-jeep-153-kr'),
    ('model-jeep-gladiator-kr'),
    ('model-jeep-grand-cherokee-l-kr'),
    ('model-jeep-avenger-kr')
)
delete from public.vehicle_powertrain_sources vps
using public.vehicle_variants vv,
  public.vehicle_model_years vmy,
  audited_model_ids ami
where vps.powertrain_id = vv.id
  and vv.model_year_id = vmy.id
  and vmy.model_id = ami.id
  and vv.source_status not in ('verified_official', 'verified_admin');
