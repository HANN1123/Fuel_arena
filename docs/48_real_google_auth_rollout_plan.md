# 실제 Google 로그인 운영 전환 롤아웃 계획 (Real Google Auth Rollout Plan)

본 문서는 Fuel Arena의 Google-only 로그인을 실제 운영 환경(Production) 및 스테이징(Staging) 환경으로 안전하고 매끄럽게 전환하기 위한 마스터 롤아웃 계획서입니다.

---

## 1. 현재 코드 구현 상태
현재 Fuel Arena Flutter 클라이언트 및 Supabase 백엔드는 실제 Google 로그인 운영 전환을 위한 모든 준비를 갖추고 있습니다:
- **Google-only 로그인 UI**: 로그인 화면에 비밀번호/이메일 입력란이 전혀 없고, Google 시작하기 버튼만 노출됩니다.
- **google_sign_in 7.x + Supabase signInWithIdToken 연동**: Web, Android, iOS 플랫폼에서 Google Native Auth SDK를 통해 발급받은 `idToken`을 Supabase Auth 서비스에 안전하게 주입해 인증 세션을 시작합니다.
- **개발 환경 Mock Auth Fallback**: 개발 환경(`APP_ENV=dev`)에서는 Supabase 또는 Google 클라이언트 ID 설정이 누락되더라도 모의 인증(Mock)으로 전환되어 기획 동작을 테스트할 수 있습니다.
- **Staging/Production 설정 검증**: 빌드 시 환경변수가 누락되거나 형식이 맞지 않는 경우, 앱 진입이 `ConfigErrorScreen`으로 완전히 차단됩니다.
- **자동 프로필 생성 Trigger**: Supabase 데이터베이스 마이그레이션을 통해 `auth.users` 테이블에 새 행이 삽입되면 `public.profiles` 테이블의 레코드가 자동으로 생성 및 동기화됩니다.

---

## 2. 실제 외부 콘솔에서 설정해야 하는 항목
실제 Google 로그인이 동작하려면 다음의 두 가지 콘솔 연동이 선행되어야 합니다:
1. **Google Cloud Console (Credentials)**
   - OAuth 동의 화면(Consent Screen) 구성 (앱 이름, 지원 이메일 등 등록)
   - 각 플랫폼별 OAuth Client ID 생성:
     - **Web Client ID**: Supabase Auth와 구글 서버 간 검증의 핵심 키로 사용됩니다.
     - **Android Client ID**: Android 앱의 패키지명(`com.fuelarena`) 및 디버그/릴리즈 SHA-1 서명 지문을 입력해 발급받습니다.
     - **iOS Client ID**: iOS 번들 ID(`com.fuelarena`)를 입력해 발급받습니다.
     - **Server Client ID** (필요시): 백엔드 API 연동용.
2. **Supabase Dashboard (Authentication > Providers > Google)**
   - Google Auth Provider 활성화 (Enabled)
   - Google Web Client ID 및 Client Secret 등록 (Supabase가 Google OAuth의 토큰 서명을 검증하는 데 필수)
   - Authorized redirect URI 복사 후 Google Cloud Console의 OAuth Web Client 설정에 추가

---

## 3. dev/staging/production별 인증 동작 방식
| 환경 (`APP_ENV`) | Supabase/Google 설정 누락 시 동작 | Mock Auth 가능 여부 | 디버그 패널 노출 여부 |
| :--- | :--- | :--- | :--- |
| **dev** | Mock Auth로 자동 Fallback | **가능** (로컬 개발용) | 노출 (`showDebugPanel=true`) |
| **staging** | `ConfigErrorScreen`으로 차단 | `STAGING_ALLOW_MOCK_AUTH=true`인 경우에만 예외 허용 | 노출 (`showDebugPanel=true`) |
| **production** | `ConfigErrorScreen`으로 차단 | **절대 불가능 (보안 필수)** | 비노출 (`showDebugPanel=false`) |

---

## 4. 실제 Google 로그인 검증 절차
1. **설정값 주입**: 환경별 `.env` 파일에 각 콘솔에서 발급한 값을 정확히 주입합니다.
2. **정적 검사 스크립트 실행**:
   - `dart run tool/auth/check_google_auth_env.dart --env staging`
   - `dart run tool/auth/check_auth_routes.dart`
   - `dart run tool/auth/check_auth_logs.dart`
3. **앱 기동**: 에뮬레이터 또는 실기기를 연결하고 `flutter run --dart-define=APP_ENV=staging` 명령으로 구동합니다.
4. **인증 화면 진단**: 설정 > '개발자 인증 진단' 타일을 클릭하여 주입된 클라이언트 ID가 안전하게 마스킹되어 정상 주입되었는지 확인합니다.
5. **로그인 플로우**: Google로 로그인 버튼을 누르고 실기기 구글 어카운트를 선택하여 Supabase 세션 수립 및 프로필 동기화 여부를 확인합니다.

---

## 5. Android 검증 절차
자세한 내용은 [Android 구글 로그인 체크리스트](file:///c:/Users/yjje1/Documents/GitHub/Fuel_arena/docs/49_android_google_login_checklist.md)를 참고하십시오.
1. `gradlew signingReport`를 실행해 디버그/릴리즈 SHA-1 및 SHA-256 서명 지문을 추출합니다.
2. Google Cloud Console에 Android OAuth Client ID를 생성하고 패키지명(`com.fuelarena`)과 SHA-1 지문을 정확하게 매핑합니다.
3. 구글 로그인 시 `idToken`이 Null로 반환되거나 `12500` API 에러가 나면 SHA-1 지문과 패키지명의 대소문자가 정확히 매핑되었는지 재확인합니다.

---

## 6. iOS 검증 절차
자세한 내용은 [iOS 구글 로그인 체크리스트](file:///c:/Users/yjje1/Documents/GitHub/Fuel_arena/docs/50_ios_google_login_checklist.md)를 참고하십시오.
1. iOS Bundle ID (`com.fuelarena`)를 사용해 Google Cloud Console에서 iOS OAuth Client ID를 생성합니다.
2. `Info.plist`의 URL Types에 `Reversed Client ID`를 스키마 형태로 추가합니다.
3. 시뮬레이터 및 iPhone 실기기에서 `google_sign_in`을 호출해 iOS Native UI 동의 화면 및 콜백 동작을 검증합니다.

---

## 7. Web 검증 절차
1. Google Cloud Console의 OAuth Web Client ID 설정의 **승인된 JavaScript 원본(Authorized JavaScript Origins)**에 개발 주소(`http://localhost:5000` 등)와 실서비스 호스트 주소를 추가합니다.
2. **승인된 리디렉션 URI(Authorized redirect URIs)**에 Supabase Auth callback URL(`https://<project-ref>.supabase.co/auth/v1/callback`)을 입력합니다.
3. `flutter build web` 후 로컬 웹 서버에서 로그인 기능을 검증합니다.

---

## 8. Supabase Dashboard 설정 확인 항목
자세한 내용은 [Supabase 설정 검증 체크리스트](file:///c:/Users/yjje1/Documents/GitHub/Fuel_arena/docs/51_supabase_google_provider_checklist.md)를 참고하십시오.
- **Provider Status**: Google OAuth 활성화 확인
- **Credentials**: Client ID와 Client Secret의 공백 문자 포함 여부 확인
- **Site URL & Redirect Allow-list**: `fuelarena://login-callback` 스키마가 승인 목록에 포함되었는지 확인

---

## 9. 실패 시 디버깅 순서
1. **로깅 확인**: 터미널 또는 IDE 콘솔 출력을 모니터링하여 로그 확인. 단, 토큰 문자열 자체는 노출되지 않아야 합니다.
2. **에러 코드 식별**: 구글 SDK 에러 코드(`12500`, `7` 등)가 발생하는지 확인.
3. **네트워크 디버그**: Supabase REST API(`auth/v1/token?grant_type=id_token`) 요청의 페이로드 및 응답 상태 코드를 분석합니다.

---

## 10. 보안상 절대 노출하면 안 되는 값
다음 값들은 빌드 설정 파일, 소스코드, 디버그 화면, 클립보드 복사 결과물 등 어디에도 **평문으로 절대 노출되거나 커밋되면 안 됩니다**:
- Google OAuth **Client Secret** (구글 클라우드에서 발급한 비밀번호)
- Supabase **service_role key** (RLS 보안 정책을 무시하고 전체 DB를 조작할 수 있는 슈퍼 어드민 키)
- 사용자 **idToken**, **accessToken**, **refreshToken**

---

## 11. 이번 작업에서 코드로 보강한 항목
- **Staging Mock 제어 옵션**: `.env`에 `STAGING_ALLOW_MOCK_AUTH=true/false` 설정을 분리하여, 운영으로 전환되기 전 스테이징에서도 안전하게 목업 테스트를 할 수 있도록 차단 해제 장치를 구현했습니다.
- **개발자 인증 진단 화면 추가**: 주입된 설정 정보를 실시간으로 확인하면서도 핵심 토큰과 클라이언트 ID의 중요 구간은 마스킹하여 보안 노출을 완벽하게 예방했습니다.
- **자동 검증 CLI 스크립트 3종 세트**: `.env` 위생 검사, 소스코드의 원시 토큰 print 차단 검사, 로그인 화면 내 email/password UI 잔재 검사를 자동화했습니다.
- **단위/위젯 보안 테스트 보강**: Production 환경에서 Mock Auth 레포지토리가 사용되는 시도를 사전에 탐지하고 차단하는 테스트를 추가했습니다.

---

## 12. 외부 설정이 필요해서 코드로 처리할 수 없는 항목
- **Google Cloud OAuth Client ID/Secret 신규 발급**
- **Supabase Dashboard Google Provider 토큰 설정 및 RLS Policy 튜닝**
- **Google Play App Signing 지문 매핑** (Play 스토어 등록 단계)
- **Apple Developer Portal iOS URL Schemes 및 Deep link 설정**
