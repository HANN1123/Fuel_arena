# Flutter Architecture

Fuel Arena는 기능별 feature structure와 Repository 패턴을 사용한다. 초기에는 Mock 구현체로 앱을 완성하고, Supabase 연동 시 Repository 구현체만 교체할 수 있게 만든다.

## 폴더 구조

```text
lib/
  main.dart
  app/
    fuel_arena_app.dart
    router.dart
    theme.dart
  core/
    constants/
    utils/
    widgets/
    errors/
  design_system/
    app_colors.dart
    app_spacing.dart
    app_radius.dart
    app_typography.dart
    app_shadows.dart
  shared/
    models/
    repositories/
    providers/
    widgets/
  features/
    splash/
      presentation/
    onboarding/
      presentation/
    auth/
      presentation/
      data/
    vehicle/
      presentation/
      data/
    home/
      presentation/
    drive/
      presentation/
      data/
    ranking/
      presentation/
      data/
    battle/
      presentation/
      data/
    season/
      presentation/
      data/
    profile/
      presentation/
      data/
    stats/
      presentation/
      data/
    rewards/
      presentation/
      data/
    ads/
      data/
      presentation/
    premium/
      presentation/
      data/
    sponsor/
      presentation/
      data/
    fairness/
      presentation/
      data/
    settings/
      presentation/
    notifications/
      presentation/
  supabase/
    supabase_client_provider.dart
    auth_service.dart
```

## 상태 관리

`flutter_riverpod`을 사용한다.

- Repository는 Provider로 주입한다.
- 초기 구현은 Mock Repository Provider를 기본값으로 사용한다.
- 화면별 단순 상태는 `StatefulWidget` 또는 `StateProvider`를 사용한다.
- 비동기 데이터는 `FutureProvider`를 우선 사용한다.

## 라우팅

`go_router`를 사용한다.

주요 route:

- `/splash`
- `/onboarding`
- `/login`
- `/vehicle-register`
- `/home`
- `/drive/start`
- `/drive/safety`
- `/drive/result`
- `/premium`
- `/stats`
- `/rewards`
- `/sponsor`
- `/fairness`
- `/settings`

하단 탭은 `MainShellScreen` 내부에서 유지한다.

## 디자인 시스템

Stitch HTML/CSS의 색상과 카드 구조를 Flutter 네이티브 구성요소로 재해석한다.

- `AppColors`: 다크, 네온 그린, 전기 블루, 앰버, 골드, 에러 컬러
- `AppSpacing`: 4/8/16/24/32 기반
- `AppRadius`: 4/8/12/999
- `AppTypography`: 점수, 제목, 본문, 라벨 스타일
- `AppShadows`: 네온 glow와 카드 shadow

## 공통 위젯

공통 위젯은 `shared/widgets`에 둔다. 앱 전반에서 재사용되는 시각 요소는 feature 내부로 숨기지 않는다.

핵심 위젯:

- AppScaffold
- FuelArenaAppBar
- MainBottomNavigation
- PrimaryButton
- SecondaryButton
- AppCard
- SectionHeader
- StatusChip
- TierBadge
- ScoreGauge
- BattleCard
- MissionCard
- SeasonProgressCard
- RivalAlertCard
- DriveResultCard
- RewardCard
- VehicleCard
- ProfileHeader
- SafetyModePanel

## Repository 경계

각 기능은 Interface, Mock 구현체, Supabase mock fallback 구현체를 분리한다.

예:

```dart
abstract class RankingRepository {}
class MockRankingRepository implements RankingRepository {}
class SupabaseRankingRepository implements RankingRepository {}
```

Supabase 전환 시 UI와 Provider 의존성을 최소 변경으로 유지하는 것이 목표다.
