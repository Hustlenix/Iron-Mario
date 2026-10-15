extends RefCounted

const TITLE: String = "Bridge Builder"
const SETTING: String = "Canal crossing construction yard"
const ACCENT: Color = Color("#6da8a3")
const WASH: Color = Color("#f5efdf")
const DISTANT: Color = Color("#e4e1ce")
const EDGE: Color = Color("#aea990")
const WATER: Color = Color("#e0ece5")

func draw_background(canvas: Node2D, _context: Dictionary) -> void:
	canvas.draw_rect(Rect2(0, 0, 960, 480), WASH)
	# Pale embankments stay well behind the real bridge endpoints.
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0, 250), Vector2(42, 233), Vector2(79, 239),
		Vector2(106, 265), Vector2(106, 312), Vector2(0, 312)
	]), DISTANT)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(644, 279), Vector2(718, 259), Vector2(791, 264),
		Vector2(856, 245), Vector2(960, 251), Vector2(960, 321),
		Vector2(644, 321)
	]), Color("#e9e5d6"))
	canvas.draw_line(Vector2(656, 287), Vector2(838, 278), Color("#dbd9c8"), 2.0)
	canvas.draw_line(Vector2(17, 268), Vector2(80, 256), Color("#d7d6c2"), 2.0)
	# The canal occupies the depth beneath the playable rooftop/pier level.
	canvas.draw_rect(Rect2(0, 353, 960, 127), WATER)
	canvas.draw_rect(Rect2(0, 353, 960, 18), Color("#e9eee0"))
	for index: int in range(8):
		var ripple_x: float = 27.0 + float(index) * 119.0
		var ripple_y: float = 395.0 + float(index % 3) * 26.0
		canvas.draw_line(Vector2(ripple_x, ripple_y), Vector2(ripple_x + 46.0, ripple_y), Color("#cbded5"), 2.0)
		canvas.draw_line(Vector2(ripple_x + 16.0, ripple_y + 6.0), Vector2(ripple_x + 69.0, ripple_y + 6.0), Color("#d3e3da"), 1.0)
	# A cable hoist belongs to the far service bank, outside the action span.
	canvas.draw_rect(Rect2(885, 247, 75, 233), Color("#e2deca"))
	canvas.draw_line(Vector2(899, 272), Vector2(960, 259), EDGE, 2.0)
	canvas.draw_line(Vector2(917, 132), Vector2(917, 364), EDGE, 5.0)
	canvas.draw_line(Vector2(930, 132), Vector2(930, 364), EDGE, 5.0)
	for index: int in range(6):
		var brace_y: float = 151.0 + float(index) * 34.0
		canvas.draw_line(Vector2(917, brace_y), Vector2(930, brace_y + 23.0), Color("#c0baa0"), 2.0)
	canvas.draw_line(Vector2(866, 133), Vector2(946, 133), EDGE, 4.0)
	canvas.draw_line(Vector2(873, 133), Vector2(917, 104), EDGE, 2.0)
	canvas.draw_line(Vector2(917, 104), Vector2(941, 133), EDGE, 2.0)
	canvas.draw_line(Vector2(876, 137), Vector2(876, 245), Color("#bcb8a4"), 1.5)
	canvas.draw_arc(Vector2(880, 245), 5.0, 0.0, PI * 1.45, 14, EDGE, 2.0)
	canvas.draw_rect(Rect2(904, 357, 41, 12), Color("#c3bca3"))
	# Cable drum and its bracket ground the hoist without adding a playable ledge.
	canvas.draw_circle(Vector2(923, 414), 22.0, Color("#c5bea4"))
	canvas.draw_circle(Vector2(923, 414), 17.0, Color("#dad4bd"))
	canvas.draw_arc(Vector2(923, 414), 12.0, 0.0, TAU, 24, EDGE, 2.0)
	canvas.draw_circle(Vector2(923, 414), 4.0, EDGE)
	canvas.draw_line(Vector2(898, 440), Vector2(910, 421), EDGE, 3.0)
	canvas.draw_line(Vector2(945, 440), Vector2(935, 421), EDGE, 3.0)
	# Foreground stock is stowed below the board's real platforms.
	canvas.draw_rect(Rect2(661, 455, 171, 23), Color("#d4c4a4"))
	canvas.draw_line(Vector2(661, 456), Vector2(832, 456), Color("#bfae8d"), 2.0)
	canvas.draw_line(Vector2(665, 464), Vector2(829, 464), Color("#c3b393"), 1.5)
	canvas.draw_line(Vector2(665, 472), Vector2(829, 472), Color("#c3b393"), 1.5)
	canvas.draw_rect(Rect2(685, 454, 7, 26), Color("#b3b5a0"))
	canvas.draw_rect(Rect2(803, 454, 7, 26), Color("#b3b5a0"))
	# A survey tripod and closed tool case sit on the near-left service margin.
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0, 403), Vector2(82, 423), Vector2(102, 480), Vector2(0, 480)
	]), Color("#e1dcc6"))
	canvas.draw_line(Vector2(39, 372), Vector2(20, 433), EDGE, 2.0)
	canvas.draw_line(Vector2(39, 372), Vector2(58, 433), EDGE, 2.0)
	canvas.draw_line(Vector2(39, 372), Vector2(39, 430), EDGE, 2.0)
	canvas.draw_rect(Rect2(28, 366, 29, 9), Color("#b9b39c"))
	canvas.draw_rect(Rect2(48, 359, 9, 9), Color("#c9c0a6"))
	canvas.draw_rect(Rect2(12, 447, 55, 24), Color("#c7bc9e"))
	canvas.draw_rect(Rect2(30, 442, 17, 5), Color("#b2a88c"), false, 2.0)
	canvas.draw_line(Vector2(13, 455), Vector2(66, 455), Color("#b2a88c"), 1.5)
	canvas.draw_rect(Rect2(35, 452, 7, 7), Color("#dcd0b2"))
