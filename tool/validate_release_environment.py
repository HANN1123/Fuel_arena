import argparse
import base64
import json
import os
import plistlib
import re
import sys
import xml.etree.ElementTree as ET
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

PUBLIC_LEGAL_URL_PATHS = {
    "PUBLIC_PRIVACY_POLICY_URL": "/legal/privacy/",
    "PUBLIC_LOCATION_NOTICE_URL": "/legal/location/",
    "PUBLIC_ACCOUNT_DELETION_URL": "/legal/account-deletion/",
    "PUBLIC_TERMS_URL": "/legal/terms/",
}

PUBLIC_LEGAL_URL_CONTENT_TOKENS = {
    "PUBLIC_PRIVACY_POLICY_URL": "필요한 정보만 수집",
    "PUBLIC_LOCATION_NOTICE_URL": "주행 거리, 속도",
    "PUBLIC_ACCOUNT_DELETION_URL": "운영 큐에 접수",
    "PUBLIC_TERMS_URL": "주행 효율을 게임처럼 비교",
}

CLIENT_REQUIRED = [
    "APP_ENV",
    "SUPABASE_URL",
    "SUPABASE_ANON_KEY",
    "GOOGLE_WEB_CLIENT_ID",
    "GOOGLE_ANDROID_CLIENT_ID",
    "GOOGLE_ANDROID_RELEASE_PACKAGE_NAME",
    "GOOGLE_ANDROID_RELEASE_SHA1",
    "GOOGLE_ANDROID_RELEASE_SHA256",
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

IOS_XCCONFIG_REQUIRED = [
    "ADMOB_IOS_APP_ID",
    "GOOGLE_IOS_CLIENT_ID",
    "GOOGLE_SERVER_CLIENT_ID",
    "GOOGLE_REVERSED_IOS_CLIENT_ID",
]

ANDROID_KEY_PROPERTIES_REQUIRED = [
    "storeFile",
    "storePassword",
    "keyAlias",
    "keyPassword",
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
ANDROID_PACKAGE_NAME = "com.fuelarena.fuel_arena"
SHA1_FINGERPRINT_PATTERN = re.compile(r"^(?:[0-9A-Fa-f]{2}:){19}[0-9A-Fa-f]{2}$")
SHA256_FINGERPRINT_PATTERN = re.compile(r"^(?:[0-9A-Fa-f]{2}:){31}[0-9A-Fa-f]{2}$")
HANGUL_PATTERN = re.compile(r"[\uac00-\ud7a3]")
CJK_PATTERN = re.compile(r"[\u4e00-\u9fff]")
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


def parse_xcconfig_file(path):
    values = {}
    if not path:
        return values
    file_path = Path(path)
    if not file_path.exists():
        raise SystemExit(f"iOS xcconfig file does not exist: {file_path}")
    for raw_line in file_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or line.startswith("//") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        value = value.split("//", 1)[0].strip().rstrip(";").strip()
        values[key.strip().lstrip("\ufeff")] = strip_quotes(value)
    return values


def parse_plist_file(path):
    file_path = Path(path)
    if not file_path.exists():
        raise SystemExit(f"iOS plist file does not exist: {file_path}")
    return plistlib.loads(file_path.read_bytes())


def parse_xml_file(path, label):
    file_path = Path(path)
    if not file_path.exists():
        raise SystemExit(f"{label} file does not exist: {file_path}")
    try:
        return ET.parse(file_path).getroot()
    except ET.ParseError as error:
        raise SystemExit(f"{label} XML is invalid: {error}") from error


def parse_properties_file(path):
    values = {}
    if not path:
        return values
    file_path = Path(path)
    if not file_path.exists():
        raise SystemExit(f"properties file does not exist: {file_path}")
    for raw_line in file_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or line.startswith("!"):
            continue
        separator = "=" if "=" in line else ":"
        if separator not in line:
            continue
        key, value = line.split(separator, 1)
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


def expected_reversed_ios_client_id(ios_client_id):
    suffix = ".apps.googleusercontent.com"
    if not ios_client_id.endswith(suffix):
        return ""
    client_prefix = ios_client_id[: -len(suffix)]
    if not client_prefix:
        return ""
    return f"com.googleusercontent.apps.{client_prefix}"


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

    if values.get("GOOGLE_ANDROID_RELEASE_PACKAGE_NAME", "") != ANDROID_PACKAGE_NAME:
        failures.append(
            Failure(
                "client env",
                f"GOOGLE_ANDROID_RELEASE_PACKAGE_NAME must be {ANDROID_PACKAGE_NAME}",
            )
        )
    android_sha1 = values.get("GOOGLE_ANDROID_RELEASE_SHA1", "")
    if android_sha1 and not SHA1_FINGERPRINT_PATTERN.match(android_sha1):
        failures.append(
            Failure(
                "client env",
                "GOOGLE_ANDROID_RELEASE_SHA1 must be a colon-separated SHA-1 fingerprint",
            )
        )
    android_sha256 = values.get("GOOGLE_ANDROID_RELEASE_SHA256", "")
    if android_sha256 and not SHA256_FINGERPRINT_PATTERN.match(android_sha256):
        failures.append(
            Failure(
                "client env",
                "GOOGLE_ANDROID_RELEASE_SHA256 must be a colon-separated SHA-256 fingerprint",
            )
        )

    reversed_id = values.get("GOOGLE_REVERSED_IOS_CLIENT_ID", "")
    if reversed_id and not reversed_id.startswith("com.googleusercontent.apps."):
        failures.append(
            Failure(
                "client env",
                "GOOGLE_REVERSED_IOS_CLIENT_ID must start with com.googleusercontent.apps.",
            )
        )
    expected_reversed_id = expected_reversed_ios_client_id(
        values.get("GOOGLE_IOS_CLIENT_ID", "")
    )
    if (
        reversed_id
        and expected_reversed_id
        and reversed_id != expected_reversed_id
    ):
        failures.append(
            Failure(
                "client env",
                "GOOGLE_REVERSED_IOS_CLIENT_ID must match GOOGLE_IOS_CLIENT_ID "
                f"(expected {expected_reversed_id})",
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

    legal_url_origins = {}
    for key, expected_path in PUBLIC_LEGAL_URL_PATHS.items():
        value = values.get(key, "")
        if value and not value.startswith("https://"):
            failures.append(Failure("client env", f"{key} must be an https URL"))
            continue
        parsed = urllib.parse.urlparse(value)
        if value and parsed.scheme == "https" and parsed.netloc:
            legal_url_origins[key] = f"{parsed.scheme}://{parsed.netloc}"
        normalized_path = parsed.path.rstrip("/") + "/"
        if value and normalized_path != expected_path:
            failures.append(
                Failure(
                    "client env",
                    f"{key} must point to {expected_path}",
                )
            )
        if value and (parsed.query or parsed.fragment):
            failures.append(
                Failure(
                    "client env",
                    f"{key} must not include query or fragment",
                )
            )
    if len(set(legal_url_origins.values())) > 1:
        failures.append(
            Failure(
                "client env",
                "PUBLIC legal URLs must share the same origin",
            )
        )


def validate_ios_xcconfig(values, client_values, failures):
    require_present(failures, values, IOS_XCCONFIG_REQUIRED, "iOS xcconfig")

    for key in IOS_XCCONFIG_REQUIRED:
        xcconfig_value = values.get(key, "").strip()
        client_value = client_values.get(key, "").strip()
        if (
            xcconfig_value
            and client_value
            and not is_placeholder(xcconfig_value)
            and not is_placeholder(client_value)
            and xcconfig_value != client_value
        ):
            failures.append(
                Failure(
                    "iOS xcconfig",
                    f"{key} must match .env.production {key}",
                )
            )

    reversed_id = values.get("GOOGLE_REVERSED_IOS_CLIENT_ID", "")
    expected_reversed_id = expected_reversed_ios_client_id(
        values.get("GOOGLE_IOS_CLIENT_ID", "")
    )
    if (
        reversed_id
        and expected_reversed_id
        and not is_placeholder(reversed_id)
        and reversed_id != expected_reversed_id
    ):
        failures.append(
            Failure(
                "iOS xcconfig",
                "GOOGLE_REVERSED_IOS_CLIENT_ID must match GOOGLE_IOS_CLIENT_ID "
                f"in iOS xcconfig (expected {expected_reversed_id})",
            )
        )


def validate_ios_info_plist(values, failures):
    expected_settings = {
        "GADApplicationIdentifier": "$(ADMOB_IOS_APP_ID)",
        "GIDClientID": "$(GOOGLE_IOS_CLIENT_ID)",
        "GIDServerClientID": "$(GOOGLE_SERVER_CLIENT_ID)",
    }
    for key, expected_value in expected_settings.items():
        actual_value = values.get(key, "")
        if actual_value != expected_value:
            failures.append(
                Failure(
                    "iOS Info.plist",
                    f"{key} must be {expected_value}",
                )
            )

    expected_usage_copy = {
        "NSLocationWhenInUseUsageDescription":
            "주행 거리와 지역 리그 계산을 위해 위치 정보가 필요합니다.",
        "NSUserNotificationUsageDescription":
            "랭킹 추월, 배틀 결과, 시즌 보상을 알려드리기 위해 알림을 사용합니다.",
        "NSUserTrackingUsageDescription":
            "개인 맞춤 광고 제공 여부를 사용자가 선택할 수 있도록 광고 식별자 사용 가능성을 안내합니다.",
    }
    for key, expected_value in expected_usage_copy.items():
        actual_value = values.get(key, "")
        if actual_value != expected_value:
            failures.append(
                Failure(
                    "iOS Info.plist",
                    f"{key} must use approved Korean copy",
                )
            )
        if (
            not isinstance(actual_value, str)
            or not HANGUL_PATTERN.search(actual_value)
            or CJK_PATTERN.search(actual_value)
            or "\ufffd" in actual_value
        ):
            failures.append(
                Failure(
                    "iOS Info.plist",
                    f"{key} must contain readable Korean copy without mojibake",
                )
            )

    url_schemes = []
    for item in values.get("CFBundleURLTypes", []):
        if isinstance(item, dict):
            url_schemes.extend(item.get("CFBundleURLSchemes", []))
    for scheme in ["$(GOOGLE_REVERSED_IOS_CLIENT_ID)", "fuelarena"]:
        if scheme not in url_schemes:
            failures.append(
                Failure(
                    "iOS Info.plist",
                    f"CFBundleURLSchemes must include {scheme}",
                )
            )


def android_store_file_path(key_properties_path, store_file):
    raw_path = Path(store_file)
    if raw_path.is_absolute():
        return raw_path
    return (Path(key_properties_path).parent / "app" / raw_path).resolve()


def validate_android_key_properties(values, key_properties_path, failures):
    require_present(
        failures,
        values,
        ANDROID_KEY_PROPERTIES_REQUIRED,
        "Android key.properties",
    )

    store_file = values.get("storeFile", "").strip()
    if store_file and not is_placeholder(store_file):
        resolved_store_file = android_store_file_path(key_properties_path, store_file)
        lower_store_file = str(resolved_store_file).lower()
        if "debug" in lower_store_file or "androiddebugkey" in lower_store_file:
            failures.append(
                Failure(
                    "Android key.properties",
                    "storeFile must not point at a debug keystore",
                )
            )
        if resolved_store_file.suffix.lower() not in {".jks", ".keystore"}:
            failures.append(
                Failure(
                    "Android key.properties",
                    "storeFile should point to a .jks or .keystore upload keystore",
                )
            )
        if not resolved_store_file.is_file():
            failures.append(
                Failure(
                    "Android key.properties",
                    f"storeFile does not exist: {resolved_store_file}",
                )
            )

    key_alias = values.get("keyAlias", "").strip().lower()
    if key_alias == "androiddebugkey":
        failures.append(
            Failure(
                "Android key.properties",
                "keyAlias must not use androiddebugkey",
            )
        )

    for key in ["storePassword", "keyPassword"]:
        value = values.get(key, "")
        if value and not is_placeholder(value) and len(value) < 12:
            failures.append(
                Failure(
                    "Android key.properties",
                    f"{key} must be at least 12 characters for release signing",
                )
            )


def validate_android_manifest(root, failures):
    android_namespace = "{http://schemas.android.com/apk/res/android}"
    application = root.find("application")
    if application is None:
        failures.append(Failure("Android manifest", "application node is missing"))
        return

    cleartext = application.attrib.get(f"{android_namespace}usesCleartextTraffic")
    if cleartext != "false":
        failures.append(
            Failure(
                "Android manifest",
                "application must set android:usesCleartextTraffic=\"false\"",
            )
        )

    admob_metadata_found = False
    for metadata in application.findall("meta-data"):
        name = metadata.attrib.get(f"{android_namespace}name", "")
        value = metadata.attrib.get(f"{android_namespace}value", "")
        if name == "com.google.android.gms.ads.APPLICATION_ID":
            admob_metadata_found = True
            if value != "${ADMOB_ANDROID_APP_ID}":
                failures.append(
                    Failure(
                        "Android manifest",
                        "AdMob APPLICATION_ID must use ${ADMOB_ANDROID_APP_ID}",
                    )
                )
    if not admob_metadata_found:
        failures.append(
            Failure(
                "Android manifest",
                "AdMob APPLICATION_ID meta-data is missing",
            )
        )

    callback_found = False
    for data in application.findall(".//data"):
        scheme = data.attrib.get(f"{android_namespace}scheme", "")
        host = data.attrib.get(f"{android_namespace}host", "")
        if scheme == "${APP_AUTH_REDIRECT_SCHEME}" and host == "${APP_AUTH_REDIRECT_HOST}":
            callback_found = True
            break
    if not callback_found:
        failures.append(
            Failure(
                "Android manifest",
                "OAuth callback data must use APP_AUTH_REDIRECT_SCHEME/HOST placeholders",
            )
        )


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


def check_public_urls(values, failures, urlopen=None):
    if urlopen is None:
        urlopen = urllib.request.urlopen
    for key, expected_token in PUBLIC_LEGAL_URL_CONTENT_TOKENS.items():
        url = values.get(key, "")
        if not url:
            continue
        try:
            request = urllib.request.Request(
                url,
                headers={"User-Agent": "FuelArenaReleasePreflight/1.0"},
            )
            with urlopen(request, timeout=10) as response:
                if response.status >= 400:
                    failures.append(Failure("public url", f"{key} returned {response.status}"))
                    continue
                body = response.read(8192).decode("utf-8", errors="replace")
                for token in ["<html", "Fuel Arena", expected_token]:
                    if token not in body:
                        failures.append(
                            Failure(
                                "public url",
                                f"{key} does not look like the expected Fuel Arena legal page",
                            )
                        )
                        break
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

    cors_origin = public_web_origin(values) or "https://fuelarena.app"
    for function_name in EDGE_FUNCTION_NAMES:
        url = f"{base_url}/functions/v1/{urllib.parse.quote(function_name)}"
        try:
            request = urllib.request.Request(
                url,
                method="OPTIONS",
                headers={
                    "Origin": cors_origin,
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
        allow_origin = headers.get("access-control-allow-origin", "")
        if allow_origin not in {"*", cors_origin}:
            failures.append(
                Failure(
                    "supabase live",
                    f"{function_name} CORS origin must allow {cors_origin}",
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
    parser.add_argument(
        "--ios-xcconfig",
        help="Validate ios/Flutter/FuelArenaSecrets.xcconfig against .env.production.",
    )
    parser.add_argument(
        "--ios-info-plist",
        help="Validate Runner Info.plist Google/AdMob build-setting references.",
    )
    parser.add_argument(
        "--android-key-properties",
        help="Validate android/key.properties and the referenced upload keystore.",
    )
    parser.add_argument(
        "--android-manifest",
        help="Validate Android manifest AdMob and OAuth callback placeholders.",
    )
    args = parser.parse_args()

    failures = []
    client_values = merged_env(args.env_file)
    validate_client(client_values, failures)
    if args.ios_xcconfig:
        validate_ios_xcconfig(
            parse_xcconfig_file(args.ios_xcconfig),
            client_values,
            failures,
        )
    if args.ios_info_plist:
        validate_ios_info_plist(parse_plist_file(args.ios_info_plist), failures)
    if args.android_key_properties:
        validate_android_key_properties(
            parse_properties_file(args.android_key_properties),
            args.android_key_properties,
            failures,
        )
    if args.android_manifest:
        validate_android_manifest(
            parse_xml_file(args.android_manifest, "Android manifest"),
            failures,
        )

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
    android_label = (
        " with Android signing checks" if args.android_key_properties else ""
    )
    native_label = (
        " with native source checks"
        if args.ios_info_plist or args.android_manifest
        else ""
    )
    print(
        f"release environment valid: production "
        f"{edge_label}{android_label}{native_label}{url_label}{live_label}"
    )


if __name__ == "__main__":
    main()
