insert into public.subscription_plans (
  id,
  title,
  description,
  price_text,
  plan_type,
  benefits,
  product_id
)
values
  (
    'premium-monthly',
    'Fuel Arena 프리미엄',
    '광고 없이 고급 분석과 시즌패스 추가 보상을 제공합니다.',
    '월 4,900원',
    'monthly',
    '["광고 제거", "고급 통계", "라이벌 분석", "동급 차량 상세 비교"]'::jsonb,
    'fuel_arena_premium_monthly'
  ),
  (
    'premium-yearly',
    'Fuel Arena 프리미엄 연간',
    '연간 구독으로 더 낮은 가격에 프리미엄을 사용합니다.',
    '연 49,000원',
    'yearly',
    '["광고 제거", "고급 통계", "라이벌 분석", "시즌패스 추가 보상"]'::jsonb,
    'fuel_arena_premium_yearly'
  ),
  (
    'season-pass',
    'Fuel Arena 시즌패스',
    '시즌 미션 추가 보상과 시즌 전용 보너스를 제공합니다.',
    '시즌 9,900원',
    'season_pass',
    '["시즌 미션 추가 보상", "시즌 전용 보너스", "보상 지갑 추가 슬롯"]'::jsonb,
    'fuel_arena_season_pass'
  ),
  (
    'premium-bundle',
    'Fuel Arena 프리미엄 번들',
    '프리미엄과 시즌패스를 함께 사용할 수 있는 번들 상품입니다.',
    '번들 14,900원',
    'bundle',
    '["프리미엄 혜택", "시즌패스 혜택", "라이벌 분석", "광고 제거"]'::jsonb,
    'fuel_arena_premium_bundle'
  )
on conflict (id) do update set
  title = excluded.title,
  description = excluded.description,
  price_text = excluded.price_text,
  plan_type = excluded.plan_type,
  benefits = excluded.benefits,
  product_id = excluded.product_id;
