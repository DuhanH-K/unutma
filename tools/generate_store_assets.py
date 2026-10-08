"""Generate deterministic, privacy-safe Google Play artwork from real UI goldens."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]
FONT_REGULAR = Path(r"C:\Windows\Fonts\segoeui.ttf")
FONT_BOLD = Path(r"C:\Windows\Fonts\segoeuib.ttf")
NAVY = "#13213A"
BLUE = "#2B66F6"
CORAL = "#FF5B62"
ORANGE = "#FF9E18"
OFF_WHITE = "#F6F7FB"
MUTED = "#647087"

COPY = {
    "tr-TR": {
        "feature": "Bildirim gelir.\nUNUTMA hatırlar.",
        "headlines": [
            "Önemli şeyleri tek yerde gör.",
            "Mesajdaki işi anlayıp hatırlatmaya çevirir.",
            "Tarihi yakalar, zamanı gelince hatırlatır.",
            "Özel bildirimler, özel kalır.",
        ],
        "notification_sender": "Anne",
        "notification_body": "Gelirken ekmek almayı unutma",
        "notification_badge": "MESAJ",
    },
    # The layout and copy pipeline are locale-aware. Add localized golden names
    # here when the English Play listing is scheduled; TR remains the release source.
    "en-US": {
        "feature": "A notification arrives.\nUNUTMA remembers.",
        "headlines": [
            "See what matters in one place.",
            "Turn a message into a reminder.",
            "Catch the date and get reminded on time.",
            "Private notifications stay private.",
        ],
        "notification_sender": "Mom",
        "notification_body": "Remember to buy bread on your way",
        "notification_badge": "MESSAGE",
    },
}

CURATED_PHONE_ASSETS = {
    "tr-TR": {
        "phone_02_inbox_1080x1920.png",
        "phone_03_action_card_1080x1920.png",
        "phone_04_privacy_1080x1920.png",
    },
}


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    path = FONT_BOLD if bold else FONT_REGULAR
    return ImageFont.truetype(str(path), size=size)


def wrapped(draw: ImageDraw.ImageDraw, text: str, face: ImageFont.FreeTypeFont, width: int) -> list[str]:
    lines: list[str] = []
    for paragraph in text.splitlines():
        words = paragraph.split()
        current = ""
        for word in words:
            candidate = word if not current else f"{current} {word}"
            if draw.textlength(candidate, font=face) <= width:
                current = candidate
            else:
                if current:
                    lines.append(current)
                current = word
        lines.append(current)
    return lines


def centered_copy(
    draw: ImageDraw.ImageDraw,
    text: str,
    y: int,
    max_width: int,
    start_size: int = 68,
    fill: str = NAVY,
) -> int:
    size = start_size
    while size > 40:
        face = font(size, bold=True)
        lines = wrapped(draw, text, face, max_width)
        if len(lines) <= 2:
            break
        size -= 2
    line_height = int(size * 1.14)
    for line in lines:
        box = draw.textbbox((0, 0), line, font=face)
        draw.text(((1080 - (box[2] - box[0])) / 2, y), line, font=face, fill=fill)
        y += line_height
    return y


def normalize_curated_phone_asset(source: Path, output: Path) -> None:
    """Preserve curated artwork while normalizing it to the V4 Play dimensions."""
    with Image.open(source) as original:
        artwork = ImageOps.contain(
            original.convert("RGB"),
            (1080, 1920),
            method=Image.Resampling.LANCZOS,
        )
    canvas = Image.new("RGB", (1080, 1920), "white")
    canvas.paste(
        artwork,
        ((canvas.width - artwork.width) // 2, (canvas.height - artwork.height) // 2),
    )
    canvas.save(output, format="PNG", optimize=True)


def brand_header(canvas: Image.Image) -> None:
    draw = ImageDraw.Draw(canvas)
    icon = Image.open(ROOT / "assets/brand/unutma_app_icon_1024.png").convert("RGBA")
    icon.thumbnail((66, 66), Image.Resampling.LANCZOS)
    canvas.paste(icon, (54, 50), icon)
    draw.text((138, 61), "UNUTMA", font=font(32, bold=True), fill=NAVY)
    draw.rounded_rectangle((910, 61, 1020, 73), radius=6, fill=ORANGE)
    draw.rounded_rectangle((955, 83, 1020, 95), radius=6, fill=CORAL)


def shadowed_round_rect(
    canvas: Image.Image,
    box: tuple[int, int, int, int],
    radius: int,
    fill: str,
    shadow_alpha: int = 42,
) -> None:
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    shifted = (box[0], box[1] + 15, box[2], box[3] + 15)
    sd.rounded_rectangle(shifted, radius=radius, fill=(18, 32, 56, shadow_alpha))
    shadow = shadow.filter(ImageFilter.GaussianBlur(22))
    canvas.alpha_composite(shadow)
    ImageDraw.Draw(canvas).rounded_rectangle(box, radius=radius, fill=fill)


def phone(
    canvas: Image.Image,
    source_path: Path,
    box: tuple[int, int, int, int],
    crop: tuple[int, int, int, int] | None = None,
) -> None:
    x1, y1, x2, y2 = box
    shadowed_round_rect(canvas, box, 72, NAVY, shadow_alpha=58)
    inset = 18
    screen_box = (x1 + inset, y1 + inset, x2 - inset, y2 - inset)
    sw, sh = screen_box[2] - screen_box[0], screen_box[3] - screen_box[1]
    source = Image.open(source_path).convert("RGBA")
    if crop:
        source = source.crop(crop)
    source.thumbnail((sw, sh), Image.Resampling.LANCZOS)
    screen = Image.new("RGBA", (sw, sh), "#F7F8FC")
    screen.alpha_composite(source, ((sw - source.width) // 2, 0))
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw, sh), radius=56, fill=255)
    canvas.paste(screen, (screen_box[0], screen_box[1]), mask)


def notification(canvas: Image.Image, y: int, copy: dict[str, object]) -> None:
    box = (120, y, 960, y + 174)
    shadowed_round_rect(canvas, box, 36, "#FFFFFF", shadow_alpha=38)
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((150, y + 38, 238, y + 126), radius=24, fill="#E9EEFF")
    draw.rounded_rectangle((174, y + 60, 214, y + 96), radius=11, outline=BLUE, width=5)
    draw.text((266, y + 26), str(copy["notification_badge"]), font=font(19, bold=True), fill=MUTED)
    draw.text((266, y + 59), str(copy["notification_sender"]), font=font(30, bold=True), fill=NAVY)
    draw.text((266, y + 102), str(copy["notification_body"]), font=font(27), fill=NAVY)


def screenshot_asset(index: int, locale: str, source_path: Path, output: Path) -> None:
    copy = COPY[locale]
    canvas = Image.new("RGBA", (1080, 1920), OFF_WHITE)
    # Brand-led corner accents keep every image related without obscuring UI.
    accents = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ad = ImageDraw.Draw(accents)
    ad.ellipse((-260, 1120, 310, 1690), fill=(43, 102, 246, 18))
    ad.ellipse((850, 210, 1250, 610), fill=(255, 91, 98, 20))
    canvas.alpha_composite(accents)
    brand_header(canvas)
    draw = ImageDraw.Draw(canvas)
    y = centered_copy(draw, copy["headlines"][index - 1], 150, 930)

    if index == 2:
        notification(canvas, y + 35, copy)
        arrow_y = y + 235
        draw.line((540, arrow_y, 540, arrow_y + 54), fill=BLUE, width=8)
        draw.polygon(((522, arrow_y + 43), (558, arrow_y + 43), (540, arrow_y + 68)), fill=BLUE)
        phone(canvas, source_path, (154, arrow_y + 92, 926, 1705), crop=(0, 0, 393, 500))
    else:
        top = max(330, y + 45)
        phone(canvas, source_path, (184, top, 896, 1875))

    # Store screenshots must be opaque 24-bit PNGs.
    canvas.convert("RGB").save(output, format="PNG", optimize=True)


def feature_graphic(locale: str, output: Path) -> None:
    copy = COPY[locale]
    canvas = Image.new("RGBA", (1024, 500), NAVY)
    draw = ImageDraw.Draw(canvas)
    draw.ellipse((-160, 250, 300, 710), fill="#1B3156")
    draw.ellipse((830, -180, 1200, 190), fill="#263F69")
    icon = Image.open(ROOT / "assets/brand/unutma_app_icon_1024.png").convert("RGBA")
    icon.thumbnail((92, 92), Image.Resampling.LANCZOS)
    canvas.paste(icon, (64, 62), icon)
    draw.text((178, 78), "UNUTMA", font=font(37, bold=True), fill="white")
    y = 190
    for line in str(copy["feature"]).splitlines():
        draw.text((64, y), line, font=font(47, bold=True), fill="white")
        y += 61
    draw.text((67, 340), "Önemli bildirimlerden yerel hatırlatma kartları.", font=font(22), fill="#C9D5EB")

    shadowed_round_rect(canvas, (598, 58, 965, 215), 28, "#FFFFFF", shadow_alpha=60)
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((622, 90, 682, 150), radius=17, fill="#E9EEFF")
    draw.text((704, 82), "MESAJ", font=font(15, bold=True), fill=MUTED)
    draw.text((704, 112), "Yarın ödemeyi unutma", font=font(22, bold=True), fill=NAVY)
    draw.text((704, 148), "Bildirim önizlemesi", font=font(17), fill=MUTED)
    draw.line((782, 225, 782, 267), fill=CORAL, width=7)
    draw.polygon(((766, 256), (798, 256), (782, 278)), fill=CORAL)
    shadowed_round_rect(canvas, (564, 286, 960, 444), 30, "#FFFFFF", shadow_alpha=60)
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((589, 320, 653, 384), radius=18, fill="#FFF0E5")
    draw.text((674, 308), "İnternet faturası", font=font(25, bold=True), fill=NAVY)
    draw.text((674, 349), "Yarın  •  ₺549,90", font=font(20), fill=MUTED)
    draw.rounded_rectangle((674, 389, 794, 426), radius=18, fill=BLUE)
    draw.text((702, 395), "Onayla", font=font(17, bold=True), fill="white")
    canvas.convert("RGB").save(output, format="PNG", optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--locale", choices=COPY, default="tr-TR")
    args = parser.parse_args()
    locale = args.locale
    output_dir = ROOT / "store_assets" / locale
    output_dir.mkdir(parents=True, exist_ok=True)

    icon = Image.open(ROOT / "assets/brand/unutma_app_icon_1024.png").convert("RGBA")
    icon.resize((512, 512), Image.Resampling.LANCZOS).save(
        output_dir / "app_icon_512.png", format="PNG", optimize=True
    )
    feature_graphic(locale, output_dir / "feature_graphic_1024x500.png")

    sources = [
        ROOT / "test/goldens/store_dashboard.png",
        ROOT / "test/goldens/store_inbox_message.png",
        ROOT / "test/goldens/store_detail.png",
        ROOT / "test/goldens/privacy.png",
    ]
    outputs = [
        "phone_01_dashboard_1080x1920.png",
        "phone_02_inbox_1080x1920.png",
        "phone_03_action_card_1080x1920.png",
        "phone_04_privacy_1080x1920.png",
    ]
    for index, (source, name) in enumerate(zip(sources, outputs), start=1):
        curated_source = ROOT / "store_assets" / "sources" / locale / name
        if name in CURATED_PHONE_ASSETS.get(locale, set()):
            if not curated_source.exists():
                raise FileNotFoundError(f"Missing curated store artwork: {curated_source}")
            normalize_curated_phone_asset(curated_source, output_dir / name)
            continue
        if not source.exists():
            raise FileNotFoundError(f"Missing visual golden: {source}")
        screenshot_asset(index, locale, source, output_dir / name)
    print(f"Generated Play Store assets in {output_dir}")


if __name__ == "__main__":
    main()
