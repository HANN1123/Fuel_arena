# Google OAuth Setup Guide

Fuel Arena Flutter 앱은 Google OAuth Client ID와 Supabase Google Provider를 사용해 로그인한다. Flutter 앱에는 Google OAuth client secret이나 Supabase service role key를 넣지 않는다.

## 1. Google Cloud Console 프로젝트
1. Google Cloud Console에서 Fuel Arena용 프로젝트를 만든다.
2. APIs & Services > OAuth consent screen에서 앱 이름을 `Fuel Arena`로 설정한다.
3. 사용자 지원 이메일, 개발자 연락처, 개인정보 처리방침 URL, 약관 URL을 입력한다.
4. 테스트 단계에서는 테스트 사용자를 등록한다.
5. production 배포 전 Publishing status와 앱 검증 상태를 확인한다.

## 2. Web OAuth Client ID
1. Credentials > Create credentials > OAuth client ID를 선택한다.
2. Application type은 Web application으로 만든다.
3. Authorized JavaScript origins에 배포 origin을 등록한다.
   - 예: `https://fuelarena.app`
   - 로컬 Web 확인 시 `http://127.0.0.1:5173`, `http://localhost:5173`도 dev 전용 client에 등록한다.
4. 생성된 client ID를 `.env`의 `GOOGLE_WEB_CLIENT_ID_<ENV>`에 넣는다.
5. Server client ID를 별도 운용하면 `GOOGLE_SERVER_CLIENT_ID_<ENV>`에 넣고, 별도 client가 없으면 Web client ID와 같은 값을 사용한다.

## 3. Android OAuth Client ID
1. Application type은 Android로 만든다.
2. package name은 `android/app/build.gradle.kts`의 `applicationId`를 확인해 입력한다.
   - 현재 package name: `com.fuelarena.fuel_arena`
3. debug SHA-1은 로컬 검증용 dev client에만 사용한다.
4. release SHA-1/SHA-256은 production client에 사용한다.

SHA-1 확인 예:

```bash
cd android
./gradlew signingReport
```

keytool 예:

```bash
keytool -list -v -keystore android/app/upload-keystore.jks -alias fuel-arena-upload
```

Google Play App Signing을 사용하면 Play Console > App integrity에서 App signing certificate SHA-1/SHA-256을 확인해 Google Cloud Console에 추가한다.

`.env.production`에는 다음 값을 기록한다.

```dotenv
GOOGLE_ANDROID_CLIENT_ID_PRODUCTION=
GOOGLE_ANDROID_RELEASE_PACKAGE_NAME=com.fuelarena.fuel_arena
GOOGLE_ANDROID_RELEASE_SHA1=
GOOGLE_ANDROID_RELEASE_SHA256=
```

## 4. iOS OAuth Client ID
1. Application type은 iOS로 만든다.
2. Bundle ID는 Xcode project의 `PRODUCT_BUNDLE_IDENTIFIER`와 맞춘다.
   - 현재 release bundle id: `com.fuelarena.fuelArena`
3. 생성된 iOS client ID를 `GOOGLE_IOS_CLIENT_ID_<ENV>`에 넣는다.
4. Reversed Client ID를 `GOOGLE_REVERSED_IOS_CLIENT_ID_<ENV>`에 넣는다.
5. `ios/Flutter/FuelArenaSecrets.xcconfig.example`를 `FuelArenaSecrets.xcconfig`로 복사하고 Google/iOS/AdMob 값을 채운다.

`GoogleService-Info.plist`를 쓰는 방식도 가능하지만 실제 plist는 secret 파일로 취급하고 commit하지 않는다. 현재 repo는 Info.plist build setting 방식으로 `GIDClientID`, `GIDServerClientID`, URL scheme을 연결한다.

## 5. Supabase Dashboard Google Provider
1. Supabase Dashboard > Authentication > Providers > Google을 연다.
2. Google Provider를 활성화한다.
3. Google Web/Server OAuth client ID를 입력한다.
4. Google OAuth client secret은 Supabase Dashboard에만 입력한다.
5. Flutter client `.env`에는 client secret을 넣지 않는다.

## 6. Redirect URL
Supabase Auth callback URL은 Supabase가 제공하는 URL을 Google Web client의 Authorized redirect URI에 등록한다.

일반 형식:

```text
https://<project-ref>.supabase.co/auth/v1/callback
```

앱 커스텀 callback은 다음 값으로 고정한다.

```dotenv
AUTH_REDIRECT_SCHEME=fuelarena
AUTH_REDIRECT_HOST=login-callback
```

결과 URI:

```text
fuelarena://login-callback
```

Supabase Authentication > URL Configuration > Redirect URLs에는 Web 배포 origin과 native callback을 등록한다.

## 7. 환경 분리
`APP_ENV`에 따라 AppConfig가 scoped key를 우선 읽는다.

```dotenv
APP_ENV=dev
SUPABASE_URL_DEV=
SUPABASE_ANON_KEY_DEV=
GOOGLE_WEB_CLIENT_ID_DEV=
GOOGLE_ANDROID_CLIENT_ID_DEV=
GOOGLE_IOS_CLIENT_ID_DEV=
GOOGLE_SERVER_CLIENT_ID_DEV=
GOOGLE_REVERSED_IOS_CLIENT_ID_DEV=
```

staging/production도 같은 패턴으로 `_STAGING`, `_PRODUCTION` suffix를 사용한다. 기존 release preflight 호환을 위해 공통 alias도 둘 수 있지만, 앱 런타임은 scoped key를 우선한다.

## 8. 자주 발생하는 오류
- `Google 로그인 설정이 필요합니다.`: active APP_ENV에 맞는 Google client ID가 누락되었다.
- `Google ID 토큰을 찾을 수 없습니다.`: Android/iOS client ID, server client ID, SHA-1 또는 bundle ID가 맞지 않을 수 있다.
- `Supabase 세션을 만들지 못했습니다.`: Supabase Google Provider, redirect URL, Google client secret 설정을 확인한다.
- `로그인이 취소되었어요.`: 사용자가 Google 로그인 창을 닫았다.
- Android release에서만 실패: Play App Signing SHA-1/SHA-256을 Google OAuth client에 추가했는지 확인한다.
- iOS에서 callback 실패: `GOOGLE_REVERSED_IOS_CLIENT_ID`가 iOS client ID와 정확히 짝인지 확인한다.

## 9. Production 배포 체크리스트
- `APP_ENV=production`
- `SUPABASE_URL_PRODUCTION`은 `https://<project-ref>.supabase.co` 형식
- `SUPABASE_ANON_KEY_PRODUCTION`은 anon JWT
- Web/Android/iOS/Server Google client ID가 모두 `.apps.googleusercontent.com`으로 끝남
- iOS reversed client ID가 `com.googleusercontent.apps.<ios-client-prefix>` 형식
- `fuelarena://login-callback`이 Supabase redirect allow list에 등록됨
- Google OAuth client secret은 Supabase Dashboard에만 있음
- `SUPABASE_SERVICE_ROLE_KEY`는 Flutter client env에 없음
- `flutter analyze`와 `flutter test` 통과
- Supabase migration과 RLS가 production DB에 적용됨
