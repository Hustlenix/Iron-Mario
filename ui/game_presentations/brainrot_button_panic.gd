extends RefCounted

const TITLE: String = "Brainrot Button Panic"
const SETTING: String = "The overloaded instruction desk"
const ACCENT: Color = Color("#b89b73")
const WALL: Color = Color("#f4f0e4")
const SURFACE: Color = Color("#fff6e4")
const SEAM: Color = Color("#dbd3be")
const EDGE: Color = Color("#b5ac98")
const MACHINE: Color = Color("#d4d8cb")
const SHEET: Color = Color("#fffaf0")

func draw_background(canvas: Node2D, context: Dictionary) -> void:
	var board: Rect2 = context.get("board_rect", Rect2(0, 0, 960, 480))
	canvas.draw_rect(board, WALL)
	# The existing instruction remains on a blank wall; the desk recedes below it.
	canvas.draw_rect(Rect2(0, 177, 960, 10), Color("#e4decf"))
	canvas.draw_rect(Rect2(0, 187, 960, 203), SURFACE)
	canvas.draw_rect(Rect2(0, 390, 960, 13), Color("#e8ddc4"))
	canvas.draw_rect(Rect2(0, 403, 960, 77), Color("#f8f0df"))
	canvas.draw_line(Vector2(0, 390), Vector2(960, 390), SEAM, 2.0)
	canvas.draw_line(Vector2(142, 403), Vector2(124, 480), Color("#ede4d2"), 2.0)
	canvas.draw_line(Vector2(818, 403), Vector2(836, 480), Color("#ede4d2"), 2.0)
	_draw_intake(canvas)
	_draw_receipt_machine(canvas)
	_draw_cable(canvas, PackedVector2Array([Vector2(42, 177), Vector2(42, 355), Vector2(75, 369), Vector2(193, 369)]))
	_draw_cable(canvas, PackedVector2Array([Vector2(924, 178), Vector2(924, 357), Vector2(890, 374), Vector2(739, 374)]))
	# Maintenance hardware is confined to the desk rim, away from the pads.
	for y: int in [231, 250, 269, 288, 307]:
		canvas.draw_line(Vector2(15, y), Vector2(26, y), SEAM, 2.0)
		canvas.draw_line(Vector2(935, y), Vector2(946, y), SEAM, 2.0)
	_draw_spilled_papers(canvas)
	_draw_eraser(canvas)

func _draw_intake(canvas: Node2D) -> void:
	# A printer swallowing contradictory paperwork, visibly overstuffed.
	canvas.draw_rect(Rect2(17, 103, 123, 72), Color("#e3e1d4"))
	canvas.draw_rect(Rect2(14, 98, 119, 68), MACHINE)
	canvas.draw_rect(Rect2(14, 98, 119, 68), EDGE, false, 2.0)
	canvas.draw_rect(Rect2(24, 108, 99, 13), Color("#babeb3"))
	canvas.draw_line(Vector2(28, 115), Vector2(119, 115), EDGE, 2.0)
	var folded: PackedVector2Array = PackedVector2Array([Vector2(37, 111), Vector2(29, 70), Vector2(51, 76), Vector2(69, 63), Vector2(76, 81), Vector2(105, 73), Vector2(112, 111)])
	canvas.draw_colored_polygon(folded, SHEET)
	canvas.draw_polyline(folded, SEAM, 2.0)
	canvas.draw_line(Vector2(51, 76), Vector2(57, 105), SEAM, 1.0)
	canvas.draw_line(Vector2(76, 81), Vector2(83, 105), SEAM, 1.0)
	canvas.draw_line(Vector2(39, 89), Vector2(48, 90), SEAM, 2.0)
	canvas.draw_line(Vector2(87, 87), Vector2(99, 85), SEAM, 2.0)
	canvas.draw_rect(Rect2(25, 139, 96, 10), Color("#b9bdae"))
	canvas.draw_rect(Rect2(49, 150, 47, 17), Color("#e6deca"))
	canvas.draw_line(Vector2(49, 166), Vector2(96, 166), EDGE, 2.0)
	for x: int in [25, 120]:
		canvas.draw_line(Vector2(x, 155), Vector2(x + 4, 155), EDGE, 2.0)

func _draw_receipt_machine(canvas: Node2D) -> void:
	canvas.draw_rect(Rect2(868, 89, 77, 82), Color("#e2dfd0"))
	canvas.draw_rect(Rect2(864, 85, 77, 80), Color("#d9d3bd"))
	canvas.draw_rect(Rect2(864, 85, 77, 80), EDGE, false, 2.0)
	canvas.draw_rect(Rect2(875, 100, 56, 10), Color("#b8b39e"))
	var ribbon: PackedVector2Array = PackedVector2Array([Vector2(882, 104), Vector2(881, 56), Vector2(896, 47), Vector2(911, 51), Vector2(917, 62), Vector2(915, 104)])
	canvas.draw_colored_polygon(ribbon, SHEET)
	canvas.draw_polyline(ribbon, SEAM, 1.5)
	for y: int in [66, 74, 82, 90]:
		canvas.draw_line(Vector2(888, y), Vector2(908, y), SEAM, 1.5)
	canvas.draw_line(Vector2(875, 127), Vector2(931, 127), EDGE, 2.0)
	canvas.draw_line(Vector2(875, 134), Vector2(931, 134), SEAM, 2.0)
	canvas.draw_line(Vector2(875, 141), Vector2(920, 141), SEAM, 2.0)
	canvas.draw_rect(Rect2(876, 154, 51, 11), Color("#e9e0cb"))

func _draw_cable(canvas: Node2D, points: PackedVector2Array) -> void:
	canvas.draw_polyline(points, Color("#e1d9c5"), 6.0, true)
	canvas.draw_polyline(points, Color("#cec6b3"), 2.0, true)

func _draw_spilled_papers(canvas: Node2D) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(21, 416), Vector2(99, 403), Vector2(112, 446), Vector2(35, 456)]), Color("#e7ddc8"))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(17, 404), Vector2(92, 399), Vector2(103, 439), Vector2(29, 448)]), SHEET)
	canvas.draw_polyline(PackedVector2Array([Vector2(17, 404), Vector2(92, 399), Vector2(103, 439), Vector2(29, 448), Vector2(17, 404)]), SEAM, 1.5)
	for y: int in [415, 423, 431]:
		canvas.draw_line(Vector2(34, y), Vector2(78, y - 4), SEAM, 1.5)
	canvas.draw_line(Vector2(81, 400), Vector2(83, 411), EDGE, 2.0)
	canvas.draw_line(Vector2(87, 400), Vector2(89, 410), EDGE, 2.0)

func _draw_eraser(canvas: Node2D) -> void:
	# An absurdly chunky eraser has worn a shallow groove into the desk edge.
	canvas.draw_line(Vector2(859, 431), Vector2(940, 431), Color("#e5dac5"), 5.0)
	canvas.draw_rect(Rect2(867, 397, 66, 29), Color("#dfd5c1"))
	canvas.draw_rect(Rect2(864, 392, 66, 29), Color("#e7c6b2"))
	canvas.draw_rect(Rect2(880, 392, 33, 29), Color("#d8d3bc"))
	canvas.draw_rect(Rect2(864, 392, 66, 29), Color("#c4b39d"), false, 2.0)
	canvas.draw_line(Vector2(884, 400), Vector2(908, 400), Color("#bfb69f"), 2.0)
	canvas.draw_line(Vector2(884, 408), Vector2(901, 408), Color("#bfb69f"), 2.0)
