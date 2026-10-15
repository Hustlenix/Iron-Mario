"""Local pixel review catalog using actual production exports."""
import json
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]; base=ROOT/'assets/shared_foundation'
out=ROOT/'build/shared-foundation'; out.mkdir(parents=True,exist_ok=True)
data=json.loads((base/'town_library/catalog.json').read_text())
data['sources']=json.loads((base/'source_inventory.json').read_text())['sources']
data['cast']=json.loads((base/'town_cast/recipes.json').read_text())
data['workshop']=json.loads((base/'workshop/manifest.json').read_text())
fx=json.loads((base/'town_fx_ui/manifest.json').read_text())
for asset in fx['assets']:
    file=base/'town_fx_ui'/asset['file']
    if file.suffix!='.png': continue
    data['assets'].append({**asset,'file':file.relative_to(ROOT).as_posix(),'kind':'effects' if asset['family']=='effects' else 'ui','size':list(Image.open(file).size),'source':'project_original_pixel_art','status':'integrated_selector' if asset['id'] in ['success_burst','button_normal','button_hover','button_pressed','button_disabled'] else 'exported_for_review'})
data['aseprite']=json.loads((base/'town_cast/aseprite_production.json').read_text())
for c in data['cast']:
    c['file']=f"assets/shared_foundation/town_cast/{c['id']}_motion.png"
    c['animation']=json.loads((base/f"town_cast/{c['id']}_motion.json").read_text())
for kind in ['scene','tiles','props','npc','enemy','effects','ui','hazards','animated_object']:
    items=[a for a in data['assets'] if a['kind']==kind]; cell=(320,204) if kind=='scene' else (192,152)
    sheet=Image.new('RGB',(cell[0]*3,cell[1]*((len(items)+2)//3)),'#fff3d7'); draw=ImageDraw.Draw(sheet)
    for i,item in enumerate(items):
        im=Image.open(ROOT/item['file']).convert('RGBA')
        if kind=='npc': im=im.crop((48,0,64,32)).resize((48,96),Image.Resampling.NEAREST)
        elif kind=='effects': im=im.crop((96,0,128,32)).resize((96,96),Image.Resampling.NEAREST)
        elif im.width>cell[0] or im.height>cell[1]-24: im.thumbnail((cell[0],cell[1]-24),Image.Resampling.NEAREST)
        x=i%3*cell[0]; y=i//3*cell[1]; sheet.paste(im,(x,y),im)
        draw.text((x+4,y+cell[1]-20),item['id'][:32],fill='#252844')
    sheet.save(out/f'contact_{kind}.png')
(out/'catalog.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
template=(ROOT/'tools/town_catalog.html').read_text(encoding='utf-8')
template=template.replace('</select><span id="count"','<option value="effects">Effects</option><option value="ui">UI kit</option><option value="hazards">Hazards</option><option value="animated_object">Animated props</option></select><span id="count"')
template=template.replace('Distinctive accessories and missing character actions; district exteriors, hazards and effects; UI sprites; individual visual review of all 105 games.','Remaining work: distinctive accessories and missing character actions, plus individual visual application and review across the 105 games. Editable Aseprite cast timelines and the current effects/buttons are integrated in the selector.')
template=template.replace('</html>','<script>'+ (ROOT/'tools/town_catalog_extras.js').read_text()+'</script></html>')
template=template.replace("['scene','tiles','props','npc','enemy']","['scene','tiles','props','npc','enemy','effects','ui','hazards','animated_object']")
(out/'index.html').write_text(template.replace('__CATALOG__',json.dumps(data).replace('</','<\\/')),encoding='utf-8')
print(f"TOWN_CATALOG: {len(data['assets'])} exports, six animated cast previews, nine family contact sheets")
