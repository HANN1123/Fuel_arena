import argparse
import socket
import subprocess
import sys
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def run(label: str, command: list[str]) -> None:
    print(f"\n==> {label}", flush=True)
    print(" ".join(command), flush=True)
    subprocess.run(command, cwd=ROOT, check=True)


def is_port_open(host: str, port: int) -> bool:
    try:
        with socket.create_connection((host, port), timeout=0.3):
            return True
    except OSError:
        return False


def assert_port_free(host: str, port: int) -> None:
    if is_port_open(host, port):
        raise RuntimeError(
            f"{host}:{port} is already in use. Choose a free --port so the "
            "smoke test verifies the build it just served."
        )


def wait_for_port(host: str, port: int, timeout_seconds: float) -> None:
    deadline = time.monotonic() + timeout_seconds
    last_error: OSError | None = None
    while time.monotonic() < deadline:
        try:
            with socket.create_connection((host, port), timeout=0.5):
                return
        except OSError as error:
            last_error = error
            time.sleep(0.25)
    raise RuntimeError(f"server did not open {host}:{port}: {last_error}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Serve build/web and run Fuel Arena web render smoke tests.",
    )
    parser.add_argument("--directory", default="build/web")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=5173)
    parser.add_argument("--startup-timeout", type=float, default=20)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    assert_port_free(args.host, args.port)

    server = subprocess.Popen(
        [
            sys.executable,
            "tool/serve_web.py",
            "--directory",
            args.directory,
            "--host",
            args.host,
            "--port",
            str(args.port),
        ],
        cwd=ROOT,
    )
    try:
        wait_for_port(args.host, args.port, args.startup_timeout)
        if server.poll() is not None:
            raise RuntimeError(f"web server exited early with code {server.returncode}")

        base_url = f"http://{args.host}:{args.port}"
        run(
            "Web render smoke",
            [
                sys.executable,
                "tool/verify_web_render.py",
                "--url",
                f"{base_url}/#/auth/login",
            ],
        )
        run(
            "Web core routes smoke",
            [
                sys.executable,
                "tool/verify_web_core_routes.py",
                "--base-url",
                base_url,
            ],
        )
    finally:
        server.terminate()
        try:
            server.wait(timeout=5)
        except subprocess.TimeoutExpired:
            server.kill()
            server.wait(timeout=5)

    print("\nweb smoke passed", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
