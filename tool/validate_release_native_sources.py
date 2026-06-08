import sys
from pathlib import Path

from validate_release_environment import (
    Failure,
    parse_plist_file,
    parse_xml_file,
    validate_android_manifest,
    validate_ios_info_plist,
)


ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    failures: list[Failure] = []
    validate_ios_info_plist(
        parse_plist_file(ROOT / "ios" / "Runner" / "Info.plist"),
        failures,
    )
    validate_android_manifest(
        parse_xml_file(
            ROOT / "android" / "app" / "src" / "main" / "AndroidManifest.xml",
            "Android manifest",
        ),
        failures,
    )

    if failures:
        print("release native source validation failed:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1

    print("release native sources valid: iOS Info.plist + AndroidManifest.xml")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
