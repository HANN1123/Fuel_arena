import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

ALLOWED_ENV_EXAMPLES = {
    ".env.example",
    ".env.production.example",
    ".env.staging.example",
    ".env.edge.production.example",
}

FORBIDDEN_TRACKED_NAMES = {
    "key.properties",
    "FuelArenaSecrets.xcconfig",
    "google-services.json",
    "GoogleService-Info.plist",
}

FORBIDDEN_TRACKED_SUFFIXES = {
    ".jks",
    ".keystore",
    ".p8",
    ".mobileprovision",
}

REQUIRED_GITIGNORE_TOKENS = {
    ".gitignore": [
        ".env",
        ".env.*",
        "!.env.example",
        "!.env.production.example",
        "!.env.staging.example",
        "!.env.edge.production.example",
        "*.p8",
        "*.mobileprovision",
        "google-services.json",
        "GoogleService-Info.plist",
    ],
    "android/.gitignore": [
        "key.properties",
        "**/*.keystore",
        "**/*.jks",
    ],
    "ios/.gitignore": [
        "Flutter/FuelArenaSecrets.xcconfig",
    ],
}

SECRET_IGNORE_CANDIDATES = [
    ".env",
    ".env.production",
    ".env.edge.production",
    "android/key.properties",
    "android/app/upload.keystore",
    "android/app/upload.jks",
    "android/app/google-services.json",
    "ios/Flutter/FuelArenaSecrets.xcconfig",
    "ios/Runner/GoogleService-Info.plist",
    "ios/AuthKey_FUELARENA.p8",
    "ios/FuelArena.mobileprovision",
]


class Failure:
    def __init__(self, scope, message):
        self.scope = scope
        self.message = message

    def __str__(self):
        return f"{self.scope}: {self.message}"


def tracked_files():
    result = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=ROOT,
        check=True,
        stdout=subprocess.PIPE,
    )
    return [
        item.decode("utf-8", errors="replace").replace("\\", "/")
        for item in result.stdout.split(b"\0")
        if item
    ]


def unignored_untracked_files():
    result = subprocess.run(
        ["git", "ls-files", "--others", "--exclude-standard", "-z"],
        cwd=ROOT,
        check=True,
        stdout=subprocess.PIPE,
    )
    return [
        item.decode("utf-8", errors="replace").replace("\\", "/")
        for item in result.stdout.split(b"\0")
        if item
    ]


def git_check_ignore(path):
    result = subprocess.run(
        ["git", "check-ignore", "-q", "--", path],
        cwd=ROOT,
    )
    return result.returncode == 0


def validate_tracked_file_names(files, failures):
    for path in files:
        name = Path(path).name
        suffix = Path(path).suffix
        if name.startswith(".env") and path not in ALLOWED_ENV_EXAMPLES:
            failures.append(Failure(path, "tracked env files must be example files only"))
        if name in FORBIDDEN_TRACKED_NAMES:
            failures.append(Failure(path, "tracked production secret file name is forbidden"))
        if suffix in FORBIDDEN_TRACKED_SUFFIXES:
            failures.append(Failure(path, f"tracked {suffix} secret artifact is forbidden"))


def validate_gitignore_tokens(failures):
    for path_text, tokens in REQUIRED_GITIGNORE_TOKENS.items():
        path = ROOT / path_text
        if not path.exists():
            failures.append(Failure(path_text, "gitignore file is missing"))
            continue
        source = path.read_text(encoding="utf-8")
        for token in tokens:
            if token not in source:
                failures.append(Failure(path_text, f"missing gitignore token {token}"))


def validate_secret_candidates_are_ignored(failures):
    for path in SECRET_IGNORE_CANDIDATES:
        if not git_check_ignore(path):
            failures.append(Failure(path, "local secret candidate is not ignored by git"))


def main():
    failures: list[Failure] = []
    try:
        files = tracked_files()
    except Exception as error:  # noqa: BLE001 - release diagnostics need exact failure.
        failures.append(Failure("git ls-files", f"cannot inspect tracked files: {error}"))
        files = []

    validate_tracked_file_names(files, failures)
    try:
        untracked_files = unignored_untracked_files()
    except Exception as error:  # noqa: BLE001 - release diagnostics need exact failure.
        failures.append(
            Failure("git ls-files --others", f"cannot inspect untracked files: {error}")
        )
        untracked_files = []
    validate_tracked_file_names(untracked_files, failures)
    validate_gitignore_tokens(failures)
    validate_secret_candidates_are_ignored(failures)

    if failures:
        print("secret hygiene validation failed:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1

    print("secret hygiene valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
