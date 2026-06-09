# Android 구글 로그인 체크리스트 및 검증 가이드 (Android Google Sign-In Checklist)

Android 플랫폼에서 실제 Google OAuth 로그인을 활성화하고 세션을 수립하기 위한 연동 가이드입니다.

---

## 1. Android applicationId 확인 위치
- **파일명**: [build.gradle](file:///c:/Users/yjje1/Documents/GitHub/Fuel_arena/android/app/build.gradle)
- **내용**: `defaultConfig` 블록 아래의 `applicationId` 값을 확인합니다.
  ```groovy
  defaultConfig {
      applicationId "com.fuelarena"
      ...
  }
  ```
- **주의**: Google Cloud Console의 패키지 이름 등록 값과 이 `applicationId`가 대소문자까지 한 글자도 틀림없이 정확히 일치해야 합니다.

---

## 2. Debug SHA-1 및 SHA-256 확인 명령
로컬 개발 및 에뮬레이터 검증 시 사용되는 디버그 키용 서명 지문입니다.

### 자동 추출 도구 실행
로컬 환경에 Java 및 Gradle이 설정되어 있다면 다음 자동 도구로 지문을 손쉽게 추출할 수 있습니다:
```bash
dart run tool/auth/android_oauth_checklist.dart
```

### 수동 명령 실행 (Keytool)
- **Windows**:
  ```cmd
  keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore -storepass android
  ```
- **Mac / Linux**:
  ```bash
  keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android
  ```

---

## 3. Release Keystore SHA-1 확인 방법
앱 스토어 배포용 빌드(Release APK/AAB)를 서명하는 Keystore 파일의 서명 지문입니다.
```bash
keytool -list -v -alias <your-release-key-alias> -keystore <path-to-production-keystore>
```

---

## 4. Google Play App Signing SHA-1 확인 위치
구글 플레이 콘솔을 통해 앱을 서명하여 배포하는 경우, 로컬 릴리즈 키 외에 Google Play가 관리하는 서명 키의 지문도 함께 등록해야 로그인 에러가 발생하지 않습니다.
- **확인 위치**: Google Play Console -> (앱 선택) -> **설정 (Setup)** -> **앱 무결성 (App Integrity)**
- **복사 항목**: **앱 서명 키 인증서 (App signing key certificate)**의 **SHA-1 인증서 지문**

---

## 5. Google Cloud Console Android OAuth Client ID 생성 방법
1. **Google Cloud Console**의 [사용자 인증 정보] 페이지로 이동합니다.
2. [+ 사용자 인증 정보 만들기] -> **OAuth 클라이언트 ID**를 선택합니다.
3. 애플리케이션 유형을 **Android**로 설정합니다.
4. 이름을 입력하고(예: `Fuel Arena Android Staging`), 패키지 이름(`com.fuelarena`)을 입력합니다.
5. 위에서 구한 **SHA-1 서명 지문**을 붙여넣기하고 **만들기**를 누릅니다.

---

## 6. 패키지명과 SHA-1 불일치 시 증상
- 구글 로그인 버튼 클릭 시 동의 팝업이 뜨자마자 즉시 사라지거나 아무 반응이 없음.
- 디버그 콘솔에 `PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10, ...)` 또는 `ApiException: 12500` 오류가 출력됨.
- 로그캣(Logcat)에 `GoogleSignIn: Sign in failed with status code 10` 또는 `12500` 에러가 표시됩니다.

---

## 7. Supabase Google Provider와 Web Client ID 관계
> [!IMPORTANT]
> **Android 네이티브 로그인 시에도 Supabase Dashboard에는 Web Client ID를 등록해야 합니다.**
> Android 네이티브 SDK가 발급한 `idToken`의 대상 고객(Audience) 필드는 **Web Client ID**를 기준으로 구글 서버와 통신하므로, Supabase Google Provider 설정에 Android Client ID가 아닌 **Web Client ID**와 **Web Client Secret**을 입력해야 올바르게 JWT 검증이 완료됩니다.

---

## 8. Android Emulator / 실기기 테스트 절차
1. 에뮬레이터 또는 실기기에 구글 플레이 서비스가 활성화되어 있고, 구글 계정이 최소 1개 이상 로그인되어 있는지 확인합니다.
2. 터미널에서 다음 명령으로 앱을 실행합니다:
   ```bash
   flutter run --dart-define=APP_ENV=staging
   ```
3. 로그인 버튼을 누르고 구글 계정 동의 팝업을 거쳐 정상 로그인 및 메인 화면 진입 여부를 검증합니다.

---

## 9. 로그인 실패 시 확인할 로그
- **Logcat 필터링**: `GoogleSignIn` 혹은 `AuthRepository`
- **검색 키워드**: `ApiException`, `status code`, `sign_in_failed`
- **체크 대상**:
  - `google-services.json` 내부의 `client_id`가 충돌하는 경우
  - 패키지명 또는 SHA-1 지문 오탈자 확인
