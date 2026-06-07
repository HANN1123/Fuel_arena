# Completion Audit

## 현재 완료된 항목
- Flutter + Dart + Riverpod + go_router 구조를 유지하고 `lib/app`, `lib/core`, `lib/shared`, `lib/features`, `lib/supabase`로 책임을 분리했다.
- dev/mock mode는 외부 키 없이 MockRepository로 가입, 동의, 차량 설정, 주행, 점수, 랭킹, 배틀, 시즌, 보상, 광고, 프리미엄, 쿠폰, 신고, 고객지원, 관리자 흐름을 이동할 수 있다.
- production mode는 Supabase URL/anon key 또는 Google client id가 없으면 설정 오류 화면을 표시한다.
- 로그인은 Google CTA 중심이며, 온보딩/동의/권한/차량 설정/홈 라우팅이 연결되어 있다.
- 필수 동의와 설정의 광고/마케팅 동의는 `app_consents` 현재값과 `consent_logs` 감사 로그로 저장된다.
- 사용자 앱 화면은 공통 `AppScaffold.mobileMaxWidth = 430`으로 제한하고, 관리자 대시보드만 `maxWidth: null`로 데스크톱 full width를 사용한다.
- 차량 설정은 제조사, 모델/파생모델, 기준 연식, 엔진·미션 파워트레인 선택과 직접 입력 pending review 흐름을 제공한다.
- 가솔린, 디젤, 하이브리드, 전기차, LPG, 플러그인 하이브리드, 기타 리그와 차급 기반 랭킹/배틀 조건을 모델과 mock data에 반영했다.
- 주행 중 안전 화면은 광고, 팝업, 도전장, 알림을 보류하고, 종료 확인도 팝업 없이 인라인 2단계 버튼으로 처리한다.
- 오프라인 상태, 로컬 큐, 동기화 배너, 활성 주행 세션 복구용 서비스 skeleton을 추가했다.
- 세션 복구 시 Supabase 프로필의 온보딩/동의/차량 설정 완료 상태를 로컬 힌트와 합쳐 OAuth redirect나 새 브라우저 런타임에서도 완료된 가입 단계를 반복하지 않도록 보강했다.
- Splash 세션 복구가 실패해도 로고 화면에 멈추지 않고 오류 안내와 재시도 버튼을 표시한다.
- 알림 센터는 읽음 처리, 전체 읽음, target route 이동, 주행 중 보류 표시를 지원한다.
- 고객지원, 신고, 개인정보 요청, 공정성 센터, 접근성/성능/분석/RLS 문서를 추가했고 신고 카테고리는 `report_items` 운영 테이블까지 생성한다.
- 고객지원은 문의 목록, 상세, 사용자 추가 메시지, 관리자 답변, 처리 상태 변경까지 `support_tickets`/`support_ticket_messages`로 연결한다.
- 개인정보 요청은 설정 화면에서 데이터 다운로드, 데이터 삭제, 계정 삭제를 `privacy_requests`로 접수하고 관리자 상태 처리 흐름으로 연결한다.
- 동의 철회 요청도 같은 `privacy_requests` 흐름으로 접수해 관리자 검토 큐에서 처리한다.
- 관리자 대시보드는 운영 섹션, 사이드바, 상단바, metric, 검색, 필터, 상태 badge, 차트, data table, action menu를 갖춘 full-width 운영 화면으로 보강했다.
- 관리자 운영 목록은 `AdminRecordPage` 기반 pagination과 상세 drawer를 제공하며 Supabase range query와 mock fallback을 함께 지원한다.
- 관리자 metric card는 Supabase 설정 시 `get_admin_dashboard_metrics` RPC로 실제 운영 집계를 읽고, dev/mock mode에서는 mock 지표로 동작한다.
- 관리자 action menu는 `admin_action_logs`에 운영 액션 요청을 기록하고 Admin Actions 섹션에서 조회한다.
- 관리자 차량 카탈로그 화면(`/admin/vehicles`)과 직접 입력 차량 검수 Edge Function 흐름을 추가했다.
- Supabase migration은 support tickets/messages, app settings, analytics events, sync logs, vehicle catalog change logs, consent logs, release notes, RLS, seed를 포함한다.
- Edge Functions는 CORS, 공통 JSON 응답, 표준 error shape, 문자열/숫자 validation helper를 공유하며, Web idempotency 요청을 위해 `x-idempotency-key` preflight header를 허용한다.
- 주행 종료는 `finish_drive_session` Edge Function을 통해 private `drive_points`를 서버에서 재검증한 뒤 `drive_sessions`, `drive_scores`를 확정하고, `verified` 점수만 `profiles.season_score`에 누적한다.
- verified 점수는 `ranking_update_jobs`에 큐잉되고 같은 기간의 active job은 하나로 합쳐진다. `update_rankings`는 `recompute_rankings` DB function을 호출해 기간별 랭킹을 트랜잭션으로 재계산한다.
- 보상, 쿠폰, 미션, 배틀 정산 계열 Edge Function은 `edge_function_idempotency_keys`에 사용자별 idempotency key와 응답을 저장하고, 각각 `ad_rewards`, `mission_progress`, `user_coupons`, `battle_participants`/`battles`를 실제 갱신한다.
- Android 표준 scaffold, v2 embedding `MainActivity`, manifest 권한/AdMob placeholder, OAuth callback intent filter, core library desugaring 설정을 추가했다.
- iOS 표준 Flutter scaffold(`Runner.xcodeproj`, `Runner.xcworkspace`, AppDelegate, storyboard, asset catalog, tests)를 생성하고 기존 Fuel Arena `Info.plist` 권한/OAuth/AdMob 설정을 표준 bundle/version/launch key와 합쳤다. `FuelArenaSecrets.xcconfig.example`와 optional include를 추가해 Xcode build setting 주입 경로를 분리했다.
- 차량 카탈로그 dev/mock seed asset은 22개 제조사, 164개 모델, 2008-2026 범위의 실제 판매 연식 조합 3098개, 파워트레인 variant 5079개를 포함한다.
- 차량 설정의 기준 연식 단계는 연식 칩 그리드 대신 하단 피커/스크롤 리스트로 바꿨고, 사용자 화면은 계속 430px 모바일 폭 안에서 동작한다.
- GitHub Actions `flutter_ci.yml`로 catalog validation, format, analyze, test, Android debug build, web build를 실행한다.

## 이번 작업에서 보강한 항목
- `lib/features/admin/presentation/admin_widgets.dart`를 추가해 대시보드 공통 운영 컴포넌트를 분리했다.
- `AdminDashboardScreen`을 full-width `AdminScaffold` 기반으로 전환하고 프롬프트의 운영 섹션을 반영했다.
- Supabase Edge Function 14개가 `handleOptions`, `jsonResponse`, `errorResponse`, `toEdgeFunctionError`, validator helper를 사용하도록 표준화했다.
- `send_notification`은 로그인 사용자 또는 관리자 대상 사용자 알림을 `notifications`에 저장하고, `isDriving` 요청은 `held_during_drive`로 기록해 주행 중 노출 금지 정책을 유지한다.
- `vehicle_catalog_change_logs` 컬럼과 `review_custom_vehicle` insert를 `before_data`/`after_data`로 정렬했다.
- 업로드 실패한 `drive_points` batch를 offline queue에 저장하고 온라인 복귀 후 성공 항목만 제거하는 동기화 경로를 추가했다.
- 오프라인에서 주행을 시작하면 `local-drive-*` 세션을 큐에 저장하고, 온라인 복귀 시 서버 `drive_sessions` row를 먼저 생성한 뒤 같은 큐의 `drive_points`를 서버 세션 ID로 재매핑해 업로드한다.
- 서버 세션 업로드 후 포인트 업로드가 실패해도 로컬 세션 ID 매핑을 `offline_drive_session_id_map`에 보존해 다음 동기화에서 같은 포인트 batch가 서버 세션 ID로 재시도된다.
- 온라인 복귀 동기화는 각 queue item의 성공/실패를 `user_local_sync_logs`에 기록한다. 로그에는 item 타입, item ID, 상태, 안전하게 축약된 오류 메시지만 남기며 좌표/raw payload는 기록하지 않는다.
- 손상된 `drive_points` payload와 지원하지 않는 legacy queue item은 `discarded` sync log로 남긴 뒤 queue에서 제거해 무한 재시도와 업로드 성공 오인을 막는다.
- 로컬 `offline_queue` 저장 문자열이 JSON으로 파싱되지 않으면 원본을 `offline_queue_corrupt_backup`에 격리하고 queue를 초기화한다. 일부 row만 손상된 경우 정상 item은 보존하고 손상 원본만 백업한다.
- Supabase `drive_points.id`는 uuid이므로 앱이 만든 로컬 `drive-point-*` ID를 서버 insert payload에서 제외하고 DB가 uuid를 생성하도록 보강했다.
- Flutter 3.44 기준 deprecation lint를 정리해 `flutter analyze`가 통과하도록 했다.
- Android debug APK 빌드를 위해 생성 누락 Android scaffold와 desugaring 설정을 보완했다.
- Android release signing을 `android/key.properties` 기반으로 분리하고, 실제 keystore 또는 production `ADMOB_ANDROID_APP_ID` 설정 없이 release build가 생성되지 않도록 명확한 Gradle 실패 메시지를 추가했다.
- 차량 직접 입력 화면과 `custom_vehicle_requests` migration/RLS를 추가했다.
- 차량 catalog import/validate tool과 production runbook을 추가했다.
- `drive_points.is_mocked`, GPS point filtering, `drive_scores` 세션별 중복 방지 migration을 추가했다.
- 주행 준비 화면은 대표 차량/오늘의 미션/위치 권한 readiness Future를 차량 ID 기준으로 고정해 build마다 새 Future를 만들지 않으며, 실패 시 로딩 스켈레톤에 머물지 않고 재시도 가능한 오류 상태를 표시한다.
- 사용자 화면에 노출되던 개발용 `mock` 표현, `준비 중`, `임시 저장` 문구를 제품 언어로 정리했다.
- 설정의 로그아웃은 인증 세션과 사용자별 로컬 동의/차량/랭킹/주행/결과 힌트를 함께 정리한다.
- 로그아웃은 `offline_queue`, `offline_drive_session_id_map`, `offline_queue_corrupt_backup`도 함께 정리해 이전 사용자의 로컬 주행 포인트 payload나 복구 백업이 다음 세션에 남지 않게 한다.
- 안전 모드 설정은 주행 중 알림 보류, 광고 차단, 자동 안전 모드를 고정 보호 정책으로 유지하고, 종료 확인 설정만 저장한다.
- 차량 관리는 보유 차량 목록, 대표 차량 지정, 대표 차량 삭제를 실제 repository mutation으로 처리하고 변경 후 리그/홈/프로필 상태를 갱신한다.
- 배틀 상세/결과는 URL의 `battleId`로 단일 배틀을 조회하고, dev/mock mode에서 생성한 배틀도 상세 화면으로 이어지도록 mock 저장소 상태를 유지한다.
- 배틀 결과의 미정산 상태는 `settle_battle` Edge Function 호출과 mock 정산 상태 갱신으로 연결하고, 성공 후 상세/목록 provider와 analytics 이벤트를 갱신한다.
- 공개 운전자 프로필은 `public_rankings`의 공개 필드만 사용하고, 이메일/정확한 위치/상세 경로/raw drive_points를 노출하지 않도록 실제 화면과 테스트로 고정했다.
- 전역 Flutter/Platform/Zone 오류와 주행 완료 fallback은 `AppLogger` 구조화 로그로 남기며, 로그 context에서 좌표, raw drive_points, 토큰, service role, secret 계열 키를 제거한다.
- 주행 결과 확정 fallback은 dev/staging에서만 허용하고, production에서는 `finish_drive_session` 검증 실패 또는 공식 세션 누락 시 mock 점수를 반환하지 않고 재시도 오류로 남긴다.
- 프리미엄 활성화 fallback도 dev/staging에서만 허용하고, production에서는 스토어/IAP 검증 없이 mock premium을 활성화하지 않는다.
- 리워드 광고 보상은 production에서 광고 시청 검증 없이 `grant_ad_reward`를 직접 호출하지 않으며, 검증 실패 시 기본 보상 유지 안내로 복구한다.
- 온보딩의 영어 CTA를 한국어 문구로 정리했다.
- 356/390px 좁은 viewport, 430px 최대 폭, 1920px 데스크톱 미리보기에서 사용자 앱이 모바일 폭으로 제한되는지와 app bar/bottom bar 제한, 하단 5개 탭 표시, 관리자 full-width shell을 위젯 테스트로 고정했다.
- `AppLayout`, `AppIconSize`, `AppCardSize`, `AppButtonHeight` 토큰과 compact manufacturer card를 추가하고, core route smoke 테스트로 주요 사용자 URL이 router를 통해 본문을 렌더링하는지 고정했다.
- Deno 없이도 Edge Function 공통 CORS/응답/error/idempotency 구조와 `x-idempotency-key` CORS 허용 여부를 검사하는 `tool/validate_edge_functions.dart` smoke validator를 추가하고 CI에 연결했다.
- Supabase migration 묶음의 필수 테이블, RLS, 정책, public view privacy, RPC 보안 속성, Edge 전용 RPC 권한, 중복 방지 index를 검사하는 `tool/validate_supabase_schema.dart`를 추가하고 CI에 연결했다.
- service role 비밀값, `.env` 번들링 차단, 사용자 화면 폭 제한, AppScaffold 우회 방지, 사용자 presentation/widget placeholder 문구 방지, 사용자 주요 화면 빈 상태 복구 CTA, 공개 화면 좌표/raw drive_points 노출 방지, 비현금 배틀 보상, analytics 민감 키 제거, 구조화 로그 민감 키 제거, 공개 랭킹 privacy, drive_points RLS, 플랫폼 권한, Android release signing/AdMob gate, CI 명령, 릴리스 문서, runbook Edge Function deploy 목록과 환경 변수 템플릿을 검사하는 `tool/validate_product_invariants.dart`를 추가하고 CI에 연결했다.
- product invariant validator는 runtime fallback 차량 카탈로그와 mock 가입 흐름이 현재 아반떼 2026 파워트레인 ID를 쓰는지도 검사해, 오래된 `variant-avante-2024-*` 데이터가 다시 들어오지 못하게 한다.
- 직접 의존성의 `any` 버전 범위를 lockfile 기준 caret range로 고정하고, product invariant validator가 `pubspec.yaml`의 `any` 재도입을 막도록 보강했다.
- Android 13+ 알림 권한 `POST_NOTIFICATIONS`와 OAuth callback intent filter를 manifest에 추가하고, Android/iOS 권한, iOS secret xcconfig, OAuth/AdMob plist placeholder 선언을 product invariant validator로 검증한다.

## 남은 외부 연동 확인
- Supabase CLI가 로컬 PATH에 없어 migration push, seed 적용, Edge Function deploy/serve는 실행하지 못했다.
- Deno가 로컬 PATH에 없어 Edge Function 타입 체크와 로컬 serve 검증은 실행하지 못했다.
- Google OAuth client, Android SHA-1/SHA-256, iOS URL scheme, AdMob live id, Play/App Store IAP, Supabase production secrets는 외부 콘솔에서 확인해야 한다.
- 실제 결제 검증은 `verify_purchase`가 provider API를 호출하고 서버 소유 Google Play package name과 App Store Bundle ID secret만 사용하도록 보강했다. 남은 확인은 Play/App Store sandbox에서 실제 상품, 복원, 만료, 환불 케이스를 검증하는 것이다.
- Android release build는 debug signing과 테스트 AdMob App ID를 사용하지 않으며, 출시 전 `android/key.properties`, 실제 upload keystore, production `ADMOB_ANDROID_APP_ID` 설정이 필요하다.
- Android debug build는 통과하지만 `geolocator_linux -> package_info_plus 10.1.0` 경로의 upstream Android Gradle script가 Kotlin Gradle Plugin을 직접 적용해 Flutter의 Built-in Kotlin 전환 경고가 남아 있다.

## 검증 결과
- `flutter pub get`: 통과.
- `dart format`: 변경 파일 기준 통과.
- `flutter analyze`: 통과, No issues found.
- `dart run tool/validate_vehicle_catalog.dart`: 통과, 22 manufacturers / 164 models / 3098 years / 5079 variants.
- `dart run tool/validate_edge_functions.dart`: 통과, 14 functions / 266 checks.
- `dart run tool/validate_supabase_schema.dart`: 통과, 297 checks.
- `dart run tool/validate_product_invariants.dart`: 통과, 1613 checks.
- `flutter test`: 통과, 191 tests passed.
- `flutter build apk --debug`: 통과, `build/app/outputs/flutter-apk/app-debug.apk` 생성.
- `flutter build apk --release`: keystore/production AdMob 미설정 상태에서 의도대로 실패, `android/key.properties`와 `ADMOB_ANDROID_APP_ID` 필요 메시지 확인.
- `flutter build web`: 통과, `build/web` 생성.
- `python tool/verify_web_render.py`: 통과, 390x844 screenshot에서 본문 UI 렌더링 확인.
- `python tool/validate_release_environment.py`: valid/invalid sample env 기준 동작 확인.
- `python tool/validate_store_submission_assets.py`: 통과, store submission assets valid.
- `python tool/validate_store_privacy_disclosures.py`: 통과, store privacy disclosures valid.
- `python tool/run_local_release_gate.py --quick`: 통과, validator/format/analyze/test와 release env example placeholder 거부 빠른 릴리즈 게이트 확인.
- `python tool/run_local_release_gate.py`: 통과, Android debug build, Web/Wasm build, Web smoke까지 로컬 릴리즈 게이트 확인.
## Production User Data Fallback
- production에서는 Supabase 인증 또는 사용자 row 조회 실패 시 mock 프로필/통계가 표시되지 않는다. 사용자별 프로필/통계 fallback은 dev/staging에서만 허용한다.
## Latest Verification Snapshot
- `dart run tool/validate_product_invariants.dart`: 1613 checks passed.
- `flutter test`: 191 tests passed.

## Web Host Viewport Guard
- `web/index.html`에서 `html`, `body`, `flutter-view`, `flt-glass-pane`를 `100vw/100vh`와 `overflow: hidden`으로 고정해 Flutter Web 루트가 브라우저 viewport보다 넓게 잡히는 캡처/좁은 창 회귀를 방지한다.
- `tool/validate_product_invariants.dart`는 viewport meta뿐 아니라 Flutter Web host CSS 토큰까지 검사한다.
- `dart run tool/validate_product_invariants.dart`: 1613 checks passed.

## Staging Runtime Policy
- staging/production은 Supabase URL과 anon key가 없으면 설정 오류로 막고, mock repository 실행은 dev mode에서만 허용한다.
