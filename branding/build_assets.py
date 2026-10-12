#!/usr/bin/env python3
"""Build MILI app branding PNG assets from branding/mili-mark.svg.

Requires Pillow and cairosvg. No Flutter builds or application logic changes.
"""
from __future__ import annotations
import io
from pathlib import Path
from PIL import Image, ImageDraw
import cairosvg

ROOT = Path(__file__).resolve().parent.parent
SVG = ROOT / "branding/mili-mark.svg"
RESAMPLE = Image.Resampling.LANCZOS

def master_logo():
    raw = cairosvg.svg2png(url=str(SVG), output_width=1536, output_height=1536)
    im = Image.open(io.BytesIO(raw)).convert("RGBA")
    bounds = im.getbbox()
    if not bounds:
        raise RuntimeError("MILI vector logo is empty")
    return im.crop(bounds)

def render(mark, size, width_frac=0.76, height_frac=0.72, background="transparent", round_icon=False):
    w, h = size
    if background == "transparent":
        base = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    elif background == "white":
        base = Image.new("RGBA", (w, h), (255, 255, 255, 255))
    else:
        raise ValueError(background)
    scale = min((w * width_frac) / mark.width, (h * height_frac) / mark.height)
    scaled = mark.resize((max(1, round(mark.width * scale)), max(1, round(mark.height * scale))), RESAMPLE)
    base.alpha_composite(scaled, ((w - scaled.width) // 2, (h - scaled.height) // 2))
    if round_icon:
        circle = Image.new("L", (w, h), 0)
        ImageDraw.Draw(circle).ellipse((0, 0, w - 1, h - 1), fill=255)
        base.putalpha(circle)
    return base

def save_png(mark, path, size, occupancy=0.76, height=0.72, background="transparent", round_icon=False):
    path.parent.mkdir(parents=True, exist_ok=True)
    render(mark, size, occupancy, height, background, round_icon).save(path, format="PNG", optimize=True)
    print(f"generated {path.relative_to(ROOT)} {size}")

def main():
    mark = master_logo()
    image_dir = ROOT / "assets/image"
    brand_dimensions = {
        "logo.png": (640, 320),
        "auth_logo.png": (640, 320),
        "header_logo.png": (512, 256),
        "brand_mark.png": (512, 512),
        "logo_icon.png": (512, 512),
    }
    for name, dims in brand_dimensions.items():
        file = image_dir / name
        if file.exists():
            save_png(mark, file, dims, occupancy=0.84, height=0.76)

    android_res = ROOT / "android/app/src/main/res"
    density = {"ldpi": 36, "mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for folder in android_res.glob("mipmap-*"):
        density_name = folder.name.replace("mipmap-", "")
        if density_name not in density:
            continue
        px = density[density_name]
        for name in ("ic_launcher.png", "ic_launcher_round.png", "ic_launcher_foreground.png"):
            f = folder / name
            if not f.exists():
                continue
            if name == "ic_launcher_foreground.png":
                # The launcher mask can clip anything outside the central safe zone.
                save_png(mark, f, (round(px * 2.25), round(px * 2.25)), occupancy=0.60, height=0.59)
            elif name == "ic_launcher_round.png":
                save_png(mark, f, (px, px), occupancy=0.66, height=0.62, background="white", round_icon=True)
            else:
                save_png(mark, f, (px, px), occupancy=0.70, height=0.70, background="white")

    ios_icons = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    if ios_icons.exists():
        for f in sorted(ios_icons.glob("*.png")):
            with Image.open(f) as existing:
                size = existing.size
            if size[0] != size[1]:
                raise ValueError(f"Unexpected iOS app icon: {f}: {size}")
            save_png(mark, f, size, occupancy=0.70, height=0.70, background="white")

    launch_dir = ROOT / "ios/Runner/Assets.xcassets/LaunchImage.imageset"
    if launch_dir.exists():
        for f in sorted(launch_dir.glob("LaunchImage*.png")):
            # V4.2 original storyboard centers the image on white.
            save_png(mark, f, (320, 320), occupancy=0.76, height=0.67)

    web = ROOT / "web"
    for name, size in (("favicon.png", 48), ("icons/Icon-192.png", 192), ("icons/Icon-512.png", 512), ("logo.png", 512)):
        f = web / name
        if f.exists():
            save_png(mark, f, (size, size), occupancy=0.70, height=0.70, background="white")
    print("MILI_BRAND_ASSETS_DONE")

if __name__ == "__main__":
    main()
