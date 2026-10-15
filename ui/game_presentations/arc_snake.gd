extends RefCounted

const TITLE: String = "Arc Snake"
const SETTING: String = "Reactor inspection tray on a coolant service bench"
const ACCENT: Color = Color("#91a88c")

# The playable grid and controls are painted by the cabinet after this backdrop.
# All hardware stays outside BOARD.grow(5) and the three existing button areas.
func draw_background(canvas: Node2D, context: Dictionary) -> void:
	var board: Rect2 = context.get("board_rect", Rect2(0, 0, 960, 480))
	var paper: Color = Color("#f8f2e3")
	var wall: Color = Color("#e8e9dc")
	var metal: Color = Color("#d9dfd0")
	var seam: Color = Color("#bfcbb8")
	var shadow: Color = Color("#e1dfcd")
	var copper: Color = Color("#d3bea2")
	canvas.draw_rect(board, paper)
	# A light rear wall and bench depth remain visible in the narrow side margins.
	canvas.draw_rect(Rect2(0, 104, 88, 275), wall)
	canvas.draw_rect(Rect2(872, 104, 88, 275), wall)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0, 379), Vector2(87, 368), Vector2(873, 368),
		Vector2(960, 379), Vector2(960, 480), Vector2(0, 480)
	]), shadow)
	# Recessed tray bevel: foreground black rim remains the sole collision boundary.
	canvas.draw_rect(Rect2(85, 96, 5, 280), metal)
	canvas.draw_rect(Rect2(870, 96, 5, 280), metal)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(85, 376), Vector2(90, 384), Vector2(870, 384),
		Vector2(875, 376), Vector2(875, 387), Vector2(85, 387)
	]), seam)
	# Left coolant expansion vessel: rectangular neck, insulated body, return elbow.
	canvas.draw_rect(Rect2(36, 116, 15, 22), seam)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(24, 139), Vector2(62, 139), Vector2(69, 153),
		Vector2(69, 235), Vector2(62, 251), Vector2(24, 251),
		Vector2(17, 235), Vector2(17, 153)
	]), metal)
	canvas.draw_polyline(PackedVector2Array([
		Vector2(24, 139), Vector2(62, 139), Vector2(69, 153),
		Vector2(69, 235), Vector2(62, 251), Vector2(24, 251),
		Vector2(17, 235), Vector2(17, 153), Vector2(24, 139)
	]), seam, 2.0, true)
	canvas.draw_line(Vector2(22, 167), Vector2(64, 167), seam, 4.0)
	canvas.draw_line(Vector2(22, 221), Vector2(64, 221), seam, 4.0)
	canvas.draw_rect(Rect2(28, 176, 8, 35), wall)
	canvas.draw_polyline(PackedVector2Array([
		Vector2(44, 253), Vector2(44, 271), Vector2(76, 271), Vector2(76, 309)
	]), copper, 8.0, true)
	canvas.draw_rect(Rect2(37, 259, 14, 8), seam)
	canvas.draw_rect(Rect2(69, 286, 14, 8), seam)
	# Folded hose on an edge-only rack, not another snake in the playable grid.
	canvas.draw_rect(Rect2(12, 294, 43, 67), metal)
	for index: int in range(4):
		var hose_y: float = 306.0 + float(index) * 12.0
		canvas.draw_polyline(PackedVector2Array([
			Vector2(18, hose_y), Vector2(43, hose_y),
			Vector2(49, hose_y + 6), Vector2(18, hose_y + 6)
		]), copper, 3.0, true)
	canvas.draw_rect(Rect2(23, 294, 6, 67), seam)
	# Right return heat exchanger: fins and a cropped rear pipe add mechanical depth.
	canvas.draw_polyline(PackedVector2Array([
		Vector2(960, 119), Vector2(946, 119), Vector2(946, 148), Vector2(932, 148)
	]), copper, 8.0, true)
	canvas.draw_rect(Rect2(889, 140, 48, 110), metal)
	canvas.draw_rect(Rect2(889, 140, 7, 110), seam)
	for index: int in range(7):
		var fin_y: float = 151.0 + float(index) * 13.0
		canvas.draw_line(Vector2(901, fin_y), Vector2(930, fin_y), seam, 3.0)
	canvas.draw_polyline(PackedVector2Array([
		Vector2(913, 251), Vector2(913, 270), Vector2(941, 270), Vector2(941, 299)
	]), copper, 7.0, true)
	# Service hatch with broad louvers; no colored indicators resembling reactor food.
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(889, 300), Vector2(939, 300), Vector2(949, 307),
		Vector2(949, 358), Vector2(889, 358)
	]), metal)
	canvas.draw_rect(Rect2(939, 307, 10, 51), seam)
	for index: int in range(3):
		var hatch_y: float = 314.0 + float(index) * 12.0
		canvas.draw_line(Vector2(899, hatch_y), Vector2(930, hatch_y), seam, 3.0)
	# Bench ventilation occupies only the two gaps between existing touch buttons.
	for gap_x: float in [263.0, 608.0]:
		canvas.draw_rect(Rect2(gap_x, 405, 89, 58), metal)
		for index: int in range(4):
			var vent_y: float = 415.0 + float(index) * 12.0
			canvas.draw_line(Vector2(gap_x + 10.0, vent_y), Vector2(gap_x + 79.0, vent_y), seam, 3.0)
	# Static drawing is identical during pause and with reduced motion enabled.
