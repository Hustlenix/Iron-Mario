extends RefCounted
## Original mouse-drawn look: fixed wobble, square pencil edges, solid bucket fills.
## No animation-frame noise: a drawing keeps its shape while it moves.
const INK := Color("202022")
const PAPER := Color("fff6dc")
const RED := Color("e34838")
const GOLD := Color("ffd13c")
const BLUE := Color("3c74b7")
const CYAN := Color("7bd9df")
const GLYPHS := {
 "%": "4,0 0,7|0,0 1,0 1,2 0,2 0,0|3,5 4,5 4,7 3,7 3,5",
 "_": "0,7 4,7",
 "A": "0,7 0,3 2,0 4,3 4,7|0,4 4,4",
 "B": "0,7 0,0 3,0 4,1 4,2 3,3 0,3|3,3 4,4 4,6 3,7 0,7",
 "C": "4,1 3,0 1,0 0,1 0,6 1,7 4,6",
 "D": "0,7 0,0 2,0 4,2 4,5 2,7 0,7",
 "E": "4,0 0,0 0,7 4,7|0,3 3,3",
 "F": "0,7 0,0 4,0|0,3 3,3",
 "G": "4,1 3,0 1,0 0,2 0,6 1,7 4,7 4,4 2,4",
 "H": "0,0 0,7|4,0 4,7|0,3 4,3",
 "I": "0,0 4,0|2,0 2,7|0,7 4,7",
 "J": "0,0 4,0 4,6 3,7 1,7 0,5",
 "K": "0,0 0,7|4,0 0,4 4,7",
 "L": "0,0 0,7 4,7",
 "M": "0,7 0,0 2,3 4,0 4,7",
 "N": "0,7 0,0 4,7 4,0",
 "O": "1,0 3,0 4,1 4,6 3,7 1,7 0,6 0,1 1,0",
 "P": "0,7 0,0 3,0 4,1 4,3 3,4 0,4",
 "Q": "1,0 3,0 4,1 4,5 3,7 1,7 0,6 0,1 1,0|2,5 5,8",
 "R": "0,7 0,0 3,0 4,1 4,3 3,4 0,4|2,4 4,7",
 "S": "4,1 3,0 1,0 0,1 0,3 4,4 4,6 3,7 0,7",
 "T": "0,0 4,0|2,0 2,7",
 "U": "0,0 0,6 1,7 3,7 4,6 4,0",
 "V": "0,0 1,5 2,7 3,5 4,0",
 "W": "0,0 0,7 2,4 4,7 4,0",
 "X": "0,0 4,7|4,0 0,7",
 "Y": "0,0 2,3 4,0|2,3 2,7",
 "Z": "0,0 4,0 0,7 4,7",
 "0": "1,0 3,0 4,1 4,6 3,7 1,7 0,6 0,1 1,0|1,5 3,2",
 "1": "1,1 2,0 2,7|0,7 4,7",
 "2": "0,1 1,0 3,0 4,1 4,3 0,7 4,7",
 "3": "0,0 4,0 2,3 4,4 4,6 3,7 0,7",
 "4": "3,7 3,0 0,5 4,5",
 "5": "4,0 0,0 0,3 3,3 4,4 4,6 3,7 0,7",
 "6": "4,0 1,0 0,2 0,6 1,7 3,7 4,6 4,4 3,3 0,3",
 "7": "0,0 4,0 1,7",
 "8": "1,0 3,0 4,1 4,2 0,5 0,6 1,7 3,7 4,6 4,5 0,2 0,1 1,0",
 "9": "4,4 1,4 0,3 0,1 1,0 3,0 4,1 4,6 3,7 0,7",
 "!": "2,0 2,4|2,6 2,7",
 "?": "0,1 1,0 3,0 4,1 4,2 2,4|2,6 2,7",
 "-": "0,3 4,3",
 ".": "2,6 2,7",
 ":": "2,2 2,3|2,5 2,6",
 "/": "0,7 4,0",
 "+": "0,3 4,3|2,1 2,5",
 "(": "3,0 1,2 1,5 3,7",
 ")": "1,0 3,2 3,5 1,7",
 "<": "4,1 0,3 4,6",
 ">": "0,1 4,3 0,6",
 "•": "2,3 2,4",
 "←": "2,1 0,3 2,5|0,3 4,3",
 "→": "2,1 4,3 2,5|0,3 4,3",
 "↑": "0,2 2,0 4,2|2,0 2,7",
 "↓": "0,5 2,7 4,5|2,0 2,7",
 "'": "2,0 1,2",
 ",": "2,6 1,8",
 "=": "0,2 4,2|0,5 4,5",
 "&": "4,7 0,2 1,0 3,0 3,2 0,5 0,6 1,7 3,6 4,4"
}

static var glyph_cache: Dictionary = {}

static func wobble(points: PackedVector2Array, amount: float = 1.6) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in range(points.size()):
		var offset := Vector2(sin(float(i) * 5.7 + 0.8), cos(float(i) * 3.3 + 1.2)) * amount
		result.append((points[i] + offset).round())
	return result

static func polyline(canvas: CanvasItem, points: PackedVector2Array, color: Color, width: float = 3.0) -> void:
	if points.size() < 2:
		return
	var path := wobble(points, minf(1.2, width * 0.25))
	canvas.draw_polyline(path, color, maxf(1.0, width), false)

static func line(canvas: CanvasItem, a: Vector2, b: Vector2, color: Color, width: float = 3.0) -> void:
	var path := PackedVector2Array([a, a.lerp(b, 0.27), a.lerp(b, 0.57), a.lerp(b, 0.82), b])
	polyline(canvas, path, color, width)

static func polygon(canvas: CanvasItem, points: PackedVector2Array, colors: PackedColorArray) -> void:
	if points.size() < 3:
		return
	var path := wobble(points)
	canvas.draw_colored_polygon(path, colors[0])
	if colors[0].a > 0.5:
		path.append(path[0])
		canvas.draw_polyline(path, INK, 2.0, false)

static func rect(canvas: CanvasItem, box: Rect2, color: Color, filled: bool = true, width: float = 3.0) -> void:
	if box.size.x < 1.0 or box.size.y < 1.0:
		return
	if box.size.x >= 1270 and box.size.y >= 710:
		canvas.draw_rect(box, color)
		return
	var x := box.position.x
	var y := box.position.y
	var w := box.size.x
	var h := box.size.y
	var bend := minf(3.0, minf(w, h) * 0.08)
	var points := PackedVector2Array([
		Vector2(x, y), Vector2(x+w*0.44, y-bend), Vector2(x+w, y+bend),
		Vector2(x+w-bend, y+h*0.55), Vector2(x+w, y+h),
		Vector2(x+w*0.4, y+h-bend), Vector2(x-bend, y+h), Vector2(x, y)])
	if filled:
		canvas.draw_colored_polygon(points, color)
		if w > 25 and h > 20 and color.a > 0.5:
			canvas.draw_polyline(points, INK, 2.0, false)
	else:
		canvas.draw_polyline(points, color, width, false)

static func circle(canvas: CanvasItem, center: Vector2, radius: float, color: Color, filled: bool = true, width: float = 3.0) -> void:
	var points := PackedVector2Array()
	var count := 16 if radius < 45 else 28
	for i in range(count):
		var angle := float(i) / count * TAU
		var irregular_radius := radius * (1.0 + 0.04 * sin(float(i) * 2.3))
		points.append((center + Vector2(cos(angle), sin(angle)) * irregular_radius).round())
	points.append(points[0])
	if filled:
		canvas.draw_colored_polygon(points, color)
		if color.a > 0.5 and radius > 12.0:
			canvas.draw_polyline(points, INK, 2.0, false)
	else:
		canvas.draw_polyline(points, color, width, false)

static func string(canvas: CanvasItem, _font: Font, at: Vector2, value: String, alignment: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1, font_size: int = 20, _color: Color = INK) -> void:
	var color := PAPER if canvas.name == "DeathScene" else INK
	text(canvas, value, at, font_size, color, width, alignment)

static func text(canvas: CanvasItem, value: String, at: Vector2, font_size: float = 20, color: Color = INK, width: float = -1, alignment: int = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var label := value.to_upper()
	var size := font_size
	var advance := size * 0.59
	if width > 0 and label.length() * advance > width:
		size *= width / (label.length() * advance)
		advance = size * 0.59
	var x := at.x
	var text_width := label.length() * advance
	if width > 0 and alignment == HORIZONTAL_ALIGNMENT_CENTER:
		x += (width - text_width) * 0.5
	elif width > 0 and alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		x += width - text_width
	for index in range(label.length()):
		var character := label[index]
		if not GLYPHS.has(character):
			x += advance
			continue
		if not glyph_cache.has(character):
			var paths: Array[PackedVector2Array] = []
			for stroke in String(GLYPHS[character]).split("|"):
				var path := PackedVector2Array()
				for coordinate in stroke.split(" "):
					var xy := coordinate.split(",")
					path.append(Vector2(float(xy[0]), float(xy[1])))
				paths.append(path)
			glyph_cache[character] = paths
		var unit := size * 0.105
		var lift := sin(float(index) * 2.6) * size * 0.023
		for source in glyph_cache[character]:
			var path := PackedVector2Array()
			for point in source:
				path.append(Vector2(x, at.y - size * 0.77 + lift) + Vector2(point.x + point.y * 0.025, point.y) * unit)
			canvas.draw_polyline(path, color, maxf(1.8, size * 0.065), false)
		x += advance

static func burst(canvas: CanvasItem, center: Vector2, radius: float, color: Color = GOLD) -> void:
	for i in range(10):
		var direction := Vector2.RIGHT.rotated(float(i) * TAU / 10.0)
		line(canvas, center + direction * radius, center + direction * (radius + 13 + i % 3 * 4), color, 4)

static func cloud(canvas: CanvasItem, at: Vector2, scale: float = 1.0) -> void:
	var points := PackedVector2Array()
	for p in [Vector2(-55,12),Vector2(-63,0),Vector2(-46,-10),Vector2(-31,-8),Vector2(-26,-30),Vector2(-8,-35),Vector2(9,-15),Vector2(31,-19),Vector2(40,-1),Vector2(60,5),Vector2(54,18),Vector2(-55,12)]:
		points.append(at + p * scale)
	polygon(canvas, points, PackedColorArray([PAPER]))

static func background(canvas: CanvasItem, kind: String) -> void:
	var colors := {"sky": Color("b2e3ed"), "city": Color("b2e3ed"), "workshop": Color("f7dfb5"), "tunnel": Color("d6d7ca"), "space": Color("c7c9e8"), "title": Color("fff6dc"), "briefing": Color("dfe6c5"), "death": Color("273b61")}
	var cast = preload("res://scripts/HeroCatalog.gd")
	var theme: Dictionary = cast.get_hero(str(canvas.get_meta("hero_id", Global.hero_id)))
	var sky := Color(theme["sky"])
	canvas.draw_rect(Rect2(0,0,1280,720), colors["death"] if kind == "death" else sky)
	hero_environment(canvas, theme, kind == "death")
	if kind in ["sky", "city", "title"]:
		cloud(canvas, Vector2(1110,245), 1.3)
		cloud(canvas, Vector2(150,200), 0.8)
		cloud(canvas, Vector2(735,300), 0.7)
		circle(canvas, Vector2(1170,175), 35, GOLD)
		burst(canvas, Vector2(1170,175), 44, INK)
	elif kind == "workshop":
		for i in range(8):
			line(canvas, Vector2(10,200+i*66), Vector2(1270,204+i*66), Color("dabf97"), 2)
		for at in [Vector2(40,170),Vector2(1230,170),Vector2(40,680),Vector2(1230,680)]:
			circle(canvas, at, 9, Color("aaaa9a"))
			line(canvas, at-Vector2(4,4),at+Vector2(4,4),INK,2)
	elif kind == "tunnel":
		for x in [70,410,770,1150]:
			line(canvas, Vector2(x,140),Vector2(x-12,620),Color("aaa99a"),5)
			line(canvas, Vector2(x-35,235),Vector2(x+35,238),INK,3)
	elif kind in ["space", "death"]:
		for i in range(18):
			var point := Vector2(35+(i*173)%1220,180+(i*97)%470)
			line(canvas,point-Vector2(6,0),point+Vector2(6,0),PAPER if kind=="death" else INK,2)
			line(canvas,point-Vector2(0,7),point+Vector2(0,7),PAPER if kind=="death" else INK,2)

static func hero_environment(canvas: CanvasItem, theme: Dictionary, dark: bool = false) -> void:
	var scenery := Color(theme["scenery"])
	var accent := Color(theme["trim"])
	if dark:
		scenery = scenery.darkened(0.62)
		accent = accent.darkened(0.6)
	# Set pieces sit behind gameplay. No red beam-like decoration in the play area.
	match theme["motif"]:
		"forge":
			for i in range(6):
				var x := 35.0+i*245
				rect(canvas,Rect2(x,510,170,210),scenery)
				rect(canvas,Rect2(x+22,450,32,65),scenery)
				for j in range(3):
					rect(canvas,Rect2(x+16+j*48,555,30,40),accent)
			for x in [105,1190]:
				circle(canvas,Vector2(x,245),57,scenery,false,8)
				line(canvas,Vector2(x,175),Vector2(x,315),scenery,7)
		"moon":
			circle(canvas,Vector2(1100,230),90,accent)
			circle(canvas,Vector2(1130,209),75,Color("273b61") if dark else Color(theme["sky"]))
			for i in range(18):
				var p := Vector2(25+(i*191)%1250,150+(i*71)%300)
				line(canvas,p-Vector2(3,0),p+Vector2(3,0),scenery,2)
			for x in [70,930]:
				rect(canvas,Rect2(x,505,250,215),scenery)
				circle(canvas,Vector2(x+125,505),110,scenery)
				line(canvas,Vector2(x+125,480),Vector2(x+200,414),accent,18)
		"islands":
			for i in range(5):
				var p := Vector2(100+i*270,360+(i%2)*170)
				polygon(canvas,PackedVector2Array([p-Vector2(85,0),p+Vector2(85,0),p+Vector2(25,85),p+Vector2(-25,65)]),PackedColorArray([scenery]))
				rect(canvas,Rect2(p-Vector2(85,12),Vector2(170,20)),accent)
				line(canvas,p-Vector2(40,15),p-Vector2(40,80),scenery,8)
				polygon(canvas,PackedVector2Array([p-Vector2(40,80),p-Vector2(10,68),p-Vector2(40,53)]),PackedColorArray([accent]))
		"sea":
			for y in [560,610,660,710]:
				var wave := PackedVector2Array()
				for x in range(0,1300,35):
					wave.append(Vector2(x,y+sin(x*0.026)*10))
				polyline(canvas,wave,scenery,6)
			for x in [70,1120]:
				rect(canvas,Rect2(x,285,88,295),scenery)
				polygon(canvas,PackedVector2Array([Vector2(x-15,285),Vector2(x+44,230),Vector2(x+104,285)]),PackedColorArray([accent]))
				circle(canvas,Vector2(x+44,340),24,accent)
		"port":
			for i in range(4):
				var p := Vector2(80+i*345,550)
				rect(canvas,Rect2(p,Vector2(200,170)),scenery)
				line(canvas,p+Vector2(20,-70),p+Vector2(20,0),scenery,9)
				line(canvas,p+Vector2(20,-65),p+Vector2(95,-95),accent,12)
			for i in range(6):
				var p := Vector2(90+i*215,170+(i%3)*65)
				circle(canvas,p,9,accent)
				line(canvas,p-Vector2(30,-15),p-Vector2(10,-5),scenery,4)
		"garden":
			for i in range(8):
				var p := Vector2(i*180,540+(i%3)*35)
				rect(canvas,Rect2(p,Vector2(155,200)),scenery)
				rect(canvas,Rect2(p-Vector2(5,12),Vector2(165,18)),accent)
				for j in range(3):
					var stem := p+Vector2(30+j*45,-12)
					line(canvas,stem,stem-Vector2(0,34),scenery,4)
					circle(canvas,stem-Vector2(6,28),12,scenery)
			polyline(canvas,PackedVector2Array([Vector2(0,235),Vector2(270,275),Vector2(550,215),Vector2(850,260),Vector2(1280,210)]),scenery,3)
		"rail":
			for i in range(10):
				var x := float(i)*145
				rect(canvas,Rect2(x,580,120,86),scenery)
				rect(canvas,Rect2(x+15,591,38,29),accent)
				circle(canvas,Vector2(x+22,674),15,scenery)
				circle(canvas,Vector2(x+97,674),15,scenery)
			line(canvas,Vector2(0,694),Vector2(1280,694),scenery,8)
			for x in [85,1180]:
				line(canvas,Vector2(x,570),Vector2(x,220),scenery,8)
				circle(canvas,Vector2(x,215),23,accent)
		"crystal":
			for i in range(9):
				var x := float(i)*162
				var h := 110+(i*47)%130
				polygon(canvas,PackedVector2Array([Vector2(x,720),Vector2(x+16,720-h),Vector2(x+48,680-h),Vector2(x+83,720-h),Vector2(x+103,720)]),PackedColorArray([scenery]))
				line(canvas,Vector2(x+48,680-h),Vector2(x+55,710),accent,4)
			for x in [90,1165]:
				circle(canvas,Vector2(x,230),42,scenery,false,3)
				polygon(canvas,PackedVector2Array([Vector2(x,199),Vector2(x+20,230),Vector2(x,259),Vector2(x-20,230)]),PackedColorArray([accent]))
		"fort":
			rect(canvas,Rect2(0,565,1280,155),scenery)
			for x in range(0,1280,75):
				rect(canvas,Rect2(x,535,45,35),scenery)
			for x in [70,1090]:
				rect(canvas,Rect2(x,250,135,320),scenery)
				circle(canvas,Vector2(x+67,324),49,accent)
				line(canvas,Vector2(x+67,324),Vector2(x+67,292),INK,3)
				line(canvas,Vector2(x+67,324),Vector2(x+89,338),INK,3)
