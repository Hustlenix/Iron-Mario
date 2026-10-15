"""Check atlas bounds, non-empty cells, recorded sources and distinct variants."""
from pathlib import Path
import json,hashlib
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]; BASE=ROOT/'assets/shared_foundation'
library=json.loads((BASE/'town_library/catalog.json').read_text())
checks=0
for a in library['assets']:
    with Image.open(ROOT/a['file']) as im:
        assert list(im.size)==a['size']; assert im.getbbox(); checks+=2
        if a['kind']=='tiles':
            for i in range(48):
                assert im.crop((i%8*16,i//8*16,i%8*16+16,i//8*16+16)).getbbox(),(a['id'],i); checks+=1
        for p in a.get('entries',[]):
            x,y,w,h=p['rect']; assert 0<=x<x+w<=im.width and 0<=y<y+h<=im.height
            assert p['source']=='project_original_pixel_art' or Path(p['source']).is_file(),p['source']; checks+=2
for kind in ['npc','enemy']:
    paths=[ROOT/a['file'] for a in library['assets'] if a['kind']==kind]
    assert len(paths)==12
    assert len({hashlib.sha256(p.read_bytes()).hexdigest() for p in paths})==12,kind+' duplicates'
    checks+=2
for person in json.loads((BASE/'town_cast/recipes.json').read_text()):
    name=person['id']; im=Image.open(BASE/f'town_cast/{name}_motion.png')
    meta=json.loads((BASE/f'town_cast/{name}_motion.json').read_text())
    for action in ['idle','idle_animated','walk','run','hit','hurt']:
        a=meta[action]
        for direction in range(4):
            for f in range(a['frames_per_direction']):
                x=(direction*a['frames_per_direction']+f)*16;y=a['row']*32
                assert im.crop((x,y,x+16,y+32)).getbbox(),(name,action,direction,f);checks+=1
    assert (BASE/f'town_cast/{name}_frames.tres').is_file()
report={'checks':checks,'failures':0,'scope':'PNG integrity, bounds, nonempty animation cells, source paths and duplicate variants; not subjective visual approval'}
(ROOT/'build/shared-foundation/validation.json').write_text(json.dumps(report,indent=2))
print('TOWN_ASSETS',report)
