import argparse
import os
import tempfile
from pathlib import Path

from verify_web_render import (
    assert_url_reachable,
    capture,
    inspect_image,
    resolve_chrome,
)


DEFAULT_ROUTE_CASES = [
    ("/auth/login", "390,844"),
    ("/consent", "390,844"),
    ("/setup/vehicle", "390,844"),
    ("/home", "390,844"),
    ("/home?tab=ranking", "390,844"),
    ("/home?tab=profile", "390,844"),
    ("/premium", "390,844"),
    ("/fairness", "390,844"),
    ("/support", "390,844"),
    ("/admin", "1440,1000"),
    ("/admin/vehicles", "1440,1000"),
    ("/admin/vehicle-generations", "1440,1000"),
    ("/admin/vehicle-generations/quality", "1440,1000"),
    ("/admin/vehicle-generations/bmw", "1440,1000"),
]

DEFAULT_ROUTES = [route for route, _ in DEFAULT_ROUTE_CASES]


def build_url(base_url: str, route: str, index: int) -> str:
    base = base_url.rstrip("/")
    route = route if route.startswith("/") else f"/{route}"
    return f"{base}/?verify=web-core-route-{index}#{route}"


def verify_route(chrome, url, args, window_size):
    assert_url_reachable(url)
    fd, raw_output = tempfile.mkstemp(
        prefix="fuel_arena_route_",
        suffix=".png",
    )
    os.close(fd)
    output = Path(raw_output)
    try:
        capture(
            chrome,
            url,
            output,
            window_size,
            args.virtual_time_budget,
        )
        return inspect_image(
            output,
            args.min_bytes,
            args.min_unique_colors,
            args.min_ui_ratio,
        )
    finally:
        output.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(
        description="Verify built Flutter Web core routes render visible UI."
    )
    parser.add_argument("--base-url", default="http://127.0.0.1:5173")
    parser.add_argument("--chrome")
    parser.add_argument("--route", action="append", dest="routes")
    parser.add_argument("--window-size", default="390,844")
    parser.add_argument("--virtual-time-budget", type=int, default=15000)
    parser.add_argument("--min-bytes", type=int, default=25000)
    parser.add_argument("--min-unique-colors", type=int, default=48)
    parser.add_argument("--min-ui-ratio", type=float, default=0.015)
    args = parser.parse_args()

    chrome = resolve_chrome(args.chrome)
    route_cases = (
        [(route, args.window_size) for route in args.routes]
        if args.routes
        else DEFAULT_ROUTE_CASES
    )
    results = []
    for index, (route, window_size) in enumerate(route_cases, start=1):
        url = build_url(args.base_url, route, index)
        stats = verify_route(chrome, url, args, window_size)
        results.append((route, window_size, stats))

    print(f"web core routes smoke passed: {len(results)} routes")
    for route, window_size, stats in results:
        print(
            f"- {route} @ {window_size}: {stats['width']}x{stats['height']}, "
            f"{stats['unique_colors']} color buckets, "
            f"ui_ratio={stats['ui_ratio']:.3f}"
        )


if __name__ == "__main__":
    main()
