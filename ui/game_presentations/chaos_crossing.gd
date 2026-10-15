extends RefCounted

const TITLE: String = "Chaos Crossing"
const SETTING: String = "A busy canal beside the timber maintenance yard"
const ACCENT: Color = Color("#8daa9b")
const PAPER: Color = Color("#fff4d8")
const FAR: Color = Color("#e9e5ce")
const LINE: Color = Color("#c5c8b1")
const WALL: Color = Color("#dddcc7")
const ROOF: Color = Color("#c7cdbb")
const TIMBER: Color = Color("#d5bf9a")

func draw_background(canvas: Node2D, context: Dictionary) -> void:
	var board: Rect2 = context.get("board_rect", Rect2(0, 0, 960, 480))
	canvas.draw_rect(board, PAPER)
	# The functional lanes cover y96..365; scenery occupies the banks beyond them.
	canvas.draw_rect(Rect2(0, 72, 960, 22), FAR)
	canvas.draw_line(Vector2(0, 93), Vector2(960, 93), LINE, 1.0)
	_draw_quay(canvas)
	_draw_pump_house(canvas, Vector2(720, 72))
	_draw_timber_store(canvas, Vector2(505, 77))
	_draw_reeds(canvas, Vector2(28, 91), 7)
	_draw_reeds(canvas, Vector2(870, 91), 6)
	_draw_hose_rack(canvas, Vector2(665, 76))
	# Paving remains a pale setting detail behind the existing opaque controls.
	canvas.draw_rect(Rect2(0, 366, 960, 114), Color("#f2e8cd"))
	canvas.draw_rect(Rect2(0, 367, 960, 10), Color("#e4dcc3"))
	canvas.draw_line(Vector2(0, 377), Vector2(960, 377), LINE, 1.0)
	for index in range(12):
		var seam_x: float = 15.0 + float(index) * 83.0
		canvas.draw_line(Vector2(seam_x, 368), Vector2(seam_x + 2, 376), LINE, 1.0)
	_draw_drain(canvas, Rect2(92, 370, 48, 5))
	_draw_drain(canvas, Rect2(810, 370, 48, 5))

func _draw_quay(canvas: Node2D) -> void:
	canvas.draw_rect(Rect2(106, 84, 344, 8), WALL)
	canvas.draw_line(Vector2(106, 84), Vector2(450, 84), LINE, 1.0)
	for index in range(8):
		var stone_x: float = 112.0 + float(index) * 43.0
		canvas.draw_line(Vector2(stone_x, 85), Vector2(stone_x, 91), LINE, 1.0)
	# A low handrail reads as distant infrastructure, above the playable lane.
	canvas.draw_line(Vector2(155, 77), Vector2(418, 77), LINE, 1.0)
	for index in range(7):
		var post_x: float = 157.0 + float(index) * 43.0
		canvas.draw_line(Vector2(post_x, 77), Vector2(post_x, 84), LINE, 1.0)

func _draw_pump_house(canvas: Node2D, origin: Vector2) -> void:
	canvas.draw_rect(Rect2(origin + Vector2(5, 6), Vector2(100, 14)), WALL)
	var roof_points: PackedVector2Array = PackedVector2Array([
		origin + Vector2(0, 6), origin + Vector2(12, 0),
		origin + Vector2(96, 0), origin + Vector2(110, 6)])
	canvas.draw_colored_polygon(roof_points, ROOF)
	canvas.draw_line(origin + Vector2(0, 6), origin + Vector2(110, 6), LINE, 1.0)
	canvas.draw_rect(Rect2(origin + Vector2(47, 8), Vector2(12, 12)), FAR)
	canvas.draw_rect(Rect2(origin + Vector2(13, 9), Vector2(21, 5)), ROOF)
	canvas.draw_rect(Rect2(origin + Vector2(72, 9), Vector2(21, 5)), ROOF)
	canvas.draw_line(origin + Vector2(53, 8), origin + Vector2(53, 20), LINE, 1.0)
	canvas.draw_rect(Rect2(origin + Vector2(115, 11), Vector2(18, 9)), ROOF)
	for index in range(4):
		var vent_y: float = origin.y + 12.0 + float(index) * 2.0
		canvas.draw_line(Vector2(origin.x + 117, vent_y), Vector2(origin.x + 131, vent_y), LINE, 1.0)

func _draw_timber_store(canvas: Node2D, origin: Vector2) -> void:
	canvas.draw_rect(Rect2(origin + Vector2(4, 0), Vector2(117, 15)), WALL)
	canvas.draw_rect(Rect2(origin, Vector2(125, 3)), ROOF)
	for index in range(3):
		var plank_y: float = origin.y + 5.0 + float(index) * 3.0
		canvas.draw_rect(Rect2(origin.x + 11, plank_y, 99, 2), TIMBER)
	canvas.draw_line(origin + Vector2(26, 4), origin + Vector2(26, 14), LINE, 1.0)
	canvas.draw_line(origin + Vector2(93, 4), origin + Vector2(93, 14), LINE, 1.0)

func _draw_reeds(canvas: Node2D, origin: Vector2, count: int) -> void:
	for index in range(count):
		var base: Vector2 = origin + Vector2(float(index) * 8.0, 0)
		var reed_height: float = 7.0 + float(index % 3) * 2.0
		canvas.draw_line(base, base + Vector2(1, -reed_height), LINE, 1.0)
		canvas.draw_line(base + Vector2(0, -3), base + Vector2(-3, -6), LINE, 1.0)
		canvas.draw_line(base + Vector2(0, -4), base + Vector2(4, -8), LINE, 1.0)

func _draw_hose_rack(canvas: Node2D, origin: Vector2) -> void:
	canvas.draw_line(origin, origin + Vector2(0, 16), LINE, 1.0)
	canvas.draw_line(origin + Vector2(27, 0), origin + Vector2(27, 16), LINE, 1.0)
	canvas.draw_line(origin, origin + Vector2(27, 0), LINE, 1.0)
	for index in range(4):
		var hose_x: float = origin.x + 4.0 + float(index) * 6.0
		canvas.draw_polyline(PackedVector2Array([
			Vector2(hose_x, origin.y), Vector2(hose_x, origin.y + 10),
			Vector2(hose_x + 3, origin.y + 13), Vector2(hose_x + 4, origin.y + 1)]), ROOF, 1.5)

func _draw_drain(canvas: Node2D, rect: Rect2) -> void:
	canvas.draw_rect(rect, Color("#cccbb5"))
	for index in range(8):
		var slit_x: float = rect.position.x + 3.0 + float(index) * 6.0
		canvas.draw_line(Vector2(slit_x, rect.position.y + 1), Vector2(slit_x, rect.end.y - 1), WALL, 1.0)
