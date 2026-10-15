extends RefCounted

const TITLE: String = "Catapult Chaos"
const SETTING: String = "Decommissioned reactor proving yard"
const ACCENT: Color = Color("#b88659")
const FIELD: Color = Color("#faf2dd")
const DISTANT: Color = Color("#e8e1ce")
const DETAIL: Color = Color("#d7cfba")
const SERVICE: Color = Color("#eee3c9")

func draw_background(canvas: Node2D, context: Dictionary) -> void:
	var board: Rect2 = context.get("board_rect", Rect2(0, 0, 960, 480))
	canvas.draw_rect(board, FIELD)
	# Preserve the full ballistic field; the only strong ground edge is gameplay's.
	canvas.draw_rect(Rect2(0, 384, 960, 96), Color("#f0e6cf"))
	canvas.draw_rect(Rect2(0, 385, 960, 9), Color("#e9ddc2"))
	canvas.draw_line(Vector2(0, 425), Vector2(960, 425), Color("#e6dac1"), 1.0)
	canvas.draw_line(Vector2(0, 470), Vector2(960, 470), Color("#e6dac1"), 1.0)
	# A pale service gantry identifies the test yard without becoming a platform.
	canvas.draw_rect(Rect2(753, 110, 168, 8), DISTANT)
	canvas.draw_rect(Rect2(763, 118, 7, 57), DISTANT)
	canvas.draw_rect(Rect2(904, 118, 7, 57), DISTANT)
	canvas.draw_line(Vector2(775, 121), Vector2(819, 157), DISTANT, 2.0)
	canvas.draw_line(Vector2(860, 157), Vector2(901, 121), DISTANT, 2.0)
	canvas.draw_rect(Rect2(829, 107, 22, 13), Color("#e3dac5"))
	canvas.draw_line(Vector2(840, 120), Vector2(840, 146), DISTANT, 2.0)
	canvas.draw_polyline(PackedVector2Array([
		Vector2(833, 146), Vector2(840, 153), Vector2(847, 146)
	]), DISTANT, 2.0)
	# Wall-mounted maintenance conduits stay faint and above the pull area.
	canvas.draw_polyline(PackedVector2Array([
		Vector2(25, 122), Vector2(104, 122), Vector2(104, 149), Vector2(137, 149)
	]), DISTANT, 5.0)
	canvas.draw_polyline(PackedVector2Array([
		Vector2(25, 137), Vector2(84, 137), Vector2(84, 161), Vector2(127, 161)
	]), DISTANT, 3.0)
	canvas.draw_rect(Rect2(31, 114, 5, 30), Color("#e6dcc7"))
	canvas.draw_rect(Rect2(65, 114, 5, 30), Color("#e6dcc7"))
	canvas.draw_rect(Rect2(127, 144, 17, 11), DISTANT)
	# Below the actual floor: the launcher service winch and its parked cable.
	canvas.draw_rect(Rect2(32, 403, 98, 20), SERVICE)
	canvas.draw_rect(Rect2(32, 403, 98, 20), DETAIL, false, 1.5)
	canvas.draw_rect(Rect2(38, 399, 7, 25), DETAIL)
	canvas.draw_rect(Rect2(95, 399, 7, 25), DETAIL)
	canvas.draw_rect(Rect2(46, 405, 48, 13), Color("#ded2b8"))
	for index in range(7):
		var cable_x: float = 49.0 + float(index) * 6.0
		canvas.draw_line(Vector2(cable_x, 405), Vector2(cable_x, 418), Color("#cdbfa3"), 1.0)
	canvas.draw_polyline(PackedVector2Array([
		Vector2(104, 411), Vector2(123, 411), Vector2(135, 401), Vector2(160, 401)
	]), DETAIL, 2.0)
	canvas.draw_rect(Rect2(27, 424, 109, 3), Color("#e0d4b9"))
	# Long spare launch beams in a recessed maintenance rack.
	canvas.draw_rect(Rect2(319, 400, 230, 21), Color("#eadfc5"))
	canvas.draw_rect(Rect2(329, 402, 208, 4), Color("#d8c8aa"))
	canvas.draw_rect(Rect2(337, 410, 189, 4), Color("#dfcfb1"))
	canvas.draw_line(Vector2(348, 398), Vector2(348, 421), DETAIL, 3.0)
	canvas.draw_line(Vector2(514, 398), Vector2(514, 421), DETAIL, 3.0)
	# Right-side transport chest and folded lifting sling, safely below the towers.
	canvas.draw_rect(Rect2(849, 401, 77, 23), SERVICE)
	canvas.draw_rect(Rect2(849, 401, 77, 23), DETAIL, false, 1.5)
	canvas.draw_line(Vector2(849, 408), Vector2(926, 408), DETAIL, 1.5)
	canvas.draw_rect(Rect2(861, 400, 4, 25), Color("#d9cbb0"))
	canvas.draw_rect(Rect2(910, 400, 4, 25), Color("#d9cbb0"))
	canvas.draw_rect(Rect2(883, 405, 10, 4), Color("#d2c3a5"))
	canvas.draw_polyline(PackedVector2Array([
		Vector2(773, 418), Vector2(781, 401), Vector2(806, 401),
		Vector2(814, 418), Vector2(773, 418)
	]), DETAIL, 2.0)
	canvas.draw_line(Vector2(783, 418), Vector2(788, 406), DETAIL, 1.0)
	canvas.draw_line(Vector2(804, 418), Vector2(799, 406), DETAIL, 1.0)
	# Small recessed fasteners only in the service apron, never cue-shaped lights.
	for x in [239.0, 601.0, 730.0]:
		var seam_x: float = float(x)
		canvas.draw_line(Vector2(seam_x, 397), Vector2(seam_x, 423), Color("#e1d6bd"), 1.0)
		canvas.draw_rect(Rect2(seam_x - 2.0, 407, 4, 2), DETAIL)
	# Static scenery is identical with reduced motion and cannot advance on pause.
