extends RefCounted

const TITLE: String = "Arc Dash"
const SETTING: String = "Suspended rail depot above a cable workshop"
const ACCENT: Color = Color("#b77f55")

# All scenery is fixed. Neither pause nor reduced motion causes decorative travel.
# Existing functional rails at y215/y345 and actors at y170/y300 own the center.
func draw_background(canvas: Node2D, context: Dictionary) -> void:
	var board: Rect2 = context.get("board_rect", Rect2(0, 0, 960, 480))
	var paper: Color = Color("#f8f2e4")
	var far: Color = Color("#e9e7d9")
	var structure: Color = Color("#d9dccc")
	var edge: Color = Color("#bfcbbb")
	var recess: Color = Color("#e3dfce")
	var copper: Color = Color("#d4baa0")
	canvas.draw_rect(board, paper)
	# A cropped roof section makes this an interior rather than a generic skyline.
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0, 0), Vector2(960, 0), Vector2(960, 24),
		Vector2(650, 24), Vector2(625, 11), Vector2(0, 11)
	]), far)
	canvas.draw_line(Vector2(625, 11), Vector2(650, 24), structure, 2.0)
	canvas.draw_line(Vector2(650, 24), Vector2(960, 24), structure, 2.0)
	# Suspension and folded service duct, outside the instruction and actor bounds.
	canvas.draw_rect(Rect2(805, 0, 14, 38), structure)
	canvas.draw_rect(Rect2(891, 0, 14, 38), structure)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(768, 30), Vector2(935, 30), Vector2(960, 43),
		Vector2(960, 72), Vector2(935, 58), Vector2(768, 58)
	]), far)
	canvas.draw_line(Vector2(768, 58), Vector2(935, 58), edge, 2.0)
	canvas.draw_line(Vector2(935, 58), Vector2(960, 72), structure, 2.0)
	for index: int in range(4):
		var vent_x: float = 801.0 + float(index) * 27.0
		canvas.draw_line(Vector2(vent_x, 38), Vector2(vent_x + 12, 48), structure, 3.0)
	# Edge wall pier is cropped before the real rails' x50 start.
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0, 88), Vector2(15, 97), Vector2(15, 384), Vector2(0, 396)
	]), far)
	canvas.draw_line(Vector2(15, 97), Vector2(15, 384), structure, 2.0)
	# Under-floor workshop cutaway: diagonal depth edges cannot read as extra rails.
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0, 408), Vector2(250, 393), Vector2(709, 393),
		Vector2(960, 416), Vector2(960, 480), Vector2(0, 480)
	]), recess)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0, 408), Vector2(250, 393), Vector2(250, 412), Vector2(0, 427)
	]), far)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(709, 393), Vector2(960, 416), Vector2(960, 435), Vector2(709, 412)
	]), far)
	# Folded copper busbars disappear into the cutaway, never into the play field.
	var upper_bus: PackedVector2Array = PackedVector2Array([
		Vector2(22, 447), Vector2(116, 447), Vector2(148, 422),
		Vector2(350, 422), Vector2(384, 447), Vector2(552, 447)
	])
	canvas.draw_polyline(upper_bus, copper, 7.0, true)
	var lower_bus: PackedVector2Array = PackedVector2Array([
		Vector2(22, 464), Vector2(125, 464), Vector2(160, 439),
		Vector2(343, 439), Vector2(377, 464), Vector2(552, 464)
	])
	canvas.draw_polyline(lower_bus, copper, 7.0, true)
	# Broad insulated clamps give the busbars a mechanical purpose, not target dots.
	for clamp_x: float in [75.0, 216.0, 293.0, 467.0]:
		var clamp_y: float = 413.0 if clamp_x > 150.0 and clamp_x < 350.0 else 438.0
		canvas.draw_rect(Rect2(clamp_x, clamp_y, 14, 37), structure)
		canvas.draw_line(Vector2(clamp_x + 7, clamp_y + 4), Vector2(clamp_x + 7, clamp_y + 33), edge, 2.0)
	# One louvered transformer cabinet, shown in oblique section beneath the rails.
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(686, 421), Vector2(809, 421), Vector2(836, 435),
		Vector2(836, 480), Vector2(686, 480)
	]), structure)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(809, 421), Vector2(836, 435), Vector2(836, 480), Vector2(809, 480)
	]), edge)
	for index: int in range(5):
		var louver_y: float = 434.0 + float(index) * 9.0
		canvas.draw_line(Vector2(701, louver_y), Vector2(792, louver_y), edge, 3.0)
	canvas.draw_polyline(PackedVector2Array([
		Vector2(836, 452), Vector2(898, 452), Vector2(914, 467), Vector2(960, 467)
	]), copper, 6.0, true)
