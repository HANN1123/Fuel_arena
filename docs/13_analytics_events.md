# Analytics Events

## 원칙
- 분석 이벤트는 제품 개선용이며 사용자 흐름을 막지 않는다.
- `location`, `latitude`, `longitude`, `drive_points` 키는 저장 전에 제거한다.
- 사용자 속성(`setUserProperty`)도 같은 민감 키를 거부한다.
- 이벤트 payload에는 공개 화면에 노출 가능한 수준의 요약 정보만 남긴다.

## 핵심 이벤트
- `onboarding_completed`: 온보딩 완료
- `google_login_started`: Google 로그인 시도
- `google_login_redirect_started`: Web OAuth 로그인 redirect 시작
- `google_login_succeeded`: Google 로그인 성공
- `consent_completed`: 필수 동의 완료, 선택 동의 여부 포함
- `consent_preferences_updated`: 설정에서 맞춤형 광고/마케팅 동의 변경
- `privacy_request_submitted`: 데이터 다운로드, 삭제, 계정 삭제, 동의 철회 요청 접수
- `drive_started`: 주행 시작, 차량 ID 요약 포함
- `drive_finished`: 주행 종료, 거리/시간 요약 포함
- `report_submitted`: 문의 또는 신고 접수
- `review_request_submitted`: 점수/랭킹/배틀 정산 이의제기 접수
- `battle_settle_requested`: 배틀 결과 화면에서 사용자가 정산 요청 선택
- `battle_settle_succeeded`: 배틀 정산 완료 후 결과 화면 갱신
- `coupon_issue_requested`: 리워드 지갑에서 사용자가 쿠폰 발급 선택
- `coupon_issue_succeeded`: 쿠폰 발급 성공 후 사용자 피드백 표시
- `purchase_verified`: Edge Function 구매 검증 성공
- `set_user_property`: 사용자 속성 변경

## Supabase 테이블
`analytics_events`
- `user_id`: 로그인 사용자, 익명 이벤트는 null 가능
- `event_name`: 이벤트 이름
- `properties`: 위치/좌표 제거 후 저장한 JSON
- `created_at`: 서버 저장 시각

## RemoteConfig
공개 `app_settings`에서 읽는 값은 `AppRemoteConfig.fromSettingsMap`으로 파싱한다. 범위를 벗어난 값은 기본값으로 되돌려 주행 검증과 광고 보상 정책이 비정상 설정에 흔들리지 않게 한다.

- `reward_ad_daily_limit`: 0~20, 기본 3
- `new_user_ad_protection_days`: 0~30, 기본 3
- `official_drive_min_distance_km`: 0.1~50, 기본 1.0
- `official_drive_min_duration_seconds`: 30~7200, 기본 180
- `abnormal_speed_kmh`: 60~300, 기본 180
- `reward_ads_enabled`, `friendly_battle_enabled`, `coupons_enabled`: bool 값

## Structured Logging
앱 시작 시 `FlutterError.onError`, `PlatformDispatcher.instance.onError`, `runZonedGuarded`를 `AppLogger`에 연결한다. 로그는 `developer.log`에 JSON record로 남기며, 주행 포인트 업로드 실패와 주행 완료 Edge Function fallback 같은 운영 이벤트도 같은 포맷을 사용한다.

로그 context는 저장 전에 `sanitizedLogContext`를 통과한다. `latitude`, `longitude`, `location`, `drive_points`, `raw_points`, `access_token`, `refresh_token`, `authorization`, `service_role`, `secret` 계열 키는 재귀적으로 제거하거나 `[redacted]`로 치환한다.

## 확인 항목
- 주행 중에는 이벤트 저장 실패가 UI를 막지 않는지 확인한다.
- 공개 랭킹과 분석 이벤트 모두 정확한 좌표를 포함하지 않는지 확인한다.
- 관리자 대시보드에서 이벤트를 조회하려면 `profiles.is_admin = true` 계정으로 테스트한다.
