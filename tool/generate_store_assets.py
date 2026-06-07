from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "store"

BG = (7, 20, 15)
SURFACE = (18, 28, 24)
SURFACE_HIGH = (31, 38, 34)
GREEN = (121, 255, 91)
BLUE = (0, 218, 248)
GOLD = (255, 212, 90)
TEXT = (239, 255, 227)
MUTED = (186, 204, 176)


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        ROOT / "assets" / "fonts" / "NotoSansKR-VF.ttf",
        Path("C:/Windows/Fonts/malgunbd.ttf" if bold else "C:/Windows/Fonts/malgun.ttf"),
        Path("C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf"),
    ]
    for path in candidates:
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


def wrap_text(draw: ImageDraw.ImageDraw, text: str, max_width: int, font_obj: ImageFont.ImageFont) -> list[str]:
    lines: list[str] = []
    for paragraph in text.splitlines():
        current = ""
        for word in paragraph.split(" "):
            candidate = word if not current else f"{current} {word}"
            if draw.textlength(candidate, font=font_obj) <= max_width:
                current = candidate
                continue
            if current:
                lines.append(current)
            current = word
        if current:
            lines.append(current)
    return lines


def gradient(size: tuple[int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGB", size, BG)
    pixels = image.load()
    for y in range(height):
        for x in range(width):
            nx = x / max(width - 1, 1)
            ny = y / max(height - 1, 1)
            green = max(0, 1 - ((nx - 0.18) ** 2 + (ny - 0.08) ** 2) ** 0.5 * 1.5)
            blue = max(0, 1 - ((nx - 0.82) ** 2 + (ny - 0.76) ** 2) ** 0.5 * 1.7)
            r = int(BG[0] + green * 24 + blue * 3)
            g = int(BG[1] + green * 58 + blue * 24)
            b = int(BG[2] + green * 25 + blue * 48)
            pixels[x, y] = (r, g, b)
    return image


def rounded(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], fill: tuple[int, int, int], radius: int = 28, outline=None, width: int = 1) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def text(draw: ImageDraw.ImageDraw, xy: tuple[int, int], value: str, size: int, fill=TEXT, bold: bool = False, max_width: int | None = None, line_gap: int = 10) -> int:
    font_obj = font(size, bold)
    x, y = xy
    lines = [value] if max_width is None else wrap_text(draw, value, max_width, font_obj)
    for line in lines:
        draw.text((x, y), line, font=font_obj, fill=fill)
        bbox = draw.textbbox((x, y), line, font=font_obj)
        y = bbox[3] + line_gap
    return y


def draw_phone(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, title: str, subtitle: str, cards: list[tuple[str, str, tuple[int, int, int]]]) -> None:
    rounded(draw, (x, y, x + w, y + h), (4, 6, 5), radius=58)
    rounded(draw, (x + 22, y + 22, x + w - 22, y + h - 22), BG, radius=42)
    for gx in range(x + 60, x + w - 60, 70):
        draw.line((gx, y + 70, gx, y + h - 150), fill=(30, 64, 39), width=1)
    for gy in range(y + 90, y + h - 150, 70):
        draw.line((x + 55, gy, x + w - 55, gy), fill=(30, 64, 39), width=1)
    cy = y + 82
    text(draw, (x + 58, cy), title, 34, GREEN, True, max_width=w - 116)
    cy += 92
    text(draw, (x + 58, cy), subtitle, 22, MUTED, max_width=w - 116)
    cy += 88
    for card_title, card_subtitle, accent in cards:
        rounded(draw, (x + 48, cy, x + w - 48, cy + 170), SURFACE, radius=24, outline=(53, 65, 55), width=2)
        draw.rounded_rectangle((x + 72, cy + 30, x + 104, cy + 62), radius=10, fill=accent)
        text(draw, (x + 124, cy + 28), card_title, 25, TEXT, True, max_width=w - 210)
        text(draw, (x + 124, cy + 76), card_subtitle, 18, MUTED, max_width=w - 210)
        cy += 198
    rounded(draw, (x + 72, y + h - 112, x + w - 72, y + h - 48), (13, 15, 14), radius=30)
    labels = ["홈", "배틀", "랭킹", "시즌", "프로필"]
    step = (w - 144) // len(labels)
    for index, label in enumerate(labels):
        fill = GREEN if index == 0 else MUTED
        text(draw, (x + 90 + step * index, y + h - 95), label, 17, fill, True)


def screenshot(name: str, headline: str, subhead: str, phone_title: str, phone_subtitle: str, cards: list[tuple[str, str, tuple[int, int, int]]]) -> None:
    width, height = 1080, 1920
    image = gradient((width, height)).convert("RGBA")
    draw = ImageDraw.Draw(image)
    text(draw, (80, 96), "Fuel Arena", 34, BLUE, True)
    text(draw, (80, 158), headline, 72, TEXT, True, max_width=920, line_gap=14)
    text(draw, (80, 390), subhead, 31, MUTED, max_width=900, line_gap=12)
    mark = Image.open(ROOT / "assets" / "brand" / "fuel_arena_mark.png").convert("RGBA").resize((170, 170), Image.Resampling.LANCZOS)
    image.alpha_composite(mark, (830, 96))
    shadow = Image.new("RGBA", (620, 1180), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    rounded(sd, (24, 24, 596, 1156), (0, 0, 0), radius=62)
    shadow = shadow.filter(ImageFilter.GaussianBlur(30))
    image.alpha_composite(shadow, (230, 650))
    draw = ImageDraw.Draw(image)
    draw_phone(draw, 240, 620, 600, 1180, phone_title, phone_subtitle, cards)
    out = OUT / "screenshots" / "phone" / name
    out.parent.mkdir(parents=True, exist_ok=True)
    image.convert("RGB").save(out, quality=95)


def feature_graphic() -> None:
    width, height = 1024, 500
    image = gradient((width, height)).convert("RGBA")
    draw = ImageDraw.Draw(image)
    mark = Image.open(ROOT / "assets" / "brand" / "fuel_arena_mark.png").convert("RGBA").resize((210, 210), Image.Resampling.LANCZOS)
    image.alpha_composite(mark, (730, 142))
    text(draw, (58, 66), "Fuel Arena", 42, BLUE, True)
    text(draw, (58, 132), "연비로 증명하는\n드라이빙 경쟁", 62, TEXT, True, max_width=620, line_gap=6)
    text(draw, (58, 322), "주행 기록, 차량 리그, 랭킹, 배틀, 시즌 보상을 하나의 게임 흐름으로 연결합니다.", 25, MUTED, max_width=620)
    for i, label in enumerate(["주행 점수", "리그 랭킹", "공정성 검증"]):
        x = 58 + i * 190
        rounded(draw, (x, 408, x + 164, 456), (29, 64, 37), radius=24, outline=GREEN)
        text(draw, (x + 24, 418), label, 20, GREEN, True)
    out = OUT / "feature_graphic_1024x500.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    image.convert("RGB").save(out, quality=95)


def listing_copy() -> None:
    data = {
        "ko": {
            "app_name": "Fuel Arena",
            "short_description": "연비와 주행 효율로 경쟁하는 게임형 드라이빙 플랫폼",
            "full_description": [
                "Fuel Arena는 연비 기록장이 아니라 주행 효율로 경쟁하는 드라이빙 플랫폼입니다.",
                "차량 제조사, 모델, 기준 연식, 엔진·미션 파워트레인을 기준으로 리그를 나누고 같은 조건의 운전자와 점수를 비교합니다.",
                "주행 중에는 광고, 팝업, 도전장, 불필요한 알림을 표시하지 않으며, 원본 위치 좌표와 raw drive_points는 공개 화면에 노출하지 않습니다.",
                "랭킹, 배틀, 시즌 미션, 보상, 쿠폰, 고객지원, 개인정보 요청 흐름을 앱 안에서 연결합니다."
            ],
            "keywords": ["연비", "주행 기록", "드라이빙", "랭킹", "배틀", "차량 관리", "친환경 운전"],
            "support_routes": ["/legal/privacy/", "/legal/location/", "/legal/account-deletion/", "/legal/terms/"],
            "screenshots": [
                "assets/store/screenshots/phone/01_home_league.png",
                "assets/store/screenshots/phone/02_vehicle_catalog.png",
                "assets/store/screenshots/phone/03_drive_score.png",
                "assets/store/screenshots/phone/04_battle_season.png",
                "assets/store/screenshots/phone/05_privacy_fairness.png"
            ],
            "feature_graphic": "assets/store/feature_graphic_1024x500.png"
        }
    }
    path = OUT / "store_listing_ko.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    screenshot(
        "01_home_league.png",
        "내 차량 리그에서\n효율로 경쟁",
        "연비 기록을 점수와 랭킹으로 바꾸고, 같은 조건의 운전자와 비교합니다.",
        "홈",
        "대표 차량 기준 리그와 오늘의 미션",
        [
            ("아반떼 1.6 가솔린", "가솔린 준중형 리그 · 공식 효율 기준", GREEN),
            ("오늘의 미션", "12km 이상 안전 주행으로 시즌 점수 획득", BLUE),
            ("내 주변 순위", "같은 리그 운전자와 주간 점수 비교", GOLD),
        ],
    )
    screenshot(
        "02_vehicle_catalog.png",
        "차종과 파워트레인으로\n정확하게 분류",
        "판매 트림이나 휠 인치가 아니라 차종, 기준 연식, 엔진·미션 차이만 선택합니다.",
        "차량 설정",
        "K3와 K3 GT, 1.6과 1.6T를 구분",
        [
            ("기아 K3", "2024년식 · 1.6 가솔린 IVT", BLUE),
            ("기아 K3 GT", "2024년식 · 1.6T 가솔린 DCT", GREEN),
            ("직접 입력 검수", "카탈로그 밖 차량은 운영자 검토 큐로 접수", GOLD),
        ],
    )
    screenshot(
        "03_drive_score.png",
        "주행 결과를\n점수로 확인",
        "서버 검증을 통과한 주행만 랭킹과 배틀 정산에 반영합니다.",
        "주행 결과",
        "효율, 거리, 시간, 공정성 신호를 한 화면에",
        [
            ("92점", "검증 완료 · 리그 상위 12%", GREEN),
            ("18.4 km/L", "차량 공식 효율 대비 +11%", BLUE),
            ("랭킹 반영", "검증된 점수만 시즌 순위에 반영", GOLD),
        ],
    )
    screenshot(
        "04_battle_season.png",
        "배틀과 시즌을\n현금 없이 안전하게",
        "친선 배틀, 시즌 미션, 쿠폰과 배지 보상을 하나의 흐름으로 연결합니다.",
        "배틀",
        "같은 리그 조건으로 공정하게 매칭",
        [
            ("친선 배틀", "현금성 보상 없이 점수와 배지로 경쟁", GREEN),
            ("시즌 미션", "일일 주행 목표와 주간 효율 미션", BLUE),
            ("보상 지갑", "쿠폰, 배지, 시즌 혜택을 한곳에서 관리", GOLD),
        ],
    )
    screenshot(
        "05_privacy_fairness.png",
        "위치와 기록은\n공개 범위를 제한",
        "정확한 좌표와 raw drive_points는 공개하지 않고, 이의제기와 개인정보 요청을 앱에서 접수합니다.",
        "공정성 센터",
        "주행 중에는 광고와 팝업을 표시하지 않음",
        [
            ("공개 제한", "랭킹에는 요약 점수와 리그 정보만 표시", GREEN),
            ("검토 요청", "GPS 품질, 점수 보류, 정산 이슈를 접수", BLUE),
            ("데이터 요청", "다운로드, 삭제, 계정 삭제 요청 상태 확인", GOLD),
        ],
    )
    feature_graphic()
    listing_copy()
    print("Fuel Arena store listing assets generated.")


if __name__ == "__main__":
    main()
