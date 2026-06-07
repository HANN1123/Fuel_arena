from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageFilter


ROOT = Path(__file__).resolve().parents[1]

BG = (7, 20, 15)
SURFACE = (18, 35, 27)
GREEN = (121, 255, 91)
GREEN_DIM = (42, 229, 0)
BLUE = (0, 218, 248)
GOLD = (255, 212, 90)
WHITE = (239, 255, 227)


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        ROOT / "assets" / "fonts" / "NotoSansKR-VF.ttf",
        Path("C:/Windows/Fonts/segoeuib.ttf"),
        Path("C:/Windows/Fonts/arialbd.ttf"),
    ]
    for path in candidates:
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


def _overlay(base: Image.Image, layer: Image.Image) -> None:
    base.alpha_composite(layer)


def _draw_gradient(size: int) -> Image.Image:
    image = Image.new("RGBA", (size, size), BG + (255,))
    pixels = image.load()
    for y in range(size):
        for x in range(size):
            nx = x / (size - 1)
            ny = y / (size - 1)
            glow = max(0.0, 1.0 - math.hypot(nx - 0.34, ny - 0.22) * 1.25)
            blue_glow = max(0.0, 1.0 - math.hypot(nx - 0.72, ny - 0.80) * 1.5)
            r = int(BG[0] + glow * 20 + blue_glow * 2)
            g = int(BG[1] + glow * 45 + blue_glow * 22)
            b = int(BG[2] + glow * 23 + blue_glow * 35)
            pixels[x, y] = (r, g, b, 255)
    return image


def _draw_grid(base: Image.Image, inset: int, step: int, alpha: int) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    w, h = base.size
    for x in range(inset, w - inset + 1, step):
        draw.line((x, inset, x, h - inset), fill=(*GREEN, alpha), width=2)
    for y in range(inset, h - inset + 1, step):
        draw.line((inset, y, w - inset, y), fill=(*GREEN, alpha), width=2)
    _overlay(base, layer)


def _tick(cx: int, cy: int, radius: int, angle: float, length: int) -> tuple[int, int, int, int]:
    rad = math.radians(angle)
    outer = (cx + math.cos(rad) * radius, cy + math.sin(rad) * radius)
    inner = (
        cx + math.cos(rad) * (radius - length),
        cy + math.sin(rad) * (radius - length),
    )
    return (round(inner[0]), round(inner[1]), round(outer[0]), round(outer[1]))


def _draw_mark(base: Image.Image, center: tuple[int, int], scale: float) -> None:
    cx, cy = center
    radius = round(300 * scale)
    ring_width = max(12, round(30 * scale))
    draw = ImageDraw.Draw(base)

    glow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    bbox = (cx - radius, cy - radius, cx + radius, cy + radius)
    glow_draw.arc(bbox, 205, 335, fill=(*GREEN, 150), width=round(54 * scale))
    glow_draw.arc(bbox, 25, 155, fill=(*BLUE, 130), width=round(44 * scale))
    glow = glow.filter(ImageFilter.GaussianBlur(round(18 * scale)))
    _overlay(base, glow)

    draw.arc(bbox, 205, 335, fill=GREEN, width=ring_width)
    draw.arc(bbox, 25, 155, fill=BLUE, width=ring_width)
    for angle in range(210, 331, 24):
        draw.line(_tick(cx, cy, radius - 14, angle, round(48 * scale)), fill=(*WHITE, 185), width=max(3, round(6 * scale)))

    needle_angle = -38
    rad = math.radians(needle_angle)
    tip = (cx + math.cos(rad) * radius * 0.72, cy + math.sin(rad) * radius * 0.72)
    left = (
        cx + math.cos(rad + math.pi / 2) * radius * 0.07,
        cy + math.sin(rad + math.pi / 2) * radius * 0.07,
    )
    right = (
        cx + math.cos(rad - math.pi / 2) * radius * 0.07,
        cy + math.sin(rad - math.pi / 2) * radius * 0.07,
    )
    draw.polygon((left, tip, right), fill=GOLD)
    draw.ellipse(
        (
            cx - round(42 * scale),
            cy - round(42 * scale),
            cx + round(42 * scale),
            cy + round(42 * scale),
        ),
        fill=SURFACE,
        outline=GREEN,
        width=max(3, round(7 * scale)),
    )

    font = _font(round(260 * scale))
    text = "FA"
    box = draw.textbbox((0, 0), text, font=font)
    tw = box[2] - box[0]
    th = box[3] - box[1]
    tx = cx - tw / 2
    ty = cy + round(74 * scale) - th / 2 - box[1]
    draw.text((tx + round(7 * scale), ty + round(7 * scale)), text, font=font, fill=(0, 0, 0, 120))
    draw.text((tx, ty), text, font=font, fill=WHITE)

    draw.rounded_rectangle(
        (
            cx - round(168 * scale),
            cy + round(215 * scale),
            cx + round(168 * scale),
            cy + round(248 * scale),
        ),
        radius=round(16 * scale),
        fill=(*GREEN, 225),
    )
    draw.rounded_rectangle(
        (
            cx - round(168 * scale),
            cy + round(258 * scale),
            cx + round(76 * scale),
            cy + round(284 * scale),
        ),
        radius=round(13 * scale),
        fill=(*BLUE, 230),
    )


def make_icon(size: int = 1024, safe_scale: float = 1.0) -> Image.Image:
    image = _draw_gradient(size)
    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    radius = round(size * 0.205)
    mask_draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    image.putalpha(mask)
    _draw_grid(image, inset=round(size * 0.08), step=round(size * 0.078), alpha=18)

    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    _draw_mark(layer, (size // 2, round(size * 0.47)), safe_scale)
    _overlay(image, layer)

    no_alpha = Image.new("RGB", (size, size), BG)
    no_alpha.paste(image.convert("RGB"), mask=image.getchannel("A"))
    return no_alpha


def make_launch_mark(size: int) -> Image.Image:
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    _draw_mark(image, (size // 2, round(size * 0.46)), size / 1024)
    return image


def save_resized(source: Image.Image, path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    resized = source.resize((size, size), Image.Resampling.LANCZOS)
    if path.suffix.lower() == ".png":
        resized.save(path, optimize=True)


def android_icons(source: Image.Image) -> None:
    sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in sizes.items():
        save_resized(
            source,
            ROOT / "android" / "app" / "src" / "main" / "res" / folder / "ic_launcher.png",
            size,
        )
    launch = make_launch_mark(512)
    save_resized(
        launch,
        ROOT / "android" / "app" / "src" / "main" / "res" / "drawable-nodpi" / "launch_mark.png",
        512,
    )


def ios_icons(source: Image.Image) -> None:
    contents = json.loads(
        (ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset" / "Contents.json").read_text(
            encoding="utf-8"
        )
    )
    icon_dir = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    for item in contents["images"]:
        filename = item.get("filename")
        if not filename:
            continue
        size_value = float(item["size"].split("x")[0])
        scale = int(item["scale"].replace("x", ""))
        save_resized(source, icon_dir / filename, round(size_value * scale))

    launch_dir = ROOT / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset"
    for filename, size in {
        "LaunchImage.png": 168,
        "LaunchImage@2x.png": 336,
        "LaunchImage@3x.png": 504,
    }.items():
        save_resized(make_launch_mark(size), launch_dir / filename, size)


def web_icons(source: Image.Image) -> None:
    web = ROOT / "web"
    save_resized(source, web / "icons" / "Icon-192.png", 192)
    save_resized(source, web / "icons" / "Icon-512.png", 512)
    maskable = make_icon(1024, safe_scale=0.82)
    save_resized(maskable, web / "icons" / "Icon-maskable-192.png", 192)
    save_resized(maskable, web / "icons" / "Icon-maskable-512.png", 512)
    save_resized(source, web / "favicon.png", 32)


def brand_assets(source: Image.Image) -> None:
    brand = ROOT / "assets" / "brand"
    save_resized(source, brand / "fuel_arena_icon_1024.png", 1024)
    save_resized(source, brand / "fuel_arena_mark.png", 512)


def main() -> None:
    source = make_icon()
    brand_assets(source)
    android_icons(source)
    ios_icons(source)
    web_icons(source)
    print("Fuel Arena brand assets generated.")


if __name__ == "__main__":
    main()
