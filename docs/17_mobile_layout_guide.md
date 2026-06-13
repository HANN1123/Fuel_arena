# Mobile Layout Guide

## 원칙
- 사용자 앱은 어떤 화면 크기에서도 430px 이하 모바일 레이아웃으로 제한한다.
- 관리자 대시보드만 full width를 사용한다.
- iPhone SE급 320px 폭에서도 버튼과 텍스트가 겹치지 않아야 한다.

## Shell
- `MobileViewportShell`: 모바일 앱 폭 제한.
- `ResponsiveAppShell`: `maxWidth`가 있으면 모바일 shell, 없으면 admin shell을 선택.
- `AdminViewportShell`: 관리자 화면 full width와 최소 1024px 작업 폭 보장.
- `AppScaffold` body는 route content를 바깥 `SafeArea`로 감싸지 않는다. Flutter Web hash route(`#/home`)에서 바깥/안쪽 SafeArea가 중첩되면 본문이 비고 하단 탭만 보이는 회귀가 발생할 수 있다.
- 홈, 배틀, 랭킹, 시즌, 프로필 같은 메인 탭 화면은 내부 `SafeArea`로 시작하지 않는다. 상단/하단 여백은 화면 padding과 bottom navigation 여백으로 처리한다.

## 토큰
- `AppLayout.mobileDesignWidth = 390`
- `AppLayout.mobileMinWidth = 320`
- `AppLayout.mobileMaxWidth = 430`
- `AppLayout.adminMinWidth = 1024`
- `AppLayout.bottomNavHeight = 72`
- `AppCardSize.manufacturerHeight = 104`
- `AppCardSize.vehicleModelHeight = 88`
- `AppCardSize.vehicleVariantHeight = 112`
- `AppButtonHeight.primary = 52`

## 아이콘 기준
- bottom nav: `AppIconSize.sm`
- app bar: `AppIconSize.sm`-`AppIconSize.md`
- chip: `AppIconSize.xs`
- card leading: `AppIconSize.md`-`AppIconSize.lg`
- vehicle setup fuel/model/powertrain card leading: `AppIconSize.lg` 이하
- manufacturer logo badge: `AppIconSize.xl`
- empty state icon: `AppIconSize.hero`
- hero reward icon: 최대 64

## 금지
- 일반 사용자 route에서 `maxWidth: null` 사용 금지.
- 관리자 route가 아닌 곳에서 데스크톱 전체 폭 검색창 사용 금지.
- 카드 안 아이콘 80px 이상 사용 금지.
- 차량 설정 화면에서 데스크톱 폭에 맞춰 카드, 검색창, 아이콘을 키우는 것 금지. 사용자 앱은 계속 430px 모바일 폭 안에서 동작해야 한다.
- `AppScaffold` 또는 메인 탭 화면에 중첩 `SafeArea`를 추가하는 것 금지.
- 제조사 grid를 `childAspectRatio`만으로 제어하지 말고 `mainAxisExtent: AppCardSize.manufacturerHeight`를 사용한다.

## 회귀 방지
- `test/widget/flow_screens_test.dart`의 core route smoke 테스트는 `/home` 5개 탭, 차량 설정, 주행, 랭킹, 배틀, 설정, 차량 관리, 알림, 고객지원, 프리미엄 화면이 router를 통해 본문을 렌더링하는지 확인한다.
- `tool/validate_product_invariants.dart`는 `AppLayout`, `AppIconSize`, `AppCardSize`, `CompactManufacturerCard`, route smoke 테스트 토큰이 사라지면 실패한다.
- `tool/run_web_smoke.py`는 `build/web` 정적 서버를 띄우고 포트 준비를 기다린 뒤 `tool/verify_web_render.py`와 `tool/verify_web_core_routes.py`를 실행한다. CI와 로컬 릴리즈 게이트는 고정 대기시간 대신 이 runner를 사용한다.
- `tool/verify_web_render.py`는 `build/web`을 실제 Chrome/Edge headless screenshot으로 열어 초록 배경만 보이는 회귀, 초기 Flutter 본문 미렌더링, 지나치게 작은 screenshot을 릴리스 전에 잡는다.
- `tool/verify_web_core_routes.py`는 로그인, 동의, 차량 설정, 홈, 랭킹, 프로필, 프리미엄, 공정성 센터, 고객지원 route를 390px 모바일 폭으로 순회하고, `/admin`, `/admin/vehicles`는 1440px 데스크톱 폭으로 캡처해 사용자 앱 폭 제한과 관리자 full-width 렌더링 회귀를 함께 잡는다.
