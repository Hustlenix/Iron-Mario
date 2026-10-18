"""Original integer-grid artwork for Dino Dash. Exported through Aseprite."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,hashlib
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'onlyeducation/arcade/art'
SRC=ROOT/'source_art/dino_dash'
OUT.mkdir(parents=True,exist_ok=True);SRC.mkdir(parents=True,exist_ok=True)
ink='#152536';teal='#61bda5';light='#9ad8af';gold='#ffc56a';coral='#db6b4d'
def dino(frame):
    im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im)
    if frame==3:
        d.polygon([(1,22),(9,25),(12,23),(22,23),(22,20),(31,20),(31,28),(24,28),(21,30),(10,30),(6,27)],fill=ink)
        d.polygon([(3,24),(10,27),(13,25),(24,25),(24,22),(29,22),(29,26),(23,26),(20,28),(11,28),(7,26)],fill=teal)
        d.rectangle((12,28,15,31),fill=ink);d.rectangle((23,28,26,31),fill=ink)
        d.rectangle((27,23,28,24),fill=gold);d.rectangle((20,25,22,28),fill=coral)
    else:
        d.polygon([(1,17),(5,19),(10,20),(12,15),(17,14),(17,6),(20,3),(30,3),(31,6),(31,15),(24,17),(22,24),(19,28),(11,28),(8,25),(4,24),(2,21)],fill=ink)
        d.polygon([(3,19),(9,22),(12,21),(14,17),(19,16),(19,7),(21,5),(29,5),(29,13),(23,14),(21,22),(18,26),(12,26),(9,23),(5,22)],fill=teal)
        d.rectangle((20,6,28,7),fill=light);d.rectangle((26,8,27,9),fill=gold);d.rectangle((25,12,30,13),fill=ink)
        d.polygon([(12,20),(16,19),(18,22),(17,26),(12,26)],fill=gold)
        d.rectangle((17,16,22,18),fill=coral);d.rectangle((20,18,22,21),fill=coral)
        d.rectangle((20,21,25,23),fill=ink);d.rectangle((21,21,25,22),fill=teal)
        for x,y in [(10,17),(12,13),(15,11)]:d.rectangle((x,y,x+2,y+2),fill=coral)
        legs=[[(11,26,14,31),(19,27,23,29)],[(11,27,15,29),(18,26,21,31)],[(11,26,16,28),(18,26,23,28)],[(11,26,16,28),(18,26,23,28)],[(11,26,16,31),(18,26,23,31)]][frame]
        for box in legs:d.rectangle(box,fill=ink)
        if frame==4:
            d.rectangle((25,8,28,9),fill=coral);d.rectangle((26,7,27,10),fill=coral)
    return im
strip=Image.new('RGBA',(160,32))
for i in range(5):strip.paste(dino(i),(i*32,0))
strip.save(SRC/'runner_strip.png')
card=Image.new('RGBA',(128,80),'#fff0cf');d=ImageDraw.Draw(card)
d.rectangle((98,12,114,28),fill=gold);d.rectangle((94,16,118,24),fill=gold)
for x in [0,35,78]:
    d.polygon([(x-10,68),(x+14,37),(x+40,68)],fill='#c7cdaa')
d.rectangle((0,68,128,70),fill=ink);d.rectangle((0,71,128,79),fill='#e5c995')
d.rectangle((101,48,109,68),fill=ink);d.rectangle((96,55,114,60),fill=ink);d.rectangle((103,50,107,68),fill=coral)
card.alpha_composite(dino(0).resize((64,64),Image.Resampling.NEAREST),(16,4))
card.save(OUT/'dino-dash-card.png')
manifest={'version':1,'title':'OnlyEducation Dino Dash original artwork','assets':[{'id':'dino_runner','file':'dino-runner.png','size':[160,32],'frame_size':[32,32],'frames':5,'fps':10,'reduced_motion_frame':0,'license':'project_original','source':'Original Moss Rex silhouette; integer-grid artwork, Aseprite timeline export.','status':'ready'}]}
(OUT/'dino-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
(SRC/'README.md').write_text('# Dino Dash artwork\n\nOriginal OnlyEducation artwork. Teal Moss Rex, coral neck band, gold eye and belly. No third-party sprites.\n\nrunner.aseprite has five tagged frames: run-left, run-right, jump, duck and bump. tools/build_dino_art.py builds the integer-grid source; tools/export_dino_art.lua creates the editable Aseprite timeline. The public PNG is exported from that timeline.\n',encoding='utf-8')
print('DINO_ART: original five-frame source and cover prepared')
