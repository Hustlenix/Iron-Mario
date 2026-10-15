extends RefCounted

const TITLE: String = "Boulder Push"
const SETTING: String = "The park stoneworks delivery yard"
const ACCENT: Color = Color("#a98b66")
const PAPER: Color = Color("#f7efdf")
const FAINT: Color = Color("#e5dcc8")
const EDGE: Color = Color("#b9aa90")
const STONE: Color = Color("#ddd4c2")

func draw_background(canvas: Node2D, _context: Dictionary) -> void:
	canvas.draw_rect(Rect2(0, 0, 960, 480), PAPER)
	# Distant cut-stone terraces stay above the boulder's rolling corridor.
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0, 125), Vector2(90, 125), Vector2(90, 145),
		Vector2(215, 145), Vector2(215, 164), Vector2(350, 164),
		Vector2(350, 191), Vector2(450, 191), Vector2(450, 214),
		Vector2(0, 214)]), Color("#eee5d3"))
	canvas.draw_polyline(PackedVector2Array([
		Vector2(0, 125), Vector2(90, 125), Vector2(90, 145),
		Vector2(215, 145), Vector2(215, 164), Vector2(350, 164),
		Vector2(350, 191), Vector2(450, 191)]), FAINT, 2.0)
	for index: int in range(4):
		var seam_x: float = 35.0 + float(index) * 88.0
		canvas.draw_line(Vector2(seam_x, 181), Vector2(seam_x + 17, 208), FAINT, 1.5)
	canvas.draw_line(Vector2(0, 214), Vector2(960, 214), Color("#eee6d7"), 2.0)
	# A service gantry is parked beyond the right end, well above PARK.
	canvas.draw_rect(Rect2(858, 111, 13, 122), STONE)
	canvas.draw_rect(Rect2(932, 111, 12, 122), STONE)
	canvas.draw_rect(Rect2(845, 99, 110, 16), Color("#d6c5a8"))
	canvas.draw_line(Vector2(846, 100), Vector2(955, 100), EDGE, 2.0)
	canvas.draw_line(Vector2(864, 119), Vector2(884, 140), EDGE, 2.0)
	canvas.draw_line(Vector2(938, 119), Vector2(917, 140), EDGE, 2.0)
	canvas.draw_line(Vector2(901, 115), Vector2(901, 169), EDGE, 2.0)
	canvas.draw_polyline(PackedVector2Array([
		Vector2(901, 169), Vector2(911, 182), Vector2(903, 190),
		Vector2(895, 185)]), EDGE, 2.0)
	canvas.draw_line(Vector2(883, 200), Vector2(896, 189), FAINT, 2.0)
	canvas.draw_line(Vector2(919, 200), Vector2(909, 189), FAINT, 2.0)
	# Small sawn blocks on the far left shelf explain the yard's trade.
	_draw_block(canvas, Rect2(18, 179, 44, 31))
	_draw_block(canvas, Rect2(63, 193, 46, 17))
	canvas.draw_line(Vector2(16, 217), Vector2(117, 217), FAINT, 3.0)
	# The foreground apron starts below the existing y358 ground line.
	canvas.draw_rect(Rect2(0, 389, 960, 91), Color("#eee3d0"))
	canvas.draw_line(Vector2(0, 389), Vector2(960, 389), Color("#e4d8bf"), 2.0)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(82, 480), Vector2(160, 406), Vector2(799, 406),
		Vector2(881, 480)]), Color("#f2e9d8"))
	# Broad paving seams suggest weight-bearing stone, never extra lanes.
	canvas.draw_line(Vector2(136, 445), Vector2(826, 445), FAINT, 1.5)
	canvas.draw_line(Vector2(322, 407), Vector2(300, 480), FAINT, 1.5)
	canvas.draw_line(Vector2(633, 407), Vector2(658, 480), FAINT, 1.5)
	# A chisel tray and mallet occupy only the noninteractive apron.
	canvas.draw_rect(Rect2(17, 416, 100, 37), Color("#dbccb0"))
	canvas.draw_rect(Rect2(22, 421, 90, 26), Color("#eee3cb"))
	canvas.draw_line(Vector2(31, 437), Vector2(62, 426), EDGE, 4.0)
	canvas.draw_line(Vector2(43, 445), Vector2(75, 433), EDGE, 3.0)
	canvas.draw_line(Vector2(93, 425), Vector2(99, 449), Color("#bca583"), 5.0)
	canvas.draw_rect(Rect2(79, 420, 27, 11), EDGE)
	# Rolled lifting straps and a folded sack await the next delivery.
	canvas.draw_rect(Rect2(870, 414, 69, 42), Color("#d9ccb4"))
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(870, 414), Vector2(907, 401), Vector2(939, 414),
		Vector2(910, 424)]), Color("#e4d9c3"))
	canvas.draw_line(Vector2(910, 424), Vector2(910, 456), EDGE, 1.5)
	canvas.draw_arc(Vector2(853, 451), 14.0, 0.0, TAU, 24, EDGE, 4.0)
	canvas.draw_arc(Vector2(853, 451), 7.0, 0.0, TAU, 20, Color("#d3c4a9"), 2.0)
	canvas.draw_line(Vector2(838, 457), Vector2(818, 460), EDGE, 3.0)

func _draw_block(canvas: Node2D, rect: Rect2) -> void:
	var corner: Vector2 = rect.position
	var far_corner: Vector2 = rect.end
	canvas.draw_rect(rect, STONE)
	canvas.draw_colored_polygon(PackedVector2Array([
		corner, corner + Vector2(9, -6),
		Vector2(far_corner.x + 9, corner.y - 6),
		Vector2(far_corner.x, corner.y)]), Color("#e9e0ce"))
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(far_corner.x, corner.y), Vector2(far_corner.x + 9, corner.y - 6),
		far_corner + Vector2(9, -6), far_corner]), Color("#cfc4af"))
	canvas.draw_line(corner, Vector2(far_corner.x, corner.y), EDGE, 1.5)
	canvas.draw_line(corner + Vector2(10, 8), corner + Vector2(27, 11), FAINT, 1.5)
