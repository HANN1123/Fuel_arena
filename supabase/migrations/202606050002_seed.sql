insert into public.subscription_plans (id, title, description, price_text, plan_type, benefits, product_id)
values
  ('premium-monthly', 'Fuel Arena Premium', '광고 없이 고급 분석과 시즌패스 추가 보상을 제공합니다.', '월 4,900원', 'monthly', '["광고 제거", "고급 통계", "라이벌 분석", "동급 차량 상세 비교"]', 'fuel_arena_premium_monthly'),
  ('premium-yearly', 'Fuel Arena Premium Yearly', '연간 구독으로 더 낮은 가격에 프리미엄을 사용합니다.', '연 49,000원', 'yearly', '["광고 제거", "고급 통계", "시즌패스 추가 보상"]', 'fuel_arena_premium_yearly')
on conflict (id) do update set
  title = excluded.title,
  description = excluded.description,
  price_text = excluded.price_text,
  plan_type = excluded.plan_type,
  benefits = excluded.benefits,
  product_id = excluded.product_id;

insert into public.badges (name, description, rarity)
select '연비 검투사', '첫 배틀 승리', 'Rare'
where not exists (select 1 from public.badges where name = '연비 검투사');

insert into public.badges (name, description, rarity)
select '정속 장인', '안정 점수 90점 이상', 'Epic'
where not exists (select 1 from public.badges where name = '정속 장인');

insert into public.achievements (title, description, target)
select '첫 검증 완료', '검증된 주행 기록 1회 달성', 1
where not exists (select 1 from public.achievements where title = '첫 검증 완료');

insert into public.sponsors (name, description, is_active)
select 'Charge Lab', '효율 주행 챌린지 스폰서', true
where not exists (select 1 from public.sponsors where name = 'Charge Lab');

insert into public.sponsor_challenges (sponsor_id, title, description, reward_summary, ends_at)
select s.id, '도심 효율 챌린지', '15km 이상 주행하고 동급 대비 상위 30%를 달성하세요.', '쿠폰 응모권 1장', now() + interval '14 days'
from public.sponsors s
where s.name = 'Charge Lab'
  and not exists (select 1 from public.sponsor_challenges where title = '도심 효율 챌린지');

insert into public.coupons (sponsor_id, title, description, expires_at)
select s.id, '세차 쿠폰 응모권', '스폰서 챌린지 완료 보상', now() + interval '30 days'
from public.sponsors s
where s.name = 'Charge Lab'
  and not exists (select 1 from public.coupons where title = '세차 쿠폰 응모권');

