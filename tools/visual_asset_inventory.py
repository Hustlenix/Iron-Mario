"""Read-only local asset audit and private contact sheets; never runs supplied code.

Contact sheets belong in ignored build/visual-assets. Only three authored, flattened
rooms from the licensed full Modern Interiors pack are suitable release assets.
"""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import html
import json
import os
from pathlib import Path
import re
import struct
import textwrap

from PIL import Image, ImageDraw, ImageFont

PROJECT = Path(__file__).resolve().parents[1]
DOWNLOADS = Path.home() / "Downloads"
OUTPUT = PROJECT / "build" / "visual-assets"
PACKS = [
    ("generator", "Character Generator 2.0 Linux Build", "Unverified; exclude", "Avatar parts; no local output license"),
    ("modern-full", "moderninteriors-win", "Commercial permitted; credit required", "Rooms, furniture, UI, civilian sprites"),
    ("modern-rpg", "Modern_Interiors_RPG_Maker_Version", "Commercial permitted; credit required", "RPG Maker layouts; conversion required"),
    ("modern-free", "Modern_Interiors_Free_v2.2", "Noncommercial only; exclude", "Free interiors and civilian sprites"),
    ("battlers-complete", "Fantasy Battlers - Complete", "Unverified; exclude", "Static fantasy opponents, not the four original heroes"),
    ("battlers-free", "Fantasy Battlers - Free", "Unverified; exclude", "Static fantasy opponents, not the four original heroes"),
    ("fungus", "Fungus Cave [16x16]", "Unverified; exclude", "Cave scenery, monsters, character sheets"),
]


def png_header(path: Path) -> dict | None:
    try:
        with path.open("rb") as stream:
            data = stream.read(26)
        if data[:8] != b"\x89PNG\r\n\x1a\n" or len(data) != 26:
            return None
        width, height = struct.unpack(">II", data[16:24])
        return {"width": width, "height": height, "bit_depth": data[24], "color_type": data[25]}
    except (OSError, ValueError):
        return None


def font(size: int):
    path = Path("C:/Windows/Fonts/consola.ttf")
    return ImageFont.truetype(str(path), size) if path.exists() else ImageFont.load_default()


def checker(size: tuple[int, int]) -> Image.Image:
    canvas = Image.new("RGBA", size, "#1b2434")
    draw = ImageDraw.Draw(canvas)
    for y in range(0, size[1], 12):
        for x in range(0, size[0], 12):
            if (x // 12 + y // 12) % 2 == 0:
                draw.rectangle((x, y, x + 11, y + 11), fill="#243149")
    return canvas


def sample_score(path: Path) -> tuple[int, int, str]:
    name = path.as_posix().lower()
    priorities = ["room_builder_16x16.png", "1_generic_16x16.png", "8_gym_16x16.png",
                  "13_conference_hall_16x16.png", "14_basement_16x16.png", "ui_16x16.png",
                  "preview", "complete.png", "tileset", "idle", "run", "character"]
    priority = next((i for i, token in enumerate(priorities) if token in name), 30)
    if "singles" in name or "shadowless" in name or "black_shadow" in name:
        priority += 40
    if "/32x32/" in name or "/48x48/" in name or "x2 size" in name:
        priority += 15
    return priority, len(name), name


def choose_samples(paths: list[Path], maximum: int = 16) -> list[Path]:
    result, families = [], Counter()
    for path in sorted(paths, key=sample_score):
        family = path.parent.as_posix()
        if families[family] >= 4:
            continue
        result.append(path)
        families[family] += 1
        if len(result) == maximum:
            break
    return result


def image_observation(path: Path, root: Path) -> dict:
    with Image.open(path) as source:
        original_mode = source.mode
        rgba = source.convert("RGBA")
    alpha = rgba.getchannel("A")
    histogram = alpha.histogram()
    pixels = rgba.width * rgba.height
    cell_match = re.search(r"(?:^|[^0-9])(16|32|48)x\1(?:[^0-9]|$)", path.as_posix())
    cell = int(cell_match.group(1)) if cell_match else None
    grid = None
    if cell and rgba.width % cell == 0 and rgba.height % cell == 0:
        grid = {"cell": cell, "columns": rgba.width // cell, "rows": rgba.height // cell,
                "evidence": "filename size and divisible image dimensions; animation order unverified"}
    empty_columns = [x for x in range(rgba.width) if alpha.crop((x, 0, x + 1, rgba.height)).getbbox() is None]
    layout = {"kind": "atlas or individual image; inspect before animating", "frame_order": "unverified"}
    lower_name = path.as_posix().lower()
    if "/battlers/" in lower_name or ("battlers" in lower_name and "complete.png" not in lower_name):
        layout = {"kind": "single static battler illustration", "frames": 1}
    elif "characters" in lower_name and rgba.width * 8 == rgba.height * 3:
        layout = {"kind": "three poses per row, four rows", "columns": 3, "rows": 4,
                  "frame_width": rgba.width // 3, "frame_height": rgba.height // 4,
                  "evidence": "actual 3:8 sheet geometry and inspected character contact sheet",
                  "frame_order": "direction order unverified"}
    elif "idle" in lower_name and rgba.height in {32, 64, 96} and rgba.width == rgba.height * 2:
        layout = {"kind": "four horizontal character poses", "columns": 4, "rows": 1,
                  "frame_width": rgba.width // 4, "frame_height": rgba.height,
                  "evidence": "actual 2:1 geometry and inspected idle contact sheet", "frame_order": "direction order unverified"}
    return {"path": path.relative_to(root).as_posix(), "size": list(rgba.size),
            "mode": original_mode, "transparent_percent": round(100 * histogram[0] / pixels, 2),
            "partial_alpha_percent": round(100 * sum(histogram[1:255]) / pixels, 2),
            "visible_bounds": alpha.getbbox(), "candidate_tile_grid": grid,
            "empty_column_count": len(empty_columns),
            "observed_layout": layout}


def contact_sheet(slug: str, title: str, status: str, root: Path, samples: list[Path]) -> list[dict]:
    cell_w, cell_h, columns = 310, 250, 4
    rows = (len(samples) + columns - 1) // columns
    canvas = Image.new("RGB", (columns * cell_w, 94 + rows * cell_h), "#0e1523")
    draw = ImageDraw.Draw(canvas)
    draw.text((18, 14), title, font=font(22), fill="#edf2ff")
    draw.text((18, 47), status + " | local inspection only | source art not shipped", font=font(14), fill="#a4bad7")
    observations = []
    for index, path in enumerate(samples):
        observation = image_observation(path, root)
        observations.append(observation)
        x, y = (index % columns) * cell_w + 12, 94 + (index // columns) * cell_h
        view = checker((286, 175))
        with Image.open(path) as source:
            sprite = source.convert("RGBA")
        scale = min(view.width / sprite.width, view.height / sprite.height)
        size = (max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale)))
        sprite = sprite.resize(size, Image.Resampling.NEAREST)
        view.alpha_composite(sprite, ((view.width - sprite.width) // 2, (view.height - sprite.height) // 2))
        canvas.paste(view.convert("RGB"), (x, y))
        draw.text((x, y + 181), f"{observation['size'][0]}x{observation['size'][1]} | alpha {observation['transparent_percent']}%", font=font(13), fill="#b4cae8")
        for line_index, line in enumerate(textwrap.wrap(observation["path"], 38)[:3]):
            draw.text((x, y + 199 + line_index * 14), line, font=font(12), fill="#eff5ff")
    canvas.save(OUTPUT / f"{slug}.png")
    return observations


def inventory():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    manifests = []
    for slug, folder, status, context in PACKS:
        root = DOWNLOADS / folder
        paths, text_files, counts = [], [], Counter()
        for directory, _, names in os.walk(root):
            for name in names:
                path = Path(directory) / name
                counts[path.suffix.lower()] += 1
                if path.suffix.lower() == ".png":
                    paths.append(path)
                if path.suffix.lower() in {".txt", ".md", ".rtf"}:
                    text_files.append(path)
        # File counts cover the entire folder. Header reads deliberately sample
        # large packs so review stays bounded rather than opening 50,000 sprites.
        samples = choose_samples(paths)
        stride = max(1, len(paths) // 496)
        header_paths = list(dict.fromkeys(samples + sorted(paths)[::stride][:496]))
        headers = [header for path in header_paths if (header := png_header(path))]
        dimensions = Counter(f"{h['width']}x{h['height']}" for h in headers)
        color_types = Counter(str(h["color_type"]) for h in headers)
        licenses = []
        for path in text_files:
            # Read license/readme documents only, never config files, binaries or code.
            if not re.search(r"license|eula|read[ _-]*me|copyright|permission", path.name, re.IGNORECASE):
                continue
            text = path.read_text(encoding="utf-8", errors="replace")[:30000]
            licenses.append({"path": path.relative_to(root).as_posix(),
                             "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "text": text})
        observations = contact_sheet(slug, folder, status, root, samples) if paths else []
        manifest = {"slug": slug, "folder": folder, "available": root.is_dir(), "status": status,
                    "context": context, "file_counts": dict(counts), "png_total": len(paths), "png_headers_read": len(headers),
                    "dimensions": dict(dimensions.most_common(12)), "png_color_types": dict(color_types),
                    "local_license_documents": licenses, "samples": observations}
        manifests.append(manifest)
        print(f"{slug}: {len(paths)} PNG, {len(licenses)} license/readme documents, {status}", flush=True)
    (OUTPUT / "inventory.json").write_text(json.dumps(manifests, indent=2), encoding="utf-8")
    cards = []
    if (OUTPUT / "authored-rooms.png").exists():
        cards.append('<section><h2>Three authored game rooms</h2><p>Selected full-version Modern Interiors regions '
                     'in original room layouts. All 640×360 RGB, pixel-perfect integer scale. '
                     'Credit: Modern Interiors by LimeZu — https://limezu.itch.io/.</p>'
                     '<a href="authored-rooms.png"><img src="authored-rooms.png" alt="Authored arcade, training and workshop rooms"></a></section>')
    for entry in manifests:
        cards.append(f'<section><h2>{html.escape(entry["folder"])}</h2><p>{html.escape(entry["status"])}. '
                     f'{html.escape(entry["context"])}. {entry["png_total"]} PNG files; {entry["png_headers_read"]} header samples inspected.</p>'
                     f'<a href="{entry["slug"]}.png"><img src="{entry["slug"]}.png" alt="{html.escape(entry["folder"])} contact sheet"></a></section>')
    page = ('<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width">'
            '<title>Local visual asset review</title><style>body{margin:32px auto;max-width:1280px;padding:0 20px;'
            'background:#0e1523;color:#edf2ff;font:16px system-ui}h1,h2{letter-spacing:-.02em}'
            'p{color:#b5c8e1;line-height:1.5}img{width:100%;height:auto;border-radius:12px}'
            'section{margin:40px 0}a{color:#88c8ff}</style><h1>Local visual asset review</h1>'
            '<p>Private review contact sheets only. No supplied executable was run. Gray squares show alpha; '
            'candidate tile grids are geometry observations, not verified animation orders. '
            'Keep these sheets and the local manifest out of public releases.</p>' + ''.join(cards))
    (OUTPUT / "index.html").write_text(page, encoding="utf-8")


def build_rooms():
    """Compose original layouts, selected tiles and a few props into game backgrounds."""
    base = DOWNLOADS / "moderninteriors-win"
    license_text = (base / "LICENSE.txt").read_text(encoding="utf-8").lower()
    required = ("commercial", "edit", "credits required", "resell or distribute")
    if not all(token in license_text for token in required):
        raise RuntimeError("Full Modern Interiors local license evidence changed; stop integration")
    interiors = base / "1_Interiors" / "16x16"
    atlas = Image.open(interiors / "Room_Builder_16x16.png").convert("RGBA")
    generic = Image.open(interiors / "Theme_Sorter" / "1_Generic_16x16.png").convert("RGBA")
    gym = Image.open(interiors / "Theme_Sorter" / "8_Gym_16x16.png").convert("RGBA")
    rooms_path = PROJECT / "assets" / "rooms"
    rooms_path.mkdir(parents=True, exist_ok=True)
    provenance = []

    def crop(source, rect):
        x, y, width, height = rect
        return source.crop((x, y, x + width, y + height))

    def prop(room, source, rect, position):
        room.alpha_composite(crop(source, rect), position)

    def room_base(floor_rect, wall_rect, strip):
        room = Image.new("RGBA", (320, 180), "#2b313b")
        floor = crop(atlas, floor_rect)
        wall = crop(atlas, wall_rect)
        for y in range(40, 180, floor.height):
            for x in range(0, 320, floor.width):
                room.alpha_composite(floor, (x, y))
        for x in range(0, 320, wall.width):
            room.alpha_composite(wall, (x, 8))
        draw = ImageDraw.Draw(room)
        draw.rectangle((0, 0, 319, 7), fill="#151c2a")
        draw.rectangle((0, 38, 319, 41), fill="#1b2330")
        draw.line((1, 6, 318, 6), fill=strip, width=2)
        draw.rectangle((0, 42, 3, 179), fill="#252b36")
        draw.rectangle((316, 42, 319, 179), fill="#252b36")
        # Clear center is authored around the four hero cards / gameplay overlay.
        return room

    def cabinet(room, x, y, color):
        # Original small arcade furniture; no supplied sprite is relabeled as a hero.
        draw = ImageDraw.Draw(room)
        draw.rectangle((x + 2, y + 43, x + 29, y + 48), fill="#2a2830")
        draw.polygon([(x + 2, y + 3), (x + 28, y + 3), (x + 28, y + 22),
                      (x + 31, y + 33), (x + 28, y + 46), (x, y + 46),
                      (x, y + 31), (x + 3, y + 22)], fill="#262334", outline="#121826")
        draw.rectangle((x + 3, y + 1, x + 27, y + 8), fill=color)
        draw.rectangle((x + 5, y + 10, x + 25, y + 26), fill="#090f1d", outline="#5b677c")
        draw.line((x + 7, y + 22, x + 23, y + 22), fill=color)
        draw.rectangle((x + 14, y + 15, x + 17, y + 19), fill="#fff1c4")
        draw.line((x + 3, y + 31, x + 27, y + 31), fill=color, width=2)
        draw.rectangle((x + 8, y + 29, x + 9, y + 31), fill="#dee6f4")
        draw.point((x + 22, y + 29), fill="#ed8584")
        draw.rectangle((x + 12, y + 37, x + 17, y + 40), fill="#111927")

    def save(room, name, purpose, regions):
        path = rooms_path / name
        flattened = room.convert("RGB").resize((640, 360), Image.Resampling.NEAREST)
        flattened.save(path, optimize=True)
        with Image.open(path) as verification:
            assert verification.size == (640, 360) and verification.mode == "RGB"
        provenance.append({"file": f"assets/rooms/{name}", "purpose": purpose,
                           "layout": "original authored 320x180 layout; flattened RGB, integer scale 2",
                           "safe_center": [128, 120, 384, 216], "source_regions": regions,
                           "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                           "credit": "Modern Interiors by LimeZu — https://limezu.itch.io/"})
        print(f"Authored {name}: {path.stat().st_size} bytes", flush=True)

    hub = room_base((736, 592, 16, 16), (352, 240, 16, 32), "#b6a8ee")
    for index, color in enumerate(("#c37164", "#76a999", "#9b82c1")):
        cabinet(hub, 12, 54 + index * 35, color)
        cabinet(hub, 276, 54 + index * 35, color)
    prop(hub, generic, (176, 912, 16, 32), (51, 17))
    prop(hub, generic, (176, 912, 16, 32), (253, 17))
    d = ImageDraw.Draw(hub)
    d.rectangle((105, 14, 215, 31), fill="#202438", outline="#c2b59c")
    d.line((112, 22, 143, 22), fill="#c37164", width=3)
    d.line((147, 22, 178, 22), fill="#76a999", width=3)
    d.line((182, 22, 208, 22), fill="#9b82c1", width=3)
    d.line((65, 162, 255, 162), fill="#8f97a4", width=1)
    save(hub, "menu_arcade_hub.png", "Menu / hero selection: calm arcade room with perimeter cabinets",
         [{"source": "Room_Builder_16x16.png", "floor": [736, 592, 16, 16], "wall": [352, 240, 16, 32]},
          {"source": "1_Generic_16x16.png", "wall_fixture": [176, 912, 16, 32]}, {"source": "original drawing", "objects": "six cabinets and wall sign"}])

    training = room_base((736, 416, 16, 16), (16, 224, 16, 16), "#d4b36b")
    # Neutral mat with restrained lane marks; equipment lives at the edges.
    d = ImageDraw.Draw(training)
    d.rectangle((62, 66, 257, 160), fill="#555563", outline="#a7a4a1", width=2)
    d.line((72, 153, 247, 153), fill="#777888")
    prop(training, gym, (96, 0, 16, 48), (20, 50))
    prop(training, gym, (96, 96, 16, 48), (283, 50))
    prop(training, gym, (0, 224, 48, 32), (9, 127))
    prop(training, gym, (144, 256, 32, 48), (278, 120))
    prop(training, gym, (144, 0, 32, 16), (83, 19))
    prop(training, gym, (144, 0, 32, 16), (205, 19))
    d = ImageDraw.Draw(training)
    for x in (141, 157, 173):
        d.rectangle((x, 14, x + 5, 30), fill="#c2a86f")
    save(training, "hero_training_room.png", "Hero selection / training: clear mat, gym props around perimeter",
         [{"source": "Room_Builder_16x16.png", "floor": [736, 416, 16, 16], "wall": [16, 224, 16, 16]},
          {"source": "8_Gym_16x16.png", "regions": [[96, 0, 16, 48], [96, 96, 16, 48], [0, 224, 48, 32], [144, 256, 32, 48], [144, 0, 32, 16]]}])

    workshop = room_base((736, 416, 16, 16), (352, 368, 16, 32), "#78b6b3")
    prop(workshop, generic, (48, 320, 48, 32), (13, 19))
    prop(workshop, generic, (48, 320, 48, 32), (259, 19))
    d = ImageDraw.Draw(workshop)
    for x in (13, 270):
        d.rectangle((x, 71, x + 37, 149), fill="#333c4e", outline="#151c27", width=2)
        d.rectangle((x + 4, 76, x + 33, 100), fill="#0d2934", outline="#859ba6")
        for yy in range(81, 96, 5):
            d.line((x + 9, yy, x + 27, yy), fill="#79c0b8")
        d.rectangle((x + 4, 106, x + 33, 120), fill="#596679")
        d.rectangle((x + 4, 126, x + 33, 142), fill="#596679")
        d.line((x + 13, 112, x + 23, 112), fill="#c3d2d5")
        d.line((x + 13, 133, x + 23, 133), fill="#c3d2d5")
    d.rectangle((136, 10, 183, 36), fill="#222d3d", outline="#aac4c2")
    d.ellipse((148, 13, 171, 34), fill="#64a89e", outline="#2e655f", width=3)
    d.ellipse((157, 21, 162, 26), fill="#d5e6be")
    # Subtle working-zone edge marks, with no visual obstacles in the play area.
    for x in range(66, 255, 12):
        d.line((x, 166, x + 5, 166), fill="#c1ad72", width=2)
    save(workshop, "reactor_workshop.png", "Garage / elevator room scenery: side terminals and clear working area",
         [{"source": "Room_Builder_16x16.png", "floor": [736, 416, 16, 16], "wall": [352, 368, 16, 32]},
          {"source": "1_Generic_16x16.png", "storage": [48, 320, 48, 32]}, {"source": "original drawing", "objects": "terminals, indicator, zone marks"}])
    OUTPUT.mkdir(parents=True, exist_ok=True)
    (OUTPUT / "room-provenance.json").write_text(json.dumps(provenance, indent=2, ensure_ascii=False), encoding="utf-8")
    sheet = Image.new("RGB", (640, 3 * 398), "#101827")
    d = ImageDraw.Draw(sheet)
    for index, entry in enumerate(provenance):
        y = index * 398
        d.text((12, y + 9), entry["file"], font=font(17), fill="#e7efff")
        sheet.paste(Image.open(PROJECT / entry["file"]), (0, y + 38))
    sheet.save(OUTPUT / "authored-rooms.png")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--inventory", action="store_true")
    parser.add_argument("--rooms", action="store_true")
    args = parser.parse_args()
    if args.rooms:
        build_rooms()
    if args.inventory or not args.rooms:
        inventory()
