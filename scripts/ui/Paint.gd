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
	canvas.draw_rect(Rect2(0,0,1280,720), colors.get(kind, PAPER))
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
