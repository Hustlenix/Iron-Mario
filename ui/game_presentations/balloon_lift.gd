extends RefCounted

const TITLE: String = "Balloon Lift"
const SETTING: String = "The rooftop balloon post"
const ACCENT: Color = Color("c98e73")
const SKY: Color = Color("f5f0df")
const DISTANT: Color = Color("e4e7dc")
const PROP: Color = Color("b2b9aa")
const SHADOW: Color = Color("d7d9cb")

func draw_background(canvas: Node2D, context: Dictionary) -> void:
	var board: Rect2 = context.get("board_rect", Rect2(0, 0, 960, 480))
	canvas.draw_rect(board, SKY)
	# Broad cloud banks belong to the distant sky, without enclosed target shapes.
	_cloud(canvas, Vector2(244, 104), 1.15)
	_cloud(canvas, Vector2(499, 382), 1.35)
	_cloud(canvas, Vector2(883, 72), 0.62)
	# The town is far below the flight envelope, seen through warm morning haze.
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0, 468), Vector2(144, 457), Vector2(283, 470),
		Vector2(446, 462), Vector2(623, 471), Vector2(818, 459),
		Vector2(960, 468), Vector2(960, 480), Vector2(0, 480)
	]), DISTANT)
	canvas.draw_rect(Rect2(318, 455, 62, 25), Color("e0e1d2"))
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(310, 455), Vector2(348, 444), Vector2(389, 455)
	]), Color("d9ddcd"))
	canvas.draw_rect(Rect2(329, 463, 11, 13), SKY)
	canvas.draw_rect(Rect2(353, 463, 11, 13), SKY)
	canvas.draw_line(Vector2(429, 478), Vector2(455, 451), DISTANT, 5.0, true)
	canvas.draw_line(Vector2(455, 451), Vector2(481, 478), DISTANT, 5.0, true)
	# Launch-room parapet is tucked below the playable lower boundary.
	canvas.draw_rect(Rect2(0, 446, 106, 34), SHADOW)
	canvas.draw_rect(Rect2(0, 442, 109, 6), Color("c5ccba"))
	for seam: int in range(3):
		var x: float = 12.0 + float(seam) * 32.0
		canvas.draw_line(Vector2(x, 454), Vector2(x, 480), DISTANT, 1.5)
	_fill_station(canvas)
	_windsock(canvas)
	# The actual roof target and blue tower are painted by gameplay at x765..905.
	# This narrow annex reads as the side of that destination, never a landing ledge.
	canvas.draw_rect(Rect2(911, 270, 49, 210), Color("e0dfce"))
	canvas.draw_rect(Rect2(929, 271, 31, 209), Color("d2d6c8"))
	canvas.draw_line(Vector2(914, 282), Vector2(914, 480), PROP, 2.0)
	for row: int in range(4):
		var y: float = 298.0 + float(row) * 40.0
		canvas.draw_rect(Rect2(935, y, 15, 21), Color("bcc9c0"))
		canvas.draw_line(Vector2(942, y), Vector2(942, y + 21), Color("dce2d7"), 2.0)
	canvas.draw_line(Vector2(937, 266), Vector2(937, 167), PROP, 2.5, true)
	canvas.draw_line(Vector2(927, 266), Vector2(937, 231), PROP, 2.0, true)
	canvas.draw_line(Vector2(950, 266), Vector2(937, 231), PROP, 2.0, true)
	canvas.draw_line(Vector2(923, 186), Vector2(953, 186), PROP, 2.0, true)
	canvas.draw_line(Vector2(928, 173), Vector2(947, 173), PROP, 2.0, true)
	canvas.draw_line(Vector2(953, 186), Vector2(957, 182), PROP, 2.0, true)

func _cloud(canvas: Node2D, origin: Vector2, scale: float) -> void:
	var silhouette: PackedVector2Array = PackedVector2Array([
		Vector2(0, 13), Vector2(23, 12), Vector2(35, 2), Vector2(61, 2),
		Vector2(75, -6), Vector2(97, -3), Vector2(109, 10),
		Vector2(150, 13), Vector2(177, 20), Vector2(0, 20)
	])
	for index: int in range(silhouette.size()):
		silhouette[index] = origin + silhouette[index] * scale
	canvas.draw_colored_polygon(silhouette, Color("ebece0"))

func _fill_station(canvas: Node2D) -> void:
	# A helium cylinder, secured straps, valve and coiled hose suggest the departure.
	canvas.draw_rect(Rect2(22, 382, 25, 53), Color("ccd7c8"))
	canvas.draw_arc(Vector2(34.5, 382), 12.5, PI, TAU, 12, PROP, 2.0, true)
	canvas.draw_line(Vector2(22, 382), Vector2(22, 435), PROP, 2.0)
	canvas.draw_line(Vector2(47, 382), Vector2(47, 435), PROP, 2.0)
	canvas.draw_rect(Rect2(19, 398, 31, 5), Color("b6c3b4"))
	canvas.draw_rect(Rect2(19, 421, 31, 5), Color("b6c3b4"))
	canvas.draw_line(Vector2(34, 369), Vector2(34, 378), PROP, 3.0)
	canvas.draw_line(Vector2(28, 369), Vector2(42, 369), PROP, 2.0)
	canvas.draw_polyline(PackedVector2Array([
		Vector2(42, 373), Vector2(62, 373), Vector2(68, 384),
		Vector2(68, 415), Vector2(81, 430), Vector2(97, 430)
	]), PROP, 2.0, true)
	canvas.draw_arc(Vector2(79, 417), 12, -0.7, 4.2, 20, PROP, 2.0, true)
	canvas.draw_line(Vector2(17, 437), Vector2(54, 437), PROP, 2.5)

func _windsock(canvas: Node2D) -> void:
	canvas.draw_line(Vector2(32, 284), Vector2(32, 125), PROP, 2.0, true)
	canvas.draw_line(Vector2(32, 142), Vector2(44, 142), PROP, 2.0, true)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(43, 133), Vector2(66, 136), Vector2(89, 147),
		Vector2(87, 153), Vector2(64, 148), Vector2(43, 150)
	]), Color("d6bcaa"))
	canvas.draw_line(Vector2(43, 133), Vector2(43, 150), PROP, 2.0)
	canvas.draw_line(Vector2(56, 135), Vector2(55, 148), SKY, 3.0)
	canvas.draw_line(Vector2(72, 140), Vector2(69, 149), SKY, 3.0)
	canvas.draw_line(Vector2(20, 285), Vector2(45, 285), SHADOW, 3.0)
