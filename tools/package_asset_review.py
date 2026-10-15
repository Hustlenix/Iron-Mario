"""Publish the selected asset review beside the web game, excluding raw packs."""
from pathlib import Path
import json,shutil,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
subprocess.run([sys.executable,'tools/build_town_catalog.py'],check=True,cwd=ROOT)
review=ROOT/'build/shared-foundation';target=ROOT/'build/web/asset-workshop'
target.mkdir(parents=True,exist_ok=True)
data=json.loads((review/'catalog.json').read_text())
files={a['file'] for a in data['assets']}|{a['file'] for a in data['cast']}
files.add('assets/shared_foundation/workshop/room.png')
files.update('assets/shared_foundation/workshop/'+a['file'] for a in data['workshop']['animated'])
for source in files:
    path=ROOT/source;dest=target/source
    assert path.resolve().is_relative_to((ROOT/'assets/shared_foundation').resolve())
    dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,dest)
for p in review.glob('contact_*.png'):shutil.copy2(p,target/p.name)
# Paths/recipes remain useful, but absolute workstation paths do not belong online.
def clean(value):
    if isinstance(value,dict):return {k:clean(v) for k,v in value.items()}
    if isinstance(value,list):return [clean(v) for v in value]
    if isinstance(value,str) and (':\\' in value or ':/' in value and not value.startswith('http')):return 'local-source/'+value.replace('\\','/').split('/')[-1]
    return value
public=clean(data)
html=(review/'index.html').read_text(encoding='utf-8')
html=html.replace(json.dumps(data).replace('</','<\\/'),json.dumps(public).replace('</','<\\/'))
html=html.replace('../../','./')
html=html.replace('../visual-after/town_milo.png','../').replace('../visual-after/town_mobile_top.png','../')
html=html.replace('Godot desktop capture','Play in Godot').replace('Mobile capture','Return to arcade')
(target/'index.html').write_text(html,encoding='utf-8')
(target/'catalog.json').write_text(json.dumps(public,indent=2),encoding='utf-8')
print(f'ASSET_REVIEW_PACKAGE: {len(files)} selected PNGs and searchable catalog')
