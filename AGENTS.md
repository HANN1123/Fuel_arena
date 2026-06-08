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

## 테스트 기준
- 계산 helper는 단위 테스트를 추가한다.
- 주요 화면은 mock provider로 렌더링 테스트를 유지한다.
- repository mock은 가입, 차량, 주행, 광고 보상 흐름을 검증한다.
- Flutter SDK가 설치된 환경에서 `flutter analyze`와 `flutter test`가 통과해야 한다.

## 완료 기준
- 앱이 dev/mock mode에서 실제 사용자 흐름으로 이동 가능해야 한다.
- `.env.example`, Supabase migration, RLS, seed, Edge Functions, README, docs가 함께 최신 상태여야 한다.
- 외부 콘솔 설정이 필요한 값은 코드에 하드코딩하지 않고 문서와 `.env.example`로 분리한다.

