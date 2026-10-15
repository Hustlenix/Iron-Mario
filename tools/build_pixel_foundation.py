"""Build small, original pixel-art environment previews for Iron-Mario."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "shared_foundation"
SCENES = OUT / "pixel_kits"
PAPER = "#faf3df"
INK = "#29263d"
PALE = "#e9e5d5"
BLUE = "#4d94e4"
CORAL = "#f16458"
GOLD = "#ffc756"
TEAL = "#70d3c8"
VIOLET = "#a991df"


def new_scene(accent: str) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    im = Image.new("RGB", (320, 180), PAPER)
    d = ImageDraw.Draw(im)
    # Keep the big central field quiet like the actual arcade boards.
    d.line((0, 0, 208, 0), fill="#dedbcc", width=2)
    d.line((0, 0, 0, 48), fill="#dedbcc", width=2)
    d.line((319, 0, 319, 30), fill="#dedbcc", width=2)
    d.line((8, 151, 62, 151), fill="#e4ddca", width=2)
    d.line((258, 151, 312, 151), fill="#e4ddca", width=2)
    d.rectangle((12, 167, 307, 170), fill="#e8dfce")
    d.rectangle((15, 172, 102, 175), fill="#dbc3a6")
    d.rectangle((214, 172, 305, 175), fill="#dbc3a6")
    d.rectangle((16, 166, 18, 176), fill=accent)
    d.rectangle((301, 166, 303, 176), fill=accent)
    # Tiny, deliberate pixel motifs. No gradients, blur, or smoothing.
    for x, y in ((31, 31), (282, 28), (55, 128), (265, 117)):
        d.rectangle((x, y, x + 2, y + 2), fill=GOLD)
        d.point((x + 4, y + 2), fill=INK)
    return im, d


def block(d, x, y, w, h, fill, edge=INK):
    d.rectangle((x, y, x+w-1, y+h-1), fill=fill, outline=edge, width=2)


def sky_foundry():
    im, d = new_scene(BLUE)
    # Far skyline and stepped launch gantries stay at the edge of play.
    for x, h in ((20, 28), (42, 44), (73, 34), (244, 38), (276, 52)):
        d.rectangle((x, 150-h, x+12, 150), fill="#e8e5d8")
        d.rectangle((x, 150-h, x+12, 150-h+2), fill="#c9d5d8")
        for yy in range(150-h+9, 145, 12):
            d.rectangle((x+4, yy, x+7, yy+2), fill="#bac9ca")
    block(d, 4, 119, 40, 7, "#b9d9dc")
    block(d, 275, 108, 41, 7, "#b9d9dc")
    d.line((9, 126, 9, 159), fill=INK, width=2); d.line((38, 126, 38, 159), fill=INK, width=2)
    d.line((280, 115, 280, 159), fill=INK, width=2); d.line((311, 115, 311, 159), fill=INK, width=2)
    for x in (12, 30, 283, 303): d.rectangle((x, 132, x+4, 136), fill=GOLD)
    # Launch pad: deliberately playful, bold, and readable at 1x.
    block(d, 123, 146, 74, 10, "#a9d9d5")
    d.rectangle((134, 156, 138, 165), fill=CORAL); d.rectangle((182, 156, 186, 165), fill=CORAL)
    d.rectangle((143, 141, 177, 144), fill=GOLD)
    return im


def neon_workshop():
    im, d = new_scene(TEAL)
    # Side benches and open center, echoing the tiny garage/toolbox motifs in-game.
    block(d, 8, 119, 65, 8, "#d5b892")
    block(d, 12, 127, 57, 30, "#d8c8a9")
    for x in (17, 34, 51): block(d, x, 132, 12, 19, ("#a7d4ce", "#e2a095", "#f0cc74")[(x//17-1)%3])
    block(d, 242, 119, 69, 8, "#d5b892")
    block(d, 248, 127, 57, 30, "#d8c8a9")
    # Little robot parts, laid out like game pickups.
    for x, color in ((89, CORAL), (103, TEAL), (217, GOLD), (231, VIOLET)):
        block(d, x, 140, 9, 10, color)
        d.rectangle((x+2, 137, x+6, 140), fill=INK)
    block(d, 132, 20, 56, 28, "#d4e4df")
    d.rectangle((138, 26, 181, 43), fill="#c2e9df")
    d.rectangle((143, 30, 150, 33), fill=TEAL); d.rectangle((154, 30, 162, 33), fill=CORAL)
    d.rectangle((166, 30, 176, 33), fill=GOLD)
    return im


def reactor_core():
    im, d = new_scene(VIOLET)
    # Reactor chamber silhouette frames a calm, usable central gameplay field.
    for x in (5, 295):
        block(d, x, 48, 20, 95, "#d9d2c5")
        d.rectangle((x+6, 57, x+13, 60), fill=CORAL)
        d.rectangle((x+6, 67, x+13, 70), fill=GOLD)
        d.rectangle((x+6, 77, x+13, 80), fill=TEAL)
        d.rectangle((x+3, 140, x+16, 149), fill="#c3b9a5")
    block(d, 133, 124, 54, 33, "#d8ded4")
    block(d, 141, 131, 38, 18, "#bde3d7")
    d.rectangle((149, 136, 170, 143), fill="#70c8bd")
    d.rectangle((157, 133, 162, 146), fill=GOLD)
    d.line((22, 51, 69, 51), fill=VIOLET, width=3); d.line((250, 51, 297, 51), fill=VIOLET, width=3)
    d.rectangle((21, 50, 25, 54), fill=GOLD); d.rectangle((292, 50, 296, 54), fill=GOLD)
    return im


def fungus_underworks():
    im, d = new_scene(TEAL)
    # A paper-lit cave, with chunky mushroom and crystal clusters at the edges.
    for x, y, h, color in ((12, 130, 17, CORAL), (40, 120, 27, VIOLET), (268, 129, 18, GOLD), (297, 115, 32, CORAL)):
        d.rectangle((x+7, y+8, x+11, y+h), fill="#728c76")
        d.rectangle((x+2, y+4, x+16, y+10), fill=color, outline=INK, width=2)
        d.rectangle((x+4, y+7, x+6, y+9), fill=PAPER)
        d.rectangle((x+12, y+7, x+14, y+9), fill=PAPER)
    for x, y, col in ((70, 144, TEAL), (83, 137, VIOLET), (233, 143, BLUE), (250, 135, TEAL)):
        d.polygon([(x, y+12), (x+5, y), (x+10, y+12)], fill=col, outline=INK)
        d.line((x+5, y+3, x+5, y+9), fill="#e8ffff", width=1)
    for x in range(8, 314, 24):
        d.rectangle((x, 163, x+10, 165), fill="#b5c9a8")
    return im


def battle_lab():
    im, d = new_scene(CORAL)
    # The original arcade's blue rail and red hazard become a playful ring.
    d.line((15, 61, 305, 61), fill=BLUE, width=4)
    d.line((15, 119, 305, 119), fill=BLUE, width=4)
    for x, y in ((42, 55), (274, 113)):
        block(d, x, y, 14, 18, "#c9ddd8")
        d.rectangle((x+5, y+5, x+9, y+9), fill=GOLD)
    block(d, 16, 138, 28, 17, "#c9dfe0")
    block(d, 276, 138, 28, 17, "#c9dfe0")
    for x in (22, 34, 282, 294): d.rectangle((x, 142, x+4, 150), fill=CORAL)
    # Center stays open; one tiny target provides a readable game cue.
    d.rectangle((156, 87, 163, 94), fill=GOLD, outline=INK)
    d.line((159, 82, 159, 77), fill=INK, width=2); d.line((154, 90, 149, 90), fill=INK, width=2)
    return im


def chaos_carnival():
    im, d = new_scene(GOLD)
    # A deliberately wonky pixel marquee and three tiny carnival props.
    block(d, 111, 22, 98, 24, "#f5d78a")
    for i, color in enumerate((CORAL, TEAL, VIOLET, BLUE, CORAL, TEAL)):
        x = 118 + i*14
        d.rectangle((x, 28, x+6, 34), fill=color)
    d.rectangle((116, 41, 203, 43), fill=INK)
    # Surprise boxes and a wind-up toy occupy the low side margins.
    for x, color in ((22, CORAL), (53, TEAL), (253, VIOLET), (284, GOLD)):
        block(d, x, 137, 20, 20, color)
        d.line((x+2, 143, x+17, 143), fill=PAPER, width=2)
        d.rectangle((x+8, 144, x+11, 149), fill=INK)
    block(d, 144, 142, 31, 15, "#d9b49a")
    d.rectangle((151, 132, 168, 144), fill="#e9ba67", outline=INK, width=2)
    d.rectangle((154, 136, 156, 139), fill=INK); d.rectangle((163, 136, 165, 139), fill=INK)
    d.line((158, 127, 158, 132), fill=INK, width=2); d.rectangle((155, 124, 161, 127), fill=GOLD)
    return im


def hero_sheet() -> Image.Image:
    """Four project-original 32x32 idle sprites in the game's little-hero scale."""
    sheet = Image.new("RGBA", (128, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)
    heroes = [
        # Solstice: bright faceplate, sun crest, short coral scarf.
        (GOLD, CORAL, TEAL, "sun"),
        # Vector: blue/teal flight suit with a sharp gold visor.
        (BLUE, TEAL, GOLD, "wing"),
        # Umbra: violet hood and dark split cape, pale eyes.
        (VIOLET, "#5a5279", "#eee3d1", "moon"),
        # Prism: magenta crystal crest, teal suit, gold core.
        ("#df8fc8", TEAL, GOLD, "gem"),
    ]
    for i, (helmet, cape, core, crest) in enumerate(heroes):
        x = i * 32
        # cape/backpack silhouette, chunky arms and booted legs
        draw.rectangle((x+4, 13, x+8, 24), fill=cape, outline=INK)
        draw.rectangle((x+6, 24, x+12, 27), fill=cape)
        draw.rectangle((x+22, 14, x+27, 21), fill=cape, outline=INK)
        draw.rectangle((x+10, 10, x+22, 21), fill=INK)
        draw.rectangle((x+12, 12, x+20, 19), fill=core)
        draw.rectangle((x+7, 12, x+10, 18), fill=INK)
        draw.rectangle((x+8, 13, x+10, 17), fill=helmet)
        draw.rectangle((x+22, 12, x+25, 18), fill=INK)
        draw.rectangle((x+23, 13, x+25, 17), fill=helmet)
        draw.rectangle((x+12, 20, x+15, 26), fill=INK)
        draw.rectangle((x+17, 20, x+20, 26), fill=INK)
        draw.rectangle((x+10, 26, x+16, 29), fill=INK)
        draw.rectangle((x+17, 26, x+22, 29), fill=INK)
        # helmet and readable face/eye line
        draw.rectangle((x+11, 2, x+21, 11), fill=INK)
        draw.rectangle((x+12, 3, x+20, 9), fill=helmet)
        draw.rectangle((x+12, 7, x+20, 9), fill="#26314a")
        draw.rectangle((x+14, 7, x+15, 8), fill=PAPER)
        draw.rectangle((x+18, 7, x+19, 8), fill=PAPER)
        # unique emblem/crest pixels
        if crest == "sun":
            draw.rectangle((x+15, 13, x+17, 17), fill=GOLD)
            draw.rectangle((x+14, 14, x+18, 16), fill=GOLD)
            draw.rectangle((x+14, 0, x+18, 1), fill=GOLD)
        elif crest == "wing":
            draw.rectangle((x+13, 14, x+19, 15), fill=GOLD)
            draw.rectangle((x+14, 13, x+18, 16), fill=GOLD)
            draw.rectangle((x+5, 8, x+9, 11), fill=BLUE)
            draw.rectangle((x+23, 8, x+27, 11), fill=BLUE)
        elif crest == "moon":
            draw.rectangle((x+14, 13, x+17, 17), fill=PAPER)
            draw.rectangle((x+16, 12, x+18, 16), fill=cape)
            draw.rectangle((x+20, 1, x+23, 4), fill=PAPER)
        else:
            draw.rectangle((x+15, 13, x+17, 17), fill=GOLD)
            draw.rectangle((x+14, 14, x+18, 16), fill=GOLD)
            draw.point((x+16, 0), fill=helmet); draw.point((x+14, 2), fill=helmet); draw.point((x+18, 2), fill=helmet)
    return sheet


BUILDERS = {
    "sky_foundry": sky_foundry,
    "neon_workshop": neon_workshop,
    "reactor_core": reactor_core,
    "fungus_underworks": fungus_underworks,
    "battle_lab": battle_lab,
    "chaos_carnival": chaos_carnival,
}


def build() -> list[dict]:
    SCENES.mkdir(parents=True, exist_ok=True)
    entries = []
    for name, builder in BUILDERS.items():
        image = builder()
        path = SCENES / f"{name}.png"
        image.save(path, optimize=True)
        entries.append({"id": name, "file": f"assets/shared_foundation/pixel_kits/{path.name}",
                        "canvas": "320x180", "pixel_scale": 1, "format": "PNG RGB",
                        "source": "original pixel composition, drawn to match Iron-Mario paper boards",
                        "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
    # Reusable low-resolution hit sparkle in the project's own palette.
    sheet = Image.new("RGBA", (4*16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(sheet)
    for index, color in enumerate((GOLD, CORAL, TEAL, VIOLET)):
        x = index*16
        for coords in (((6,1,9,4),(4,6,11,9),(6,11,9,14),(1,6,4,9),(11,6,14,9)),
                       ((6,2,9,5),(3,6,6,9),(9,6,12,9),(6,10,9,13)),
                       ((6,4,9,11),(4,6,11,9)),
                       ((6,2,9,5),(3,6,6,9),(9,6,12,9),(6,10,9,13)))[index]:
            d.rectangle(tuple(v+x if j % 2 == 0 else v for j, v in enumerate(coords)), fill=color)
    effects = OUT / "pixel_effects.png"
    sheet.save(effects, optimize=True)
    entries.append({"id": "pixel_effects", "file": "assets/shared_foundation/pixel_effects.png",
                    "canvas": "64x16; four 16x16 frames", "pixel_scale": 1, "format": "PNG RGBA",
                    "source": "original palette-matched pixel sprites", "sha256": hashlib.sha256(effects.read_bytes()).hexdigest()})
    heroes = SCENES / "hero_idles.png"
    hero_sheet().save(heroes, optimize=True)
    entries.append({"id": "hero_idles", "file": "assets/shared_foundation/pixel_kits/hero_idles.png",
                    "canvas": "128x32; four 32x32 heroes", "pixel_scale": 1, "format": "PNG RGBA",
                    "source": "original pixel sprites for Solstice, Vector, Umbra, Prism", "sha256": hashlib.sha256(heroes.read_bytes()).hexdigest()})
    (OUT / "pixel_catalog.json").write_text(json.dumps({"style": "warm paper arcade pixel art", "assets": entries}, indent=2), encoding="utf-8")
    # One contact sheet for a fast native-pixel review of the whole original kit.
    sheet = Image.new("RGB", (960, 2 * 180 + 170), PAPER)
    for index, name in enumerate(BUILDERS):
        scene = Image.open(SCENES / f"{name}.png").convert("RGB")
        sheet.paste(scene, ((index % 3) * 320, (index // 3) * 180))
    hero_preview = Image.open(heroes).resize((512, 128), Image.Resampling.NEAREST)
    effect_preview = Image.open(effects).resize((192, 48), Image.Resampling.NEAREST).convert("RGBA")
    sheet.paste(hero_preview.convert("RGB"), (80, 2 * 180 + 12), hero_preview)
    sheet.paste(effect_preview, (660, 2 * 180 + 44), effect_preview)
    preview_path = ROOT / "build" / "shared-foundation" / "pixel-contact-sheet.png"
    preview_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(preview_path, optimize=True)
    return entries


if __name__ == "__main__":
    assets = build()
    print(f"PIXEL_FOUNDATION built={len(assets)} 320x180_rooms=6 effects=4_frames")
