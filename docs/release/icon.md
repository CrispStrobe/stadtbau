<!-- SPDX-License-Identifier: AGPL-3.0-or-later -->
# App icon

`python3 tools/gen_icon.py` regenerates every platform slot (Pillow only, no pub dependency)
and prints a verification table; `--verify` checks without rewriting. It drives the two
`AppIcon.appiconset` directories from their existing `Contents.json`, so new Xcode slots are
picked up automatically, and keeps the Android resource name `ic_launcher`, so
`AndroidManifest.xml` needs no change.

Design: a 4x4 grid of rounded hectare tiles on the deep green `#1B5E20`, with a two-tile-wide
diagonal band of meadow/park/forest cutting a dense block of housing, commercial and road
tiles away from a small settlement in the lower right — the game's core tension in one glyph.
The one water tile is the accent. Colours are exactly `app/lib/ui/tile_style.dart`.

Constraints the script encodes: everything is drawn from primitives at 4x and downsampled, so
the artwork is our own and reproducible; iOS PNGs are flattened to RGB (the App Store rejects
alpha); the Android adaptive foreground and PWA maskable icons are sized so the grid's
*bounding circle* fits the 66 % / 80 % safe circle, which is what a round mask clips against;
macOS follows Apple's 824-in-1024 rounded-square grid.
