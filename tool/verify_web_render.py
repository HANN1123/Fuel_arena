import argparse
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path

from PIL import Image


DEFAULT_URL = (
    "http://127.0.0.1:5173/?verify=web-render-smoke#/setup/vehicle"
)


def chrome_candidates():
    env = os.environ.get("CHROME_PATH")
    if env:
        yield Path(env)

    for name in (
        "chrome",
        "google-chrome",
        "google-chrome-stable",
        "chromium",
        "chromium-browser",
        "msedge",
    ):
        found = shutil.which(name)
        if found:
            yield Path(found)

    if sys.platform.startswith("win"):
        for raw in (
            r"C:\Program Files\Google\Chrome\Application\chrome.exe",
            r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
            r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
            r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        ):
            yield Path(raw)
    elif sys.platform == "darwin":
        for raw in (
            "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
            "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
            "/Applications/Chromium.app/Contents/MacOS/Chromium",
        ):
            yield Path(raw)


def resolve_chrome(explicit):
    if explicit:
        path = Path(explicit)
        if path.exists():
            return path
        raise SystemExit(f"Chrome executable does not exist: {path}")

    for path in chrome_candidates():
        if path.exists():
            return path
    raise SystemExit("Chrome was not found. Set CHROME_PATH to run web smoke.")


def assert_url_reachable(url):
    request = urllib.request.Request(
        url,
        headers={"Cache-Control": "no-cache", "Pragma": "no-cache"},
    )
    with urllib.request.urlopen(request, timeout=10) as response:
        if response.status != 200:
            raise SystemExit(f"Web URL returned HTTP {response.status}: {url}")


def capture(chrome, url, output, window_size, virtual_time_budget):
    cmd = [
        str(chrome),
        "--headless=new",
        "--disable-gpu",
        "--disable-dev-shm-usage",
        "--no-sandbox",
        "--hide-scrollbars",
        "--force-device-scale-factor=1",
        f"--window-size={window_size}",
        f"--virtual-time-budget={virtual_time_budget}",
        f"--screenshot={output}",
        url,
    ]
    result = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    if result.returncode != 0:
        raise SystemExit(
            "Chrome screenshot failed\n"
            f"exit={result.returncode}\n"
            f"stdout={result.stdout}\n"
            f"stderr={result.stderr}"
        )
    if not output.exists():
        raise SystemExit("Chrome did not create a screenshot.")


def inspect_image(path, min_bytes, min_unique_colors, min_ui_ratio):
    file_size = path.stat().st_size
    if file_size < min_bytes:
        raise SystemExit(
            f"Screenshot is too small ({file_size} bytes). "
            "The Flutter view may still be blank."
        )

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

    unique_count = len(unique)
    ui_ratio = ui_pixels / samples if samples else 0.0
    if unique_count < min_unique_colors:
        raise SystemExit(
            f"Screenshot has too few color buckets ({unique_count}). "
            "The page may be a flat loading background."
        )
    if ui_ratio < min_ui_ratio:
        raise SystemExit(
            f"Screenshot UI pixel ratio is too low ({ui_ratio:.3f}). "
            "Expected visible text, cards, or navigation."
        )

    return {
        "bytes": file_size,
        "width": width,
        "height": height,
        "unique_colors": unique_count,
        "ui_ratio": ui_ratio,
    }


def main():
    parser = argparse.ArgumentParser(
        description="Verify that a built Flutter Web page renders visible UI."
    )
    parser.add_argument("--url", default=DEFAULT_URL)
    parser.add_argument("--chrome")
    parser.add_argument("--output")
    parser.add_argument("--window-size", default="390,844")
    parser.add_argument("--virtual-time-budget", type=int, default=15000)
    parser.add_argument("--min-bytes", type=int, default=25000)
    parser.add_argument("--min-unique-colors", type=int, default=48)
    parser.add_argument("--min-ui-ratio", type=float, default=0.015)
    args = parser.parse_args()

    chrome = resolve_chrome(args.chrome)
    assert_url_reachable(args.url)

    if args.output:
        output = Path(args.output).resolve()
    else:
        fd, raw_output = tempfile.mkstemp(
            prefix="fuel_arena_web_",
            suffix=".png",
        )
        os.close(fd)
        output = Path(raw_output)
    try:
        capture(
            chrome,
            args.url,
            output,
            args.window_size,
            args.virtual_time_budget,
        )
        stats = inspect_image(
            output,
            args.min_bytes,
            args.min_unique_colors,
            args.min_ui_ratio,
        )
        print(
            "web render smoke passed: "
            f"{stats['width']}x{stats['height']}, "
            f"{stats['bytes']} bytes, "
            f"{stats['unique_colors']} color buckets, "
            f"ui_ratio={stats['ui_ratio']:.3f}"
        )
        if args.output:
            print(f"screenshot: {output}")
    finally:
        if not args.output:
            output.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
