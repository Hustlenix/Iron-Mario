"""Export Godot SpriteFrames with explicit directional frame regions."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/shared_foundation/town_cast'
for recipe in json.loads((OUT/'recipes.json').read_text()):
    name=recipe['id']; meta=json.loads((OUT/f'{name}_motion.json').read_text())
    ase=json.loads((OUT/f'{name}_aseprite.json').read_text())
    tags={tag['name']:tag for tag in ase['meta']['frameTags']}
    chunks=[]; animations=[]; n=0
    for action in ['idle','idle_animated','walk','run','hit','hurt']:
        a=meta[action]
        for direction,facing in enumerate(meta['directions']):
            frames=[]
            for i in range(a['frames_per_direction']):
                tag=tags[f"{'walk' if action=='run' else action}_{facing}"]
                source=ase['frames'][tag['from']+i]['frame']
                n+=1; x=source['x']; y=source['y']
                chunks.append(f'[sub_resource type="AtlasTexture" id="Frame_{n}"]\natlas = ExtResource("1")\nregion = Rect2({x}, {y}, 16, 32)\n')
                frames.append('{"duration": 1.0, "texture": SubResource("Frame_'+str(n)+'")}')
            loop='false' if action in ['hit','hurt'] else 'true'
            animations.append('{"frames": ['+','.join(frames)+'], "loop": '+loop+', "name": &"'+action+'_'+facing+'", "speed": '+str(float(a['fps']))+'}')
    text=f'[gd_resource type="SpriteFrames" load_steps={n+2} format=3]\n\n[ext_resource type="Texture2D" path="res://assets/shared_foundation/town_cast/{name}_aseprite.png" id="1"]\n\n'+'\n'.join(chunks)+'\n[resource]\nanimations = ['+',\n'.join(animations)+']\n'
    (OUT/f'{name}_frames.tres').write_text(text)
print('SPRITEFRAMES: six resources, 24 directional animations per character')
