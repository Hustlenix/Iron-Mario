extends RefCounted

const TITLE: String = "Marble Bureau"
const SETTING: String = "A conservator's marble classification bench"
const ACCENT: Color = Color("#b98e58")
const PAPER: Color = Color("#faf3e2")
const EDGE: Color = Color("#c1ae8c")
const QUIET: Color = Color("#e7dcc5")

func draw_background(canvas: Node2D, _context: Dictionary) -> void:
	# Four existing tubes remain the only marble containers on the bench.
	canvas.draw_rect(Rect2(0, 0, 960, 480), PAPER)
	canvas.draw_rect(Rect2(0, 0, 960, 37), Color("#e8ddc6"))
	canvas.draw_line(Vector2(0, 36), Vector2(960, 36), EDGE, 2.0)
	for index: int in range(8):
		var x: float = 18.0 + float(index) * 120.0
		canvas.draw_rect(Rect2(x, 3, 106, 26), Color("#e0d2b7"))
		canvas.draw_line(Vector2(x + 1, 28), Vector2(x + 105, 28), EDGE, 1.0)
		canvas.draw_rect(Rect2(x + 43, 13, 20, 3), Color("#bca98a"))
	# Broad continuous felt pad: no false slots or input guides.
	canvas.draw_rect(Rect2(171, 92, 584, 306), Color("#ded7c7"))
	canvas.draw_rect(Rect2(166, 87, 584, 306), Color("#f1eee2"))
	canvas.draw_rect(Rect2(170, 91, 576, 298), Color("#f7f4e9"))
	canvas.draw_line(Vector2(168, 390), Vector2(748, 390), Color("#cdc7b6"), 2.0)
	# Bench edge creates depth below the puzzle without crossing the footer.
	canvas.draw_rect(Rect2(0, 405, 960, 75), Color("#efe3cc"))
	canvas.draw_line(Vector2(0, 405), Vector2(960, 405), Color("#d6c4a5"), 2.0)
	canvas.draw_line(Vector2(0, 410), Vector2(960, 410), Color("#f8efdd"), 2.0)
	_draw_caliper(canvas)
	_draw_brush(canvas)
	_draw_ledger(canvas)
	_draw_sleeves(canvas)

func _draw_caliper(canvas: Node2D) -> void:
	# A flat measuring tool, parked outside the left tube hit region.
	canvas.draw_rect(Rect2(48, 120, 15, 184), Color("#d8ccb5"))
	canvas.draw_rect(Rect2(44, 117, 14, 180), Color("#d7dcda"))
	canvas.draw_rect(Rect2(44, 117, 14, 180), Color("#aebbb8"), false, 1.5)
	canvas.draw_rect(Rect2(55, 117, 67, 9), Color("#c6d0ca"))
	canvas.draw_rect(Rect2(113, 117, 9, 40), Color("#c6d0ca"))
	canvas.draw_rect(Rect2(39, 181, 26, 22), Color("#b9c6c0"))
	canvas.draw_rect(Rect2(60, 188, 62, 9), Color("#bdc9c2"))
	canvas.draw_rect(Rect2(113, 165, 9, 32), Color("#bdc9c2"))
	for tick: int in range(13):
		var y: float = 137.0 + float(tick) * 11.0
		var length: float = 7.0 if tick % 3 == 0 else 4.0
		canvas.draw_line(Vector2(45, y), Vector2(45 + length, y), Color("#9eaca6"), 1.0)
	canvas.draw_line(Vector2(47, 121), Vector2(47, 292), Color("#eef0e8"), 1.0)

func _draw_brush(canvas: Node2D) -> void:
	var handle: PackedVector2Array = PackedVector2Array([
		Vector2(94, 262), Vector2(104, 259), Vector2(129, 341), Vector2(118, 345)])
	canvas.draw_colored_polygon(handle, Color("#c4a077"))
	canvas.draw_line(Vector2(99, 267), Vector2(123, 338), Color("#ead0a8"), 2.0)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(83, 232), Vector2(97, 228), Vector2(108, 258), Vector2(94, 263)]), QUIET)
	canvas.draw_line(Vector2(93, 258), Vector2(107, 254), EDGE, 5.0)
	for bristle: int in range(4):
		var x: float = 84.0 + float(bristle) * 4.0
		canvas.draw_line(Vector2(x, 232), Vector2(x + 7, 249), Color("#c5b596"), 1.0)

func _draw_ledger(canvas: Node2D) -> void:
	# A closed archival register with pages, spine and a ribbon; no fake UI text.
	canvas.draw_rect(Rect2(798, 123, 116, 151), Color("#dbcfb8"))
	canvas.draw_rect(Rect2(791, 117, 116, 151), Color("#cbd2bb"))
	canvas.draw_rect(Rect2(800, 122, 105, 141), Color("#f4eddb"))
	canvas.draw_rect(Rect2(787, 114, 112, 145), Color("#d3d9c3"))
	canvas.draw_rect(Rect2(787, 114, 14, 145), Color("#b8c4ac"))
	canvas.draw_rect(Rect2(817, 145, 53, 40), Color("#e9e8d5"))
	canvas.draw_rect(Rect2(817, 145, 53, 40), Color("#bbc5ad"), false, 1.0)
	canvas.draw_line(Vector2(827, 162), Vector2(861, 162), Color("#c6ccb8"), 2.0)
	canvas.draw_line(Vector2(827, 169), Vector2(850, 169), Color("#c6ccb8"), 1.0)
	canvas.draw_rect(Rect2(856, 252, 8, 24), Color("#c5a678"))
	canvas.draw_line(Vector2(901, 128), Vector2(901, 254), Color("#d9ccb4"), 1.0)

func _draw_sleeves(canvas: Node2D) -> void:
	canvas.draw_rect(Rect2(795, 313, 128, 68), Color("#ded2bb"))
	canvas.draw_rect(Rect2(790, 307, 128, 68), Color("#f2e8d4"))
	canvas.draw_line(Vector2(790, 307), Vector2(854, 341), Color("#d3c2a2"), 1.5)
	canvas.draw_line(Vector2(918, 307), Vector2(854, 341), Color("#d3c2a2"), 1.5)
	canvas.draw_line(Vector2(792, 371), Vector2(833, 343), Color("#e0d2b8"), 1.0)
	canvas.draw_line(Vector2(916, 371), Vector2(875, 343), Color("#e0d2b8"), 1.0)
	canvas.draw_rect(Rect2(800, 294, 106, 13), Color("#ece0c8"))
	canvas.draw_line(Vector2(812, 300), Vector2(892, 300), Color("#d8c7a7"), 1.0)
