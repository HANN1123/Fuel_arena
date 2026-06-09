# 구글 로그인 및 세션 장애 대응 트러블슈팅 가이드 (Google Auth Troubleshooting)

본 가이드는 Fuel Arena 운영 전환 및 연동 중 발생할 수 있는 주요 로그인/인증 에러 케이스와 해결 조치법을 담고 있습니다.

---

## 1. Google Native Sign-In에서 `idToken`이 null로 획득됨
- **증상**: 구글 로그인창에서 계정을 선택했으나, `idToken`이 비어 있어 Supabase 로그인을 시작하지 못함.
- **주요 원인 및 해결책**:
  - `google_sign_in` 객체 초기화 시 `serverClientId` 매핑이 누락되었거나 다른 클라이언트 ID가 들어갔을 가능성이 큽니다.
  - Android 및 iOS 네이티브 SDK 호출 시 반드시 **Web Client ID**를 `serverClientId` 인자로 넘겨주어야 구글 인증서버에서 서명된 `idToken`을 반환합니다.
  - [repository_providers.dart](file:///c:/Users/yjje1/Documents/GitHub/Fuel_arena/lib/shared/providers/repository_providers.dart)의 `SupabaseGoogleAuthRepository` 인스턴스화 시 환경별 `googleWebClientId`가 주입되는지 확인합니다.

---

## 2. `accessToken`이 null로 반환됨
- **증상**: Supabase 연동에 필요한 `accessToken`이 반환되지 않음.
- **해결책**:
  - Supabase `signInWithIdToken` API 규격에서는 구글의 `accessToken`이 필수가 아닙니다. 구글에서 받은 `idToken`만으로 JWT 인증 처리가 완료되므로 `idToken` 획득 여부를 우선 순위로 점검합니다.

---

## 3. Supabase Auth error (인증 실패)
- **증상**: 구글 인증서버 동의는 완료되었으나, Supabase REST API(`signInWithIdToken`) 호출 시 `Invalid ID Token` 혹은 `400 Bad Request` 에러 발생.
- **해결책**:
  - Supabase Dashboard -> **OAuth Providers** -> **Google**에 등록된 **Client ID**가 구글 클라우드 콘솔의 **Web Client ID**와 일치하는지 확인합니다. (Android/iOS 클라이언트 ID를 잘못 등록하면 토큰 Audience 불일치로 검증에 실패합니다)
  - Google Client Secret에 빈칸이나 특수문자 오탈자가 포함되지 않았는지 점검합니다.

---

## 4. Android 기기에서만 로그인이 실패함
- **증상**: iOS는 로그인에 성공하나, Android 에뮬레이터나 실기기에서는 버튼 클릭 후 튕기거나 실패 에러 발생.
- **해결책**:
  - Android 빌드 서명인 **SHA-1 지문** 등록 상태를 반드시 재검사해야 합니다. 
  - 개발 중인 경우 디버그용 `debug.keystore` SHA-1 지문이 구글 클라우드 콘솔 Android 클라이언트 정보에 매핑되어 있어야 합니다.
  - 플레이 스토어 배포본의 경우 **Google Play Console의 앱 서명 지문**이 추가로 등록되어야 합니다.

---

## 5. iOS 기기에서만 로그인이 실패함
- **증상**: iOS에서 로그인 버튼 클릭 시 동의 창이 떴다가 계정을 누르면 진행이 멈추거나 바로 튕김.
- **해결책**:
  - [Info.plist](file:///c:/Users/yjje1/Documents/GitHub/Fuel_arena/ios/Runner/Info.plist)의 `CFBundleURLSchemes` 항목에 **iOS Reversed Client ID** (`com.googleusercontent.apps.xxxx`)가 올바른 형식으로 누락 없이 바인딩되어 있는지 점검합니다.

---

## 6. Production/Staging 모드인데 Mock Login 버튼이나 배지가 보임
- **증상**: 운영/스테이징 환경인데 Mock 로그인 화면이 나타남.
- **해결책**:
  - `.env` 파일의 `APP_ENV` 값이 `production` 혹은 `staging`으로 설정되어 있는지 다시 점검합니다.
  - `STAGING_ALLOW_MOCK_AUTH` 환경 변수가 `false`로 격리되어 있는지 점검하십시오.
  - [app_config.dart](file:///c:/Users/yjje1/Documents/GitHub/Fuel_arena/lib/app/app_config.dart)의 `canUseMockAuthRepository` 로직을 상향하고 빌드 무결성 도구인 `check_google_auth_env.dart`를 실행하여 오류를 색출합니다.

---

## 7. 로그인 성공 후 Profile 테이블에 row가 생성되지 않음
- **증상**: 로그인은 정상 처리되었으나, 프로필 설정 화면 진입 시 사용자 정보를 불러올 수 없다는 에러 발생.
- **해결책**:
  - Supabase Database의 `public.profiles` 생성 트리거 마이그레이션이 성공적으로 수행되었는지 점검합니다.
  - `auth.users`에 신규 유저가 생성될 때 DB가 트리거 오류로 트랜잭션을 롤백했는지 봅니다. (Supabase DB Logs -> Postgres logs 점검)

---

## 8. 로그인 후 온보딩/차량 설정 라우팅이 이상함
- **증상**: 로그인 후 매번 동의 화면(`/consent`)이나 차량 설정 화면(`/setup`)으로 가며 메인 화면으로 진입하지 못함.
- **해결책**:
  - 로그인 성공 시 반환되는 `UserProfile`의 `consentCompleted` 및 `vehicleSetupCompleted` 플래그가 `true`인지 확인합니다.
  - 데이터베이스의 profiles 테이블 레코드 컬럼이 갱신되지 않았다면 DB Update 쿼리가 정상인지 RLS Update 정책을 검토합니다.

---

## 9. 로그아웃 완료 후 다시 홈 화면으로 자동 재진입됨
- **증상**: 로그아웃 후 로그인 화면으로 갔다가 즉시 다시 메인 홈 화면으로 리다이렉트됨.
- **해결책**:
  - `GoRouter` 인스턴스에 전달되는 `refreshListenable`에서 캐시된 이전 세션 스트림이 즉시 초기화(`ref.invalidate`)되지 않았거나, 비동기 세션 정리가 완전히 끝나기 전에 라우팅이 실행되었기 때문입니다.
  - 로그아웃 처리 메서드 내부에서 `invalidateUserScopedSessionProviders(ref)`가 즉각 동작하는지 재확인합니다.

---

## 10. ConfigErrorScreen이 너무 많은 정보를 노출함
- **증상**: 설정 오류 발생 시 화면에 민감한 API Key나 URL 문자열 전체가 그대로 드러남.
- **해결책**:
  - [config_error_screen.dart](file:///c:/Users/yjje1/Documents/GitHub/Fuel_arena/lib/core/widgets/config_error_screen.dart)는 `config.isProduction`인 경우 `showDebugPanel` 플래그를 자동으로 `false` 처리하여 민감 정보를 원천 차단합니다.
  - [safe_logger.dart](file:///c:/Users/yjje1/Documents/GitHub/Fuel_arena/lib/core/utils/safe_logger.dart)를 통해 출력값을 항상 1차 마스킹 통제하고 있는지 다시 점검하십시오.
