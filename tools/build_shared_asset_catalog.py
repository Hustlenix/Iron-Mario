"""Build a searchable HTML index for the shared asset foundation."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
foundation = ROOT / "assets" / "shared_foundation"
out = ROOT / "build" / "shared-foundation"
out.mkdir(parents=True, exist_ok=True)
manifest = json.loads((foundation / "source_inventory.json").read_text(encoding="utf-8"))
kits = []
for path in sorted((foundation / "zone_kits").glob("*.svg")):
    kits.append({"id": path.stem, "file": f"../../assets/shared_foundation/zone_kits/{path.name}", "status": "original_vector_composition"})
for name in ("ui_kit.svg", "effects_kit.svg"):
    kits.append({"id": Path(name).stem, "file": f"../../assets/shared_foundation/{name}", "status": "original_vector_composition"})
catalog = {"generated_from": "source_inventory.json", "kits": kits, "sources": manifest["sources"], "project_originals": manifest["project_originals"]}
(out / "catalog.json").write_text(json.dumps(catalog, indent=2), encoding="utf-8")
cards = []
for kit in kits:
    cards.append(f'<article><img src="{kit["file"]}" alt="{kit["id"]} shared kit"><h2>{kit["id"].replace("_", " ").title()}</h2><p>{kit["status"].replace("_", " ")}</p></article>')
originals = [
    ("Solstice", "../../assets/roster/solstice.png", "project original hero"),
    ("Vector", "../../assets/roster/vector.png", "project original hero"),
    ("Umbra", "../../assets/roster/umbra.png", "project original hero"),
    ("Prism", "../../assets/roster/prism.png", "project original hero"),
    ("Arcade Hub", "../../assets/rooms/menu_arcade_hub.png", "authored room composition"),
    ("Training Room", "../../assets/rooms/hero_training_room.png", "authored room composition"),
    ("Reactor Workshop", "../../assets/rooms/reactor_workshop.png", "authored room composition"),
]
for name, file, status in originals:
    cards.append(f'<article><img src="{file}" alt="{name} shared asset"><h2>{name}</h2><p>{status}</p></article>')
source_rows = []
for source in manifest["sources"]:
    source_rows.append(f'<tr><td>{source["id"]}</td><td>{source.get("observed_files", "")}</td><td>{source["license"]}</td><td>{source["public_status"]}</td></tr>')
html = f'''<!doctype html><meta charset="utf-8"><title>Iron-Mario Shared Asset Foundation</title>
<style>body{{font:16px system-ui;background:#101c28;color:#faf3df;margin:24px;max-width:calc(100vw - 48px);overflow-x:hidden}}h1{{color:#f2c15d}}.grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:16px}}article{{background:#1b2c3a;border:1px solid #607e8b;border-radius:12px;padding:12px;min-width:0}}img{{width:100%;aspect-ratio:2/1;object-fit:cover;border-radius:8px;background:#101c28}}table{{display:block;max-width:100%;overflow-x:auto;white-space:nowrap}}td,th{{padding:8px;border-bottom:1px solid #36505d;text-align:left}}.ready{{color:#66dcca}}</style>
<h1>IRON-MARIO / SHARED ASSET FOUNDATION</h1><p>Original vector zone kits and license-aware source inventory. The 105 game catalog is unchanged.</p><h2>Shared kits</h2><main class="grid">{"".join(cards)}</main><h2>Source and release status</h2><table><tr><th>Source</th><th>Files</th><th>License</th><th>Status</th></tr>{"".join(source_rows)}</table>'''
(out / "index.html").write_text(html, encoding="utf-8")
print(f"SHARED_ASSET_CATALOG kits={len(kits)} sources={len(manifest['sources'])} output={out}")
