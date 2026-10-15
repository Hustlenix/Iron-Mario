"""Build original, integer-grid Pixel Town feedback and UI sprites.

No downloaded art or pack pixels are used by this builder. Every primitive is
drawn at export resolution; enlargement in review sheets is nearest-neighbour.
"""
from pathlib import Path
import json
import math
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/shared_foundation/town_fx_ui"
P = {
    "ink": "#252c42", "shade": "#434961", "muted": "#747588",
    "paper": "#f4e6be", "light": "#fff3d2", "sand": "#cbaa80",
    "teal": "#527f83", "mint": "#8fc5ad", "cyan": "#a7d9ce",
    "coral": "#d57971", "red": "#ad535e", "gold": "#e8b95d",
    "ochre": "#ae793d", "violet": "#8c7caa", "purple": "#62587c",
}
FRAME = 32
FRAMES = 8


def canvas(w, h):
    return Image.new("RGBA", (w, h))


def rect(d, box, color, outline=None):
    d.rectangle(tuple(map(round, box)), fill=P.get(color, color), outline=P.get(outline, outline))


def line(d, pts, color, width=1):
    d.line([(round(x), round(y)) for x, y in pts], fill=P.get(color, color), width=width)


def poly(d, pts, color, outline=None):
    d.polygon([(round(x), round(y)) for x, y in pts], fill=P.get(color, color), outline=P.get(outline, outline))


def star(d, x, y, r, color="gold"):
    r = max(1, round(r))
    poly(d, [(x,y-r), (x+1,y-1), (x+r,y), (x+1,y+1),
             (x,y+r), (x-1,y+1), (x-r,y), (x-1,y-1)], color)


def puff(d, x, y, r, color, edge=None):
    # Stepped octagon deliberately preserves a visible pixel contour.
    r = max(1, round(r))
    a = max(1, r // 2)
    poly(d, [(x-a,y-r),(x+a,y-r),(x+r,y-a),(x+r,y+a),
             (x+a,y+r),(x-a,y+r),(x-r,y+a),(x-r,y-a)], color, edge)


def make_fx(kind, t):
    im = canvas(32,32)
    d = ImageDraw.Draw(im)
    if kind == "spark_weld":
        for j in range(7):
            angle = -2.8 + j * .46
            distance = 2 + t * (1.7 + (j % 3)*.2)
            x, y = 16 + math.cos(angle)*distance, 22 + math.sin(angle)*distance + t*t*.09
            length = max(1, 5-t//2)
            line(d, [(x,y),(x+math.cos(angle)*length,y+math.sin(angle)*length)], "ochre", 2)
            line(d, [(x,y),(x+math.cos(angle)*(length-1),y+math.sin(angle)*(length-1))], "gold")
            rect(d,(x,y,x,y),"light")
        if t < 3:
            star(d,16,22,5-t,"light")
    elif kind == "dust_step":
        for j in range(4):
            x = 15 + (j-1.5)*(2+t*1.05)
            y = 25 - (t*(.45+(j%2)*.4))
            r = (2+t*.35) * (1 if t < 5 else (8-t)/3)
            puff(d,x,y,r,"sand","ochre")
            if t < 6: line(d,[(x-1,y-r+1),(x+1,y-r+1)],"paper")
    elif kind == "smoke_vent":
        for j in range(3):
            phase = (t+j*3)%10
            x = 16 + math.sin(phase*.6+j)*3
            y = 27 - phase*2
            puff(d,x,y,2+phase*.3,"muted","shade")
            line(d,[(x-2,y-2),(x,y-3)],"sand")
    elif kind == "slime_splash":
        spread = 3+t*1.45
        rect(d,(16-spread,25,16+spread,26),"teal")
        line(d,[(16-spread+1,24),(16+spread-1,24)],"mint")
        for j in range(5):
            x = 16 + (j-2)*(1+t*.77)
            y = 22 - (6-abs(j-2))*math.sin((t+1)/9*math.pi)*1.9 + t*.5
            puff(d,x,y,1+(j%2),"mint","teal")
            rect(d,(x,y-1,x,y-1),"cyan")
    elif kind == "energy_arc":
        if t < 7:
            points = [(3,17),(8,10+(t%2)*5),(12,19),(17,8+(t%3)*2),(21,21),(27,13),(29,17)]
            line(d,points,"purple",4)
            line(d,points,"teal",2)
            line(d,points,"cyan")
            for x,y in (points[1], points[4]):
                star(d,x,y,2+(t%2),"light")
        else:
            star(d,8,15,2,"cyan"); star(d,25,16,2,"cyan")
    elif kind == "hit_flash":
        radius = [3,8,13,11,8,5,3,1][t]
        points=[]
        for j in range(16):
            angle=-math.pi/2+j*math.pi/8
            r=radius if j%2==0 else radius*.37
            points.append((16+math.cos(angle)*r,16+math.sin(angle)*r))
        poly(d,points,"coral","red")
        star(d,16,16,max(1,radius*.7),"gold")
        if t < 5: star(d,16,16,max(1,radius*.38),"light")
    elif kind == "portal_fold":
        radius = 7 + (2 if t in (2,3,4,5) else 1)
        poly(d,[(16,3),(27,12),(27,20),(16,29),(5,20),(5,12)],"purple","ink")
        poly(d,[(16,6),(24,13),(24,19),(16,26),(8,19),(8,13)],"violet")
        poly(d,[(16,9),(21,14),(21,18),(16,23),(11,18),(11,14)],"ink")
        angle = t*math.pi/4
        for j in range(4):
            a=angle+j*math.pi/2
            star(d,16+math.cos(a)*radius,16+math.sin(a)*radius,2,"cyan")
        line(d,[(12,11),(16,8),(20,11)],"paper")
    elif kind == "warning_ping":
        poly(d,[(16,5),(29,27),(3,27)],"ink")
        poly(d,[(16,8),(26,25),(6,25)],"gold" if t%4<2 else "coral")
        rect(d,(15,14,17,19),"ink")
        rect(d,(15,22,17,23),"ink")
        if t in (0,1,4,5):
            for x,flip in ((2,-1),(29,1)):
                line(d,[(x,10),(x+flip,7)],"paper")
    elif kind == "success_burst":
        radius=5+t*1.35
        for j in range(6):
            a=j*math.pi/3-math.pi/2
            x,y=16+math.cos(a)*radius,16+math.sin(a)*radius
            star(d,x,y,3 if t<5 else 1,"mint" if j%2 else "gold")
        if t<6:
            puff(d,16,16,6,"teal","ink")
            line(d,[(12,16),(15,19),(20,13)],"light",2)
    elif kind == "failure_fizzle":
        # Broken heart splits apart and becomes two descending groups of pixels.
        y=9+t//2
        left=[(7-t//3,y),(11-t//3,y),(15-t//3,y+4),(12-t//3,y+8),(10-t//3,y+12),(5-t//3,y+5),(5-t//3,y+2)]
        right=[(21+t//3,y),(25+t//3,y),(27+t//3,y+2),(27+t//3,y+5),(20+t//3,y+12),(17+t//3,y+8),(19+t//3,y+4)]
        poly(d,left,"red","ink"); poly(d,right,"coral","ink")
        line(d,[(8-t//3,y+2),(10-t//3,y+2)],"paper")
        line(d,[(22+t//3,y+2),(24+t//3,y+2)],"paper")
        if t>2:
            for x,delay in ((10,0),(21,2),(15,3)):
                rect(d,(x,21+(t+delay)%8,x+1,22+(t+delay)%8),"muted")
    elif kind == "landing_ring":
        radius=3+t*1.5
        points=[(16-radius,26),(16-radius*.7,23),(16+radius*.7,23),(16+radius,26),(16+radius*.7,28),(16-radius*.7,28),(16-radius,26)]
        line(d,points,"sand",2 if t<5 else 1)
        line(d,[(16-radius+2,25),(16-radius*.5,24)],"paper")
        if t<4:
            for side in (-1,1):
                line(d,[(16+side*(5+t),22),(16+side*(7+t),19+t)],"gold")
    elif kind == "charge_orbit":
        for j in range(3):
            a=(t/8+j/3)*math.tau
            x,y=16+math.cos(a)*11,16+math.sin(a)*8
            star(d,x,y,3,"gold")
            for k in (1,2,3):
                aa=a-k*.18
                rect(d,(16+math.cos(aa)*11,16+math.sin(aa)*8,
                        16+math.cos(aa)*11,16+math.sin(aa)*8),"ochre")
        puff(d,16,16,3+(t%2),"teal","ink")
        star(d,16,16,2,"cyan")
    return im


# An original 5x7 bitmap alphabet keeps labels integer-aligned and independent
# from system fonts. Only contact-sheet annotations use Pillow's review font.
FONT = {
"A":["01110","10001","10001","11111","10001","10001","10001"],
"B":["11110","10001","10001","11110","10001","10001","11110"],
"C":["01111","10000","10000","10000","10000","10000","01111"],
"D":["11110","10001","10001","10001","10001","10001","11110"],
"E":["11111","10000","10000","11110","10000","10000","11111"],
"F":["11111","10000","10000","11110","10000","10000","10000"],
"G":["01111","10000","10000","10111","10001","10001","01110"],
"H":["10001","10001","10001","11111","10001","10001","10001"],
"I":["11111","00100","00100","00100","00100","00100","11111"],
"J":["00111","00010","00010","00010","10010","10010","01100"],
"K":["10001","10010","10100","11000","10100","10010","10001"],
"L":["10000","10000","10000","10000","10000","10000","11111"],
"M":["10001","11011","10101","10101","10001","10001","10001"],
"N":["10001","11001","10101","10011","10001","10001","10001"],
"O":["01110","10001","10001","10001","10001","10001","01110"],
"P":["11110","10001","10001","11110","10000","10000","10000"],
"Q":["01110","10001","10001","10001","10101","10010","01101"],
"R":["11110","10001","10001","11110","10100","10010","10001"],
"S":["01111","10000","10000","01110","00001","00001","11110"],
"T":["11111","00100","00100","00100","00100","00100","00100"],
"U":["10001","10001","10001","10001","10001","10001","01110"],
"V":["10001","10001","10001","10001","10001","01010","00100"],
"W":["10001","10001","10001","10101","10101","10101","01010"],
"X":["10001","10001","01010","00100","01010","10001","10001"],
"Y":["10001","10001","01010","00100","00100","00100","00100"],
"Z":["11111","00001","00010","00100","01000","10000","11111"],
"0":["01110","10001","10011","10101","11001","10001","01110"],
"1":["00100","01100","00100","00100","00100","00100","01110"],
"2":["01110","10001","00001","00010","00100","01000","11111"],
"3":["11110","00001","00001","01110","00001","00001","11110"],
"4":["00010","00110","01010","10010","11111","00010","00010"],
"5":["11111","10000","10000","11110","00001","00001","11110"],
"6":["01110","10000","10000","11110","10001","10001","01110"],
"7":["11111","00001","00010","00100","01000","01000","01000"],
"8":["01110","10001","10001","01110","10001","10001","01110"],
"9":["01110","10001","10001","01111","00001","00001","01110"],
"!":["00100","00100","00100","00100","00100","00000","00100"],
"?":["01110","10001","00001","00010","00100","00000","00100"],
"-":["00000","00000","00000","11111","00000","00000","00000"],
".":["00000","00000","00000","00000","00000","00100","00100"],
" ":["00000"]*7,
}


def label(d, text, x, y, color="ink", scale=1):
    for char in text.upper():
        for row,bits in enumerate(FONT.get(char,FONT["?"])):
            for col,bit in enumerate(bits):
                if bit=="1":
                    rect(d,(x+col*scale,y+row*scale,x+(col+1)*scale-1,y+(row+1)*scale-1),color)
        x += 6*scale


def panel(w=32,h=32,tone="paper",focus=False):
    im=canvas(w,h); d=ImageDraw.Draw(im)
    poly(d,[(3,0),(w-4,0),(w-1,3),(w-1,h-3),(w-4,h-1),(3,h-1),(0,h-4),(0,3)],"ink")
    rect(d,(2,3,w-3,h-5),tone)
    rect(d,(4,2,w-5,2),"light" if tone=="paper" else "mint")
    line(d,[(2,4),(2,h-6)],"light" if tone=="paper" else "mint")
    line(d,[(3,h-4),(w-4,h-4)],"sand" if tone=="paper" else "shade")
    if focus:
        for x,y in ((4,4),(w-5,4),(4,h-7),(w-5,h-7)):
            rect(d,(x,y,x+1,y+1),"gold")
    return im


def icon(name):
    im=canvas(16,16); d=ImageDraw.Draw(im)
    if name=="wrench":
        poly(d,[(9,1),(12,1),(10,4),(12,6),(15,4),(15,7),(12,9),(9,8),(4,14),(1,14),(1,11),(7,6),(7,3)],"ink")
        line(d,[(3,12),(10,5)],"sand",2); rect(d,(9,3,10,5),"paper")
    elif name=="bolt":
        poly(d,[(8,0),(3,9),(7,9),(5,16),(14,6),(9,6),(12,0)],"ink")
        poly(d,[(8,2),(5,8),(9,8),(8,11),(12,7),(8,7),(10,2)],"gold")
    elif name=="gear":
        for b in ((6,1,9,14),(1,6,14,9),(3,3,12,12)): rect(d,b,"ink")
        puff(d,8,8,5,"sand"); puff(d,8,8,2,"ink"); rect(d,(7,7,8,8),"teal")
    elif name=="mushroom":
        rect(d,(6,8,10,14),"ink"); rect(d,(7,9,9,13),"paper")
        poly(d,[(5,1),(11,1),(14,4),(15,9),(1,9),(2,4)],"ink")
        poly(d,[(5,2),(10,2),(13,5),(13,7),(3,7),(3,5)],"coral")
        rect(d,(5,3,6,4),"paper"); rect(d,(10,5,11,6),"paper")
    elif name=="flag":
        rect(d,(3,1,4,14),"ink"); rect(d,(2,14,7,15),"ink")
        poly(d,[(5,2),(14,2),(11,5),(14,8),(5,8)],"teal","ink")
        rect(d,(6,3,9,4),"mint")
    elif name=="ticket":
        poly(d,[(2,3),(13,3),(13,5),(15,6),(15,9),(13,10),(13,12),(2,12),(2,10),(0,9),(0,6),(2,5)],"gold","ink")
        for y in (5,7,9): rect(d,(10,y,10,y),"ochre")
        star(d,5,8,3,"light")
    elif name=="person":
        puff(d,8,4,3,"ink"); rect(d,(7,2,9,5),"paper")
        poly(d,[(5,8),(11,8),(14,12),(14,15),(2,15),(2,12)],"ink")
        rect(d,(5,9,11,13),"coral")
    elif name in ("heart","heart_empty"):
        points=[(1,3),(3,1),(6,1),(8,3),(10,1),(13,1),(15,3),(15,7),(8,14),(1,7)]
        poly(d,points,"coral" if name=="heart" else "shade","ink")
        if name=="heart": line(d,[(3,3),(5,3)],"paper")
    elif name=="coin":
        puff(d,8,8,7,"ochre","ink"); puff(d,7,7,5,"gold")
        line(d,[(6,4),(6,10),(9,10),(9,4)],"ochre")
        rect(d,(3,4,3,8),"light")
    elif name in ("sound","mute"):
        poly(d,[(1,6),(4,6),(8,2),(8,14),(4,10),(1,10)],"ink")
        line(d,[(3,7),(5,7),(6,6),(6,10)],"paper")
        if name=="sound":
            line(d,[(10,5),(12,7),(12,9),(10,11)],"teal"); line(d,[(12,2),(15,5),(15,11),(12,14)],"teal")
        else:
            line(d,[(10,5),(15,10)],"red",2); line(d,[(15,5),(10,10)],"red",2)
    elif name=="play":
        poly(d,[(4,1),(14,8),(4,15)],"ink"); poly(d,[(6,5),(10,8),(6,11)],"mint")
    elif name=="back":
        poly(d,[(7,2),(1,8),(7,14),(7,10),(15,10),(15,6),(7,6)],"ink")
        line(d,[(5,6),(3,8),(5,10)],"paper"); rect(d,(6,7,13,8),"paper")
    elif name=="pause":
        rect(d,(2,2,6,14),"ink"); rect(d,(10,2,14,14),"ink")
        rect(d,(3,3,4,12),"gold"); rect(d,(11,3,12,12),"gold")
    elif name=="check":
        line(d,[(2,8),(6,12),(14,3)],"ink",4); line(d,[(2,7),(6,11),(14,2)],"mint",2)
    elif name=="close":
        line(d,[(3,3),(13,13)],"ink",4); line(d,[(13,3),(3,13)],"ink",4)
        line(d,[(3,2),(13,12)],"coral",2); line(d,[(13,2),(3,12)],"coral",2)
    elif name=="search":
        puff(d,6,6,5,"ink"); puff(d,6,6,3,"paper")
        line(d,[(10,10),(14,14)],"ink",4); line(d,[(11,10),(15,14)],"teal",2)
    elif name=="lock":
        puff(d,8,6,5,"ink"); puff(d,8,6,3,"paper")
        rect(d,(2,7,14,15),"ink"); rect(d,(3,8,13,13),"gold")
        rect(d,(7,9,9,10),"ink"); rect(d,(8,11,8,12),"ink")
    elif name=="home":
        poly(d,[(0,7),(8,0),(15,7),(13,9),(13,15),(3,15),(3,9)],"ink")
        rect(d,(4,7,12,14),"sand"); poly(d,[(3,7),(8,2),(13,7)],"coral")
        rect(d,(7,10,9,14),"ink"); rect(d,(10,8,11,10),"cyan")
    elif name=="star":
        poly(d,[(8,0),(10,5),(15,5),(11,9),(13,15),(8,12),(3,15),(5,9),(1,5),(6,5)],"gold","ink")
        rect(d,(7,4,8,5),"light")
    elif name=="moon":
        puff(d,8,8,7,"ink"); puff(d,7,7,5,"gold"); puff(d,11,5,5,"ink")
        star(d,13,2,2,"paper")
    elif name=="bag":
        rect(d,(4,2,11,5),"ink"); rect(d,(5,3,10,4),"sand")
        rect(d,(2,5,14,14),"ink"); rect(d,(3,6,13,12),"teal")
        rect(d,(4,9,12,12),"mint"); rect(d,(7,8,9,10),"gold")
    elif name=="jump":
        poly(d,[(8,1),(1,7),(5,7),(5,12),(11,12),(11,7),(15,7)],"teal","ink")
        rect(d,(6,7,9,10),"mint"); line(d,[(2,15),(14,15)],"sand")
    elif name=="keyboard":
        rect(d,(0,3,15,13),"ink"); rect(d,(1,4,14,11),"paper")
        for y in (5,7):
            for x in (2,5,8,11): rect(d,(x,y,x+1,y),"shade")
        rect(d,(4,9,11,9),"shade")
    elif name=="turbine":
        puff(d,8,8,7,"ink"); puff(d,8,8,5,"teal")
        for pts in ([(8,8),(8,2),(11,3),(10,6)],[(8,8),(14,8),(13,11),(10,10)],[(8,8),(8,14),(5,13),(6,10)],[(8,8),(2,8),(3,5),(6,6)]): poly(d,pts,"mint")
        puff(d,8,8,2,"gold","ink")
    elif name=="target":
        puff(d,8,8,7,"ink"); puff(d,8,8,5,"paper"); puff(d,8,8,3,"coral"); rect(d,(7,7,9,9),"gold")
    elif name=="reactor":
        puff(d,8,8,7,"ink"); puff(d,8,8,5,"teal")
        for j in range(3):
            a=j*math.tau/3-math.pi/2
            poly(d,[(8,8),(8+math.cos(a-.5)*6,8+math.sin(a-.5)*6),(8+math.cos(a+.5)*6,8+math.sin(a+.5)*6)],"gold")
        puff(d,8,8,2,"paper","ink")
    elif name=="carnival":
        poly(d,[(1,7),(8,0),(15,7)],"coral","ink")
        rect(d,(2,7,14,14),"paper","ink")
        for x in (3,7,11): rect(d,(x,8,x+1,13),"coral")
        rect(d,(7,10,9,14),"ink"); star(d,8,4,2,"gold")
    return im


FX = {
"spark_weld": (14,False,2,[16,22],"Welding, repairs and metal impacts"),
"dust_step": (12,False,3,[16,26],"Footsteps and quick changes of direction"),
"smoke_vent": (7,True,4,[16,28],"Warm machinery and ventilation"),
"slime_splash": (11,False,4,[16,26],"Organic hazards and goo landings"),
"energy_arc": (12,False,2,[16,16],"Short circuit between two nearby terminals"),
"hit_flash": (16,False,3,[16,16],"Single local hit marker, never fullscreen"),
"portal_fold": (8,True,2,[16,28],"Small dimensional door or district transition"),
"warning_ping": (4,True,0,[16,27],"World hazard cue paired with text or icon"),
"success_burst": (12,False,3,[16,16],"Completed repair or successful round"),
"failure_fizzle": (10,False,0,[16,26],"Failure result or damage feedback"),
"landing_ring": (12,False,2,[16,26],"Ground contact and safe landing"),
"charge_orbit": (8,True,0,[16,16],"Charging interactable or special object"),
}
ICONS = ["wrench","bolt","gear","mushroom","flag","ticket","person","heart","heart_empty","coin","sound","mute","play","back","pause","check","close","search","lock","home","star","moon","bag","jump","keyboard","turbine","target","reactor","carnival"]


def write_png(im, path):
    path=OUT/path; path.parent.mkdir(parents=True,exist_ok=True); im.save(path)


def build():
    OUT.mkdir(parents=True,exist_ok=True)
    records=[]
    atlas=canvas(256,len(FX)*32)
    contact=Image.new("RGBA",(768,len(FX)*92),P["ink"])
    cd=ImageDraw.Draw(contact)
    for row,(name,(fps,loop,still,anchor,use)) in enumerate(FX.items()):
        strip=canvas(256,32)
        for t in range(8):
            frame=make_fx(name,t)
            assert frame.getbbox(), (name,t)
            strip.alpha_composite(frame,(t*32,0))
            contact.alpha_composite(frame.resize((64,64),Image.Resampling.NEAREST),(216+t*68,row*92+19))
        write_png(strip,Path("effects")/(name+".png"))
        write_png(make_fx(name,still),Path("effects")/(name+"_still.png"))
        atlas.alpha_composite(strip,(0,row*32))
        cd.text((8,row*92+25),name,fill=P["paper"])
        cd.text((8,row*92+43),f"8 frames / {fps} fps / {'loop' if loop else 'one shot'}",fill=P["mint"])
        cd.text((8,row*92+59),f"reduced motion: frame {still}",fill=P["sand"])
        records.append({"id":name,"family":"effects","file":f"effects/{name}.png","atlas_rect":[0,row*32,256,32],"frame_size":[32,32],"frame_count":8,"fps":fps,"loop":loop,"anchor":anchor,"reduced_motion":{"file":f"effects/{name}_still.png","frame":still,"behavior":"Static image; no flicker, movement, scaling or rotation"},"use":use,"ready":True})
    write_png(atlas,Path("effects_atlas.png")); write_png(contact,Path("effects_contact_sheet.png"))

    panels=[]
    for name,tone,focus in [("paper_panel","paper",False),("workshop_panel","teal",False),("focused_panel","paper",True),("night_panel","shade",False)]:
        image=panel(tone=tone,focus=focus); write_png(image,Path("ui")/(name+".png")); panels.append((name,image))
        records.append({"id":name,"family":"ui_panel","file":f"ui/{name}.png","size":[32,32],"nine_slice_margins":{"left":6,"top":6,"right":6,"bottom":8},"content_margins":[8,8,8,10],"min_size":[24,24],"ready":True})
    buttons=[]
    for state in ("normal","hover","pressed","disabled"):
        im=panel(64,24,"teal" if state in ("hover","pressed") else "paper",state=="hover")
        d=ImageDraw.Draw(im)
        if state=="pressed":
            rect(d,(2,3,61,19),"shade"); line(d,[(3,3),(60,3)],"ink")
        if state=="disabled": rect(d,(2,3,61,19),"sand")
        write_png(im,Path("ui")/f"button_{state}.png"); buttons.append((state,im))
        records.append({"id":f"button_{state}","family":"ui_button","file":f"ui/button_{state}.png","size":[64,24],"nine_slice_margins":{"left":6,"top":6,"right":6,"bottom":8},"text_color":P["light"] if state in ("hover","pressed") else P["ink"],"text_offset":[0,1 if state=="pressed" else 0],"mobile_min_hit_target":[48,48],"ready":True})
    icon_atlas=canvas(128,64)
    for i,name in enumerate(ICONS):
        im=icon(name); assert im.getbbox(),name
        write_png(im,Path("ui/icons")/(name+".png"))
        x=(i%8)*16; y=(i//8)*16; icon_atlas.alpha_composite(im,(x,y))
        records.append({"id":f"icon_{name}","family":"ui_icon","file":f"ui/icons/{name}.png","size":[16,16],"atlas_rect":[x,y,16,16],"ready":True})
    write_png(icon_atlas,Path("ui/icons_atlas.png"))
    badges=[]
    districts=[("sky_foundry","turbine"),("neon_workshop","wrench"),("reactor_works","reactor"),("fungus_underworks","mushroom"),("training_yard","target"),("chaos_carnival","carnival")]
    for name,mark in districts:
        im=canvas(24,28); d=ImageDraw.Draw(im)
        poly(d,[(4,0),(19,0),(23,4),(23,19),(12,27),(0,19),(0,4)],"ink")
        poly(d,[(4,2),(19,2),(21,4),(21,18),(12,24),(2,18),(2,4)],"gold")
        rect(d,(4,4,19,19),"paper"); im.alpha_composite(icon(mark),(4,4))
        write_png(im,Path("ui/badges")/(name+".png")); badges.append((name,im))
        records.append({"id":f"badge_{name}","family":"ui_badge","file":f"ui/badges/{name}.png","size":[24,28],"district":name,"ready":True})
    banners=[]
    for name,text,mark,tone in [("round_clear","ROUND CLEAR!","star","paper"),("try_again","TRY AGAIN","heart_empty","paper"),("new_best","NEW BEST!","coin","teal"),("district_ready","DISTRICT READY","flag","paper")]:
        im=panel(144,32,tone,True); d=ImageDraw.Draw(im)
        im.alpha_composite(icon(mark),(8,7))
        label(d,text,31,10,"light" if tone=="teal" else "ink")
        write_png(im,Path("ui/banners")/(name+".png")); banners.append((name,im))
        records.append({"id":f"banner_{name}","family":"ui_banner","file":f"ui/banners/{name}.png","size":[144,32],"text":text,"safe_inset":[6,6,6,8],"ready":True})
    # Transparent meter housing and separate fill support arbitrary runtime values.
    meter=panel(80,12,"shade"); md=ImageDraw.Draw(meter); rect(md,(4,4,75,6),"ink")
    fill=canvas(1,3); ImageDraw.Draw(fill).rectangle((0,0,0,2),fill=P["mint"])
    write_png(meter,Path("ui/meter_track.png")); write_png(fill,Path("ui/meter_fill.png"))
    records.extend([{"id":"meter_track","family":"ui_meter","file":"ui/meter_track.png","size":[80,12],"fill_rect":[4,4,72,3],"ready":True},{"id":"meter_fill","family":"ui_meter","file":"ui/meter_fill.png","size":[1,3],"stretch":"horizontal nearest; clip width to value","ready":True}])
    # Font itself is a reusable atlas, arranged by manifest order, not OS font data.
    glyphs=canvas(16*6,math.ceil(len(FONT)/16)*8)
    for i,char in enumerate(FONT): label(ImageDraw.Draw(glyphs),char,(i%16)*6,(i//16)*8)
    write_png(glyphs,Path("ui/font_5x7.png"))
    font_info={"file":"ui/font_5x7.png","glyph_order":list(FONT),"columns":16,"cell":[6,8],"visible_glyph":[5,7],"advance":6,"baseline":7,"filter":"nearest"}
    records.append({"id":"town_5x7","family":"ui_font",**font_info,"ready":True})

    review=Image.new("RGBA",(400,420),P["ink"]); rd=ImageDraw.Draw(review)
    label(rd,"PIXEL TOWN - SHARED UI",12,12,"paper")
    for i,(name,im) in enumerate(panels):
        review.alpha_composite(im,(12+i*96,32)); label(rd,name.split("_")[0],12+i*96,69,"paper")
    for i,(state,im) in enumerate(buttons):
        x=12+i*96; review.alpha_composite(im,(x,88)); label(rd,"PLAY",x+19,95,"light" if state in ("hover","pressed") else "ink")
        label(rd,state,x,118,"paper")
    for i,name in enumerate(ICONS):
        x=12+(i%10)*38; y=143+(i//10)*28
        review.alpha_composite(icon(name),(x,y))
    for i,(name,im) in enumerate(badges): review.alpha_composite(im,(12+i*62,235))
    label(rd,"SIX DISTRICT PATCHES",12,271,"paper")
    for i,(name,im) in enumerate(banners): review.alpha_composite(im,(12+(i%2)*190,292+(i//2)*42))
    review.alpha_composite(meter,(12,387)); review.alpha_composite(fill.resize((52,3),Image.Resampling.NEAREST),(16,391))
    label(rd,"INTEGER SCALE + NEAREST",110,389,"paper")
    write_png(review.resize((1200,1260),Image.Resampling.NEAREST),Path("ui_contact_sheet.png"))

    manifest={"title":"Pixel Town shared feedback and UI","version":1,"source":"Original integer-grid art created for Iron-Mario by the build_town_fx_ui.py asset tool; no third-party pixels included","license_status":"ready-original","attribution":"Iron-Mario Pixel Town original UI and feedback art","palette":P,"sampling":"nearest","pixel_grid":1,"alpha":"transparent outside silhouettes; no antialiasing","effects_atlas":{"file":"effects_atlas.png","size":[256,len(FX)*32],"layout":"one effect row, eight 32x32 frames left-to-right"},"icon_atlas":{"file":"ui/icons_atlas.png","size":[128,64]},"font":font_info,"assets":records,"integration":{"Godot":"CanvasItem.texture_filter = TEXTURE_FILTER_NEAREST; SpriteFrames duration uses fps; all animation frame indices are zero based","nine_slice":"Use StyleBoxTexture or NinePatchRect with the listed margins. Retain corner pixels at integer scale. Add text via runtime Label for localization.","mobile":"UI artwork is native size, independent of hit targets. Use >=48x48 logical touch targets and keep banners within safe-area margins.","reduced_motion":"Use each effect's _still.png. A single time-limited static marker may appear without loop, flash or tween. Retain text/icon cues.","fx_anchor":"Anchor coordinates are source pixels measured from frame top-left; position sprite so anchor meets contact point."}}
    (OUT/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
    (OUT/"palette.json").write_text(json.dumps(P,indent=2)+"\n",encoding="utf-8")
    print(f"Built {len(FX)} distinct eight-frame effects, {len(ICONS)} icons, {len(records)} manifest assets in {OUT}")


if __name__=="__main__": build()
