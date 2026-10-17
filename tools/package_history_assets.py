"""Package only the original history kit; no authoring tools or curator studies."""
from pathlib import Path
import json, shutil
ROOT=Path(__file__).resolve().parents[1]
source=ROOT/"assets/shared_foundation/history_arcade"
target=ROOT/"build/web/history-assets"
data=json.loads((source/"manifest.json").read_text())
assert all(a["license"]=="project_original" for a in data["assets"])
target.mkdir(parents=True,exist_ok=True)
allowed={a["file"] for a in data["assets"]}|{"manifest.json","palette.json","LICENSE_NOTES.md","STYLE_GUIDE.md"}
allowed|={p.name for p in source.glob("contact_*.png")}
allowed|={a["file"].replace(".png","_still.png") for a in data["assets"] if a["family"]=="effects"}
for name in sorted(allowed):
    p=(source/name).resolve()
    assert p.is_relative_to(source.resolve()) and p.is_file()
    out=target/"assets"/name;out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,out)
shutil.copytree(ROOT/"onlyeducation/asset-lab",target,dirs_exist_ok=True)
shutil.copy2(ROOT/"assets/icons/onlyeducation_mark_32.png",target/"oe-mark.png")
assert not (target/"source_art").exists() and not (target/"curators").exists()
print(f"HISTORY_PACKAGE: {len(data['assets'])} original assets, Canvas renderer and asset lab.")
