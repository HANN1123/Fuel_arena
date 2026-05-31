# Fuel Arena

Fuel Arena는 연비와 주행 효율을 경쟁 점수로 바꾸는 게임형 드라이빙 플랫폼입니다.

핵심 문장:

> 기름값을 아끼는 앱이 아니라, 이기고 싶어서 자연스럽게 아끼게 만드는 앱.

## Tech Stack

- Flutter
- Dart
- Supabase Auth
- Supabase Postgres
- Supabase Realtime
- Supabase Storage
- Supabase Edge Functions
- Supabase Row Level Security

## Current Scope

현재 레포에는 Mock Repository 기반 Flutter 앱 골격이 들어 있습니다.

- Splash → Onboarding → Login → Vehicle Register → Home 흐름
- 홈, 배틀, 랭킹, 시즌, 프로필 하단 탭
- 주행 시작, 안전 주행, 주행 결과 화면
- 리워드 광고, 프리미엄, 스폰서, 지갑, 통계, 공정성 센터, 설정 placeholder
- Supabase 연동 준비 구조와 문서

## Local Setup

Flutter SDK가 설치된 환경에서 다음 명령을 실행하세요.

```bash
flutter create . --project-name fuel_arena --platforms android,ios
flutter pub get
dart format .
flutter analyze
flutter run
```

Supabase 실제 연동 전까지 앱은 Mock Repository로 동작합니다.
