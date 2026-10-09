"""Validate the shared asset foundation without opening the game runtime."""
from __future__ import annotations
import json
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
foundation = ROOT / "assets" / "shared_foundation"
manifest = json.loads((foundation / "source_inventory.json").read_text(encoding="utf-8"))
kits = sorted((foundation / "zone_kits").glob("*.svg"))
expected = {"sky_foundry", "neon_workshop", "reactor_core", "fungus_underworks", "battle_lab", "chaos_carnival"}
assert {p.stem for p in kits} == expected
for path in kits + [foundation / "ui_kit.svg", foundation / "effects_kit.svg"]:
    ET.parse(path)
assert len(manifest["sources"]) == 8
assert all(source.get("public_status") for source in manifest["sources"])
assert (foundation / "STYLE_GUIDE.md").exists()
assert (ROOT / "build/shared-foundation/index.html").exists()
print(f"ASSET_FOUNDATION_CHECK kits={len(kits)+2} sources={len(manifest['sources'])} svg_parse=ok license_status=recorded")
