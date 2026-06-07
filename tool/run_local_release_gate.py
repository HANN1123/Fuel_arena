import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _repo_tool_executable(name: str) -> str | None:
    candidates: list[Path] = []
    home = Path.home()
    if name == "flutter":
        candidates.extend(
            [
                home / ".codex" / "tools" / "flutter" / "bin" / "flutter.bat",
                home / ".codex" / "tools" / "flutter" / "bin" / "flutter",
            ]
        )
    if name == "dart":
        candidates.extend(
            [
                home / ".codex" / "tools" / "flutter" / "bin" / "dart.bat",
                home / ".codex" / "tools" / "flutter" / "bin" / "dart",
            ]
        )
    for candidate in candidates:
        if candidate.exists():
            return str(candidate)
    return None


def _resolve_executable(env_name: str, executable: str) -> str:
    env_value = os.environ.get(env_name, "")
    if env_value:
        return env_value
    found = shutil.which(executable)
    if found:
        return found
    bundled = _repo_tool_executable(executable)
    if bundled:
        return bundled
    return executable


def _run(label: str, command: list[str]) -> None:
    print(f"\n==> {label}", flush=True)
    print(" ".join(command), flush=True)
    subprocess.run(command, cwd=ROOT, check=True)


def _web_smoke(python: str, label: str, port: int) -> None:
    _run(
        label,
        [
            python,
            "tool/run_web_smoke.py",
            "--port",
            str(port),
        ],
    )


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Run the local release gate that mirrors Flutter CI.",
    )
    parser.add_argument(
        "--skip-android",
        action="store_true",
        help="Skip the Android debug APK build.",
    )
    parser.add_argument(
        "--skip-wasm",
        action="store_true",
        help="Skip the Flutter Web Wasm compatibility build and smoke.",
    )
    parser.add_argument(
        "--skip-web-smoke",
        action="store_true",
        help="Skip serving build/web and running browser smoke tests.",
    )
    parser.add_argument(
        "--skip-format",
        action="store_true",
        help="Skip dart format --set-exit-if-changed.",
    )
    parser.add_argument(
        "--quick",
        action="store_true",
        help="Run validators, format, analyze, and tests only.",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=6173,
        help="Local port for web smoke tests. Defaults to 6173.",
    )
    return parser


def main() -> int:
    args = _build_parser().parse_args()
    flutter = _resolve_executable("FLUTTER_BIN", "flutter")
    dart = _resolve_executable("DART_BIN", "dart")
    python = sys.executable

    try:
        _run("Dependencies", [flutter, "pub", "get"])
        _run("Python tool dependencies", [python, "-m", "pip", "install", "-r", "requirements-dev.txt"])
        _run("Vehicle catalog integrity", [dart, "run", "tool/validate_vehicle_catalog.dart"])
        _run("Edge Function smoke validation", [dart, "run", "tool/validate_edge_functions.dart"])
        _run("Supabase schema validation", [dart, "run", "tool/validate_supabase_schema.dart"])
        _run("Product invariant validation", [dart, "run", "tool/validate_product_invariants.dart"])
        _run("Store submission asset validation", [python, "tool/validate_store_submission_assets.py"])
        _run("Store privacy disclosure validation", [python, "tool/validate_store_privacy_disclosures.py"])
        _run("Release environment validator self-test", [python, "tool/validate_release_environment_selftest.py"])
        _run(
            "Release example placeholder rejection",
            [python, "tool/validate_release_example_placeholders.py"],
        )
        if not args.skip_format:
            _run("Format check", [dart, "format", "--set-exit-if-changed", "."])
        _run("Analyze", [flutter, "analyze"])
        _run("Test", [flutter, "test"])

        if args.quick:
            print("\nlocal release gate passed (quick)", flush=True)
            return 0

        if not args.skip_android:
            _run("Build Android debug", [flutter, "build", "apk", "--debug"])

        if not args.skip_wasm:
            _run(
                "Build web Wasm compatibility",
                [flutter, "build", "web", "--wasm"],
            )
            if not args.skip_web_smoke:
                _web_smoke(python, "Web Wasm compatibility smoke", args.port)

        _run("Build web", [flutter, "build", "web"])
        if not args.skip_web_smoke:
            _web_smoke(python, "Web runtime smoke", args.port)
    except subprocess.CalledProcessError as error:
        print(f"\nlocal release gate failed: {error}", file=sys.stderr, flush=True)
        return error.returncode or 1
    except Exception as error:
        print(f"\nlocal release gate failed: {error}", file=sys.stderr, flush=True)
        return 1

    print("\nlocal release gate passed", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
