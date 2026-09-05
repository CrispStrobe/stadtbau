# SPDX-License-Identifier: AGPL-3.0-or-later
"""Generate the Hectopolis app icon for every platform slot.

Original artwork for this project; ships under AGPL-3.0-or-later with the app.
No external assets, no fonts, no traced logos: everything below is drawn from
primitives with Pillow, so the icon can be regenerated from source at any time.

Design
------
A 4x4 grid of rounded "hectare" tiles on the deep-green ground #1B5E20.  A
two-tile-wide diagonal band of meadow/park/forest greens runs from the top
right to the bottom left, cutting a dense block of built tiles (housing,
commercial, road) in the upper left away from a small settlement in the lower
right -- the game's core tension in one glyph.  A single water tile is the
accent.  Colours are exactly the tile palette of `app/lib/ui/tile_style.dart`.

Usage
-----
    python3 tools/gen_icon.py            # generate everything, then verify
    python3 tools/gen_icon.py --verify   # verify existing files only
"""

from __future__ import annotations

import json
import os
import sys
from typing import Iterable

from PIL import Image, ImageDraw, ImageFilter

# --------------------------------------------------------------------------
# Palette (mirrors app/lib/ui/tile_style.dart)
# --------------------------------------------------------------------------
BG = (0x1B, 0x5E, 0x20)  # deep green ground

MEADOW = (0xA5, 0xD6, 0xA7)
FOREST = (0x38, 0x8E, 0x3C)
WATER = (0x64, 0xB5, 0xF6)
PARK = (0x81, 0xC7, 0x84)
HOUSING_LOW = (0xFF, 0xE0, 0xB2)
HOUSING_HIGH = (0xFF, 0xAB, 0x91)
COMMERCIAL = (0xB3, 0x9D, 0xDB)
ROAD = (0x75, 0x75, 0x75)

# Row 0 is the top row.  Cells on the anti-diagonals row+col in {3, 4} form the
# green band; everything above-left and below-right of it is built.
LAYOUT = [
    [HOUSING_HIGH, COMMERCIAL, HOUSING_LOW, MEADOW],
    [HOUSING_LOW, ROAD, MEADOW, PARK],
    [COMMERCIAL, WATER, FOREST, HOUSING_HIGH],
    [MEADOW, PARK, HOUSING_LOW, COMMERCIAL],
]

N = len(LAYOUT)
GAP_RATIO = 0.050        # gap between tiles, as a fraction of the content box
CORNER_RATIO = 0.20      # tile corner radius, as a fraction of the tile size
SHADOW_OFFSET = 0.050    # drop shadow offset, as a fraction of the tile size
SHADOW_BLUR = 0.055      # drop shadow blur, as a fraction of the tile size
SHADOW_ALPHA = 90

SS = 4                   # supersampling factor: draw at 4x, then downsample

# Content box as a fraction of the drawable area.  The two masked variants are
# sized so the *bounding circle* of the square tile grid stays inside the safe
# circle, which is what a circular launcher mask actually clips against:
# side = diameter / sqrt(2).
CONTENT_FULL = 0.76      # full-bleed slots (iOS, web, Windows, master)
CONTENT_ADAPTIVE = 0.46  # Android adaptive foreground: 66 % safe circle
CONTENT_MASKABLE = 0.56  # PWA maskable icon: 80 % safe circle

# macOS icon grid: an 824 px rounded square inside a 1024 px canvas.
MACOS_INSET = (1024 - 824) / 2 / 1024
MACOS_RADIUS = 185.4 / 824
MACOS_CONTENT = 0.82     # relative to the 824 px square, not the canvas
# Legacy Android launcher icon: a rounded square with a small margin.
LEGACY_INSET = 0.045
LEGACY_RADIUS = 0.22

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP = os.path.join(REPO, "app")

IOS_APPICON = os.path.join(APP, "ios/Runner/Assets.xcassets/AppIcon.appiconset")
MACOS_APPICON = os.path.join(APP, "macos/Runner/Assets.xcassets/AppIcon.appiconset")
ANDROID_RES = os.path.join(APP, "android/app/src/main/res")


# --------------------------------------------------------------------------
# Drawing
# --------------------------------------------------------------------------
def _draw(px: int, content: float, ground: str, inset: float, radius: float) -> Image.Image:
    """Draw the icon at `px` pixels.

    ground: "square" (full bleed), "rounded" (rounded square with margin) or
    "none" (transparent, for the Android adaptive foreground layer).
    """
    img = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    if ground == "square":
        origin, box = 0.0, float(px)
        d.rectangle([0, 0, px, px], fill=BG + (255,))
    elif ground == "rounded":
        origin, box = inset * px, px - 2 * inset * px
        d.rounded_rectangle(
            [origin, origin, origin + box, origin + box],
            radius=radius * box,
            fill=BG + (255,),
        )
    else:  # "none"
        origin, box = 0.0, float(px)

    side = box * content
    gap = side * GAP_RATIO
    tile = (side - (N - 1) * gap) / N
    left = origin + (box - side) / 2
    top = origin + (box - side) / 2
    corner = tile * CORNER_RATIO

    rects = []
    for r, row in enumerate(LAYOUT):
        for c, colour in enumerate(row):
            x = left + c * (tile + gap)
            y = top + r * (tile + gap)
            rects.append((x, y, x + tile, y + tile, colour))

    # Soft drop shadow, so the tiles sit on the ground rather than float in it.
    shadow = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    dy = tile * SHADOW_OFFSET
    for x0, y0, x1, y1, _ in rects:
        sd.rounded_rectangle([x0, y0 + dy, x1, y1 + dy], radius=corner,
                             fill=(0, 0, 0, SHADOW_ALPHA))
    shadow = shadow.filter(ImageFilter.GaussianBlur(max(tile * SHADOW_BLUR, 0.4)))
    if ground == "rounded":
        # Clip the shadow to the ground shape so it cannot bleed into the margin.
        mask = Image.new("L", (px, px), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            [origin, origin, origin + box, origin + box],
            radius=radius * box, fill=255)
        shadow.putalpha(Image.composite(shadow.getchannel("A"),
                                        Image.new("L", (px, px), 0), mask))
    img.alpha_composite(shadow)

    for x0, y0, x1, y1, colour in rects:
        d.rounded_rectangle([x0, y0, x1, y1], radius=corner, fill=colour + (255,))

    return img


def render(size: int, *, content: float = CONTENT_FULL, ground: str = "square",
           inset: float = 0.0, radius: float = 0.0) -> Image.Image:
    """Anti-aliased render at `size` px (drawn at SS x, then downsampled)."""
    big = _draw(size * SS, content, ground, inset, radius)
    return big.resize((size, size), Image.Resampling.LANCZOS)


def flatten(img: Image.Image) -> Image.Image:
    """Composite onto the background colour and drop the alpha channel."""
    base = Image.new("RGBA", img.size, BG + (255,))
    return Image.alpha_composite(base, img).convert("RGB")


# --------------------------------------------------------------------------
# Output helpers
# --------------------------------------------------------------------------
WRITTEN: list[tuple[str, str, int]] = []  # (path, mode, size)


def write(path: str, img: Image.Image) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, "PNG", optimize=True)
    WRITTEN.append((os.path.relpath(path, REPO), img.mode, img.size[0]))


def write_text(path: str, text: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(text)
    WRITTEN.append((os.path.relpath(path, REPO), "xml", 0))


def contents_slots(appicon_dir: str) -> dict[str, int]:
    """filename -> pixel size, from an .appiconset Contents.json."""
    with open(os.path.join(appicon_dir, "Contents.json"), encoding="utf-8") as fh:
        data = json.load(fh)
    slots: dict[str, int] = {}
    for entry in data["images"]:
        name = entry.get("filename")
        if not name:
            continue
        pt = float(entry["size"].split("x")[0])
        scale = int(entry["scale"].rstrip("x"))
        px = int(round(pt * scale))
        if name in slots and slots[name] != px:
            raise SystemExit(f"{name}: conflicting sizes {slots[name]} vs {px}")
        slots[name] = px
    return slots


# --------------------------------------------------------------------------
# Generation
# --------------------------------------------------------------------------
def generate() -> None:
    # --- master + Android adaptive source layers -------------------------
    icon_dir = os.path.join(APP, "assets/icon")
    write(os.path.join(icon_dir, "icon-1024.png"), flatten(render(1024)))
    write(os.path.join(icon_dir, "icon-foreground.png"),
          render(1024, content=CONTENT_ADAPTIVE, ground="none"))
    write(os.path.join(icon_dir, "icon-background.png"),
          Image.new("RGB", (1024, 1024), BG))

    # --- Android ---------------------------------------------------------
    legacy = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for dpi, px in legacy.items():
        write(os.path.join(ANDROID_RES, f"mipmap-{dpi}", "ic_launcher.png"),
              render(px, ground="rounded", inset=LEGACY_INSET, radius=LEGACY_RADIUS))

    # Adaptive foreground: 108 dp base, content inside the central 66 %.
    adaptive = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
    for dpi, px in adaptive.items():
        write(os.path.join(ANDROID_RES, f"mipmap-{dpi}", "ic_launcher_foreground.png"),
              render(px, content=CONTENT_ADAPTIVE, ground="none"))

    write_text(
        os.path.join(ANDROID_RES, "mipmap-anydpi-v26", "ic_launcher.xml"),
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background" />\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
        '</adaptive-icon>\n',
    )
    write_text(
        os.path.join(ANDROID_RES, "values", "ic_launcher_background.xml"),
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources>\n'
        '    <color name="ic_launcher_background">#%02X%02X%02X</color>\n'
        '</resources>\n' % BG,
    )

    # --- iOS (no alpha channel: the App Store rejects transparency) ------
    for name, px in contents_slots(IOS_APPICON).items():
        write(os.path.join(IOS_APPICON, name), flatten(render(px)))

    # --- macOS (rounded square on the Apple 824/1024 icon grid) ----------
    for name, px in contents_slots(MACOS_APPICON).items():
        write(os.path.join(MACOS_APPICON, name),
              render(px, content=MACOS_CONTENT, ground="rounded",
                     inset=MACOS_INSET, radius=MACOS_RADIUS))

    # --- Web -------------------------------------------------------------
    web = os.path.join(APP, "web")
    write(os.path.join(web, "favicon.png"), flatten(render(32)))
    for px in (192, 512):
        write(os.path.join(web, "icons", f"Icon-{px}.png"), flatten(render(px)))
        write(os.path.join(web, "icons", f"Icon-maskable-{px}.png"),
              flatten(render(px, content=CONTENT_MASKABLE)))

    # --- Windows ---------------------------------------------------------
    ico_sizes = [16, 32, 48, 64, 128, 256]
    frames = [render(px).convert("RGBA") for px in ico_sizes]
    ico = os.path.join(APP, "windows/runner/resources/app_icon.ico")
    os.makedirs(os.path.dirname(ico), exist_ok=True)
    sizes = [(s, s) for s in ico_sizes]
    try:
        frames[-1].save(ico, format="ICO", sizes=sizes, append_images=frames[:-1])
    except TypeError:  # Pillow without append_images support for ICO
        frames[-1].save(ico, format="ICO", sizes=sizes)
    WRITTEN.append((os.path.relpath(ico, REPO), "ICO", 256))


# --------------------------------------------------------------------------
# Verification
# --------------------------------------------------------------------------
def _check(rows: list[tuple[str, str, str]], path: str, want_px: int,
           *, want_mode: str | None = None, no_alpha: bool = False) -> bool:
    rel = os.path.relpath(path, REPO)
    if not os.path.exists(path):
        rows.append((rel, "-", "MISSING"))
        return False
    with Image.open(path) as im:
        w, h = im.size
        mode = im.mode
    problems = []
    if (w, h) != (want_px, want_px):
        problems.append(f"expected {want_px}x{want_px}")
    if want_mode and mode != want_mode:
        problems.append(f"expected mode {want_mode}")
    if no_alpha and ("A" in mode or mode == "P"):
        problems.append("has alpha")
    rows.append((rel, f"{w}x{h} {mode}", "; ".join(problems) if problems else "ok"))
    return not problems


def verify() -> bool:
    rows: list[tuple[str, str, str]] = []
    ok = True

    icon_dir = os.path.join(APP, "assets/icon")
    ok &= _check(rows, os.path.join(icon_dir, "icon-1024.png"), 1024, no_alpha=True)
    ok &= _check(rows, os.path.join(icon_dir, "icon-foreground.png"), 1024,
                 want_mode="RGBA")
    ok &= _check(rows, os.path.join(icon_dir, "icon-background.png"), 1024)

    for dpi, px in (("mdpi", 48), ("hdpi", 72), ("xhdpi", 96),
                    ("xxhdpi", 144), ("xxxhdpi", 192)):
        ok &= _check(rows, os.path.join(ANDROID_RES, f"mipmap-{dpi}",
                                        "ic_launcher.png"), px)
    for dpi, px in (("mdpi", 108), ("hdpi", 162), ("xhdpi", 216),
                    ("xxhdpi", 324), ("xxxhdpi", 432)):
        ok &= _check(rows, os.path.join(ANDROID_RES, f"mipmap-{dpi}",
                                        "ic_launcher_foreground.png"), px,
                     want_mode="RGBA")
    for extra in (os.path.join(ANDROID_RES, "mipmap-anydpi-v26", "ic_launcher.xml"),
                  os.path.join(ANDROID_RES, "values", "ic_launcher_background.xml")):
        present = os.path.exists(extra)
        ok &= present
        rows.append((os.path.relpath(extra, REPO), "xml",
                     "ok" if present else "MISSING"))

    for name, px in sorted(contents_slots(IOS_APPICON).items()):
        ok &= _check(rows, os.path.join(IOS_APPICON, name), px,
                     want_mode="RGB", no_alpha=True)
    for name, px in sorted(contents_slots(MACOS_APPICON).items()):
        ok &= _check(rows, os.path.join(MACOS_APPICON, name), px)

    web = os.path.join(APP, "web")
    ok &= _check(rows, os.path.join(web, "favicon.png"), 32)
    for px in (192, 512):
        ok &= _check(rows, os.path.join(web, "icons", f"Icon-{px}.png"), px)
        ok &= _check(rows, os.path.join(web, "icons", f"Icon-maskable-{px}.png"), px)

    ico = os.path.join(APP, "windows/runner/resources/app_icon.ico")
    if os.path.exists(ico):
        with Image.open(ico) as im:
            got = sorted(im.info["sizes"])
        want = [(s, s) for s in (16, 32, 48, 64, 128, 256)]
        good = got == want
        ok &= good
        rows.append((os.path.relpath(ico, REPO),
                     ",".join(str(s[0]) for s in got),
                     "ok" if good else f"expected {[s[0] for s in want]}"))
    else:
        ok = False
        rows.append((os.path.relpath(ico, REPO), "-", "MISSING"))

    w0 = max(len(r[0]) for r in rows)
    w1 = max(len(r[1]) for r in rows)
    print(f"{'file'.ljust(w0)}  {'raster'.ljust(w1)}  status")
    print(f"{'-' * w0}  {'-' * w1}  ------")
    for a, b, c in rows:
        print(f"{a.ljust(w0)}  {b.ljust(w1)}  {c}")
    print(f"\n{len(rows)} slots, {'all ok' if ok else 'PROBLEMS FOUND'}")
    return bool(ok)


def main(argv: Iterable[str]) -> int:
    if "--verify" not in argv:
        generate()
        print(f"wrote {len(WRITTEN)} files\n")
    return 0 if verify() else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
