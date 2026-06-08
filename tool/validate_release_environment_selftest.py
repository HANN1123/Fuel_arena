import base64
import json
import tempfile
from pathlib import Path

from validate_release_environment import (
    EDGE_FUNCTION_NAMES,
    Failure,
    check_public_urls,
    check_supabase_live,
    parse_properties_file,
    parse_xml_file,
    validate_android_key_properties,
    validate_android_manifest,
    validate_client,
    validate_edge,
    validate_ios_info_plist,
    validate_ios_xcconfig,
)


def _jwt_part(payload):
    raw = json.dumps(payload, separators=(",", ":")).encode("utf-8")
    return base64.urlsafe_b64encode(raw).decode("utf-8").rstrip("=")


def _valid_anon_key():
    return (
        f"{_jwt_part({'alg': 'HS256', 'typ': 'JWT'})}."
        f"{_jwt_part({'iss': 'supabase', 'role': 'anon'})}."
        "signature"
    )


def _valid_client_values():
    return {
        "APP_ENV": "production",
        "SUPABASE_URL": "https://fuelarena123.supabase.co",
        "SUPABASE_ANON_KEY": _valid_anon_key(),
        "GOOGLE_WEB_CLIENT_ID":
            "fuelarena-web-9876543210.apps.googleusercontent.com",
        "GOOGLE_ANDROID_CLIENT_ID":
            "fuelarena-android-9876543210.apps.googleusercontent.com",
        "GOOGLE_ANDROID_RELEASE_PACKAGE_NAME": "com.fuelarena.fuel_arena",
        "GOOGLE_ANDROID_RELEASE_SHA1":
            "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD",
        "GOOGLE_ANDROID_RELEASE_SHA256":
            "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:"
            "EE:FF:00:11:22:33:44:55:66:77:88:99",
        "GOOGLE_IOS_CLIENT_ID":
            "fuelarena-ios-9876543210.apps.googleusercontent.com",
        "GOOGLE_SERVER_CLIENT_ID":
            "fuelarena-server-9876543210.apps.googleusercontent.com",
        "GOOGLE_REVERSED_IOS_CLIENT_ID":
            "com.googleusercontent.apps.fuelarena-ios-9876543210",
        "APP_AUTH_REDIRECT_SCHEME": "fuelarena",
        "APP_AUTH_REDIRECT_HOST": "login-callback",
        "ADMOB_ANDROID_APP_ID": "ca-app-pub-1111222233334444~5555666677",
        "ADMOB_IOS_APP_ID": "ca-app-pub-1111222233334444~6666777788",
        "ADMOB_REWARDED_ANDROID_UNIT_ID":
            "ca-app-pub-1111222233334444/1111222233",
        "ADMOB_REWARDED_IOS_UNIT_ID":
            "ca-app-pub-1111222233334444/2222333344",
        "ADMOB_NATIVE_ANDROID_UNIT_ID":
            "ca-app-pub-1111222233334444/3333444455",
        "ADMOB_NATIVE_IOS_UNIT_ID":
            "ca-app-pub-1111222233334444/4444555566",
        "ADMOB_INTERSTITIAL_ANDROID_UNIT_ID":
            "ca-app-pub-1111222233334444/5555666677",
        "ADMOB_INTERSTITIAL_IOS_UNIT_ID":
            "ca-app-pub-1111222233334444/6666777788",
        "IAP_PREMIUM_MONTHLY_ID": "fuel_arena_premium_monthly",
        "IAP_PREMIUM_YEARLY_ID": "fuel_arena_premium_yearly",
        "IAP_SEASON_PASS_ID": "fuel_arena_season_pass",
        "IAP_PREMIUM_BUNDLE_ID": "fuel_arena_premium_bundle",
        "PUBLIC_PRIVACY_POLICY_URL": "https://fuelarena.app/legal/privacy/",
        "PUBLIC_LOCATION_NOTICE_URL":
            "https://fuelarena.app/legal/location/",
        "PUBLIC_ACCOUNT_DELETION_URL":
            "https://fuelarena.app/legal/account-deletion/",
        "PUBLIC_TERMS_URL": "https://fuelarena.app/legal/terms/",
    }


def _valid_edge_values():
    return {
        "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON":
            '{"type":"service_account",'
            '"client_email":"bot@fuel-arena-prod.iam.gserviceaccount.com",'
            '"private_key":"-----BEGIN PRIVATE KEY-----\\nabc\\n-----END '
            'PRIVATE KEY-----\\n",'
            '"project_id":"fuel-arena"}',
        "APP_STORE_CONNECT_ISSUER_ID": "12345678-1234-4abc-8def-123456789abc",
        "APP_STORE_CONNECT_KEY_ID": "FUELARENA1",
        "APP_STORE_CONNECT_PRIVATE_KEY":
            "-----BEGIN PRIVATE KEY-----\nabc\n-----END PRIVATE KEY-----",
        "APP_STORE_BUNDLE_ID": "com.fuelarena.fuelArena",
        "APP_STORE_ENV": "production",
        "ALLOW_MOCK_PURCHASE_VERIFICATION": "false",
        "RANKING_JOB_SECRET": "fuelarena-release-ranking-secret-value",
    }


def _messages(failures: list[Failure]) -> str:
    return "\n".join(str(failure) for failure in failures)


def _assert(condition: bool, message: str):
    if not condition:
        raise AssertionError(message)


class _FakeResponse:
    def __init__(self, status=200, body="[]", headers=None):
        self.status = status
        self._body = body.encode("utf-8")
        self.headers = headers or {}

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def read(self, size=-1):
        if size is None or size < 0:
            return self._body
        return self._body[:size]


def _live_urlopen_factory(
    include_idempotency_header=True,
    include_allow_origin=True,
    empty_seed_label="",
    google_location="https://accounts.google.com/o/oauth2/v2/auth?client_id=fuelarena",
    expected_edge_origin="",
):
    def fake_urlopen(request, timeout=10):
        url = request.full_url
        method = request.get_method()
        if "/auth/v1/authorize" in url:
            return _FakeResponse(
                status=302,
                body="",
                headers={"Location": google_location},
            )
        if "/rest/v1/" in url:
            if empty_seed_label and f"/rest/v1/{empty_seed_label}" in url:
                return _FakeResponse(body="[]")
            return _FakeResponse(body='[{"id":"row-1","key":"reward_ad_daily_limit"}]')
        if "/functions/v1/" in url and method == "OPTIONS":
            if expected_edge_origin:
                origin = request.get_header("Origin")
                _assert(
                    origin == expected_edge_origin,
                    f"expected Edge CORS Origin {expected_edge_origin}, got {origin}",
                )
            allow_headers = "authorization, x-client-info, apikey, content-type"
            if include_idempotency_header:
                allow_headers += ", x-idempotency-key"
            response_headers = {
                "Access-Control-Allow-Methods": "POST, OPTIONS",
                "Access-Control-Allow-Headers": allow_headers,
            }
            if include_allow_origin:
                response_headers["Access-Control-Allow-Origin"] = "*"
            return _FakeResponse(
                body="ok",
                headers=response_headers,
            )
        raise AssertionError(f"unexpected live check request: {method} {url}")

    return fake_urlopen


def _public_urlopen_factory(bad_legal_key=""):
    legal_tokens = {
        "PUBLIC_PRIVACY_POLICY_URL": "필요한 정보만 수집",
        "PUBLIC_LOCATION_NOTICE_URL": "주행 거리, 속도",
        "PUBLIC_ACCOUNT_DELETION_URL": "운영 큐에 접수",
        "PUBLIC_TERMS_URL": "주행 효율을 게임처럼 비교",
    }
    legal_paths = {
        "PUBLIC_PRIVACY_POLICY_URL": "/legal/privacy/",
        "PUBLIC_LOCATION_NOTICE_URL": "/legal/location/",
        "PUBLIC_ACCOUNT_DELETION_URL": "/legal/account-deletion/",
        "PUBLIC_TERMS_URL": "/legal/terms/",
    }

    def fake_urlopen(request, timeout=10):
        url = request.full_url
        for key, path in legal_paths.items():
            if path in url:
                body = "<html><body>Fuel Arena "
                body += "wrong legal document" if key == bad_legal_key else legal_tokens[key]
                body += "</body></html>"
                return _FakeResponse(body=body)
        raise AssertionError(f"unexpected public URL check request: {url}")

    return fake_urlopen


def test_valid_release_env_passes():
    failures: list[Failure] = []
    validate_client(_valid_client_values(), failures)
    validate_edge(_valid_edge_values(), failures)
    _assert(not failures, f"valid release env should pass:\n{_messages(failures)}")


def test_client_rejects_secret_and_test_admob_values():
    values = _valid_client_values()
    values.update({
        "SUPABASE_SERVICE_ROLE_KEY": "service-role-secret",
        "ADMOB_ANDROID_APP_ID": "ca-app-pub-3940256099942544~3347511713",
        "APP_ENV": "dev",
    })
    failures: list[Failure] = []
    validate_client(values, failures)
    messages = _messages(failures)
    _assert("SUPABASE_SERVICE_ROLE_KEY" in messages, messages)
    _assert("Google test App ID" in messages, messages)
    _assert("APP_ENV must be production" in messages, messages)


def test_edge_rejects_mock_purchase_and_short_ranking_secret():
    values = _valid_edge_values()
    values.update({
        "ALLOW_MOCK_PURCHASE_VERIFICATION": "true",
        "RANKING_JOB_SECRET": "short",
    })
    failures: list[Failure] = []
    validate_edge(values, failures)
    messages = _messages(failures)
    _assert("ALLOW_MOCK_PURCHASE_VERIFICATION must be false" in messages,
            messages)
    _assert("RANKING_JOB_SECRET must be at least 32 characters" in messages,
            messages)


def test_release_env_rejects_example_placeholders():
    client_values = _valid_client_values()
    client_values.update({
        "SUPABASE_URL": "https://project-ref.supabase.co",
        "GOOGLE_WEB_CLIENT_ID": "web-client.apps.googleusercontent.com",
        "ADMOB_ANDROID_APP_ID": "ca-app-pub-1234567890123456~1234567890",
        "PUBLIC_PRIVACY_POLICY_URL": "https://fuelarena.example/legal/privacy/",
    })
    edge_values = _valid_edge_values()
    edge_values.update({
        "APP_STORE_CONNECT_ISSUER_ID": "issuer-id",
        "APP_STORE_CONNECT_KEY_ID": "key-id",
        "APP_STORE_CONNECT_PRIVATE_KEY":
            "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----",
    })
    failures: list[Failure] = []
    validate_client(client_values, failures)
    validate_edge(edge_values, failures)
    messages = _messages(failures)
    _assert("SUPABASE_URL is missing or placeholder" in messages, messages)
    _assert("GOOGLE_WEB_CLIENT_ID is missing or placeholder" in messages,
            messages)
    _assert("ADMOB_ANDROID_APP_ID is missing or placeholder" in messages,
            messages)
    _assert("PUBLIC_PRIVACY_POLICY_URL is missing or placeholder" in messages,
            messages)
    _assert("APP_STORE_CONNECT_ISSUER_ID is missing or placeholder" in messages,
            messages)
    _assert("APP_STORE_CONNECT_PRIVATE_KEY is missing or placeholder" in messages,
            messages)


def test_release_env_requires_interstitial_ad_units():
    client_values = _valid_client_values()
    client_values.pop("ADMOB_INTERSTITIAL_ANDROID_UNIT_ID")
    client_values["ADMOB_INTERSTITIAL_IOS_UNIT_ID"] = ""
    failures: list[Failure] = []
    validate_client(client_values, failures)
    messages = _messages(failures)
    _assert("ADMOB_INTERSTITIAL_ANDROID_UNIT_ID is missing or placeholder" in messages,
            messages)
    _assert("ADMOB_INTERSTITIAL_IOS_UNIT_ID is missing or placeholder" in messages,
            messages)


def test_client_rejects_bad_anon_jwt_and_wrong_iap_product_id():
    client_values = _valid_client_values()
    client_values.update({
        "SUPABASE_ANON_KEY": "eyJbad.payload",
        "IAP_SEASON_PASS_ID": "wrong_season_pass",
    })
    failures: list[Failure] = []
    validate_client(client_values, failures)
    messages = _messages(failures)
    _assert("SUPABASE_ANON_KEY must have three JWT parts" in messages,
            messages)
    _assert("IAP_SEASON_PASS_ID must match seeded subscription product_id "
            "fuel_arena_season_pass" in messages, messages)


def test_release_env_rejects_wrong_native_redirect():
    client_values = _valid_client_values()
    client_values.update({
        "APP_AUTH_REDIRECT_SCHEME": "wrongapp",
        "APP_AUTH_REDIRECT_HOST": "wrong-callback",
    })
    failures: list[Failure] = []
    validate_client(client_values, failures)
    messages = _messages(failures)
    _assert("APP_AUTH_REDIRECT_SCHEME must be fuelarena" in messages, messages)
    _assert("APP_AUTH_REDIRECT_HOST must be login-callback" in messages,
            messages)


def test_release_env_rejects_wrong_legal_url_paths():
    client_values = _valid_client_values()
    client_values.update({
        "PUBLIC_PRIVACY_POLICY_URL": "https://fuelarena.app/privacy",
        "PUBLIC_LOCATION_NOTICE_URL":
            "https://fuelarena.app/legal/location/?utm=store",
        "PUBLIC_ACCOUNT_DELETION_URL":
            "https://fuelarena.app/legal/delete-account/",
        "PUBLIC_TERMS_URL": "https://fuelarena.app/legal/terms/#top",
    })
    failures: list[Failure] = []
    validate_client(client_values, failures)
    messages = _messages(failures)
    _assert("PUBLIC_PRIVACY_POLICY_URL must point to /legal/privacy/" in messages,
            messages)
    _assert("PUBLIC_LOCATION_NOTICE_URL must not include query or fragment"
            in messages, messages)
    _assert("PUBLIC_ACCOUNT_DELETION_URL must point to /legal/account-deletion/"
            in messages, messages)
    _assert("PUBLIC_TERMS_URL must not include query or fragment" in messages,
            messages)


def test_release_env_rejects_split_legal_url_origins():
    client_values = _valid_client_values()
    client_values["PUBLIC_LOCATION_NOTICE_URL"] = (
        "https://legal.fuelarena.app/legal/location/"
    )
    failures: list[Failure] = []
    validate_client(client_values, failures)
    messages = _messages(failures)
    _assert("PUBLIC legal URLs must share the same origin" in messages,
            messages)


def test_public_url_check_requires_legal_page_content():
    failures: list[Failure] = []
    check_public_urls(
        _valid_client_values(),
        failures,
        urlopen=_public_urlopen_factory(),
    )
    _assert(not failures, f"valid legal pages should pass:\n{_messages(failures)}")

    failures = []
    check_public_urls(
        _valid_client_values(),
        failures,
        urlopen=_public_urlopen_factory(bad_legal_key="PUBLIC_TERMS_URL"),
    )
    messages = _messages(failures)
    _assert("PUBLIC_TERMS_URL does not look like the expected Fuel Arena legal page"
            in messages, messages)


def test_release_env_rejects_bad_android_oauth_evidence():
    client_values = _valid_client_values()
    client_values.update({
        "GOOGLE_ANDROID_RELEASE_PACKAGE_NAME": "com.example.wrong",
        "GOOGLE_ANDROID_RELEASE_SHA1": "AA:BB:CC",
        "GOOGLE_ANDROID_RELEASE_SHA256": "AA:BB:CC",
    })
    failures: list[Failure] = []
    validate_client(client_values, failures)
    messages = _messages(failures)
    _assert("GOOGLE_ANDROID_RELEASE_PACKAGE_NAME must be" in messages, messages)
    _assert(
        "GOOGLE_ANDROID_RELEASE_SHA1 must be a colon-separated SHA-1 fingerprint"
        in messages,
        messages,
    )
    _assert(
        "GOOGLE_ANDROID_RELEASE_SHA256 must be a colon-separated SHA-256 fingerprint"
        in messages,
        messages,
    )


def test_release_env_rejects_mismatched_ios_reversed_client_id():
    client_values = _valid_client_values()
    client_values["GOOGLE_REVERSED_IOS_CLIENT_ID"] = (
        "com.googleusercontent.apps.fuelarena-ios-alt-2468135791"
    )
    failures: list[Failure] = []
    validate_client(client_values, failures)
    messages = _messages(failures)
    _assert(
        "GOOGLE_REVERSED_IOS_CLIENT_ID must match GOOGLE_IOS_CLIENT_ID"
        in messages,
        messages,
    )
    _assert(
        "expected com.googleusercontent.apps.fuelarena-ios-9876543210"
        in messages,
        messages,
    )


def test_ios_xcconfig_must_match_client_env():
    client_values = _valid_client_values()
    valid_xcconfig = {
        "ADMOB_IOS_APP_ID": client_values["ADMOB_IOS_APP_ID"],
        "GOOGLE_IOS_CLIENT_ID": client_values["GOOGLE_IOS_CLIENT_ID"],
        "GOOGLE_SERVER_CLIENT_ID": client_values["GOOGLE_SERVER_CLIENT_ID"],
        "GOOGLE_REVERSED_IOS_CLIENT_ID":
            client_values["GOOGLE_REVERSED_IOS_CLIENT_ID"],
    }
    failures: list[Failure] = []
    validate_ios_xcconfig(valid_xcconfig, client_values, failures)
    _assert(not failures, f"matching iOS xcconfig should pass:\n{_messages(failures)}")

    invalid_xcconfig = dict(valid_xcconfig)
    invalid_xcconfig["GOOGLE_IOS_CLIENT_ID"] = (
        "fuelarena-ios-alt-2468135791.apps.googleusercontent.com"
    )
    failures = []
    validate_ios_xcconfig(invalid_xcconfig, client_values, failures)
    messages = _messages(failures)
    _assert("GOOGLE_IOS_CLIENT_ID must match .env.production" in messages, messages)
    _assert(
        "GOOGLE_REVERSED_IOS_CLIENT_ID must match GOOGLE_IOS_CLIENT_ID "
        "in iOS xcconfig" in messages,
        messages,
    )


def test_android_key_properties_preflight():
    with tempfile.TemporaryDirectory() as temp_directory:
        android_directory = Path(temp_directory) / "android"
        release_directory = android_directory / "release"
        release_directory.mkdir(parents=True)
        upload_keystore = release_directory / "fuel-arena-upload.jks"
        upload_keystore.write_bytes(b"fake-upload-keystore")
        valid_properties = android_directory / "key.properties"
        valid_properties.write_text(
            "\n".join([
                "storeFile=../release/fuel-arena-upload.jks",
                "storePassword=release-store-password",
                "keyAlias=fuel-arena-upload",
                "keyPassword=release-key-password",
            ]),
            encoding="utf-8",
        )
        failures: list[Failure] = []
        validate_android_key_properties(
            parse_properties_file(valid_properties),
            valid_properties,
            failures,
        )
        _assert(not failures, f"valid Android signing should pass:\n{_messages(failures)}")

        invalid_properties = android_directory / "bad-key.properties"
        invalid_properties.write_text(
            "\n".join([
                "storeFile=../release/debug.keystore",
                "storePassword=short",
                "keyAlias=androiddebugkey",
                "keyPassword=replace-with-key-password",
            ]),
            encoding="utf-8",
        )
        failures = []
        validate_android_key_properties(
            parse_properties_file(invalid_properties),
            invalid_properties,
            failures,
        )
        messages = _messages(failures)
        _assert("storeFile must not point at a debug keystore" in messages, messages)
        _assert("storeFile does not exist" in messages, messages)
        _assert("keyAlias must not use androiddebugkey" in messages, messages)
        _assert(
            "storePassword must be at least 12 characters for release signing"
            in messages,
            messages,
        )
        _assert("keyPassword is missing or placeholder" in messages, messages)


def test_native_source_config_preflight():
    valid_plist = {
        "GADApplicationIdentifier": "$(ADMOB_IOS_APP_ID)",
        "GIDClientID": "$(GOOGLE_IOS_CLIENT_ID)",
        "GIDServerClientID": "$(GOOGLE_SERVER_CLIENT_ID)",
        "NSLocationWhenInUseUsageDescription":
            "주행 거리와 지역 리그 계산을 위해 위치 정보가 필요합니다.",
        "NSUserNotificationUsageDescription":
            "랭킹 추월, 배틀 결과, 시즌 보상을 알려드리기 위해 알림을 사용합니다.",
        "NSUserTrackingUsageDescription":
            "개인 맞춤 광고 제공 여부를 사용자가 선택할 수 있도록 광고 식별자 사용 가능성을 안내합니다.",
        "CFBundleURLTypes": [
            {
                "CFBundleURLSchemes": [
                    "$(GOOGLE_REVERSED_IOS_CLIENT_ID)",
                    "fuelarena",
                ],
            },
        ],
    }
    failures: list[Failure] = []
    validate_ios_info_plist(valid_plist, failures)
    _assert(not failures, f"valid iOS Info.plist should pass:\n{_messages(failures)}")

    invalid_plist = {
        "GADApplicationIdentifier": "ca-app-pub-3940256099942544~1458002511",
        "GIDClientID": "$(WRONG_CLIENT_ID)",
        "GIDServerClientID": "",
        "NSLocationWhenInUseUsageDescription": "location permission",
        "NSUserNotificationUsageDescription": "二쇳뻾 알림",
        "NSUserTrackingUsageDescription": "",
        "CFBundleURLTypes": [{"CFBundleURLSchemes": ["wrongapp"]}],
    }
    failures = []
    validate_ios_info_plist(invalid_plist, failures)
    messages = _messages(failures)
    _assert("GADApplicationIdentifier must be $(ADMOB_IOS_APP_ID)" in messages,
            messages)
    _assert("GIDClientID must be $(GOOGLE_IOS_CLIENT_ID)" in messages, messages)
    _assert("GIDServerClientID must be $(GOOGLE_SERVER_CLIENT_ID)" in messages,
            messages)
    _assert("NSLocationWhenInUseUsageDescription must use approved Korean copy"
            in messages, messages)
    _assert("NSUserNotificationUsageDescription must contain readable Korean copy"
            in messages, messages)
    _assert("NSUserTrackingUsageDescription must contain readable Korean copy"
            in messages, messages)
    _assert("CFBundleURLSchemes must include $(GOOGLE_REVERSED_IOS_CLIENT_ID)"
            in messages, messages)
    _assert("CFBundleURLSchemes must include fuelarena" in messages, messages)

    with tempfile.TemporaryDirectory() as temp_directory:
        manifest_file = Path(temp_directory) / "AndroidManifest.xml"
        manifest_file.write_text(
            """<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\">
  <application android:usesCleartextTraffic=\"false\">
    <meta-data
      android:name=\"com.google.android.gms.ads.APPLICATION_ID\"
      android:value=\"${ADMOB_ANDROID_APP_ID}\" />
    <activity android:name=\".MainActivity\">
      <intent-filter>
        <data
          android:host=\"${APP_AUTH_REDIRECT_HOST}\"
          android:scheme=\"${APP_AUTH_REDIRECT_SCHEME}\" />
      </intent-filter>
    </activity>
  </application>
</manifest>""",
            encoding="utf-8",
        )
        failures = []
        validate_android_manifest(
            parse_xml_file(manifest_file, "Android manifest"),
            failures,
        )
        _assert(not failures,
                f"valid Android manifest should pass:\n{_messages(failures)}")

        bad_manifest_file = Path(temp_directory) / "BadAndroidManifest.xml"
        bad_manifest_file.write_text(
            """<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\">
  <application android:usesCleartextTraffic=\"true\">
    <meta-data
      android:name=\"com.google.android.gms.ads.APPLICATION_ID\"
      android:value=\"ca-app-pub-3940256099942544~3347511713\" />
    <activity android:name=\".MainActivity\">
      <intent-filter>
        <data android:host=\"wrong\" android:scheme=\"wrong\" />
      </intent-filter>
    </activity>
  </application>
</manifest>""",
            encoding="utf-8",
        )
        failures = []
        validate_android_manifest(
            parse_xml_file(bad_manifest_file, "Android manifest"),
            failures,
        )
        messages = _messages(failures)
        _assert("usesCleartextTraffic" in messages, messages)
        _assert("AdMob APPLICATION_ID must use ${ADMOB_ANDROID_APP_ID}" in messages,
                messages)
        _assert("OAuth callback data must use APP_AUTH_REDIRECT_SCHEME/HOST" in messages,
                messages)


def test_edge_rejects_store_and_service_account_metadata():
    values = _valid_edge_values()
    values["GOOGLE_PLAY_SERVICE_ACCOUNT_JSON"] = (
        '{"type":"user",'
        '"client_email":"person@example.com",'
        '"private_key":"not-a-private-key",'
        '"project_id":"fuel-arena"}'
    )
    values["APP_STORE_CONNECT_ISSUER_ID"] = "not-a-uuid"
    values["APP_STORE_CONNECT_KEY_ID"] = "lowercase"
    failures: list[Failure] = []
    validate_edge(values, failures)
    messages = _messages(failures)
    _assert("type must be service_account" in messages, messages)
    _assert("client_email must be a service account" in messages, messages)
    _assert("private_key must contain a private key" in messages, messages)
    _assert("APP_STORE_CONNECT_ISSUER_ID must be an App Store Connect UUID" in messages,
            messages)
    _assert("APP_STORE_CONNECT_KEY_ID must be 10 uppercase alphanumeric" in messages,
            messages)


def test_edge_rejects_android_package_as_app_store_bundle():
    values = _valid_edge_values()
    values["APP_STORE_BUNDLE_ID"] = "com.fuelarena.fuel_arena"
    failures: list[Failure] = []
    validate_edge(values, failures)
    messages = _messages(failures)
    _assert(
        "APP_STORE_BUNDLE_ID has invalid iOS bundle identifier format" in messages,
        messages,
    )
    _assert(
        "APP_STORE_BUNDLE_ID must match iOS PRODUCT_BUNDLE_IDENTIFIER "
        "com.fuelarena.fuelArena" in messages,
        messages,
    )


def test_supabase_live_preflight_passes_with_public_rest_and_edge_cors():
    failures: list[Failure] = []
    check_supabase_live(
        _valid_client_values(),
        failures,
        urlopen=_live_urlopen_factory(),
    )
    _assert(not failures, f"valid live preflight should pass:\n{_messages(failures)}")


def test_supabase_live_preflight_uses_public_legal_origin_for_edge_cors():
    client_values = _valid_client_values()
    client_values.update({
        "PUBLIC_PRIVACY_POLICY_URL": "https://release.fuelarena.kr/legal/privacy/",
        "PUBLIC_LOCATION_NOTICE_URL": "https://release.fuelarena.kr/legal/location/",
        "PUBLIC_ACCOUNT_DELETION_URL":
            "https://release.fuelarena.kr/legal/account-deletion/",
        "PUBLIC_TERMS_URL": "https://release.fuelarena.kr/legal/terms/",
    })
    failures: list[Failure] = []
    check_supabase_live(
        client_values,
        failures,
        urlopen=_live_urlopen_factory(
            expected_edge_origin="https://release.fuelarena.kr"
        ),
    )
    _assert(not failures, f"custom origin live preflight should pass:\n{_messages(failures)}")


def test_supabase_live_preflight_requires_edge_idempotency_cors_header():
    failures: list[Failure] = []
    check_supabase_live(
        _valid_client_values(),
        failures,
        urlopen=_live_urlopen_factory(include_idempotency_header=False),
    )
    messages = _messages(failures)
    _assert("CORS headers must allow x-idempotency-key" in messages, messages)
    _assert(EDGE_FUNCTION_NAMES[0] in messages, messages)


def test_supabase_live_preflight_requires_edge_cors_origin():
    failures: list[Failure] = []
    check_supabase_live(
        _valid_client_values(),
        failures,
        urlopen=_live_urlopen_factory(include_allow_origin=False),
    )
    messages = _messages(failures)
    _assert("CORS origin must allow https://fuelarena.app" in messages, messages)
    _assert(EDGE_FUNCTION_NAMES[0] in messages, messages)


def test_supabase_live_preflight_requires_seeded_public_rest_rows():
    failures: list[Failure] = []
    check_supabase_live(
        _valid_client_values(),
        failures,
        urlopen=_live_urlopen_factory(empty_seed_label="app_settings"),
    )
    messages = _messages(failures)
    _assert("app_settings REST check returned no rows" in messages, messages)


def test_supabase_live_preflight_requires_google_oauth_redirect():
    failures: list[Failure] = []
    check_supabase_live(
        _valid_client_values(),
        failures,
        urlopen=_live_urlopen_factory(
            google_location="https://fuelarena.app/auth/error?provider=google"
        ),
    )
    messages = _messages(failures)
    _assert("Google OAuth web origin authorize" in messages, messages)
    _assert("accounts.google.com" in messages, messages)


def main():
    tests = [
        test_valid_release_env_passes,
        test_client_rejects_secret_and_test_admob_values,
        test_edge_rejects_mock_purchase_and_short_ranking_secret,
        test_release_env_rejects_example_placeholders,
        test_release_env_requires_interstitial_ad_units,
        test_client_rejects_bad_anon_jwt_and_wrong_iap_product_id,
        test_release_env_rejects_wrong_native_redirect,
        test_release_env_rejects_wrong_legal_url_paths,
        test_release_env_rejects_split_legal_url_origins,
        test_public_url_check_requires_legal_page_content,
        test_release_env_rejects_bad_android_oauth_evidence,
        test_release_env_rejects_mismatched_ios_reversed_client_id,
        test_ios_xcconfig_must_match_client_env,
        test_android_key_properties_preflight,
        test_native_source_config_preflight,
        test_edge_rejects_store_and_service_account_metadata,
        test_edge_rejects_android_package_as_app_store_bundle,
        test_supabase_live_preflight_passes_with_public_rest_and_edge_cors,
        test_supabase_live_preflight_uses_public_legal_origin_for_edge_cors,
        test_supabase_live_preflight_requires_edge_idempotency_cors_header,
        test_supabase_live_preflight_requires_edge_cors_origin,
        test_supabase_live_preflight_requires_seeded_public_rest_rows,
        test_supabase_live_preflight_requires_google_oauth_redirect,
    ]
    for test in tests:
        test()
    print(f"release environment selftest valid: {len(tests)} checks")


if __name__ == "__main__":
    main()
