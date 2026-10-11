"""Render the 尚礼 SVG mark to Android launcher icon resources.

Run with: py -3 tool/generate_app_icon.py
Requires CairoSVG and Pillow in the Python environment used for asset generation.
"""

from io import BytesIO
from pathlib import Path

import cairosvg
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "images"
RES = ROOT / "android" / "app" / "src" / "main" / "res"
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


def render(svg: Path, target: Path, size: int) -> None:
    png = cairosvg.svg2png(url=str(svg), output_width=size, output_height=size)
    with Image.open(BytesIO(png)) as image:
        target.parent.mkdir(parents=True, exist_ok=True)
        image.save(target, format="PNG", optimize=True)


def main() -> None:
    render(SOURCE / "logo.svg", SOURCE / "logo.png", 512)
    for density, scale in DENSITIES.items():
        folder = RES / f"mipmap-{density}"
        render(SOURCE / "logo.svg", folder / "ic_launcher.png", round(48 * scale))
        render(
            SOURCE / "logo_foreground.svg",
            folder / "ic_launcher_foreground.png",
            round(108 * scale),
        )
        render(
            SOURCE / "logo_monochrome.svg",
            folder / "ic_launcher_monochrome.png",
            round(108 * scale),
        )


if __name__ == "__main__":
    main()
