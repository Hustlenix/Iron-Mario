"""Compose the town cast from the licensed full Modern Interiors source layers."""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(r'C:\Users\LalithReddy.b\Downloads\moderninteriors-win\2_Characters\Character_Generator')
OUT = ROOT / 'assets/shared_foundation/town_cast'
CAST = [
    ('milo','dart',2,5,'16_02','29_02','Curious mechanic'),
    ('jun','bolt',3,2,'17_01','27_04','Energetic courier'),
    ('bea','echo',5,3,'16_01','24_02','Cheerful builder'),
    ('nia','frost',4,4,'17_02','27_06','Inventive tinkerer'),
    ('ash','tether',6,1,'25_02','21_04','Relaxed skater'),
    ('pip','snap',1,6,'16_03','11_01','Arcade regular'),
]

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    portraits = Image.new('RGBA',(192,32))
    manifest=[]
    for i,(name,legacy,body,eyes,outfit,hair,role) in enumerate(CAST):
        paths=[f'Bodies/16x16/Body_{body:02}.png',f'Eyes/16x16/Eyes_{eyes:02}.png',f'Outfits/16x16/Outfit_{outfit}.png',f'Hairstyles/16x16/Hairstyle_{hair}.png']
        sheet=Image.new('RGBA',(896,640))
        for path in paths:
            layer=Image.open(SOURCE/path).convert('RGBA').crop((0,0,896,640))
            sheet.alpha_composite(layer)
        sheet.save(OUT/f'{name}.png')
        # Export only known animation cells; source sheets contain guide labels.
        clean=Image.new('RGBA',(384,160))
        clean.alpha_composite(sheet.crop((0,0,64,32)),(0,0))
        clean.alpha_composite(sheet.crop((0,64,384,96)),(0,32))
        clean.alpha_composite(sheet.crop((0,32,384,64)),(0,64))
        clean.alpha_composite(sheet.crop((0,416,384,448)),(0,96))
        clean.alpha_composite(sheet.crop((0,608,192,640)),(0,128))
        clean.save(OUT/f'{name}_motion.png')
        animations={'cell':[16,32],'anchor':[8,32],'directions':['left','up','right','down'],'guide':'Spritesheet_animations_GUIDE.png','idle':{'row':0,'frames_per_direction':1,'fps':1},'walk':{'row':1,'frames_per_direction':6,'fps':7},'run':{'row':1,'frames_per_direction':6,'fps':10,'note':'Walk poses played faster; no separate run source'},'idle_animated':{'row':2,'frames_per_direction':6,'fps':5},'hit':{'row':3,'frames_per_direction':6,'fps':10},'hurt':{'row':4,'frames_per_direction':3,'fps':8}}
        (OUT/f'{name}_motion.json').write_text(json.dumps(animations,indent=2))
        portrait=sheet.crop((48,0,64,32))
        portraits.alpha_composite(portrait,(i*32+8,0))
        manifest.append(dict(id=name,legacy_id=legacy,role=role,source_layers=paths,cell=[16,32],credit='Modern Interiors by LimeZu — https://limezu.itch.io/',license='Full Modern Interiors: commercial/noncommercial game use with credit; no standalone redistribution'))
    portraits.save(OUT/'cast_idles.png')
    (OUT/'recipes.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    roster=ROOT/'ui/hero_roster.gd'
    rows=[]
    colors=['#c68652','#6196ab','#c6a353','#b381ac','#849a9b','#d58977']
    for i,(name,legacy,*rest) in enumerate(CAST):
        role=rest[-1]
        rows.append(dict(id=legacy,name=name.upper(),title='PIXEL TOWN',role=role.upper(),color=colors[i],secondary='#92cbb4',art=f'res://assets/shared_foundation/town_cast/{name}.png',power='town',demo='Meet the character',story=f'{name.title()}, the town’s {role.lower()}. Always ready for another little adventure.',ability='A LITTLE CELEBRATION',ability_text='A cheerful hop and a burst of confetti.',trait='SAME GAMES. YOUR OWN STYLE.',game='skyline_jumper'))
    roster.write_text('class_name HeroRoster\nextends RefCounted\nconst HEROES := '+json.dumps(rows,ensure_ascii=False,indent=2)+'\nstatic func hero(index: int) -> Dictionary: return HEROES[posmod(index,HEROES.size())]\nstatic func by_id(id: String) -> Dictionary:\n\tfor spec: Dictionary in HEROES:\n\t\tif spec.id==id: return spec\n\treturn {}\n',encoding='utf-8')
    for name in ['hero_stage.gd','hero_selection.gd']:
        p=ROOT/'ui'/name
        s=p.read_text(encoding='utf-8').replace('res://assets/shared_foundation/pixel_kits/hero_idles.png','res://assets/shared_foundation/town_cast/cast_idles.png')
        for old,new in [('THE ORIGINAL FOUR','THE TOWN SIX'),('CHOOSE YOUR EXTRAORDINARY.','MEET YOUR NEIGHBOURS.'),('DEMONSTRATE POWER','CELEBRATE'),('SPACE: POWER','SPACE: CELEBRATE'),('TAP A HERO / DEMONSTRATE THEIR POWER','PICK A CHARACTER / SEE THEIR CELEBRATION'),('YOUR ACTIVE HERO','YOUR CHARACTER')]: s=s.replace(old,new)
        p.write_text(s,encoding='utf-8')
    print('Exported six layered character sheets and shared roster portraits.')

if __name__=='__main__': main()
