"""Selected-source native pixel kits; no raw pack directories are redistributed.

Compositions are 320x180 art previews. Hazard bounds and animation frames are
authoring metadata, never changes to the existing minigames' collision rules.
"""
from pathlib import Path
import hashlib
import json
import re
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
DOWNLOADS = Path(r'C:\Users\LalithReddy.b\Downloads')
MODERN = DOWNLOADS / 'moderninteriors-win'
SINGLES = MODERN / '1_Interiors/16x16/Theme_Sorter_Shadowless_Singles'
OUT = ROOT / 'assets/shared_foundation/town_library'
OUT.mkdir(parents=True, exist_ok=True)
FLOOR = MODERN / '1_Interiors/16x16/Room_Builder_subfiles/Room_Builder_Floors_16x16.png'
CAVE = DOWNLOADS / 'Fungus Cave [16x16]/Tilesets/Tileset - Complete 16x16.png'
ANIM = MODERN / '3_Animated_objects/16x16/spritesheets'
floors = Image.open(FLOOR).convert('RGBA')
cave = Image.open(CAVE).convert('RGBA')
workshop = json.loads((ROOT / 'assets/shared_foundation/workshop/manifest.json').read_text())
catalog = []
INK = '#303548'
PAPER = '#f4dfb3'
GOLD = '#d4ab62'
TEAL = '#72a7a0'
CORAL = '#d68073'


def export(image, path, kind, source, **meta):
    target = OUT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target)
    entry = dict(id=path.removesuffix('.png').replace('/', '_'),
                 file=target.relative_to(ROOT).as_posix(), kind=kind,
                 size=list(image.size), source=source,
                 status='exported_for_review', **meta)
    catalog.append(entry)
    return entry


def source_prop(theme, number):
    folder = next(p for p in SINGLES.iterdir() if p.name.startswith(theme))
    return next(p for p in folder.glob('*.png')
                if int(re.search(r'_(\d+)$', p.stem)[1]) == number)


zones = [
    ('sky_foundry', 'Sky Foundry', 192, 32, '#8eacac', '14_Basement',
     [1, 64, 65, 85, 87, 100, 163, 168, 171, 194, 195, 235]),
    ('neon_workshop', 'Neon Workshop', 0, 160, '#789c9a', '14_Basement',
     [76, 80, 85, 88, 103, 163, 167, 171, 196, 218, 219, 235]),
    ('reactor_works', 'Reactor Works', 192, 224, '#738b91', '14_Basement',
     [163, 164, 165, 166, 168, 170, 171, 172, 176, 194, 195, 238]),
    ('fungus_underworks', 'Fungus Underworks', 0, 0, '#877a64', 'cave', []),
    ('training_yard', 'Training Yard', 0, 352, '#8da295', '8_Gym',
     [64, 66, 67, 73, 75, 87, 91, 92, 93, 102, 118, 166]),
    ('chaos_carnival', 'Chaos Carnival', 128, 32, '#be9798', '10_Birthday',
     [1, 2, 9, 10, 11, 16, 17, 19, 21, 23, 28, 29]),
]


def place(room, props, name, x, y):
    """Place cropped source artwork at native scale, top-left anchored."""
    im = props[name]
    room.alpha_composite(im, (x, y))


def window(d, x, y, w=40, h=28, night=False):
    d.rectangle((x, y, x+w, y+h), fill=INK)
    d.rectangle((x+2, y+2, x+w-2, y+h-2), fill='#768d9f' if night else '#cae1d1')
    d.rectangle((x+4, y+4, x+w-4, y+8), fill='#e5e8cd')
    d.line((x+w//2, y+2, x+w//2, y+h-2), fill=INK, width=2)
    d.rectangle((x-2, y+h, x+w+2, y+h+3), fill=GOLD)


def hazard_frame(zone, kind):
    """Original 32px modular hazard silhouettes with consistent dark outlines."""
    im = Image.new('RGBA', (32, 32))
    d = ImageDraw.Draw(im)
    if kind == 0:  # District-specific floor hazard.
        d.rectangle((2, 23, 29, 29), fill=INK)
        if zone == 'fungus_underworks':
            d.rectangle((4, 21, 27, 25), fill='#879f69')
            for x in (7, 15, 23):
                d.rectangle((x, 16, x+2, 23), fill='#c8d998')
                d.rectangle((x-2, 14, x+4, 17), fill='#a27b9b')
        elif zone == 'chaos_carnival':
            for x in (5, 13, 21):
                d.polygon([(x, 22), (x+3, 12), (x+7, 22)], fill=CORAL, outline=INK)
                d.point((x+3, 16), fill=PAPER)
        else:
            d.rectangle((4, 24, 27, 26), fill=GOLD)
            for x in range(5, 27, 6): d.line((x, 26, x+3, 24), fill=INK, width=2)
            for x in (8, 15, 22): d.rectangle((x, 16, x+2, 21), fill='#a4d0b5')
    elif kind == 1:  # Barrier.
        d.rectangle((4, 11, 27, 21), fill=INK)
        d.rectangle((6, 13, 25, 19), fill=CORAL if zone == 'chaos_carnival' else GOLD)
        for x in (7, 15, 23): d.line((x, 19, min(x+4, 26), 13), fill=INK, width=2)
        d.rectangle((6, 22, 8, 29), fill=INK); d.rectangle((23, 22, 25, 29), fill=INK)
    elif kind == 2:  # Drop/charge/rolling object, distinguished by district.
        if zone in ('sky_foundry', 'reactor_works', 'neon_workshop'):
            d.rectangle((8, 5, 24, 24), fill=INK)
            d.rectangle((10, 7, 22, 22), fill='#7e929b')
            d.rectangle((12, 9, 20, 12), fill=PAPER)
            d.polygon([(18, 12), (13, 18), (17, 18), (14, 23), (21, 15), (17, 15)], fill=GOLD)
        else:
            d.ellipse((5, 6, 27, 28), fill=INK)
            d.ellipse((7, 8, 25, 26), fill='#89768e' if zone == 'fungus_underworks' else CORAL)
            d.rectangle((10, 11, 14, 14), fill=PAPER)
            d.line((17, 10, 21, 24), fill=INK)
    else:  # Warning post is readable with motion disabled.
        d.rectangle((14, 15, 17, 29), fill=INK)
        d.polygon([(16, 2), (29, 22), (2, 22)], fill=INK)
        d.polygon([(16, 5), (25, 20), (7, 20)], fill=GOLD)
        d.rectangle((15, 10, 17, 14), fill=INK); d.point((16, 17), fill=INK)
    return im


def tiles_for(zone, fx, fy):
    source = cave if zone == 'fungus_underworks' else floors
    file = CAVE if zone == 'fungus_underworks' else FLOOR
    # Chosen cave masonry/rock/ground cells; props and empty padding are excluded.
    if zone == 'fungus_underworks':
        candidates = [(x, y) for y in range(16, 96, 16) for x in range(16, 80, 16)]
        candidates += [(x, y) for y in range(0, 112, 16) for x in (96, 112)]
        candidates += [(x, y) for y in range(128, 176, 16) for x in (0, 16)]
        candidates += [(x, y) for y in range(208, 240, 16) for x in (0, 16, 32, 48)]
        candidates += [(x, y) for y in range(272, 336, 16) for x in (0, 16, 32, 48, 64, 80)]
    else:
        # Wrap the selected material strip inside actual 240x640 source bounds.
        candidates = [(fx+x*16, 32+(fy-32+y*16)%576) for y in range(36) for x in range(3)]
    chosen = []
    for x, y in candidates:
        tile = source.crop((x, y, x+16, y+16))
        if tile.getbbox() is None: continue
        if tile.getchannel('A').histogram()[255] < 128: continue
        chosen.append((x, y, tile))
        if len(chosen) == 48: break
    assert len(chosen) == 48, (zone, len(chosen))
    atlas = Image.new('RGBA', (128, 96)); entries = []
    for i, (x, y, tile) in enumerate(chosen):
        rect = [i%8*16, i//8*16, 16, 16]
        atlas.alpha_composite(tile, tuple(rect[:2]))
        entries.append(dict(id=f'tile_{i:02}', rect=rect, source=str(file), source_rect=[x, y, 16, 16]))
    return atlas, entries, file


def prop_set(zone, theme, numbers):
    selected = [(p['id'], Path(p['source']), None) for p in workshop['props']]
    if zone == 'fungus_underworks':
        # Coherent cave outfitting: tools, ladders, beds, storage and mushrooms.
        rects = [('cave_pickaxe', (80,112,16,32)), ('cave_shovel',(64,112,16,32)),
                 ('cave_ladder',(48,192,16,48)), ('cave_stone',(96,288,16,16)),
                 ('cave_bed',(0,432,32,32)), ('cave_locker',(112,416,16,32)),
                 ('cave_mushroom_left',(0,400,32,16)), ('cave_mushroom_right',(32,400,32,16)),
                 ('cave_supplies',(32,480,16,16)), ('cave_barrel',(96,288,16,16)),
                 ('cave_crate',(32,480,16,16)), ('cave_monitor',(80,704,16,16))]
        selected += [(name, CAVE, rect) for name, rect in rects]
    else:
        selected += [(f'{theme.lower()}_{n}', source_prop(theme, n), None) for n in numbers]
    atlas = Image.new('RGBA', (384,256)); entries = []; images = {}
    for i, (name, path, source_rect) in enumerate(selected):
        raw = Image.open(path).convert('RGBA')
        if source_rect:
            sx, sy, sw, sh = source_rect
            im = raw.crop((sx, sy, sx+sw, sy+sh)); crop = [sx, sy, sw, sh]
        else:
            box = raw.getbbox()
            assert box, path
            im = raw.crop(box); crop = [box[0], box[1], box[2]-box[0], box[3]-box[1]]
        assert im.getbbox(), name
        assert im.width <= 64 and im.height <= 64, (name, im.size)
        px, py = i%6*64, i//6*64
        atlas.alpha_composite(im, (px, py)); images[name] = im
        entries.append(dict(id=name, rect=[px, py, *im.size], source=str(path), source_rect=crop))
    return atlas, entries, images


def interior(zone, wall, fx, fy, props):
    room = Image.new('RGBA', (320,180), INK)
    d = ImageDraw.Draw(room)
    d.rectangle((8,8,311,57), fill=wall)
    for x in range(16,312,32):
        d.line((x,9,x,55), fill='#ffffff18')
    d.rectangle((8,56,311,61), fill=GOLD)
    floor = cave.crop((96,64,112,80)) if zone == 'fungus_underworks' else floors.crop((fx+16,fy+16,fx+32,fy+32))
    assert floor.getbbox()
    for y in range(62,176,16):
        for x in range(8,312,16): room.alpha_composite(floor, (x,y))
    d = ImageDraw.Draw(room)
    # Readable entrance and a clear central walking lane through every room.
    d.rectangle((139,160,180,179), fill='#797669')
    d.line((142,162,177,162), fill=PAPER)
    window(d,20,19,43,28,zone=='reactor_works'); window(d,256,19,43,28)
    d.rectangle((111,19,209,39), fill=INK); d.rectangle((114,22,206,36), fill=GOLD)
    # Purposeful stations line the perimeter; objects sit on floors or benches.
    if zone == 'neon_workshop':
        for x in (22,54): place(room,props,'workbench',x,54)
        place(room,props,'monitor',28,44); place(room,props,'desk_lamp',66,44)
        place(room,props,'equipment_rack',264,61)
        place(room,props,'14_basement_235',267,105)
        place(room,props,'vending_machine',22,118)
        d.rectangle((103,91,214,143), fill='#578d89')
        d.rectangle((107,95,210,139), outline='#b6c8a3')
        place(room,props,'14_basement_196',88,49)
    elif zone == 'sky_foundry':
        for x in (24,64): place(room,props,'workbench',x,54)
        place(room,props,'monitor',28,44); place(room,props,'ladder',272,100)
        place(room,props,'equipment_rack',266,54)
        place(room,props,'14_basement_1',23,125)
        d.rectangle((113,72,220,138),fill='#526e7c',outline=GOLD,width=2)
        for x in range(120,218,16): d.line((x,77,x,133),fill='#78959a')
        # Original roof turbine housing is visually separate from active play space.
        d.rectangle((140,45,190,67),fill=INK)
        for x in (150,173):
            d.ellipse((x-9,42,x+9,60),fill='#657a85',outline=PAPER)
            d.line((x-6,45,x+6,57),fill=PAPER); d.line((x-6,57,x+6,45),fill=PAPER)
    elif zone == 'reactor_works':
        place(room,props,'equipment_rack',24,57); place(room,props,'equipment_rack',264,57)
        place(room,props,'14_basement_195',24,114)
        place(room,props,'14_basement_238',266,111)
        # Reactor is a wall-backed control object. Central lower lane stays clear.
        d.rectangle((119,47,201,111),fill=INK,outline=GOLD,width=2)
        for x in (130,153,176):
            d.rectangle((x,55,x+13,98),fill='#5f9d91',outline=PAPER)
            d.rectangle((x+4,60,x+7,93),fill='#c5dc9d')
        d.rectangle((128,103,193,107),fill='#d68073')
        for x in (82,229):
            d.line((x,57,x,91),fill=INK,width=6);d.line((x,91,119 if x<160 else 201,91),fill=INK,width=6)
            d.line((x,57,x,91),fill='#a3bdab',width=2)
    elif zone == 'fungus_underworks':
        # Masonry shelter built into a cave, rather than Halloween props in a room.
        for x in range(8,312,16): room.alpha_composite(cave.crop((16,16,32,48)),(x,8))
        d = ImageDraw.Draw(room)
        d.rectangle((111,19,209,39),fill=INK);d.rectangle((114,22,206,36),fill=GOLD)
        for x in (21,53): place(room,props,'cave_bed',x,69)
        place(room,props,'cave_shovel',92,40);place(room,props,'cave_pickaxe',111,40)
        place(room,props,'cave_ladder',267,61)
        place(room,props,'cave_locker',286,74)
        place(room,props,'cave_crate',22,135); place(room,props,'cave_supplies',40,137)
        place(room,props,'cave_mushroom_left',65,148);place(room,props,'cave_mushroom_right',249,141)
        for x,y in [(42,111),(277,129),(235,155)]:
            d.point((x,y),fill='#bacb95');d.point((x+5,y-3),fill='#a17aab')
    elif zone == 'training_yard':
        d.rectangle((90,77,232,151),fill='#558c8a')
        d.rectangle((96,83,226,145),outline=PAPER,width=2)
        d.line((160,85,160,143),fill=PAPER)
        d.ellipse((144,98,176,130),outline=PAPER)
        for x,n in [(27,64),(65,66),(263,67)]: place(room,props,f'8_gym_{n}',x,55)
        place(room,props,'8_gym_91',23,111);place(room,props,'8_gym_92',266,111)
        place(room,props,'8_gym_87',108,54);place(room,props,'8_gym_102',286,149)
    else:
        for x in range(14,303,16):
            d.polygon([(x,12),(x+12,12),(x+6,22)],fill=[CORAL,GOLD,TEAL][x//16%3])
        for x in (25,60):
            d.rectangle((x,65,x+27,109),fill=INK)
            d.rectangle((x+2,67,x+25,79),fill=CORAL)
            d.rectangle((x+5,82,x+22,96),fill='#81a29b')
            d.rectangle((x+10,101,x+17,103),fill=GOLD)
        d.rectangle((237,73,298,94),fill=GOLD,outline=INK,width=2)
        d.rectangle((240,94,245,117),fill=INK);d.rectangle((290,94,295,117),fill=INK)
        for x,n in [(244,9),(266,10),(286,11)]: place(room,props,f'10_birthday_{n}',x,60)
        for x,n in [(18,19),(280,23)]: place(room,props,f'10_birthday_{n}',x,25)
        d.rectangle((109,98,210,143),fill='#7e7e9a')
        for x in range(115,210,16): d.rectangle((x,104,x+6,110),fill=GOLD)
    return room


def exterior(zone, wall, index, props):
    """Original town facade with selected licensed native props on the sidewalk."""
    im = Image.new('RGBA',(320,180),'#8fb8b8')
    d = ImageDraw.Draw(im)
    # Three stepped skyline layers; all coordinates are integer native pixels.
    for x,h in [(0,28),(31,41),(74,34),(244,35),(281,49)]:
        d.rectangle((x,78-h,x+36,123),fill='#789fa8')
        for wx in range(x+6,x+32,10):
            for wy in range(65-h,115,14): d.rectangle((wx,wy,wx+3,wy+5),fill='#a4c1b9')
    d.rectangle((0,127,319,155),fill='#a5ae92')
    d.rectangle((0,156,319,179),fill='#596778')
    d.line((0,158,319,158),fill=INK,width=2)
    for x in range(0,320,32): d.rectangle((x+7,172,x+23,173),fill=GOLD)
    bx,by,bw = 65,39,190
    d.rectangle((bx,by,bx+bw,151),fill=INK)
    d.rectangle((bx+3,by+3,bx+bw-3,148),fill=wall)
    d.rectangle((bx-4,by-4,bx+bw+4,by+4),fill=INK)
    d.rectangle((bx-2,by-3,bx+bw+2,by),fill=GOLD)
    for y in (77,116): d.rectangle((bx+3,y,bx+bw-3,y+2),fill='#667d83')
    for x in (77,211):
        window(d,x,51,30,22)
        window(d,x,91,30,22,zone=='reactor_works')
    d.rectangle((129,100,191,151),fill=INK)
    d.rectangle((133,104,187,147),fill='#596e77')
    d.rectangle((137,108,183,123),fill='#c2d9bd')
    d.line((160,105,160,147),fill=INK,width=2)
    d.rectangle((154,132,156,136),fill=GOLD);d.rectangle((165,132,167,136),fill=GOLD)
    d.rectangle((117,80,204,95),fill=INK);d.rectangle((120,83,201,92),fill=GOLD)
    d.rectangle((121,150,199,154),fill=PAPER)
    d.rectangle((117,154,203,157),fill='#b7a17b')
    # District silhouette accents are purpose-built original pixel pieces.
    if zone == 'sky_foundry':
        for x in (102,218):
            d.rectangle((x-3,19,x+3,37),fill=INK)
            d.ellipse((x-11,7,x+11,29),fill='#5e7e8c',outline=INK,width=2)
            for dx,dy in [(0,-8),(-8,0),(0,8),(8,0)]:
                d.line((x,18,x+dx,18+dy),fill=PAPER,width=3)
        d.line((0,35,319,35),fill=INK)
        place(im,props,'14_basement_1',23,123)
    elif zone == 'neon_workshop':
        d.rectangle((110,18,132,35),fill=INK);d.rectangle((113,21,129,32),fill=TEAL)
        d.rectangle((115,24,127,26),fill=PAPER)
        place(im,props,'workbench',14,106);place(im,props,'14_basement_235',271,105)
        place(im,props,'14_basement_196',263,65)
    elif zone == 'reactor_works':
        for x in (111,202):
            d.rectangle((x,10,x+13,36),fill=INK)
            d.rectangle((x+3,12,x+10,33),fill='#9baaa1')
            d.rectangle((x-2,8,x+15,12),fill=GOLD)
        d.line((47,50,47,135),fill=INK,width=6);d.line((47,50,63,50),fill=INK,width=6)
        d.line((274,58,274,138),fill=INK,width=6)
        place(im,props,'equipment_rack',278,112)
    elif zone == 'fungus_underworks':
        d.rectangle((0,0,319,126),fill='#454656')
        d.polygon([(0,19),(36,32),(61,15),(99,29),(130,11),(170,27),(206,8),(244,30),(281,14),(319,31),(319,0),(0,0)],fill='#696270')
        # Mine shelter facade sits inside the cave rather than beneath an open sky.
        d.rectangle((61,40,259,150),fill='#9b794e',outline=INK,width=3)
        for x in range(65,255,16):
            im.alpha_composite(cave.crop((16,32,32,48)),(x,43))
        d.rectangle((126,83,194,151),fill=INK)
        d.rectangle((132,90,188,151),fill='#4e5552')
        for x in (133,183):d.rectangle((x,91,x+4,149),fill='#bc9257')
        d.rectangle((122,78,198,86),fill=GOLD)
        window(d,77,90,31,28);window(d,211,90,31,28)
        for x in (17,270): place(im,props,'cave_mushroom_left',x,133)
        place(im,props,'cave_crate',23,116);place(im,props,'cave_ladder',288,80)
        d.line((0,169,319,169),fill='#baa16d',width=2)
        for x in range(0,320,16): d.rectangle((x,162,x+3,178),fill='#8e7150')
    elif zone == 'training_yard':
        d.rectangle((115,14,205,32),fill=INK)
        d.rectangle((118,17,202,29),fill=TEAL)
        for x in (32,280):
            d.rectangle((x,111,x+2,150),fill=INK)
            d.rectangle((x-7,107,x+9,120),fill=PAPER,outline=INK)
            d.line((x-3,120,x+5,120),fill=CORAL,width=2)
        d.rectangle((267,140,307,153),fill='#6d9c91',outline=INK)
        place(im,props,'8_gym_73',279,132)
    else:
        for x in range(69,251,14):
            d.polygon([(x,36),(x+12,36),(x+6,47)],fill=[CORAL,GOLD,TEAL][x//14%3])
        for x in range(69,251,20):d.rectangle((x,97,x+9,101),fill=CORAL)
        d.rectangle((112,13,208,32),fill=INK);d.rectangle((115,16,205,29),fill=CORAL)
        for x in range(119,204,10):d.rectangle((x,19,x+2,21),fill=GOLD)
        for x,n in [(20,19),(280,23)]:place(im,props,f'10_birthday_{n}',x,100)
    # Characters are assembled review overlays, modular source assets stay separate.
    cast = Image.open(ROOT/'assets/shared_foundation/town_cast/cast_idles.png').convert('RGBA')
    im.alpha_composite(cast.crop((index*32,0,index*32+32,32)),(144,126))
    return im


animation_specs = {
    'control_screens': ('animated_control_room_screens.png',64,48,11,7),
    'server_lights': ('animated_control_room_server.png',16,48,3,5),
    'punching_bag': ('animated_punching_bag_left.png',32,32,6,8),
    'bubbling_cauldron': ('animated_cauldron.png',32,32,12,7),
    'warm_chimney': ('animated_chimney.png',32,48,3,6),
}
for name,(filename,w,h,count,fps) in animation_specs.items():
    image = Image.open(ANIM/filename).convert('RGBA')
    assert image.size == (w*count,h), (name,image.size)
    frames = [dict(index=i,rect=[i*w,0,w,h],source=str(ANIM/filename),source_rect=[i*w,0,w,h]) for i in range(count)]
    export(image,f'animated_objects/{name}.png','animated_object','moderninteriors_full_windows',
           source_file=str(ANIM/filename),cell=[w,h],frames=frames,entries=frames,fps=fps,
           loop=True,reduced_motion_frame=0,assignment_note='One shared export; district references do not count as unique objects.')

assignments = {
    'sky_foundry':['control_screens','server_lights','warm_chimney','punching_bag'],
    'neon_workshop':['control_screens','server_lights','warm_chimney','punching_bag'],
    'reactor_works':['control_screens','server_lights','warm_chimney','bubbling_cauldron'],
    'fungus_underworks':['bubbling_cauldron','warm_chimney','server_lights','control_screens'],
    'training_yard':['punching_bag','control_screens','server_lights','warm_chimney'],
    'chaos_carnival':['bubbling_cauldron','warm_chimney','control_screens','server_lights'],
}

zone_manifests=[]
for index,(zone,title,fx,fy,wall,theme,numbers) in enumerate(zones):
    atlas,entries,props = prop_set(zone,theme,numbers)
    export(atlas,f'{zone}/props.png','props','moderninteriors_full_windows'+('+fungus_cave' if zone=='fungus_underworks' else ''),district=title,entries=entries)
    tiles,tile_records,source_file = tiles_for(zone,fx,fy)
    export(tiles,f'{zone}/tiles.png','tiles','fungus_cave' if zone=='fungus_underworks' else 'moderninteriors_full_windows',district=title,source_file=str(source_file),cell=[16,16],tiles=tile_records,entries=tile_records)
    hazards = Image.new('RGBA',(128,32)); hazard_records=[]
    labels = ['spore_vent','mine_barrier','loose_rock','cave_warning'] if zone=='fungus_underworks' else ['floor_vent','striped_barrier','loose_charge' if zone=='reactor_works' else 'rolling_obstacle','warning_post']
    for i,label in enumerate(labels):
        hazards.alpha_composite(hazard_frame(zone,i),(i*32,0))
        hazard_records.append(dict(id=label,rect=[i*32,0,32,32],source='project_original_pixel_art',source_rect=[i*32,0,32,32],suggested_visual_bounds=[3,5,26,25],gameplay_integration='art_only_no_collision_changes'))
    export(hazards,f'{zone}/hazards.png','hazards','project_original_pixel_art',district=title,cell=[32,32],entries=hazard_records)
    inside=interior(zone,wall,fx,fy,props)
    outside=exterior(zone,wall,index,props)
    for label,scene in [('interior',inside),('exterior',outside)]:
        export(scene,f'{zone}/{label}.png','scene','original_composition+moderninteriors_full_windows'+('+fungus_cave' if zone=='fungus_underworks' else ''),district=title,native_scale='320x180',layers='Flattened art review. Native props, tiles and hazards are exported separately.',source_asset_ids=[f'{zone}_tiles',f'{zone}_props'],clear_play_area=[104,118,112,38])
    manifest=dict(id=zone,name=title,tiles=48,prop_assignments=24,shared_workshop_prop_assignments=12,
                  thematic_prop_assignments=12,hazard_assignments=4,animated_object_assignments=assignments[zone],
                  unique_animated_objects_in_library=5,interior=f'{zone}/interior.png',exterior=f'{zone}/exterior.png',
                  status='native_art_and_modular_assets_exported_for_review',
                  remaining=['Review and adaptation inside representative games; exported preview scenes do not change minigame mechanics.'])
    zone_manifests.append(manifest)
    (OUT/zone/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')

# Static supporting battlers; no invented animation is claimed.
battlers=DOWNLOADS/'Fantasy Battlers - Complete/Fantasy Battlers - Complete/Original size'
for i in range(1,13):
    source=battlers/f'{i:02}.png'; im=Image.open(source).convert('RGBA'); box=im.getbbox()
    assert box,source
    export(im.crop(box),f'enemies/battler_{i:02}.png','enemy','fantasy_battlers_complete',source_file=str(source),source_rect=[box[0],box[1],box[2]-box[0],box[3]-box[1]],animation='static',integration='review only')

from build_town_cast import SOURCE,CAST
for i in range(12):
    _,_,_,eyes,outfit,hair,_=CAST[i%6]
    paths=[f'Bodies/16x16/Body_{(i+i//6)%6+1:02}.png',f'Eyes/16x16/Eyes_{eyes:02}.png',f'Outfits/16x16/Outfit_{outfit}.png',f'Hairstyles/16x16/Hairstyle_{hair}.png']
    sheet=Image.new('RGBA',(384,96))
    for path in paths:
        im=Image.open(SOURCE/path).convert('RGBA')
        sheet.alpha_composite(im.crop((0,0,384,96)))
    export(sheet,f'npcs/resident_{i+1:02}.png','npc','moderninteriors_full_windows',source_layers=paths,cell=[16,32],animation_rows={'idle_pose':0,'idle_cycle':1,'walk':2},identity='supporting resident variant')

# Native and integer-scaled reviews. These are exported game art, not screenshots
# claiming successful runtime/gameplay integration.
contact=Image.new('RGBA',(656,610),INK);draw=ImageDraw.Draw(contact)
for i,(zone,title,*_) in enumerate(zones):
    x=i%2*328;y=i//2*202
    draw.text((x+8,y+2),title.upper(),fill=PAPER)
    contact.alpha_composite(Image.open(OUT/zone/'exterior.png').convert('RGBA'),(x+4,y+18))
export(contact,'review/district_exteriors.png','contact_sheet','assembled_export_review',native_scale=True)
contact=Image.new('RGBA',(656,610),INK);draw=ImageDraw.Draw(contact)
for i,(zone,title,*_) in enumerate(zones):
    x=i%2*328;y=i//2*202
    draw.text((x+8,y+2),title.upper(),fill=PAPER)
    contact.alpha_composite(Image.open(OUT/zone/'interior.png').convert('RGBA'),(x+4,y+18))
export(contact,'review/district_interiors.png','contact_sheet','assembled_export_review',native_scale=True)
contact=Image.new('RGBA',(768,240),INK);draw=ImageDraw.Draw(contact)
for i,(zone,title,*_) in enumerate(zones):
    x=i%3*256;y=i//3*120
    draw.text((x+4,y+3),title.upper(),fill=PAPER)
    contact.alpha_composite(Image.open(OUT/zone/'hazards.png').resize((256,64),Image.Resampling.NEAREST),(x,y+22))
export(contact,'review/district_hazards.png','contact_sheet','assembled_export_review',scale='2x nearest')

manifest=dict(version=2,credit='Source artwork: LimeZu - https://limezu.itch.io/',districts=zone_manifests,assets=catalog,
              counts=dict(districts=6,interior_compositions=6,exterior_compositions=6,tile_assignments=288,prop_assignments=144,hazard_assignments=24,shared_animated_object_exports=5,animated_object_assignments=24,supporting_resident_variants=12,static_battlers=12),
              counting_note='Assignments are not unique source counts. Workshop props and five animation exports are intentionally shared. Original hazard variants share base silhouettes.',
              release_note='Selected game-art review library. Full source-pack directories are not bundled; no standalone source-pack distribution.')
(OUT/'catalog.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print(f'Town library: {len(catalog)} exports; 12 compositions, 24 hazard assignments, 5 shared animated objects, 12 NPC variants and 12 static battlers.')
