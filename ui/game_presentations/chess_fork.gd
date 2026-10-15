extends RefCounted

const TITLE: String = "Double Trouble"
const SETTING: String = "The quiet chess-study desk"
const ACCENT: Color = Color("#99794f")
const PAPER: Color = Color("#f5efdf")
const WOOD: Color = Color("#ddccb0")
const EDGE: Color = Color("#b8a486")
const SOFT_INK: Color = Color("#a3957e")

func draw_background(canvas: Node2D, _context: Dictionary) -> void:
	# The original 5 x 5 board occupies x325..635, y65..375.
	# All study props stay beyond its input rectangle and below the instruction.
	canvas.draw_rect(Rect2(0, 0, 960, 480), PAPER)
	canvas.draw_rect(Rect2(0, 78, 960, 310), Color("#f0e7d4"))
	canvas.draw_rect(Rect2(24, 82, 912, 302), Color("#f5efdf"))
	canvas.draw_line(Vector2(0, 80), Vector2(960, 80), Color("#e6dbc5"), 2.0)
	canvas.draw_rect(Rect2(0, 388, 960, 92), Color("#f8f2e5"))
	canvas.draw_line(Vector2(0, 389), Vector2(960, 389), Color("#e4d8c0"), 2.0)
	# Desk edges establish depth without putting grain beneath squares or labels.
	canvas.draw_rect(Rect2(0, 82, 23, 306), WOOD)
	canvas.draw_rect(Rect2(937, 82, 23, 306), WOOD)
	for index: int in range(3):
		var edge_x: float = 6.0 + float(index) * 5.0
		canvas.draw_line(Vector2(edge_x, 94), Vector2(edge_x, 376), Color("#cdbb9e"), 1.0)
		canvas.draw_line(Vector2(960.0 - edge_x, 94), Vector2(960.0 - edge_x, 376), Color("#cdbb9e"), 1.0)
	# A shallow wooden board tray; the gameplay still paints every actual square.
	canvas.draw_rect(Rect2(316, 60, 328, 323), Color("#d7c7ab"))
	canvas.draw_rect(Rect2(320, 61, 320, 318), Color("#ede4ce"))
	canvas.draw_line(Vector2(317, 381), Vector2(643, 381), EDGE, 2.0)
	_draw_clock(canvas, Vector2(91, 138))
	_draw_books(canvas, Vector2(99, 264))
	_draw_storage_case(canvas, Vector2(710, 138))
	_draw_scoresheet(canvas, Vector2(715, 315))

func _draw_clock(canvas: Node2D, origin: Vector2) -> void:
	# A single twin-faced clock housing reads as equipment, not another puzzle.
	canvas.draw_rect(Rect2(origin + Vector2(5, 7), Vector2(181, 81)), Color("#e5dbc7"))
	canvas.draw_rect(Rect2(origin, Vector2(181, 81)), WOOD)
	canvas.draw_rect(Rect2(origin + Vector2(6, 7), Vector2(169, 66)), Color("#eae0cc"))
	canvas.draw_rect(Rect2(origin, Vector2(181, 81)), EDGE, false, 2.0)
	for index: int in range(2):
		var center: Vector2 = origin + Vector2(47.0 + float(index) * 87.0, 40)
		canvas.draw_circle(center, 26.0, Color("#f7f0e0"))
		canvas.draw_arc(center, 26.0, 0.0, TAU, 32, SOFT_INK, 1.5, true)
		for mark: int in range(4):
			var angle: float = float(mark) * PI * 0.5
			canvas.draw_line(center + Vector2.from_angle(angle) * 21.0, center + Vector2.from_angle(angle) * 24.0, SOFT_INK, 1.5)
		canvas.draw_line(center, center + Vector2(-9, -10), SOFT_INK, 2.0)
		canvas.draw_line(center, center + Vector2(12, -5), SOFT_INK, 1.5)
	canvas.draw_rect(Rect2(origin + Vector2(28, -5), Vector2(38, 5)), EDGE)
	canvas.draw_rect(Rect2(origin + Vector2(116, -5), Vector2(38, 5)), EDGE)
	canvas.draw_rect(Rect2(origin + Vector2(17, 81), Vector2(17, 6)), EDGE)
	canvas.draw_rect(Rect2(origin + Vector2(145, 81), Vector2(17, 6)), EDGE)

func _draw_books(canvas: Node2D, origin: Vector2) -> void:
	var covers: Array[Color] = [Color("#c8d1c4"), Color("#d4bfa0"), Color("#d7cec1")]
	for index: int in range(3):
		var offset: Vector2 = Vector2(float(index % 2) * 8.0, float(index) * 24.0)
		var corner: Vector2 = origin + offset
		canvas.draw_rect(Rect2(corner + Vector2(3, 4), Vector2(148, 23)), Color("#e3d8c2"))
		canvas.draw_rect(Rect2(corner, Vector2(148, 21)), covers[index])
		canvas.draw_rect(Rect2(corner + Vector2(15, 4), Vector2(130, 13)), Color("#f3ebd8"))
		canvas.draw_line(corner + Vector2(20, 10), corner + Vector2(140, 10), Color("#ddd2bb"), 1.0)
		canvas.draw_rect(Rect2(corner, Vector2(148, 21)), EDGE, false, 1.5)
		canvas.draw_line(corner + Vector2(12, 2), corner + Vector2(12, 19), EDGE, 1.5)
	# Cloth bookmark tucked into the top volume, without readable invented text.
	canvas.draw_colored_polygon(PackedVector2Array([origin + Vector2(93, 17), origin + Vector2(108, 17), origin + Vector2(108, 34), origin + Vector2(100, 29), origin + Vector2(93, 34)]), Color("#b6c1ad"))

func _draw_storage_case(canvas: Node2D, origin: Vector2) -> void:
	canvas.draw_rect(Rect2(origin + Vector2(5, 6), Vector2(171, 148)), Color("#e6dcc7"))
	canvas.draw_rect(Rect2(origin, Vector2(171, 148)), WOOD)
	canvas.draw_rect(Rect2(origin + Vector2(10, 10), Vector2(151, 127)), Color("#e8dfcb"))
	canvas.draw_rect(Rect2(origin, Vector2(171, 148)), EDGE, false, 2.0)
	# Empty fitted storage bays are offset and subdued, with no spare chess actors.
	for index: int in range(3):
		var bay: Rect2 = Rect2(origin + Vector2(20.0 + float(index) * 45.0, 24), Vector2(31, 90))
		canvas.draw_rect(bay, Color("#dfd4bf"))
		canvas.draw_line(bay.position + Vector2(3, 2), bay.position + Vector2(3, 88), Color("#d0c2a9"), 1.0)
	canvas.draw_rect(Rect2(origin + Vector2(72, 142), Vector2(27, 5)), EDGE)

func _draw_scoresheet(canvas: Node2D, origin: Vector2) -> void:
	canvas.draw_rect(Rect2(origin + Vector2(4, 4), Vector2(160, 54)), Color("#e5dcc9"))
	canvas.draw_rect(Rect2(origin, Vector2(160, 54)), Color("#faf6ea"))
	canvas.draw_rect(Rect2(origin, Vector2(160, 54)), Color("#d6c9b0"), false, 1.0)
	for row: int in range(4):
		var line_y: float = origin.y + 11.0 + float(row) * 9.0
		canvas.draw_line(Vector2(origin.x + 12, line_y), Vector2(origin.x + 145, line_y), Color("#e3dccd"), 1.0)
	canvas.draw_line(origin + Vector2(72, 7), origin + Vector2(72, 46), Color("#e3dccd"), 1.0)
	canvas.draw_line(origin + Vector2(122, 44), origin + Vector2(170, 23), Color("#b9aa91"), 4.0)
	canvas.draw_line(origin + Vector2(122, 44), origin + Vector2(116, 47), SOFT_INK, 2.0)
