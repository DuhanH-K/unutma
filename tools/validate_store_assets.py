"""Fail fast when Google Play artwork dimensions or color modes regress."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "store_assets" / "tr-TR"
EXPECTED = {
    "app_icon_512.png": ((512, 512), "RGBA"),
    "feature_graphic_1024x500.png": ((1024, 500), "RGB"),
    "phone_01_dashboard_1080x1920.png": ((1080, 1920), "RGB"),
    "phone_02_inbox_1080x1920.png": ((1080, 1920), "RGB"),
    "phone_03_action_card_1080x1920.png": ((1080, 1920), "RGB"),
    "phone_04_privacy_1080x1920.png": ((1080, 1920), "RGB"),
}


def main() -> None:
    failures: list[str] = []
    for name, (size, mode) in EXPECTED.items():
        path = ASSETS / name
        if not path.exists():
            failures.append(f"{name}: missing")
            continue
        with Image.open(path) as image:
            if image.size != size:
                failures.append(f"{name}: {image.size}, expected {size}")
            if image.mode != mode:
                failures.append(f"{name}: {image.mode}, expected {mode}")
            shortest, longest = sorted(image.size)
            if name.startswith("phone_") and longest > shortest * 2:
                failures.append(f"{name}: aspect ratio exceeds 2:1")
        if name == "app_icon_512.png" and path.stat().st_size > 1024 * 1024:
            failures.append(f"{name}: exceeds 1024 KB")
    if failures:
        raise SystemExit("Play asset validation failed:\n- " + "\n- ".join(failures))
    print(f"PASS: {len(EXPECTED)} Play Store assets validated")


if __name__ == "__main__":
    main()
