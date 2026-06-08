import argparse
import json
import re
import struct
import sys
import urllib.request
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
LISTING = ROOT / "assets" / "store" / "store_listing_ko.json"

REQUIRED_LEGAL_ROUTES = [
    "/legal/privacy/",
    "/legal/location/",
    "/legal/account-deletion/",
    "/legal/terms/",
]

LEGAL_ROUTE_CONTENT_TOKENS = {
    "/legal/privacy/": "필요한 정보만 수집",
    "/legal/location/": "주행 거리, 속도",
    "/legal/account-deletion/": "운영 큐에 접수",
    "/legal/terms/": "주행 효율을 게임처럼 비교",
}

REQUIRED_SCREENSHOTS = [
    "assets/store/screenshots/phone/01_home_league.png",
    "assets/store/screenshots/phone/02_vehicle_catalog.png",
    "assets/store/screenshots/phone/03_drive_score.png",
    "assets/store/screenshots/phone/04_battle_season.png",
    "assets/store/screenshots/phone/05_privacy_fairness.png",
]

FEATURE_GRAPHIC = "assets/store/feature_graphic_1024x500.png"

MOJIBAKE_RE = re.compile(r"[\ufffd\u00c0-\u00ff]|[一-龥豈-﫿]")
HANGUL_RE = re.compile(r"[가-힣]")


class Failure:
    def __init__(self, scope, message):
        self.scope = scope
        self.message = message

    def __str__(self):
        return f"{self.scope}: {self.message}"


def fail(failures, scope, message):
    failures.append(Failure(scope, message))


def load_listing(failures):
    if not LISTING.exists():
        fail(failures, str(LISTING.relative_to(ROOT)), "store listing JSON is missing")
        return None
    try:
        return json.loads(LISTING.read_text(encoding="utf-8"))
    except UnicodeDecodeError as error:
        fail(failures, str(LISTING.relative_to(ROOT)), f"must be UTF-8: {error}")
    except json.JSONDecodeError as error:
        fail(failures, str(LISTING.relative_to(ROOT)), f"invalid JSON: {error}")
    return None


def validate_korean_text(failures, scope, value, *, require_hangul=True):
    if not isinstance(value, str) or not value.strip():
        fail(failures, scope, "must be a non-empty string")
        return
    if require_hangul and not HANGUL_RE.search(value):
        fail(failures, scope, "must contain readable Korean text")
    if MOJIBAKE_RE.search(value):
        fail(failures, scope, "contains mojibake or non-Korean CJK glyphs")


def validate_listing_copy(data, failures):
    ko = data.get("ko") if isinstance(data, dict) else None
    if not isinstance(ko, dict):
        fail(failures, "store listing", "missing ko object")
        return

    app_name = ko.get("app_name")
    if app_name != "Fuel Arena":
        fail(failures, "app_name", "must be Fuel Arena")
    if isinstance(app_name, str) and len(app_name) > 30:
        fail(failures, "app_name", "must be 30 characters or fewer")

    short_description = ko.get("short_description")
    validate_korean_text(failures, "short_description", short_description)
    if isinstance(short_description, str) and len(short_description) > 80:
        fail(failures, "short_description", "must be 80 characters or fewer")

    descriptions = ko.get("full_description")
    if not isinstance(descriptions, list) or len(descriptions) < 4:
        fail(failures, "full_description", "must have at least 4 Korean paragraphs")
    else:
        total = "\n".join(str(item) for item in descriptions)
        if len(total) > 4000:
            fail(failures, "full_description", "must be 4000 characters or fewer")
        for index, paragraph in enumerate(descriptions):
            validate_korean_text(
                failures,
                f"full_description[{index}]",
                paragraph,
            )
        for token in [
            "연비 기록장이 아니라",
            "차량 제조사, 모델, 기준 연식, 엔진·미션 파워트레인",
            "주행 중에는 광고, 팝업, 도전장",
            "raw drive_points는 공개 화면에 노출하지 않습니다",
        ]:
            if token not in total:
                fail(failures, "full_description", f"missing release message: {token}")

    keywords = ko.get("keywords")
    if not isinstance(keywords, list) or len(keywords) < 5:
        fail(failures, "keywords", "must have at least 5 Korean keywords")
    else:
        keyword_total = ",".join(str(item) for item in keywords)
        if len(keyword_total) > 100:
            fail(failures, "keywords", "App Store keyword string must be 100 chars or fewer")
        for index, keyword in enumerate(keywords):
            validate_korean_text(failures, f"keywords[{index}]", keyword)

    if ko.get("support_routes") != REQUIRED_LEGAL_ROUTES:
        fail(failures, "support_routes", "must match the public legal route list")

    if ko.get("screenshots") != REQUIRED_SCREENSHOTS:
        fail(failures, "screenshots", "must match the five phone screenshot paths")

    if ko.get("feature_graphic") != FEATURE_GRAPHIC:
        fail(failures, "feature_graphic", "must point to the 1024x500 feature graphic")


def png_size(path):
    with path.open("rb") as file:
        header = file.read(24)
    if len(header) < 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise ValueError("not a PNG file")
    return struct.unpack(">II", header[16:24])


def inspect_png_content(failures, scope, path, *, min_color_buckets, min_ui_ratio):
    try:
        with Image.open(path) as image:
            image = image.convert("RGB")
            width, height = image.size
            step = max(1, min(width, height) // 180)
            unique = set()
            ui_pixels = 0
            samples = 0
            for y in range(0, height, step):
                for x in range(0, width, step):
                    r, g, b = image.getpixel((x, y))
                    unique.add((r // 8, g // 8, b // 8))
                    samples += 1
                    if max(r, g, b) >= 88 or max(r, g, b) - min(r, g, b) >= 42:
                        ui_pixels += 1
    except Exception as error:  # noqa: BLE001 - release diagnostics need exact image failure.
        fail(failures, scope, f"cannot inspect PNG content: {error}")
        return

    color_buckets = len(unique)
    ui_ratio = ui_pixels / samples if samples else 0.0
    if color_buckets < min_color_buckets:
        fail(
            failures,
            scope,
            f"has too few color buckets for a real store asset: {color_buckets}",
        )
    if ui_ratio < min_ui_ratio:
        fail(
            failures,
            scope,
            f"has too little visible UI/text contrast: {ui_ratio:.3f}",
        )


def validate_png(
    failures,
    path_text,
    expected_size,
    minimum_bytes,
    *,
    min_color_buckets,
    min_ui_ratio,
):
    path = ROOT / path_text
    scope = path_text
    if not path.exists():
        fail(failures, scope, "file is missing")
        return
    try:
        size = png_size(path)
    except ValueError as error:
        fail(failures, scope, str(error))
        return
    if size != expected_size:
        fail(failures, scope, f"expected {expected_size[0]}x{expected_size[1]}, got {size[0]}x{size[1]}")
    byte_size = path.stat().st_size
    if byte_size < minimum_bytes:
        fail(failures, scope, f"file is too small for a real store asset: {byte_size} bytes")
    inspect_png_content(
        failures,
        scope,
        path,
        min_color_buckets=min_color_buckets,
        min_ui_ratio=min_ui_ratio,
    )


def validate_assets(failures):
    validate_png(
        failures,
        FEATURE_GRAPHIC,
        (1024, 500),
        25000,
        min_color_buckets=120,
        min_ui_ratio=0.04,
    )
    for screenshot in REQUIRED_SCREENSHOTS:
        validate_png(
            failures,
            screenshot,
            (1080, 1920),
            120000,
            min_color_buckets=96,
            min_ui_ratio=0.04,
        )


def legal_path_for(route):
    slug = route.strip("/").split("/", 1)[1]
    return ROOT / "web" / "legal" / slug / "index.html"


def validate_legal_pages(failures):
    for route, token in LEGAL_ROUTE_CONTENT_TOKENS.items():
        path = legal_path_for(route)
        scope = route
        if not path.exists():
            fail(failures, scope, f"static legal page is missing: {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        for required in ['<html lang="ko">', '<meta name="viewport"', "Fuel Arena", token]:
            if required not in source:
                fail(failures, scope, f"static legal page missing {required}")


def validate_deployed_legal_urls(base_url, failures):
    normalized = base_url.rstrip("/")
    for route, token in LEGAL_ROUTE_CONTENT_TOKENS.items():
        url = f"{normalized}{route}"
        try:
            request = urllib.request.Request(
                url,
                headers={"User-Agent": "FuelArenaStoreSubmissionPreflight/1.0"},
            )
            with urllib.request.urlopen(request, timeout=10) as response:
                body = response.read(8192).decode("utf-8", errors="replace")
                if response.status >= 400:
                    fail(failures, url, f"returned HTTP {response.status}")
                if "<html" not in body or "Fuel Arena" not in body or token not in body:
                    fail(
                        failures,
                        url,
                        "does not look like the expected Fuel Arena legal page",
                    )
        except Exception as error:  # noqa: BLE001 - release diagnostics need the exact error.
            fail(failures, url, f"is not reachable: {error}")


def main():
    parser = argparse.ArgumentParser(
        description="Validate Korean store listing copy, screenshots, feature graphic, and legal pages before store submission."
    )
    parser.add_argument(
        "--base-url",
        help="Optional deployed HTTPS origin to fetch /legal/* pages from, for example https://fuelarena.example.com",
    )
    args = parser.parse_args()

    failures = []
    data = load_listing(failures)
    if data is not None:
        validate_listing_copy(data, failures)
    validate_assets(failures)
    validate_legal_pages(failures)

    if args.base_url:
        if not args.base_url.startswith("https://"):
            fail(failures, "--base-url", "must start with https://")
        else:
            validate_deployed_legal_urls(args.base_url, failures)

    if failures:
        print("store submission asset validation failed:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        sys.exit(1)

    deployment = " with deployed legal URL checks" if args.base_url else ""
    print(f"store submission assets valid{deployment}")


if __name__ == "__main__":
    main()
