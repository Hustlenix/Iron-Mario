extends RefCounted

const TITLE: String = "Armor Repair"
const SETTING: String = "Daylight armor service workshop"
const ACCENT: Color = Color("b68956")
const PAPER: Color = Color("f7eedc")
const WALL: Color = Color("e8dfcd")
const LINE: Color = Color("b8af9f")
const STEEL: Color = Color("c7c9be")
const SHADE: Color = Color("d4cbb9")

func draw_background(canvas: Node2D, _context: Dictionary) -> void:
	canvas.draw_rect(Rect2(0, 0, 960, 480), PAPER)
	# Rear wall and shallow floor: quiet throughout the dragging corridor.
	canvas.draw_rect(Rect2(0, 86, 110, 343), WALL)
	canvas.draw_rect(Rect2(790, 86, 170, 343), WALL)
	canvas.draw_rect(Rect2(0, 429, 960, 51), Color("eee3cc"))
	canvas.draw_line(Vector2(0, 429), Vector2(960, 429), SHADE, 2.0)
	canvas.draw_line(Vector2(110, 86), Vector2(110, 429), SHADE, 2.0)
	canvas.draw_line(Vector2(790, 86), Vector2(790, 429), SHADE, 2.0)
	for index: int in range(3):
		var seam_y: float = 178.0 + float(index) * 87.0
		canvas.draw_line(Vector2(0, seam_y), Vector2(107, seam_y), SHADE, 1.0)
		canvas.draw_line(Vector2(793, seam_y), Vector2(960, seam_y), SHADE, 1.0)
	# An overhead task light stays above the existing instruction line.
	canvas.draw_rect(Rect2(254, 9, 456, 10), STEEL)
	canvas.draw_rect(Rect2(269, 19, 426, 5), Color("e4d6b5"))
	canvas.draw_line(Vector2(312, 0), Vector2(312, 9), LINE, 2.0)
	canvas.draw_line(Vector2(650, 0), Vector2(650, 9), LINE, 2.0)
	# Side pegboard: distinct repair tools, never numbered round targets.
	_panel(canvas, Rect2(22, 105, 72, 202), Color("dacdb7"))
	for row: int in range(7):
		for column: int in range(3):
			var peg: Vector2 = Vector2(34.0 + float(column) * 20.0, 119.0 + float(row) * 27.0)
			canvas.draw_rect(Rect2(peg, Vector2(2, 2)), LINE)
	_wrench(canvas, Vector2(41, 137))
	canvas.draw_line(Vector2(75, 152), Vector2(75, 195), LINE, 6.0)
	canvas.draw_rect(Rect2(67, 139, 16, 13), STEEL)
	canvas.draw_rect(Rect2(72, 195, 6, 17), ACCENT)
	canvas.draw_line(Vector2(39, 239), Vector2(63, 262), LINE, 5.0)
	canvas.draw_line(Vector2(65, 240), Vector2(40, 261), LINE, 5.0)
	canvas.draw_line(Vector2(39, 264), Vector2(35, 279), ACCENT, 5.0)
	canvas.draw_line(Vector2(63, 264), Vector2(68, 279), ACCENT, 5.0)
	# A compact bench vise and rag sit in the left margin.
	canvas.draw_rect(Rect2(15, 394, 87, 8), SHADE)
	canvas.draw_rect(Rect2(25, 402, 9, 26), LINE)
	canvas.draw_rect(Rect2(84, 402, 9, 26), LINE)
	canvas.draw_rect(Rect2(29, 374, 40, 18), STEEL)
	canvas.draw_rect(Rect2(33, 359, 8, 17), LINE)
	canvas.draw_rect(Rect2(60, 359, 8, 17), LINE)
	canvas.draw_line(Vector2(47, 383), Vector2(81, 383), LINE, 3.0)
	canvas.draw_line(Vector2(80, 377), Vector2(80, 389), LINE, 3.0)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(70, 394), Vector2(83, 373), Vector2(97, 377), Vector2(94, 394)]), Color("d8c3aa"))
	# Daylight enters a recessed high window beyond the service stand.
	_panel(canvas, Rect2(820, 104, 110, 78), Color("d6dfdc"))
	canvas.draw_rect(Rect2(826, 110, 98, 66), Color("e7eeea"))
	canvas.draw_line(Vector2(875, 110), Vector2(875, 176), STEEL, 4.0)
	canvas.draw_line(Vector2(826, 143), Vector2(924, 143), STEEL, 4.0)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(827, 111), Vector2(865, 111), Vector2(827, 148)]), Color("f4f6ed"))
	# Service gantry at the right edge; its arm stops outside the hero.
	canvas.draw_rect(Rect2(796, 212, 11, 213), STEEL)
	canvas.draw_rect(Rect2(796, 211, 115, 9), STEEL)
	canvas.draw_rect(Rect2(889, 220, 8, 29), LINE)
	canvas.draw_line(Vector2(893, 249), Vector2(917, 275), LINE, 3.0)
	canvas.draw_line(Vector2(917, 275), Vector2(917, 312), LINE, 3.0)
	canvas.draw_rect(Rect2(909, 306, 15, 20), Color("c5b393"))
	canvas.draw_rect(Rect2(783, 423, 35, 6), SHADE)
	# Slanted parts trays reinforce assembly without imitating sockets.
	canvas.draw_rect(Rect2(830, 352, 109, 10), LINE)
	canvas.draw_rect(Rect2(836, 362, 8, 65), STEEL)
	canvas.draw_rect(Rect2(924, 362, 8, 65), STEEL)
	_tray(canvas, Vector2(835, 325), 40.0)
	_tray(canvas, Vector2(887, 325), 40.0)
	canvas.draw_rect(Rect2(846, 331, 18, 6), STEEL)
	canvas.draw_rect(Rect2(897, 331, 19, 6), Color("d5bd8f"))
	canvas.draw_rect(Rect2(846, 387, 70, 29), Color("d5c8b1"))
	canvas.draw_rect(Rect2(867, 394, 28, 4), LINE)
	# Only pale floor perspective below the play objects and score.
	canvas.draw_line(Vector2(111, 429), Vector2(90, 480), SHADE, 1.0)
	canvas.draw_line(Vector2(790, 429), Vector2(810, 480), SHADE, 1.0)
	canvas.draw_line(Vector2(0, 460), Vector2(105, 460), SHADE, 1.0)
	canvas.draw_line(Vector2(890, 460), Vector2(960, 460), SHADE, 1.0)

func _panel(canvas: Node2D, rect: Rect2, fill: Color) -> void:
	canvas.draw_rect(Rect2(rect.position + Vector2(3, 4), rect.size), SHADE)
	canvas.draw_rect(rect, fill)
	canvas.draw_rect(rect, LINE, false, 2.0)

func _wrench(canvas: Node2D, origin: Vector2) -> void:
	canvas.draw_line(origin + Vector2(0, 12), origin + Vector2(0, 51), LINE, 7.0)
	canvas.draw_line(origin + Vector2(-8, 0), origin + Vector2(-8, 10), LINE, 5.0)
	canvas.draw_line(origin + Vector2(8, 0), origin + Vector2(8, 10), LINE, 5.0)
	canvas.draw_line(origin + Vector2(-8, 10), origin + Vector2(8, 10), LINE, 5.0)

func _tray(canvas: Node2D, origin: Vector2, width: float) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([origin, origin + Vector2(width, 0), origin + Vector2(width - 4.0, 22), origin + Vector2(4, 22)]), Color("d5c4a8"))
	canvas.draw_line(origin, origin + Vector2(width, 0), LINE, 2.0)
	canvas.draw_line(origin + Vector2(4, 22), origin + Vector2(width - 4.0, 22), LINE, 2.0)
