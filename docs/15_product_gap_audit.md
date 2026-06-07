# Product Gap Audit

이 문서는 Fuel Arena를 실제 제품으로 출고하기 전에 남은 항목을 “코드로 닫을 수 있는 것”과 “외부 콘솔/운영 환경에서만 확인 가능한 것”으로 분리해 추적한다.

## 출시를 막는 외부 확인 항목
- Supabase production project에 모든 migration, seed, Edge Function이 배포되어야 한다.
- Google OAuth Web/Android/iOS client, Android SHA-1/SHA-256, iOS URL scheme, Supabase redirect allow list가 실제 도메인과 일치해야 한다.
- AdMob production app id와 reward/native/interstitial ad unit id가 live 값으로 설정되어야 한다.
- Play Console/App Store IAP 상품 ID, sandbox 계정, 서버 검증 secret이 실제 상품과 일치해야 한다.
- 개인정보 처리방침, 위치정보 이용 고지, 계정 삭제/데이터 삭제 요청 URL은 Web 정적 페이지로 준비되어 있으며 실제 배포 도메인 연결이 필요하다.

## 코드 안에서 닫은 주요 리스크
- dev/mock mode에서는 가입, 동의, 차량 설정, 주행, 점수, 랭킹, 배틀, 시즌, 보상, 고객지원 흐름이 외부 키 없이 이동 가능하다.
- 사용자 화면은 `MobileViewportShell`로 430px 이하 모바일 앱 폭을 유지하고, 관리자 화면만 full width를 사용한다.
- 차량 카탈로그는 2008-2026 기준 제조사/모델/연식/파워트레인 seed와 validator를 제공한다. 판매 트림명, 휠 인치수, placeholder variant는 verified 선택 축에 노출하지 않는다.
- 주행 포인트 업로드 실패는 local offline queue에 저장하고 온라인 복귀 후 private `drive_points`로 재전송한다.
- 손상된 offline queue payload는 백업 후 discard 로그를 남겨 무한 재시도를 막는다.
- 광고 보상, 쿠폰 발급, 미션 보상, 배틀 정산은 Edge Function idempotency key를 사용해 중복 처리 위험을 줄인다.
- production에서는 주행 점수, 프리미엄 구매, 리워드 광고, 차량 카탈로그, 홈/시즌/운영 콘텐츠가 mock fallback으로 조용히 대체되지 않는다.
- 리워드 광고와 쿠폰 지갑은 RemoteConfig를 읽지 못하면 버튼을 열지 않고 오류/재시도 상태를 보여준다.
- 공개 랭킹과 공개 프로필은 이메일, 정확한 위치 좌표, raw `drive_points`를 노출하지 않는다.
- 로그아웃은 Supabase/Google 세션, 보안 세션 힌트, 사용자별 provider cache, 오프라인 주행 queue, 세션 ID 매핑, 손상 queue 백업을 정리한다.
- Supabase service role key, 스토어 검증 private key, ranking secret은 Flutter client env에 포함하지 않도록 release preflight가 검사한다.

## 운영 검증 우선순위
1. Supabase production DB에 migration/seed를 적용하고 `validate_supabase_schema.dart`가 기대하는 RLS, RPC, Edge-only grant 상태를 실제 SQL editor에서 확인한다.
2. Edge Function 14개를 production에 배포하고 `grant_ad_reward`, `issue_coupon`, `claim_season_reward`, `settle_battle`, `finish_drive_session`, `verify_purchase`를 실제 사용자 토큰으로 호출해 본다.
3. Google OAuth는 `--check-supabase-live`로 Supabase Google provider와 web/native redirect가 `accounts.google.com`으로 이어지는지 먼저 확인하고, Web redirect, Android token exchange, iOS token exchange를 실제 계정으로 확인한다.
4. AdMob rewarded ad는 `onUserEarnedReward` 콜백 이후에만 `grant_ad_reward`가 호출되는지 production/staging 각각에서 확인한다.
5. Play/App Store sandbox에서 구매, 복원, 만료, 환불, 잘못된 상품 ID, 잘못된 receipt/token을 검증한다.
6. 차량 카탈로그 운영 import 후 관리자 화면에서 제조사/모델/연식/파워트레인 수와 대표 K3/K3 GT, 아반떼, 전기차/하이브리드 항목을 확인한다.
7. legal Web URL 네 가지(`/legal/privacy/`, `/legal/location/`, `/legal/account-deletion/`, `/legal/terms/`)가 실제 배포 도메인에서 200으로 응답하는지 확인한다.

## 자동 검증 명령
- `python tool/run_local_release_gate.py`
- `python tool/run_local_release_gate.py --quick`
- `python -m pip install -r requirements-dev.txt`
- `flutter analyze`
- `flutter test`
- `dart run tool/validate_vehicle_catalog.dart`
- `dart run tool/validate_supabase_schema.dart`
- `dart run tool/validate_edge_functions.dart`
- `dart run tool/validate_product_invariants.dart`
- `python tool/validate_release_environment_selftest.py`
- `python tool/validate_release_example_placeholders.py`
- `.env.production.example`을 `.env.production`으로 복사 후 production client/public 값을 채운다.
- `.env.edge.production.example`을 `.env.edge.production`으로 복사 후 Edge Function secret 값을 채운다.
- `python tool/validate_release_environment.py --env-file .env.production --edge-secrets-file .env.edge.production`
- `python tool/validate_release_environment.py --env-file .env.production --client-only --check-public-urls`
- `python tool/validate_release_environment.py --env-file .env.production --edge-secrets-file .env.edge.production --check-public-urls --check-supabase-live`
- `python tool/validate_store_submission_assets.py`
- `python tool/validate_store_privacy_disclosures.py`
- `flutter build web --wasm`
- `flutter build web`
- `python tool/run_web_smoke.py --port 5173`
- `python tool/serve_web.py --directory build/web --port 5173`
- `python tool/verify_web_render.py --url http://127.0.0.1:5173/#/home`
- `python tool/verify_web_core_routes.py`
- `flutter build apk --debug`

## 현재 결론
Fuel Arena는 dev/mock mode에서 실제 사용자 흐름을 이동할 수 있고, production에서는 설정 누락이나 외부 검증 실패를 mock 데이터로 숨기지 않는 방향으로 보강되어 있다. 남은 완료 조건은 production Supabase/Google/AdMob/IAP/스토어 legal URL을 외부 콘솔에서 연결하고, 위 운영 검증 우선순위와 `--check-supabase-live`를 실제 환경에서 통과시키는 것이다.
