# Fuel Arena

Fuel Arena는 연비와 주행 효율을 경쟁 점수로 바꾸는 게임형 드라이빙 플랫폼입니다.

> 기름값을 아끼는 앱이 아니라, 이기고 싶어서 자연스럽게 아끼게 만드는 앱.

## 기술 스택

Flutter, Dart, go_router, flutter_riverpod, Supabase Auth/Postgres/Realtime/Storage/Edge Functions/RLS, google_mobile_ads, in_app_purchase, geolocator.

## 현재 구현

- Splash → Onboarding → Signup/Login → Consent → Permissions → Vehicle Register → Home 흐름
- 하단 5개 탭: 홈, 배틀, 랭킹, 시즌, 프로필
- 주행 시작, 안전 모드, 주행 결과, 점수 분석, 광고 보상 선택
- 랭킹, 배틀 생성/상세/결과, 시즌패스, 미션, 라이벌, 크루
- 리워드 지갑, 스폰서 챌린지, 프리미엄 mock purchase, 공정성 센터, 설정
- `/admin` 운영자 대시보드
- Supabase schema, RLS, seed, Edge Functions
- dev/mock fallback

## 환경변수

`.env.example`을 복사해 `.env`를 만들고 필요한 값을 채웁니다. dev mode에서는 Supabase 키가 없어도 mock repository로 실행됩니다.

```bash
APP_ENV=dev
SUPABASE_URL=
SUPABASE_ANON_KEY=
```

production mode에서는 Supabase URL과 anon key가 필수입니다. service_role key는 Flutter 앱에 넣지 않습니다.

## 실행

```bash
flutter create . --project-name fuel_arena --platforms android,ios,web
flutter pub get
flutter run
```

## 테스트

```bash
flutter test
flutter analyze
```

## 빌드

```bash
flutter build apk --debug
flutter build web
```

## Supabase

```bash
supabase db push
supabase functions deploy calculate_drive_score
supabase functions deploy verify_drive_session
supabase functions deploy update_rankings
supabase functions deploy settle_battle
supabase functions deploy grant_ad_reward
supabase functions deploy claim_season_reward
supabase functions deploy issue_coupon
supabase functions deploy update_mission_progress
supabase functions deploy process_fraud_review
supabase functions deploy send_notification
```

## 개발 모드와 프로덕션 모드

- dev: 외부 키가 없어도 mock repository, mock ads, mock purchase로 실제 흐름 검증
- staging: Supabase 필수, test ads 사용
- production: Supabase 필수, live ads, 실제 IAP 상품 ID 필요
