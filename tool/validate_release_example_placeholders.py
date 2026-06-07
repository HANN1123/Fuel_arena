import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

REQUIRED_OUTPUT = [
    "release environment validation failed",
    "SUPABASE_URL is missing or placeholder",
    "SUPABASE_ANON_KEY is missing or placeholder",
    "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON is missing or placeholder",
    "APP_STORE_CONNECT_KEY_ID must be 10 uppercase alphanumeric",
]


def main() -> int:
    command = [
        sys.executable,
        "tool/validate_release_environment.py",
        "--env-file",
        ".env.production.example",
        "--edge-secrets-file",
        ".env.edge.production.example",
    ]
    result = subprocess.run(
        command,
        cwd=ROOT,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if result.stdout:
        print(result.stdout, end="" if result.stdout.endswith("\n") else "\n")

    if result.returncode == 0:
        print(
            "release example placeholder validation failed: example env files "
            "unexpectedly passed",
            file=sys.stderr,
        )
        return 1

    missing = [fragment for fragment in REQUIRED_OUTPUT if fragment not in result.stdout]
    if missing:
        print(
            "release example placeholder validation failed: missing guard "
            f"output: {', '.join(missing)}",
            file=sys.stderr,
        )
        return 1

    print("release example placeholders rejected as expected")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
