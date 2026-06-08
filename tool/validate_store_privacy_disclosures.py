import json
import plistlib
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DISCLOSURES = ROOT / "assets" / "store" / "privacy_disclosures_ko.json"
IOS_PRIVACY = ROOT / "ios" / "Runner" / "PrivacyInfo.xcprivacy"
IOS_INFO = ROOT / "ios" / "Runner" / "Info.plist"
IOS_PROJECT = ROOT / "ios" / "Runner.xcodeproj" / "project.pbxproj"
ANDROID_MANIFEST = ROOT / "android" / "app" / "src" / "main" / "AndroidManifest.xml"

REQUIRED_APPLE_TYPES = {
    "NSPrivacyCollectedDataTypeUserID",
    "NSPrivacyCollectedDataTypePreciseLocation",
    "NSPrivacyCollectedDataTypeCoarseLocation",
    "NSPrivacyCollectedDataTypeProductInteraction",
    "NSPrivacyCollectedDataTypePurchaseHistory",
    "NSPrivacyCollectedDataTypeCustomerSupport",
    "NSPrivacyCollectedDataTypeAdvertisingData",
    "NSPrivacyCollectedDataTypeDeviceID",
}

REQUIRED_PLAY_CATEGORIES = {
    "위치",
    "개인 정보",
    "금융 정보",
    "앱 활동",
    "기기 또는 기타 ID",
}

REQUIRED_PUBLIC_URLS = {
    "privacy_policy": "/legal/privacy/",
    "location_notice": "/legal/location/",
    "account_deletion": "/legal/account-deletion/",
    "terms": "/legal/terms/",
}

MOJIBAKE_RE = re.compile(r"[\ufffd\u00c0-\u00ff]|[一-龥豈-\ufaff]")
HANGUL_RE = re.compile(r"[가-힣]")


class Failure:
    def __init__(self, scope, message):
        self.scope = scope
        self.message = message

    def __str__(self):
        return f"{self.scope}: {self.message}"


def fail(failures, scope, message):
    failures.append(Failure(scope, message))


def validate_no_mojibake_tree(failures, scope, value):
    if isinstance(value, dict):
        for key, item in value.items():
            validate_no_mojibake_tree(failures, f"{scope}.{key}", item)
    elif isinstance(value, list):
        for index, item in enumerate(value):
            validate_no_mojibake_tree(failures, f"{scope}[{index}]", item)
    elif isinstance(value, str) and MOJIBAKE_RE.search(value):
        fail(failures, scope, "contains mojibake or non-Korean CJK glyphs")


def validate_korean_text(failures, scope, value):
    if not isinstance(value, str) or not value.strip():
        fail(failures, scope, "must be a non-empty string")
        return
    if not HANGUL_RE.search(value):
        fail(failures, scope, "must contain readable Korean text")
    if MOJIBAKE_RE.search(value):
        fail(failures, scope, "contains mojibake or non-Korean CJK glyphs")


def validate_korean_list(failures, scope, values):
    if not isinstance(values, list) or not values:
        fail(failures, scope, "must be a non-empty list")
        return
    for index, value in enumerate(values):
        validate_korean_text(failures, f"{scope}[{index}]", value)


def read_json(path, failures):
    if not path.exists():
        fail(failures, str(path.relative_to(ROOT)), "file is missing")
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as error:  # noqa: BLE001 - preflight should report exact parse errors.
        fail(failures, str(path.relative_to(ROOT)), f"cannot parse JSON: {error}")
        return None


def validate_disclosures(data, failures):
    if not isinstance(data, dict):
        fail(failures, "privacy disclosures", "root must be an object")
        return
    validate_no_mojibake_tree(failures, "privacy disclosures", data)

    principles = data.get("principles")
    if not isinstance(principles, list):
        fail(failures, "principles", "must be a list")
    else:
        validate_korean_list(failures, "principles", principles)
        text = "\n".join(str(item) for item in principles)
        for token in [
            "raw drive_points는 공개",
            "service_role key",
            "주행 중에는 광고",
            "계정 삭제",
        ]:
            if token not in text:
                fail(failures, "principles", f"missing privacy principle: {token}")

    app_store = data.get("app_store_privacy", {})
    linked = app_store.get("data_linked_to_user", [])
    optional = app_store.get("data_not_linked_or_optional", [])
    declared_apple_types = {
        item.get("apple_data_type")
        for item in [*linked, *optional]
        if isinstance(item, dict)
    }
    for apple_type in REQUIRED_APPLE_TYPES:
        if apple_type not in declared_apple_types:
            fail(failures, "app_store_privacy", f"missing {apple_type}")
    tracking = app_store.get("tracking", {})
    if tracking.get("uses_tracking") is not False:
        fail(failures, "app_store_privacy.tracking", "uses_tracking must be false until ATT/AdMob tracking is explicitly configured")
    if "AdMob/Google SDK" not in tracking.get("notes", ""):
        fail(failures, "app_store_privacy.tracking", "must document AdMob/Google SDK follow-up")
    validate_korean_text(
        failures,
        "app_store_privacy.tracking.notes",
        tracking.get("notes", ""),
    )

    for group_name in ["data_linked_to_user", "data_not_linked_or_optional"]:
        for index, item in enumerate(app_store.get(group_name, [])):
            if not isinstance(item, dict):
                fail(failures, f"app_store_privacy.{group_name}[{index}]", "must be an object")
                continue
            validate_korean_text(
                failures,
                f"app_store_privacy.{group_name}[{index}].type",
                item.get("type", ""),
            )
            validate_korean_list(
                failures,
                f"app_store_privacy.{group_name}[{index}].purposes",
                item.get("purposes"),
            )
            validate_korean_list(
                failures,
                f"app_store_privacy.{group_name}[{index}].examples",
                item.get("examples"),
            )
            if "notes" in item:
                validate_korean_text(
                    failures,
                    f"app_store_privacy.{group_name}[{index}].notes",
                    item.get("notes", ""),
                )

    play = data.get("google_play_data_safety", {})
    categories = {
        item.get("category")
        for item in play.get("data_collected", [])
        if isinstance(item, dict)
    }
    for category in REQUIRED_PLAY_CATEGORIES:
        if category not in categories:
            fail(failures, "google_play_data_safety", f"missing category {category}")
    for index, item in enumerate(play.get("data_collected", [])):
        if not isinstance(item, dict):
            fail(failures, f"google_play_data_safety.data_collected[{index}]", "must be an object")
            continue
        validate_korean_text(
            failures,
            f"google_play_data_safety.data_collected[{index}].category",
            item.get("category", ""),
        )
        validate_korean_list(
            failures,
            f"google_play_data_safety.data_collected[{index}].types",
            item.get("types"),
        )
        validate_korean_list(
            failures,
            f"google_play_data_safety.data_collected[{index}].purposes",
            item.get("purposes"),
        )
    shared_text = json.dumps(play.get("data_shared", []), ensure_ascii=False)
    for token in ["Google AdMob", "Google OAuth", "Apple App Store / Google Play"]:
        if token not in shared_text:
            fail(failures, "google_play_data_safety.data_shared", f"missing recipient {token}")
    for index, item in enumerate(play.get("data_shared", [])):
        if not isinstance(item, dict):
            fail(failures, f"google_play_data_safety.data_shared[{index}]", "must be an object")
            continue
        validate_korean_text(
            failures,
            f"google_play_data_safety.data_shared[{index}].purpose",
            item.get("purpose", ""),
        )
        validate_korean_text(
            failures,
            f"google_play_data_safety.data_shared[{index}].user_control",
            item.get("user_control", ""),
        )
    controls = "\n".join(str(item) for item in play.get("security_and_controls", []))
    validate_korean_list(
        failures,
        "google_play_data_safety.security_and_controls",
        play.get("security_and_controls"),
    )
    for token in ["전송 중 암호화", "데이터 삭제", "raw drive_points", "service_role key"]:
        if token not in controls:
            fail(failures, "google_play_data_safety.security_and_controls", f"missing {token}")

    if data.get("public_urls") != REQUIRED_PUBLIC_URLS:
        fail(failures, "public_urls", "must match legal static routes")


def validate_ios_privacy_manifest(failures):
    if not IOS_PRIVACY.exists():
        fail(failures, str(IOS_PRIVACY.relative_to(ROOT)), "iOS privacy manifest is missing")
        return
    try:
        manifest = plistlib.loads(IOS_PRIVACY.read_bytes())
    except Exception as error:  # noqa: BLE001
        fail(failures, str(IOS_PRIVACY.relative_to(ROOT)), f"cannot parse plist: {error}")
        return
    if manifest.get("NSPrivacyTracking") is not False:
        fail(failures, "iOS privacy manifest", "NSPrivacyTracking must be false until tracking is explicitly configured")

    collected = manifest.get("NSPrivacyCollectedDataTypes", [])
    collected_types = {
        item.get("NSPrivacyCollectedDataType")
        for item in collected
        if isinstance(item, dict)
    }
    for apple_type in REQUIRED_APPLE_TYPES:
        if apple_type not in collected_types:
            fail(failures, "iOS privacy manifest", f"missing {apple_type}")

    accessed = manifest.get("NSPrivacyAccessedAPITypes", [])
    user_defaults = [
        item
        for item in accessed
        if item.get("NSPrivacyAccessedAPIType")
        == "NSPrivacyAccessedAPICategoryUserDefaults"
    ]
    if not user_defaults:
        fail(failures, "iOS privacy manifest", "missing UserDefaults required reason API")
    elif "CA92.1" not in user_defaults[0].get("NSPrivacyAccessedAPITypeReasons", []):
        fail(failures, "iOS privacy manifest", "UserDefaults must declare CA92.1")

    project = IOS_PROJECT.read_text(encoding="utf-8") if IOS_PROJECT.exists() else ""
    if "PrivacyInfo.xcprivacy in Resources" not in project:
        fail(failures, "iOS project", "PrivacyInfo.xcprivacy must be in Runner resources")


def validate_platform_manifests(failures):
    if not IOS_INFO.exists():
        fail(failures, str(IOS_INFO.relative_to(ROOT)), "Info.plist is missing")
    else:
        info = plistlib.loads(IOS_INFO.read_bytes())
        for key in [
            "NSLocationWhenInUseUsageDescription",
            "NSUserNotificationUsageDescription",
            "NSUserTrackingUsageDescription",
        ]:
            value = info.get(key, "")
            validate_korean_text(failures, f"Info.plist.{key}", value)

    if not ANDROID_MANIFEST.exists():
        fail(failures, str(ANDROID_MANIFEST.relative_to(ROOT)), "Android manifest is missing")
    else:
        root = ET.fromstring(ANDROID_MANIFEST.read_text(encoding="utf-8"))
        android_name = "{http://schemas.android.com/apk/res/android}name"
        permissions = {
            item.attrib.get(android_name)
            for item in root.findall("uses-permission")
        }
        for permission in [
            "android.permission.ACCESS_FINE_LOCATION",
            "android.permission.ACCESS_COARSE_LOCATION",
            "android.permission.POST_NOTIFICATIONS",
            "com.google.android.gms.permission.AD_ID",
        ]:
            if permission not in permissions:
                fail(failures, "AndroidManifest.xml", f"missing {permission}")


def validate_docs(failures):
    docs = ROOT / "docs" / "23_store_privacy_disclosures.md"
    if not docs.exists():
        fail(failures, str(docs.relative_to(ROOT)), "privacy disclosure guide is missing")
        return
    source = docs.read_text(encoding="utf-8")
    validate_korean_text(failures, str(docs.relative_to(ROOT)), source)
    for token in [
        "python tool/validate_store_privacy_disclosures.py",
        "PrivacyInfo.xcprivacy",
        "Android Data Safety",
        "raw drive_points",
        "AdMob/Google SDK",
    ]:
        if token not in source:
            fail(failures, str(docs.relative_to(ROOT)), f"missing {token}")


def main():
    failures = []
    data = read_json(DISCLOSURES, failures)
    if data is not None:
        validate_disclosures(data, failures)
    validate_ios_privacy_manifest(failures)
    validate_platform_manifests(failures)
    validate_docs(failures)

    if failures:
        print("store privacy disclosure validation failed:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        sys.exit(1)

    print("store privacy disclosures valid")


if __name__ == "__main__":
    main()
