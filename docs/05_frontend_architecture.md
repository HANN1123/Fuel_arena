# Frontend Architecture

## 폴더 구조
`lib/app`, `lib/core`, `lib/design_system`, `lib/shared`, `lib/features`, `lib/supabase`로 분리한다.

## 상태 관리
Riverpod Provider와 FutureProvider를 사용한다. 각 repository provider는 AppConfig를 읽고 Supabase 설정이 있으면 Supabase class, 없으면 Mock class를 반환한다.

Supabase 값이 없는 dev mode는 Google OAuth 값이 일부 있어도 MockAuthRepository를 사용한다. production mode는 Supabase와 Google OAuth 값이 모두 있어야 앱이 시작된다.

## 라우팅
go_router가 전체 route를 관리한다. 이전 경로 `/login`, `/vehicle-register`는 새 경로로 redirect한다.

## Repository 패턴
Auth, Vehicle, Drive, Ranking, Battle, Season, Profile, Ads, Premium, Sponsor, Coupon, Notification, Crew, Admin repository를 interface와 구현체로 분리한다.

차량 설정은 VehicleCatalogRepository, UserVehicleRepository, LeagueRepository를 사용한다. vehicleCatalogRepositoryProvider는 제조사/모델/연식/파워트레인 카탈로그를 제공하고, 사용자 화면은 연식 row를 기준 연식 피커로 노출한다. userVehicleRepositoryProvider는 대표 차량과 검증 상태를 저장하며, leagueRepositoryProvider는 활성 연료 리그와 차급 멤버십을 관리한다.

## 에러 처리
dev mode는 mock fallback으로 흐름을 유지한다. production mode에서 Supabase 또는 Google OAuth 설정이 없으면 시작 시 설정 오류 화면을 표시한다.

