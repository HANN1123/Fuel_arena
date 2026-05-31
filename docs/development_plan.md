# Fuel Arena Development Plan

## 현재 상태

이 레포는 Flutter 프로젝트가 없는 새 레포에서 시작한다. 첫 작업에서는 Flutter 프로젝트를 생성하고, Mock Repository 기반으로 Phase 1과 Phase 2의 기본 화면을 컴파일 가능한 상태로 만든다.

2026-05-30 작업 메모:

- 로컬 PATH와 흔한 설치 위치에서 Flutter/Dart SDK를 찾지 못했다.
- `flutter create . --project-name fuel_arena --platforms android,ios` 실행은 `flutter` 명령을 찾지 못해 실패했다.
- SDK 부재 때문에 `flutter pub get`, `dart format .`, `flutter analyze`도 각각 `flutter` 또는 `dart` 명령을 찾지 못해 실패했다.
- 대신 Flutter 앱 소스 구조, `pubspec.yaml`, 문서, Mock Repository, 화면, 테스트 파일을 수동으로 스캐폴딩했다.
- Flutter SDK 설치 후 README의 명령을 실행하면 Android/iOS platform wrapper를 생성하고 검증할 수 있다.

## 검증 로그

현재 환경에서 시도한 명령:

```text
flutter create . --project-name fuel_arena --platforms android,ios
flutter pub get
dart format .
flutter analyze
```

결과:

- `flutter`: 명령을 찾을 수 없음
- `dart`: 명령을 찾을 수 없음

다음 조치:

1. Flutter stable SDK 설치
2. PATH에 `flutter/bin` 추가
3. 이 레포 루트에서 `flutter create . --project-name fuel_arena --platforms android,ios`
4. `flutter pub get`
5. `dart format .`
6. `flutter analyze`
7. 발견되는 analyzer 이슈 수정

## 1차 목표

- Flutter 모바일 앱 골격 생성
- 제품 문서와 Supabase 계획 문서 작성
- 디자인 시스템 구현
- Repository Interface와 Mock 구현체 구성
- Splash → Onboarding → Login → Vehicle Register → Home 흐름 구현
- 하단 탭 5개 구현
- Home, DriveResult, Ranking, Battle, Season, Profile을 Mock 데이터로 표시
- Phase 3 route와 placeholder 화면 생성
- `flutter analyze`에서 치명적인 오류 제거

## 구현 순서

1. 문서 생성
2. `flutter create . --project-name fuel_arena --platforms android,ios`
3. 패키지 추가
4. 폴더 구조 생성
5. 디자인 시스템 작성
6. 공통 위젯 작성
7. 모델 작성
8. Repository Interface, Mock, Supabase TODO 구현체 작성
9. Router와 App Shell 작성
10. Phase 1/2 화면 구현
11. Phase 3 placeholder route 구현
12. 기본 위젯 테스트 작성
13. `flutter pub get`
14. `dart format .`
15. `flutter analyze`

## Mock 우선 정책

초기 앱은 실제 Supabase 연결 없이 동작해야 한다. Supabase 구현체는 파일과 class만 준비하고 TODO로 남긴다.

Mock에서 지원할 동작:

- 로그인 성공
- 차량 등록 저장
- 홈 데이터 표시
- 주행 시작과 안전 모드 이동
- 주행 종료 후 결과 표시
- 리워드 광고 보상 획득 상태 변경
- 랭킹, 배틀, 시즌, 프로필 데이터 표시

## 리스크 및 대응

- Flutter SDK가 없거나 프로젝트 생성이 실패하면 작업을 중단하고 설치 필요 사항을 기록한다.
- 현재 환경에서는 Flutter SDK가 없어 platform wrapper 생성과 analyzer 검증이 미완료다. Flutter 설치 후 `flutter create . --project-name fuel_arena --platforms android,ios`를 다시 실행해야 한다.
- 패키지 버전 충돌이 발생하면 최신 안정 버전 대신 Flutter stable과 맞는 버전으로 조정한다.
- Supabase 환경변수가 없을 수 있으므로 초기화 실패가 앱 실행 실패로 이어지지 않게 Mock 우선 구조를 유지한다.
- 실제 GPS/주행 기록은 이번 범위에서 구현하지 않는다. 안전 모드는 UI와 route 흐름만 구현한다.

## 다음 단계

- 실제 Supabase Auth 연결
- 주행 세션 로컬 기록과 백그라운드 위치 권한 설계
- Edge Function 기반 점수 계산
- RLS 정책 SQL 작성
- 실제 광고 SDK와 인앱결제 검토
- 디자인 고도화와 애니메이션 추가
