# Fuel Arena Agent Guide

## 역할
Fuel Arena는 연비 기록장이 아니라 연비로 경쟁하는 게임형 드라이빙 플랫폼이다. 모든 구현은 가입, 동의, 차량 등록, 주행 기록, 점수, 랭킹, 배틀, 시즌, 보상, 광고, 프리미엄, 쿠폰, 공정성, 설정, 관리자 대시보드 흐름을 실제로 연결하는 방향으로 진행한다.

## 실행 명령
- `flutter pub get`
- `flutter run`
- `flutter test`
- `flutter analyze`
- `flutter build apk --debug`
- `flutter build web`

## 개발 규칙
- Flutter + Dart + Riverpod + go_router 패턴을 유지한다.
- 외부 키가 없을 때 dev 모드는 MockRepository로 동작한다.
- production 모드는 Supabase URL/anon key 또는 Web/Android/iOS/Server Google OAuth client ID, iOS reversed client ID, `fuelarena://login-callback` callback 설정이 누락되거나 형식이 맞지 않으면 설정 오류 화면을 보여준다.
- 사용자에게 보이는 텍스트는 한국어를 우선한다.
- 주행 중 광고, 팝업, 도전장, 알림을 표시하지 않는다.
- 정확한 위치 좌표와 raw drive_points는 공개 화면에 노출하지 않는다.
- Supabase service_role key는 Flutter 앱에 절대 넣지 않는다.
- Google 로그인 이후 DB 보강은 `auth.users` trigger, profiles protected field trigger/RPC, consent/account deletion/data export/auth audit RLS를 함께 유지한다.
- 차량 선택 UX는 기본적으로 제조사 → 연료 타입 → 넓은 범주 → 모델 → 세대 → 파워트레인/트림 → 확인 흐름을 유지하고, 기본 단계로 연식 선택을 되돌리지 않는다.
- 차량 세대/파워트레인 정보는 임의 생성하지 않고, 출처 없는 generation은 verified 처리하지 않는다.
- BMW 데이터는 공식 출처 또는 운영자 검수 전까지 `unverified`/`pending_review`/`conflict`로 두고 selectable verified로 노출하지 않는다.
- K3 GT는 별도 모델이 아니라 K3 모델의 GT 트림/파워트레인으로 관리한다.

## 테스트 기준
- 계산 helper는 단위 테스트를 추가한다.
- 주요 화면은 mock provider로 렌더링 테스트를 유지한다.
- repository mock은 가입, 차량, 주행, 광고 보상 흐름을 검증한다.
- Flutter SDK가 설치된 환경에서 `flutter analyze`와 `flutter test`가 통과해야 한다.
- Google Auth DB/RLS 변경 시 `dart run tool/validate_google_auth_database.dart`, `dart run tool/validate_supabase_schema.dart`, `dart run tool/security/check_auth_rls_policies.dart`, `python tool/validate_secret_hygiene.py`를 실행한다.

## 완료 기준
- 앱이 dev/mock mode에서 실제 사용자 흐름으로 이동 가능해야 한다.
- `.env.example`, Supabase migration, RLS, seed, Edge Functions, README, docs가 함께 최신 상태여야 한다.
- profiles 자동 생성 trigger, protected field 방어, consent_logs, account_deletion_requests, data_export_requests, auth_audit_logs, safe public views, RLS test SQL이 migration과 문서에 반영되어야 한다.
- 외부 콘솔 설정이 필요한 값은 코드에 하드코딩하지 않고 문서와 `.env.example`로 분리한다.

