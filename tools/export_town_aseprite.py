"""Run the installed Aseprite authoring/export pipeline and retain its metadata."""
from pathlib import Path
import subprocess,json,hashlib
ROOT=Path(__file__).resolve().parents[1]
APP=Path(r'C:\Users\LalithReddy.b\Downloads\aseprite\build\bin\aseprite.exe')
OUT=ROOT/'assets/shared_foundation/town_cast'
(ROOT/'source_art/town_cast').mkdir(parents=True,exist_ok=True)
(ROOT/'source_art/.gdignore').touch()
def run(args):
    result=subprocess.run([str(APP),*args],capture_output=True,text=True,check=True,cwd=ROOT)
    if result.stdout.strip(): print(result.stdout.strip())
run(['--batch','--script-param',f'root={ROOT.as_posix()}','--script','tools/export_town_aseprite.lua'])
records=[]
for name in ['milo','jun','bea','nia','ash','pip']:
    source=ROOT/f'source_art/town_cast/{name}.aseprite'
    run(['--batch',str(source),'--sheet-type','rows','--sheet-columns','24','--list-tags','--format','json-array','--data',str(OUT/f'{name}_aseprite.json'),'--sheet',str(OUT/f'{name}_aseprite.png')])
    data=json.loads((OUT/f'{name}_aseprite.json').read_text())
    assert len(data['frames'])==88 and len(data['meta']['frameTags'])==20
    for tag in data['meta']['frameTags']:
        expected=1 if tag['name'].startswith('idle_') and not tag['name'].startswith('idle_animated') else 3 if tag['name'].startswith('hurt_') else 6
        assert tag['to']-tag['from']+1==expected,tag
    records.append({'id':name,'source':source.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'frames':88,'tags':20,'atlas':f'{name}_aseprite.png'})
(OUT/'aseprite_production.json').write_text(json.dumps({'application':str(APP),'records':records},indent=2))
print('ASEPRITE_EXPORT: six saved timelines and six PNG/JSON atlas exports verified')
