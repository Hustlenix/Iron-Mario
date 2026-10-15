"""Validate pixel-art asset foundation files and recorded source decisions."""
from __future__ import annotations
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
foundation = ROOT / "assets" / "shared_foundation"
manifest = json.loads((foundation / "source_inventory.json").read_text(encoding="utf-8"))
catalog = json.loads((foundation / "pixel_catalog.json").read_text(encoding="utf-8"))
expected = {"sky_foundry", "neon_workshop", "reactor_core", "fungus_underworks", "battle_lab", "chaos_carnival"}
scenes = [a for a in catalog["assets"] if a["id"] in expected]
assert {Path(a["file"]).stem for a in scenes} == expected
for item in catalog["assets"]:
    path = ROOT / item["file"]
    assert path.is_file(), path
    with Image.open(path) as image:
        image.verify()
    with Image.open(path) as image:
        if item["id"] in expected:
            assert image.size == (320, 180) and image.mode == "RGB"
        elif item["id"] == "pixel_effects":
            assert image.size == (64, 16) and image.mode == "RGBA"
        elif item["id"] == "hero_idles":
            assert image.size == (128, 32) and image.mode == "RGBA"
assert len(manifest["sources"]) == 8
assert all(source.get("public_status") for source in manifest["sources"])
assert (foundation / "STYLE_GUIDE.md").exists()
assert (ROOT / "build/shared-foundation/index.html").exists()
assert not list((foundation / "zone_kits").glob("*.svg"))
print(f"PIXEL_FOUNDATION_CHECK scenes={len(scenes)} hero_sheet=4 effects=4frames sources={len(manifest['sources'])} png_integrity=ok license_status=recorded")
