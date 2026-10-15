extends RefCounted

const TITLE: String = "Big Head Energy"
const SETTING: String = "The festival inflation stall"
const ACCENT: Color = Color("c5997d")
const PAPER: Color = Color("faf1de")
const HAZE: Color = Color("ece2cc")
const WOOD: Color = Color("cfbba0")
const EDGE: Color = Color("a99e89")
const CLOTH: Color = Color("e2c1a8")
const METAL: Color = Color("bdc5b8")

func draw_background(canvas: Node2D, context: Dictionary) -> void:
	var board: Rect2 = context.get("board_rect", Rect2(0, 0, 960, 480))
	canvas.draw_rect(board, PAPER)
	# A shallow shop alcove leaves the live balloon and its growth ring quiet.
	canvas.draw_rect(Rect2(0, 76, 218, 331), Color("f0e5cf"))
	canvas.draw_rect(Rect2(742, 76, 218, 331), Color("f0e5cf"))
	canvas.draw_rect(Rect2(0, 407, 960, 73), Color("f1e6d1"))
	canvas.draw_rect(Rect2(322, 391, 316, 65), PAPER)
	canvas.draw_rect(Rect2(202, 78, 12, 318), WOOD)
	canvas.draw_rect(Rect2(746, 78, 12, 318), WOOD)
	canvas.draw_rect(Rect2(214, 78, 9, 318), HAZE)
	canvas.draw_rect(Rect2(737, 78, 9, 318), HAZE)
	_awning(canvas)
	# Low-contrast side curtains frame an open stall, never the playable ring.
	for index: int in range(4):
		var left_x: float = 16.0 + float(index) * 19.0
		var right_x: float = 882.0 + float(index) * 19.0
		canvas.draw_rect(Rect2(left_x, 93, 13, 173), CLOTH)
		canvas.draw_rect(Rect2(right_x, 93, 13, 173), CLOTH)
	canvas.draw_line(Vector2(9, 267), Vector2(88, 267), EDGE, 2.0)
	canvas.draw_line(Vector2(878, 267), Vector2(952, 267), EDGE, 2.0)
	# Supply tray: folded uninflated rubber sleeves, rather than spare targets.
	canvas.draw_rect(Rect2(94, 311, 107, 9), HAZE)
	canvas.draw_rect(Rect2(83, 283, 116, 29), WOOD)
	canvas.draw_rect(Rect2(87, 286, 108, 19), Color("e9dac2"))
	for index: int in range(5):
		var sleeve_x: float = 96.0 + float(index) * 17.0
		var sleeve_y: float = 295.0 - float(index % 2) * 4.0
		canvas.draw_line(Vector2(sleeve_x, sleeve_y), Vector2(sleeve_x + 8, sleeve_y - 8), CLOTH, 6.0)
		canvas.draw_line(Vector2(sleeve_x + 8, sleeve_y - 8), Vector2(sleeve_x + 10, sleeve_y - 14), EDGE, 1.0)
	canvas.draw_rect(Rect2(90, 312, 7, 85), WOOD)
	canvas.draw_rect(Rect2(182, 312, 7, 85), WOOD)
	_ribbon_reel(canvas, Vector2(137, 367))
	_pump(canvas)
	# Floorboard seams fade out before the balloon's instruction and string.
	for index: int in range(3):
		var seam_y: float = 428.0 + float(index) * 20.0
		canvas.draw_line(Vector2(0, seam_y), Vector2(274, seam_y), HAZE, 1.0)
		canvas.draw_line(Vector2(684, seam_y), Vector2(960, seam_y), HAZE, 1.0)

func _awning(canvas: Node2D) -> void:
	canvas.draw_rect(Rect2(186, 55, 588, 9), HAZE)
	canvas.draw_rect(Rect2(178, 64, 604, 16), Color("e7cfad"))
	for index: int in range(12):
		var stripe_x: float = 182.0 + float(index) * 50.0
		var tint: Color = CLOTH if index % 2 == 0 else Color("f1e2c8")
		canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(stripe_x, 64), Vector2(stripe_x + 44, 64),
			Vector2(stripe_x + 47, 90), Vector2(stripe_x + 22, 96),
			Vector2(stripe_x - 3, 90),
		]), tint)
	canvas.draw_line(Vector2(178, 64), Vector2(782, 64), WOOD, 2.0)

func _ribbon_reel(canvas: Node2D, position: Vector2) -> void:
	canvas.draw_rect(Rect2(position - Vector2(28, 10), Vector2(56, 21)), CLOTH)
	canvas.draw_rect(Rect2(position - Vector2(31, 15), Vector2(7, 32)), WOOD)
	canvas.draw_rect(Rect2(position + Vector2(24, -15), Vector2(7, 32)), WOOD)
	for index: int in range(6):
		var ribbon_x: float = position.x - 19.0 + float(index) * 7.0
		canvas.draw_line(Vector2(ribbon_x, position.y - 8), Vector2(ribbon_x, position.y + 9), Color("d1ad96"), 1.0)
	canvas.draw_polyline(PackedVector2Array([
		position + Vector2(0, 10), position + Vector2(0, 26),
		position + Vector2(27, 40), position + Vector2(54, 40),
	]), CLOTH, 3.0)

func _pump(canvas: Node2D) -> void:
	# An idle workshop pump explains inflation, placed well outside the live actor.
	canvas.draw_rect(Rect2(788, 394, 93, 10), HAZE)
	canvas.draw_rect(Rect2(819, 300, 35, 86), METAL)
	canvas.draw_rect(Rect2(824, 308, 6, 65), Color("d5dccd"))
	canvas.draw_rect(Rect2(831, 269, 9, 32), EDGE)
	canvas.draw_rect(Rect2(807, 265, 57, 8), WOOD)
	canvas.draw_rect(Rect2(806, 382, 67, 10), WOOD)
	canvas.draw_line(Vector2(819, 301), Vector2(854, 301), EDGE, 2.0)
	canvas.draw_polyline(PackedVector2Array([
		Vector2(855, 372), Vector2(881, 380), Vector2(899, 406),
		Vector2(886, 432), Vector2(852, 444), Vector2(780, 444),
	]), Color("c6b9a4"), 4.0)
	canvas.draw_rect(Rect2(771, 440, 13, 7), METAL)
