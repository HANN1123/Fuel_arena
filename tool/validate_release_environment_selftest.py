import base64
import json

from validate_release_environment import (
    EDGE_FUNCTION_NAMES,
    Failure,
    check_supabase_live,
    validate_client,
    validate_edge,
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

    def read(self):
        return self._body


def _live_urlopen_factory(
    include_idempotency_header=True,
    empty_seed_label="",
    google_location="https://accounts.google.com/o/oauth2/v2/auth?client_id=fuelarena",
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
            allow_headers = "authorization, x-client-info, apikey, content-type"
            if include_idempotency_header:
                allow_headers += ", x-idempotency-key"
            return _FakeResponse(
                body="ok",
                headers={
                    "Access-Control-Allow-Methods": "POST, OPTIONS",
                    "Access-Control-Allow-Headers": allow_headers,
                },
            )
        raise AssertionError(f"unexpected live check request: {method} {url}")

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
        test_edge_rejects_store_and_service_account_metadata,
        test_edge_rejects_android_package_as_app_store_bundle,
        test_supabase_live_preflight_passes_with_public_rest_and_edge_cors,
        test_supabase_live_preflight_requires_edge_idempotency_cors_header,
        test_supabase_live_preflight_requires_seeded_public_rest_rows,
        test_supabase_live_preflight_requires_google_oauth_redirect,
    ]
    for test in tests:
        test()
    print(f"release environment selftest valid: {len(tests)} checks")


if __name__ == "__main__":
    main()
