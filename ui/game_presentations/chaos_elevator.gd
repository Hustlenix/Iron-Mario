extends RefCounted

const TITLE: String = "Chaos Elevator"
const SETTING: String = "The parcel hotel lift atrium"
const ACCENT: Color = Color("#b48b59")
const PAPER: Color = Color("#f8f0df")
const WALL: Color = Color("#eee5d3")
const RECESS: Color = Color("#e3ddcd")
const EDGE: Color = Color("#c1baaa")
const METAL: Color = Color("#b5c7c6")
const SOFT_METAL: Color = Color("#d5dfda")

func draw_background(canvas: Node2D, context: Dictionary) -> void:
	var board: Rect2 = context.get("board_rect", Rect2(0, 0, 960, 480))
	canvas.draw_rect(board, PAPER)
	# A shallow atrium surrounds the four existing landings and moving lift.
	canvas.draw_rect(Rect2(30, 70, 900, 290), WALL)
	canvas.draw_rect(Rect2(105, 80, 705, 275), PAPER)
	canvas.draw_rect(Rect2(105, 80, 8, 275), RECESS)
	canvas.draw_rect(Rect2(802, 80, 8, 275), RECESS)
	canvas.draw_rect(Rect2(30, 70, 900, 9), RECESS)
	canvas.draw_line(Vector2(30, 360), Vector2(930, 360), EDGE, 2.0)
	# Pale shaft rails describe the mechanism without obscuring its gold car.
	canvas.draw_rect(Rect2(375, 95, 156, 259), Color("#f2ead9"))
	canvas.draw_line(Vector2(378, 95), Vector2(378, 353), RECESS, 3.0)
	canvas.draw_line(Vector2(528, 95), Vector2(528, 353), RECESS, 3.0)
	canvas.draw_line(Vector2(423, 103), Vector2(423, 350), Color("#ded8c7"), 1.0)
	canvas.draw_line(Vector2(482, 103), Vector2(482, 350), Color("#ded8c7"), 1.0)
	# Ceiling machine: a quiet recessed pulley and its maintenance hatch.
	canvas.draw_rect(Rect2(350, 80, 204, 25), RECESS)
	canvas.draw_circle(Vector2(452, 92), 10.0, EDGE)
	canvas.draw_circle(Vector2(452, 92), 6.0, WALL)
	canvas.draw_line(Vector2(446, 88), Vector2(458, 97), EDGE, 1.0)
	canvas.draw_rect(Rect2(359, 85, 28, 13), SOFT_METAL)
	for vent_index in range(4):
		var vent_x: float = 364.0 + float(vent_index) * 5.0
		canvas.draw_line(Vector2(vent_x, 88), Vector2(vent_x, 95), EDGE, 1.0)
	# Far-left pigeonholes imply a busy hotel receiving unusual parcels.
	canvas.draw_rect(Rect2(42, 95, 49, 94), RECESS)
	canvas.draw_rect(Rect2(47, 100, 39, 84), Color("#ddd5c3"))
	for row_index in range(4):
		var shelf_y: float = 102.0 + float(row_index) * 20.0
		canvas.draw_rect(Rect2(50, shelf_y, 33, 15), PAPER)
		canvas.draw_line(Vector2(50, shelf_y + 15), Vector2(83, shelf_y + 15), EDGE, 1.0)
	canvas.draw_rect(Rect2(53, 106, 22, 8), Color("#d1b99a"))
	canvas.draw_line(Vector2(56, 110), Vector2(72, 110), WALL, 1.0)
	canvas.draw_rect(Rect2(62, 147, 17, 8), METAL)
	# A narrow valet trolley and two mismatched cases stay outside floor labels.
	canvas.draw_line(Vector2(47, 265), Vector2(47, 345), METAL, 3.0)
	canvas.draw_line(Vector2(88, 265), Vector2(88, 345), METAL, 3.0)
	canvas.draw_arc(Vector2(67.5, 265), 20.5, PI, TAU, 16, METAL, 3.0)
	canvas.draw_rect(Rect2(43, 337, 49, 5), METAL)
	_case(canvas, Rect2(50, 305, 32, 29), Color("#d9bf9b"))
	_case(canvas, Rect2(55, 283, 25, 19), SOFT_METAL)
	canvas.draw_circle(Vector2(50, 349), 4.0, EDGE)
	canvas.draw_circle(Vector2(85, 349), 4.0, EDGE)
	# A glazed side well exposes the lift's counterweight, far from passengers.
	canvas.draw_rect(Rect2(832, 88, 44, 199), RECESS)
	canvas.draw_rect(Rect2(836, 92, 36, 190), Color("#e9ede5"))
	canvas.draw_line(Vector2(843, 94), Vector2(843, 278), METAL, 2.0)
	canvas.draw_line(Vector2(865, 94), Vector2(865, 278), METAL, 2.0)
	canvas.draw_line(Vector2(854, 96), Vector2(854, 173), EDGE, 1.0)
	for weight_index in range(5):
		var weight_y: float = 174.0 + float(weight_index) * 9.0
		canvas.draw_rect(Rect2(842, weight_y, 24, 7), METAL)
	canvas.draw_line(Vector2(834, 281), Vector2(874, 281), EDGE, 2.0)
	# Folded service cloths and a wall-mounted oil can explain routine upkeep.
	canvas.draw_rect(Rect2(886, 111, 29, 4), EDGE)
	canvas.draw_line(Vector2(893, 115), Vector2(893, 132), EDGE, 1.0)
	canvas.draw_rect(Rect2(889, 132, 12, 17), Color("#cfb898"))
	canvas.draw_line(Vector2(900, 136), Vector2(909, 128), EDGE, 2.0)
	canvas.draw_rect(Rect2(885, 309, 32, 40), RECESS)
	canvas.draw_rect(Rect2(890, 314, 22, 7), SOFT_METAL)
	canvas.draw_rect(Rect2(890, 325, 22, 7), METAL)
	canvas.draw_rect(Rect2(890, 336, 22, 7), SOFT_METAL)
	# Static architecture also retains the same hierarchy with reduced motion.

func _case(canvas: Node2D, bounds: Rect2, fill: Color) -> void:
	canvas.draw_rect(bounds, fill)
	canvas.draw_rect(bounds, EDGE, false, 1.0)
	var mid_x: float = bounds.position.x + bounds.size.x * 0.5
	canvas.draw_rect(Rect2(mid_x - 5, bounds.position.y - 4, 10, 4), EDGE, false, 1.0)
	canvas.draw_line(Vector2(mid_x - 7, bounds.position.y + 2), Vector2(mid_x - 7, bounds.end.y - 2), WALL, 2.0)
	canvas.draw_line(Vector2(mid_x + 7, bounds.position.y + 2), Vector2(mid_x + 7, bounds.end.y - 2), WALL, 2.0)
