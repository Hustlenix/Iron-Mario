"""Compose a compact town workshop from reviewed Modern Interiors props."""
from pathlib import Path
import json
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
SOURCE=Path(r'C:\Users\LalithReddy.b\Downloads\moderninteriors-win\1_Interiors\16x16\Theme_Sorter_Shadowless_Singles\14_Basement_Singles_Shadowless')
OUT=ROOT/'assets/shared_foundation/workshop'
OUT.mkdir(parents=True,exist_ok=True)
props={64:'ladder',85:'workbench',103:'stool',163:'monitor',167:'desk_lamp',174:'desktop_computer',173:'keyboard',177:'desktop_tower',194:'equipment_rack',196:'railing',219:'vending_machine',225:'landscape_picture'}
atlas=Image.new('RGBA',(384,256))
records=[]
for i,(number,name) in enumerate(props.items()):
    source=SOURCE/f'Basement_Singles_Shadowless_{number}.png'
    im=Image.open(source).convert('RGBA')
    x=(i%6)*64; y=(i//6)*128
    atlas.alpha_composite(im,(x,y))
    records.append({'id':name,'rect':[x,y,*im.size],'source':str(source),'native_size':list(im.size)})
atlas.save(OUT/'props.png')
room=Image.new('RGBA',(320,180),'#252c42'); d=ImageDraw.Draw(room)
d.rectangle((8,8,311,55),fill='#749c9d')
for x in range(8,312,16):
    d.line((x,8,x,55),fill='#517880'); d.line((x+1,9,x+1,54),fill='#97b6ad')
d.rectangle((8,52,311,57),fill='#dfbe89')
for y in range(58,176,16):
    for x in range(8,312,16):
        d.rectangle((x,y,x+15,y+15),fill='#8c776d' if (x//16+y//16)%2 else '#978176')
        d.line((x,y+15,x+15,y+15),fill='#756963')
def prop(name,x,y):
    record=next(r for r in records if r['id']==name)
    room.alpha_composite(Image.open(record['source']).convert('RGBA'),(x,y))
for x in (36,100,164): prop('workbench',x,60)
prop('monitor',38,47); prop('keyboard',39,72)
prop('desk_lamp',106,53)
prop('desktop_computer',180,64); prop('equipment_rack',240,34)
prop('vending_machine',272,83); prop('landscape_picture',100,25)
prop('ladder',16,101)
for x in (47,112,177): prop('stool',x,91)
d.rectangle((77,118,245,163),fill='#52797d',outline='#bec1a1',width=1)
d.rectangle((80,121,242,160),outline='#698e8b',width=1)
room.save(OUT/'room.png')
animated=[]
for name,cell,fps,position in [('control_room_screens',[64,48],5,[172,10]),('control_room_server',[16,48],4,[283,20]),('cat',[48,16],6,[30,150]),('amplifier',[16,32],4,[20,53])]:
    source=SOURCE.parents[3]/'3_Animated_objects'/'16x16'/'spritesheets'/f'animated_{name}.png'
    im=Image.open(source).convert('RGBA')
    im.save(OUT/f'{name}.png')
    animated.append({'id':name,'source':str(source),'file':f'{name}.png','cell':cell,'frames':im.width//cell[0],'fps':fps,'position':position,'reduced_motion_frame':0})
(OUT/'manifest.json').write_text(json.dumps({'credit':'Modern Interiors by LimeZu - https://limezu.itch.io/','license':'Full Modern Interiors commercial/noncommercial game use with credit; no standalone redistribution','canvas':[320,180],'props':records,'animated':animated},indent=2))
print('Workshop: 12 reviewed props and one 320x180 room composition')
