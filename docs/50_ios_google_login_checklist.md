# iOS 구글 로그인 체크리스트 및 설정 가이드 (iOS Google Sign-In Checklist)

iOS 플랫폼에서 실제 Google 로그인을 구성하고 네이티브 연동을 완료하기 위한 기술 가이드라인입니다.

---

## 1. iOS Bundle ID 확인 위치
- **확인 위치**: Xcode 프로젝트 설정 (`Runner.xcodeproj`) -> **Runner 타겟** -> **General 탭** -> **Identity** -> **Bundle Identifier**
- **값 확인**: 일반적으로 `com.fuelarena` 혹은 설정한 식별자로 지정되어 있습니다.
- **주의**: Google Cloud Console의 Bundle ID 설정값과 대소문자를 포함해 완전히 같아야 합니다.

---

## 2. Google Cloud Console iOS OAuth Client ID 생성 방법
1. **Google Cloud Console** -> **사용자 인증 정보** 페이지로 이동합니다.
2. [+ 사용자 인증 정보 만들기] -> **OAuth 클라이언트 ID**를 선택합니다.
3. 애플리케이션 유형을 **iOS**로 설정합니다.
4. **Bundle ID** 필드에 Xcode에서 확인한 Bundle Identifier(`com.fuelarena` 등)를 입력합니다.
5. **만들기**를 클릭하면 OAuth Client ID와 **iOS reversed client ID**가 함께 생성됩니다.

---

## 3. Reversed Client ID 확인 방법
- iOS Client ID가 `123456-abcdef.apps.googleusercontent.com`인 경우,
- **Reversed Client ID**는 도메인 역순인 `com.googleusercontent.apps.123456-abcdef` 형태가 됩니다.
- 이 값은 iOS 앱이 구글 로그인 완료 후 앱스토어/구글 인증서버로부터 리다이렉트 콜백을 수신하는 스키마 주소로 사용됩니다.

---

## 4. Info.plist URL scheme 설정 방법
- **파일명**: [Info.plist](file:///c:/Users/yjje1/Documents/GitHub/Fuel_arena/ios/Runner/Info.plist)
- **설정 내용**: `CFBundleURLTypes` 키 아래에 구글 로그인을 위한 Reversed Client ID 스키마를 추가해 주어야 구글 로그인 브라우저/인앱 브라우저에서 동의 완료 후 내 앱으로 복귀합니다.
  ```xml
  <key>CFBundleURLTypes</key>
  <array>
      <dict>
          <key>CFBundleTypeRole</key>
          <string>Editor</string>
          <key>CFBundleURLSchemes</key>
          <array>
              <!-- Google OAuth Reversed Client ID -->
              <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID_PREFIX</string>
              <!-- Supabase Redirect URL Scheme -->
              <string>fuelarena</string>
          </array>
      </dict>
  </array>
  ```

---

## 5. GoogleService-Info.plist를 사용할 경우 gitignore 처리 방법
`google_sign_in` 패키지는 별도의 `GoogleService-Info.plist` 구성 파일 없이도 Flutter `AppConfig`에 주입되는 `clientId` 매개변수로 구동될 수 있으나, 만약 Firebase 혹은 네이티브 iOS 연동을 위해 파일을 추가한다면 민감한 설정이 레포지토리에 커밋되지 않도록 `.gitignore`에 다음이 포함되어 있는지 점검해야 합니다:
- **.gitignore 등록 패턴**: `ios/Runner/GoogleService-Info.plist` (이미 `.gitignore`에 등록되어 있는지 수동 확인 요망)

---

## 6. Supabase redirect allow-list와 native sign-in 관계
- Supabase native sign-in을 사용하는 경우 실제 로그인 과정에서 리다이렉트 URL 호출을 생략하고 네이티브 클라이언트 단에서 구글 ID 토큰을 Supabase Auth REST API(`signInWithIdToken`)에 바로 던지므로 iOS 리다이렉션 승인 목록 설정은 생략되거나, `fuelarena://login-callback`만 유지하면 됩니다.

---

## 7. iOS Simulator 및 실제 iPhone 테스트 절차
- **iOS Simulator**:
  1. 시뮬레이터 내 Safari 브라우저에서 구글 계정으로 로그인되어 있는지 확인합니다.
  2. `flutter run --dart-define=APP_ENV=staging` 명령으로 시뮬레이터에 앱을 기동하여 검증합니다.
- **실제 iPhone**:
  1. 애플 개발자 프로필을 통해 서명 후 iPhone 단말기에 설치합니다.
  2. 앱 기동 후 Google로 시작하기 클릭 시 나타나는 native iOS Consent Sheet (`"fuel_arena"에서 로그인하기 위해 "google.com"을 사용하려고 합니다`) 팝업을 확인하고 로그인을 완료합니다.

---

## 8. 로그인 실패 시 흔한 원인
1. **URL Scheme 누락**: `Info.plist` 내 Reversed Client ID 스키마가 오탈자 또는 누락되어 구글 로그인 브라우저 화면이 닫힌 후 앱이 아무 반응을 보이지 않음.
2. **Bundle ID 불일치**: 구글 클라우드에 등록된 Bundle ID와 빌드된 앱의 Bundle ID가 맞지 않아 구글 로그인 화면 진입 시 `Error: invalid_client` 메시지가 발생합니다.
