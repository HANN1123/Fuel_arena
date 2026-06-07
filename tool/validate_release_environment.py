import argparse
import base64
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


ADMOB_UNIT_ID_KEYS = [
    "ADMOB_REWARDED_ANDROID_UNIT_ID",
    "ADMOB_REWARDED_IOS_UNIT_ID",
    "ADMOB_NATIVE_ANDROID_UNIT_ID",
    "ADMOB_NATIVE_IOS_UNIT_ID",
    "ADMOB_INTERSTITIAL_ANDROID_UNIT_ID",
    "ADMOB_INTERSTITIAL_IOS_UNIT_ID",
]

IAP_PRODUCT_IDS = {
    "IAP_PREMIUM_MONTHLY_ID": "fuel_arena_premium_monthly",
    "IAP_PREMIUM_YEARLY_ID": "fuel_arena_premium_yearly",
    "IAP_SEASON_PASS_ID": "fuel_arena_season_pass",
    "IAP_PREMIUM_BUNDLE_ID": "fuel_arena_premium_bundle",
}

CLIENT_REQUIRED = [
    "APP_ENV",
    "SUPABASE_URL",
    "SUPABASE_ANON_KEY",
    "GOOGLE_WEB_CLIENT_ID",
    "GOOGLE_ANDROID_CLIENT_ID",
    "GOOGLE_IOS_CLIENT_ID",
    "GOOGLE_SERVER_CLIENT_ID",
    "GOOGLE_REVERSED_IOS_CLIENT_ID",
    "APP_AUTH_REDIRECT_SCHEME",
    "APP_AUTH_REDIRECT_HOST",
    "ADMOB_ANDROID_APP_ID",
    "ADMOB_IOS_APP_ID",
    *ADMOB_UNIT_ID_KEYS,
    "IAP_PREMIUM_MONTHLY_ID",
    "IAP_PREMIUM_YEARLY_ID",
    "IAP_SEASON_PASS_ID",
    "IAP_PREMIUM_BUNDLE_ID",
    "PUBLIC_PRIVACY_POLICY_URL",
    "PUBLIC_LOCATION_NOTICE_URL",
    "PUBLIC_ACCOUNT_DELETION_URL",
    "PUBLIC_TERMS_URL",
]

EDGE_REQUIRED = [
    "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON",
    "APP_STORE_CONNECT_ISSUER_ID",
    "APP_STORE_CONNECT_KEY_ID",
    "APP_STORE_CONNECT_PRIVATE_KEY",
    "APP_STORE_BUNDLE_ID",
    "APP_STORE_ENV",
    "ALLOW_MOCK_PURCHASE_VERIFICATION",
    "RANKING_JOB_SECRET",
]

EDGE_FUNCTION_NAMES = [
    "assign_vehicle_league",
    "calculate_drive_score",
    "claim_season_reward",
    "finish_drive_session",
    "grant_ad_reward",
    "issue_coupon",
    "process_fraud_review",
    "review_custom_vehicle",
    "send_notification",
    "settle_battle",
    "update_mission_progress",
    "update_rankings",
    "verify_drive_session",
    "verify_purchase",
]

PUBLIC_REST_CHECKS = [
    (
        "app_settings",
        "/rest/v1/app_settings?select=key&key=eq.reward_ad_daily_limit&limit=1",
        True,
    ),
    (
        "fuel_leagues",
        "/rest/v1/fuel_leagues?select=key&limit=1",
        True,
    ),
    (
        "vehicle_manufacturer_catalog_view",
        "/rest/v1/vehicle_manufacturer_catalog_view?select=id,model_count,min_year,max_year&limit=1",
        True,
    ),
    (
        "subscription_plans",
        "/rest/v1/subscription_plans?select=product_id&is_active=eq.true&limit=1",
        True,
    ),
    (
        "public_rankings",
        "/rest/v1/public_rankings?select=user_id,nickname,tier,score&limit=1",
        False,
    ),
]

REDIRECT_STATUSES = {301, 302, 303, 307, 308}

FORBIDDEN_CLIENT_KEYS = [
    "SUPABASE_SERVICE_ROLE_KEY",
    "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON",
    "APP_STORE_CONNECT_PRIVATE_KEY",
    "RANKING_JOB_SECRET",
]

PLACEHOLDER_PARTS = [
    "replace-with",
    "project-ref",
    "example",
    "xxxxxxxx",
    "yyyyyyyy",
    "<",
    ">",
    "...",
    "todo",
    "changeme",
    "your-",
    "web-client",
    "android-client",
    "ios-client",
    "server-client",
    "issuer-id",
    "key-id",
    "1234567890123456",
    "1234567890",
]

TEST_ADMOB_APP_IDS = {
    "ca-app-pub-3940256099942544~3347511713",
    "ca-app-pub-3940256099942544~1458002511",
}

TEST_ADMOB_UNIT_IDS = {
    "ca-app-pub-3940256099942544/5224354917",
    "ca-app-pub-3940256099942544/1712485313",
    "ca-app-pub-3940256099942544/2247696110",
    "ca-app-pub-3940256099942544/3986624511",
    "ca-app-pub-3940256099942544/1044960115",
    "ca-app-pub-3940256099942544/4411468910",
    "ca-app-pub-3940256099942544/1033173712",
}

IOS_RUNNER_BUNDLE_ID = "com.fuelarena.fuelArena"
IOS_BUNDLE_ID_PATTERN = re.compile(r"^[A-Za-z0-9]+(?:[.-][A-Za-z0-9]+)+$")
APPLE_ISSUER_ID_PATTERN = re.compile(
    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-"
    r"[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
)
APPLE_KEY_ID_PATTERN = re.compile(r"^[A-Z0-9]{10}$")


class Failure:
    def __init__(self, scope, message):
        self.scope = scope
        self.message = message

    def __str__(self):
        return f"{self.scope}: {self.message}"


class NoRedirectHandler(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def no_redirect_urlopen(request, timeout=10):
    opener = urllib.request.build_opener(NoRedirectHandler)
    return opener.open(request, timeout=timeout)


def parse_env_file(path):
    values = {}
    if not path:
        return values
    file_path = Path(path)
    if not file_path.exists():
        raise SystemExit(f"env file does not exist: {file_path}")
    for raw_line in file_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip().lstrip("\ufeff")] = strip_quotes(value.strip())
    return values


def strip_quotes(value):
    if len(value) >= 2 and value[0] == value[-1] and value[0] in ("'", '"'):
        return value[1:-1]
    return value


def merged_env(path):
    values = dict(os.environ)
    values.update(parse_env_file(path))
    return values


def is_placeholder(value):
    normalized = value.strip().lower()
    if not normalized:
        return True
    return any(part in normalized for part in PLACEHOLDER_PARTS)


def decode_jwt_part(value):
    padding = "=" * (-len(value) % 4)
    return json.loads(base64.urlsafe_b64decode(value + padding).decode("utf-8"))


def validate_supabase_anon_key(value, failures):
    if not value.startswith("eyJ"):
        failures.append(
            Failure("client env", "SUPABASE_ANON_KEY should be a JWT-like anon key")
        )
        return
    parts = value.split(".")
    if len(parts) != 3:
        failures.append(
            Failure("client env", "SUPABASE_ANON_KEY must have three JWT parts")
        )
        return
    try:
        header = decode_jwt_part(parts[0])
        payload = decode_jwt_part(parts[1])
    except Exception as error:  # noqa: BLE001 - release diagnostics need context.
        failures.append(
            Failure("client env", f"SUPABASE_ANON_KEY JWT is not decodable: {error}")
        )
        return
    if header.get("alg") != "HS256":
        failures.append(
            Failure("client env", "SUPABASE_ANON_KEY JWT alg should be HS256")
        )
    if payload.get("role") != "anon":
        failures.append(
            Failure("client env", "SUPABASE_ANON_KEY JWT role claim must be anon")
        )


def require_present(failures, values, keys, scope):
    for key in keys:
        value = values.get(key, "")
        if is_placeholder(value):
            failures.append(Failure(scope, f"{key} is missing or placeholder"))


def validate_client(values, failures):
    require_present(failures, values, CLIENT_REQUIRED, "client env")

    for key in FORBIDDEN_CLIENT_KEYS:
        if values.get(key, "").strip():
            failures.append(
                Failure(
                    "client env",
                    f"{key} must not be present in Flutter client env",
                )
            )

    if values.get("APP_ENV", "").strip().lower() != "production":
        failures.append(Failure("client env", "APP_ENV must be production"))

    supabase_url = values.get("SUPABASE_URL", "")
    if not re.match(r"^https://[a-z0-9-]+\.supabase\.co/?$", supabase_url):
        failures.append(
            Failure(
                "client env",
                "SUPABASE_URL must look like https://<project-ref>.supabase.co",
            )
        )

    validate_supabase_anon_key(values.get("SUPABASE_ANON_KEY", ""), failures)

    for key in [
        "GOOGLE_WEB_CLIENT_ID",
        "GOOGLE_ANDROID_CLIENT_ID",
        "GOOGLE_IOS_CLIENT_ID",
        "GOOGLE_SERVER_CLIENT_ID",
    ]:
        value = values.get(key, "")
        if value and not value.endswith(".apps.googleusercontent.com"):
            failures.append(
                Failure("client env", f"{key} must end with .apps.googleusercontent.com")
            )

    reversed_id = values.get("GOOGLE_REVERSED_IOS_CLIENT_ID", "")
    if reversed_id and not reversed_id.startswith("com.googleusercontent.apps."):
        failures.append(
            Failure(
                "client env",
                "GOOGLE_REVERSED_IOS_CLIENT_ID must start with com.googleusercontent.apps.",
            )
        )

    if values.get("APP_AUTH_REDIRECT_SCHEME", "") != "fuelarena":
        failures.append(
            Failure(
                "client env",
                "APP_AUTH_REDIRECT_SCHEME must be fuelarena",
            )
        )
    if values.get("APP_AUTH_REDIRECT_HOST", "") != "login-callback":
        failures.append(
            Failure(
                "client env",
                "APP_AUTH_REDIRECT_HOST must be login-callback",
            )
        )

    for key in ["ADMOB_ANDROID_APP_ID", "ADMOB_IOS_APP_ID"]:
        value = values.get(key, "")
        if value in TEST_ADMOB_APP_IDS:
            failures.append(Failure("client env", f"{key} is a Google test App ID"))
        if value and not re.match(r"^ca-app-pub-\d{16}~\d{10}$", value):
            failures.append(Failure("client env", f"{key} has invalid AdMob app format"))

    for key in ADMOB_UNIT_ID_KEYS:
        value = values.get(key, "")
        if value in TEST_ADMOB_UNIT_IDS:
            failures.append(Failure("client env", f"{key} is a Google test ad unit"))
        if value and not re.match(r"^ca-app-pub-\d{16}/\d{10}$", value):
            failures.append(Failure("client env", f"{key} has invalid AdMob unit format"))

    for key, expected in IAP_PRODUCT_IDS.items():
        value = values.get(key, "")
        if value and value != expected:
            failures.append(
                Failure(
                    "client env",
                    f"{key} must match seeded subscription product_id {expected}",
                )
            )

    for key in [
        "PUBLIC_PRIVACY_POLICY_URL",
        "PUBLIC_LOCATION_NOTICE_URL",
        "PUBLIC_ACCOUNT_DELETION_URL",
        "PUBLIC_TERMS_URL",
    ]:
        value = values.get(key, "")
        if value and not value.startswith("https://"):
            failures.append(Failure("client env", f"{key} must be an https URL"))


def validate_edge(values, failures):
    require_present(failures, values, EDGE_REQUIRED, "edge env")

    service_account = values.get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON", "")
    if service_account:
        try:
            decoded = json.loads(service_account)
        except json.JSONDecodeError as error:
            failures.append(
                Failure("edge env", f"GOOGLE_PLAY_SERVICE_ACCOUNT_JSON is invalid JSON: {error}")
            )
        else:
            for key in ["client_email", "private_key", "project_id"]:
                if not decoded.get(key):
                    failures.append(
                        Failure(
                            "edge env",
                            f"GOOGLE_PLAY_SERVICE_ACCOUNT_JSON missing {key}",
                        )
                    )
            if decoded.get("type") != "service_account":
                failures.append(
                    Failure(
                        "edge env",
                        "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON type must be service_account",
                    )
                )
            client_email = decoded.get("client_email", "")
            if client_email and not client_email.endswith(".iam.gserviceaccount.com"):
                failures.append(
                    Failure(
                        "edge env",
                        "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON client_email must be a service account",
                    )
                )
            private_key_json = decoded.get("private_key", "")
            if private_key_json and "BEGIN PRIVATE KEY" not in private_key_json:
                failures.append(
                    Failure(
                        "edge env",
                        "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON private_key must contain a private key",
                    )
                )

    issuer_id = values.get("APP_STORE_CONNECT_ISSUER_ID", "")
    if issuer_id and not APPLE_ISSUER_ID_PATTERN.match(issuer_id):
        failures.append(
            Failure(
                "edge env",
                "APP_STORE_CONNECT_ISSUER_ID must be an App Store Connect UUID",
            )
        )

    key_id = values.get("APP_STORE_CONNECT_KEY_ID", "")
    if key_id and not APPLE_KEY_ID_PATTERN.match(key_id):
        failures.append(
            Failure(
                "edge env",
                "APP_STORE_CONNECT_KEY_ID must be 10 uppercase alphanumeric characters",
            )
        )

    private_key = values.get("APP_STORE_CONNECT_PRIVATE_KEY", "")
    if private_key and "PRIVATE KEY" not in private_key:
        failures.append(
            Failure(
                "edge env",
                "APP_STORE_CONNECT_PRIVATE_KEY must contain a p8 private key",
            )
        )

    if values.get("APP_STORE_ENV", "").strip().lower() != "production":
        failures.append(Failure("edge env", "APP_STORE_ENV must be production"))

    app_store_bundle_id = values.get("APP_STORE_BUNDLE_ID", "").strip()
    if app_store_bundle_id:
        if not IOS_BUNDLE_ID_PATTERN.match(app_store_bundle_id):
            failures.append(
                Failure(
                    "edge env",
                    "APP_STORE_BUNDLE_ID has invalid iOS bundle identifier format",
                )
            )
        if app_store_bundle_id != IOS_RUNNER_BUNDLE_ID:
            failures.append(
                Failure(
                    "edge env",
                    "APP_STORE_BUNDLE_ID must match iOS "
                    f"PRODUCT_BUNDLE_IDENTIFIER {IOS_RUNNER_BUNDLE_ID}",
                )
            )

    if values.get("ALLOW_MOCK_PURCHASE_VERIFICATION", "").strip().lower() != "false":
        failures.append(
            Failure("edge env", "ALLOW_MOCK_PURCHASE_VERIFICATION must be false")
        )

    if len(values.get("RANKING_JOB_SECRET", "")) < 32:
        failures.append(
            Failure("edge env", "RANKING_JOB_SECRET must be at least 32 characters")
        )


def check_public_urls(values, failures):
    for key in [
        "PUBLIC_PRIVACY_POLICY_URL",
        "PUBLIC_LOCATION_NOTICE_URL",
        "PUBLIC_ACCOUNT_DELETION_URL",
        "PUBLIC_TERMS_URL",
    ]:
        url = values.get(key, "")
        if not url:
            continue
        try:
            request = urllib.request.Request(
                url,
                headers={"User-Agent": "FuelArenaReleasePreflight/1.0"},
            )
            with urllib.request.urlopen(request, timeout=10) as response:
                if response.status >= 400:
                    failures.append(Failure("public url", f"{key} returned {response.status}"))
        except Exception as error:  # noqa: BLE001 - release diagnostics need the exact error.
            failures.append(Failure("public url", f"{key} is not reachable: {error}"))


def public_web_origin(values):
    for key in [
        "PUBLIC_TERMS_URL",
        "PUBLIC_PRIVACY_POLICY_URL",
        "PUBLIC_LOCATION_NOTICE_URL",
        "PUBLIC_ACCOUNT_DELETION_URL",
    ]:
        value = values.get(key, "").strip()
        if not value or is_placeholder(value):
            continue
        parsed = urllib.parse.urlparse(value)
        if parsed.scheme == "https" and parsed.netloc:
            return f"{parsed.scheme}://{parsed.netloc}"
    return ""


def google_oauth_redirect_checks(values):
    redirect_checks = []
    origin = public_web_origin(values)
    if origin:
        redirect_checks.append(("web origin", origin))
    scheme = values.get("APP_AUTH_REDIRECT_SCHEME", "").strip()
    host = values.get("APP_AUTH_REDIRECT_HOST", "").strip()
    if scheme and host:
        redirect_checks.append(("native callback", f"{scheme}://{host}"))
    return redirect_checks


def check_google_oauth_live(base_url, anon_key, values, failures, urlopen):
    redirect_checks = google_oauth_redirect_checks(values)
    if not redirect_checks:
        failures.append(
            Failure(
                "supabase live",
                "Google OAuth live check needs a public web URL or app redirect URI",
            )
        )
        return

    for label, redirect_to in redirect_checks:
        query = urllib.parse.urlencode(
            {
                "provider": "google",
                "redirect_to": redirect_to,
            }
        )
        url = f"{base_url}/auth/v1/authorize?{query}"
        headers = {}
        try:
            request = urllib.request.Request(
                url,
                method="GET",
                headers={
                    "Accept": "text/html,application/json",
                    "apikey": anon_key,
                    "User-Agent": "FuelArenaReleasePreflight/1.0",
                },
            )
            with urlopen(request, timeout=10) as response:
                status = response.status
                headers = {key.lower(): value for key, value in response.headers.items()}
        except urllib.error.HTTPError as error:
            if error.code not in REDIRECT_STATUSES:
                failures.append(
                    Failure(
                        "supabase live",
                        f"Google OAuth {label} authorize returned {error.code}",
                    )
                )
                continue
            status = error.code
            headers = {key.lower(): value for key, value in error.headers.items()}
        except Exception as error:  # noqa: BLE001 - release diagnostics need the exact error.
            failures.append(
                Failure(
                    "supabase live",
                    f"Google OAuth {label} authorize failed: {error}",
                )
            )
            continue

        location = headers.get("location", "")
        if status not in REDIRECT_STATUSES:
            failures.append(
                Failure(
                    "supabase live",
                    f"Google OAuth {label} authorize must redirect to Google, got {status}",
                )
            )
            continue
        if "accounts.google.com" not in location.lower():
            failures.append(
                Failure(
                    "supabase live",
                    f"Google OAuth {label} authorize did not redirect to accounts.google.com",
                )
            )


def check_supabase_live(values, failures, urlopen=None):
    if urlopen is None:
        urlopen = no_redirect_urlopen
    base_url = values.get("SUPABASE_URL", "").strip().rstrip("/")
    anon_key = values.get("SUPABASE_ANON_KEY", "").strip()
    if is_placeholder(base_url) or is_placeholder(anon_key):
        failures.append(
            Failure(
                "supabase live",
                "SUPABASE_URL and SUPABASE_ANON_KEY are required for live checks",
            )
        )
        return

    rest_headers = {
        "Accept": "application/json",
        "apikey": anon_key,
        "Authorization": f"Bearer {anon_key}",
        "User-Agent": "FuelArenaReleasePreflight/1.0",
    }
    for label, path, require_rows in PUBLIC_REST_CHECKS:
        url = f"{base_url}{path}"
        try:
            request = urllib.request.Request(url, headers=rest_headers)
            with urlopen(request, timeout=10) as response:
                body = response.read().decode("utf-8")
                if response.status != 200:
                    failures.append(
                        Failure(
                            "supabase live",
                            f"{label} REST check returned {response.status}",
                        )
                    )
                    continue
        except urllib.error.HTTPError as error:
            failures.append(
                Failure(
                    "supabase live",
                    f"{label} REST check returned {error.code}",
                )
            )
            continue
        except Exception as error:  # noqa: BLE001 - release diagnostics need the exact error.
            failures.append(
                Failure(
                    "supabase live",
                    f"{label} REST check failed: {error}",
                )
            )
            continue

        try:
            decoded = json.loads(body)
        except json.JSONDecodeError as error:
            failures.append(
                Failure(
                    "supabase live",
                    f"{label} REST check did not return JSON: {error}",
                )
            )
            continue
        if not isinstance(decoded, list):
            failures.append(
                Failure(
                    "supabase live",
                    f"{label} REST check should return a JSON array",
                )
            )
            continue
        if require_rows and not decoded:
            failures.append(
                Failure(
                    "supabase live",
                    f"{label} REST check returned no rows; migration/seed/RLS may be missing",
                )
            )

    check_google_oauth_live(base_url, anon_key, values, failures, urlopen)

    for function_name in EDGE_FUNCTION_NAMES:
        url = f"{base_url}/functions/v1/{urllib.parse.quote(function_name)}"
        try:
            request = urllib.request.Request(
                url,
                method="OPTIONS",
                headers={
                    "Origin": "https://fuelarena.app",
                    "Access-Control-Request-Method": "POST",
                    "Access-Control-Request-Headers":
                        "authorization, apikey, content-type, x-idempotency-key",
                    "User-Agent": "FuelArenaReleasePreflight/1.0",
                },
            )
            with urlopen(request, timeout=10) as response:
                status = response.status
                headers = {key.lower(): value for key, value in response.headers.items()}
        except urllib.error.HTTPError as error:
            failures.append(
                Failure(
                    "supabase live",
                    f"{function_name} Edge Function preflight returned {error.code}",
                )
            )
            continue
        except Exception as error:  # noqa: BLE001 - release diagnostics need the exact error.
            failures.append(
                Failure(
                    "supabase live",
                    f"{function_name} Edge Function preflight failed: {error}",
                )
            )
            continue

        if status not in (200, 204):
            failures.append(
                Failure(
                    "supabase live",
                    f"{function_name} Edge Function preflight returned {status}",
                )
            )
            continue
        allow_methods = headers.get("access-control-allow-methods", "").lower()
        allow_headers = headers.get("access-control-allow-headers", "").lower()
        if "post" not in allow_methods or "options" not in allow_methods:
            failures.append(
                Failure(
                    "supabase live",
                    f"{function_name} CORS methods must include POST and OPTIONS",
                )
            )
        if "x-idempotency-key" not in allow_headers:
            failures.append(
                Failure(
                    "supabase live",
                    f"{function_name} CORS headers must allow x-idempotency-key",
                )
            )


def main():
    parser = argparse.ArgumentParser(
        description="Validate production release environment values before store submission."
    )
    parser.add_argument("--env-file", default=".env.production")
    parser.add_argument("--edge-secrets-file")
    parser.add_argument(
        "--client-only",
        action="store_true",
        help="Skip Edge Function secret validation.",
    )
    parser.add_argument(
        "--check-public-urls",
        action="store_true",
        help="Fetch public legal/support URLs and require HTTP success.",
    )
    parser.add_argument(
        "--check-supabase-live",
        action="store_true",
        help="Fetch production Supabase public REST endpoints and Edge Function CORS preflight.",
    )
    args = parser.parse_args()

    failures = []
    client_values = merged_env(args.env_file)
    validate_client(client_values, failures)

    edge_values = client_values
    if args.edge_secrets_file:
        edge_values = dict(client_values)
        edge_values.update(parse_env_file(args.edge_secrets_file))
    if not args.client_only:
        validate_edge(edge_values, failures)

    if args.check_public_urls:
        check_public_urls(client_values, failures)
    if args.check_supabase_live:
        check_supabase_live(client_values, failures)

    if failures:
        print("release environment validation failed:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        sys.exit(1)

    edge_label = "client only" if args.client_only else "client + edge"
    url_label = " with public URL checks" if args.check_public_urls else ""
    live_label = " with Supabase live checks" if args.check_supabase_live else ""
    print(f"release environment valid: production {edge_label}{url_label}{live_label}")


if __name__ == "__main__":
    main()
