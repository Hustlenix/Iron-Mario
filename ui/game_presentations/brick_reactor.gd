extends RefCounted

const TITLE: String = "Brick Reactor"
const SETTING: String = "Ceramic pulse chamber with cooling manifolds"
const ACCENT: Color = Color("c7884b")
const PAPER: Color = Color("f4f0e5")
const CASING: Color = Color("d9e0de")
const SEAM: Color = Color("a4b4b7")
const SHADE: Color = Color("c4cfce")
const RECESS: Color = Color("b9c8ca")

func draw_background(canvas: Node2D, _context: Dictionary) -> void:
	# The cabinet owns its opaque chamber and every control hit area.
	canvas.draw_rect(Rect2(0, 0, 960, 480), PAPER)
	# Header stays pale for the existing dark title and actual brick count.
	canvas.draw_rect(Rect2(0, 0, 960, 49), Color("f8f3e7"))
	canvas.draw_line(Vector2(0, 48), Vector2(960, 48), Color("ded9cb"), 1.0)
	# The lower backing is a machine plinth, visible between the controls.
	canvas.draw_rect(Rect2(0, 382, 960, 98), CASING)
	canvas.draw_rect(Rect2(0, 382, 960, 8), SHADE)
	canvas.draw_line(Vector2(0, 478), Vector2(960, 478), SEAM, 2.0)
	# Narrow casing outside the authoritative bounce bounds: no fake walls.
	canvas.draw_rect(Rect2(34, 56, 892, 326), SHADE)
	canvas.draw_rect(Rect2(39, 60, 882, 323), CASING)
	canvas.draw_rect(Rect2(45, 65, 870, 316), Color("e0eaf5"))
	# Upper twin coolant feed, clear of all header lettering.
	canvas.draw_line(Vector2(69, 53), Vector2(891, 53), SHADE, 5.0)
	canvas.draw_line(Vector2(69, 52), Vector2(891, 52), Color("aebfc1"), 2.0)
	for feed_x: float in [69.0, 891.0]:
		canvas.draw_rect(Rect2(feed_x - 9, 49, 18, 10), SEAM)
		canvas.draw_rect(Rect2(feed_x - 7, 49, 14, 7), Color("e6ece7"))
		canvas.draw_line(Vector2(feed_x - 3, 50), Vector2(feed_x - 3, 56), SHADE, 1.0)
		canvas.draw_line(Vector2(feed_x + 3, 50), Vector2(feed_x + 3, 56), SHADE, 1.0)
	# Cooling jackets use long grooves; they cannot resemble the colored bricks.
	_draw_cooling_jacket(canvas, 7.0)
	_draw_cooling_jacket(canvas, 931.0)
	# Two maintenance bays fit solely in the existing gaps between buttons.
	_draw_service_bay(canvas, 256.0)
	_draw_service_bay(canvas, 602.0)
	# Corner fasteners tie the upper chamber to the plinth.
	for anchor: Vector2 in [Vector2(17, 66), Vector2(943, 66), Vector2(17, 374), Vector2(943, 374)]:
		canvas.draw_circle(anchor, 4.0, SEAM)
		canvas.draw_line(anchor - Vector2(2, 0), anchor + Vector2(2, 0), PAPER, 1.0)

func _draw_cooling_jacket(canvas: Node2D, x: float) -> void:
	canvas.draw_rect(Rect2(x + 2, 87, 22, 274), Color("d0dad8"))
	canvas.draw_rect(Rect2(x, 82, 22, 274), Color("e5e9df"))
	canvas.draw_rect(Rect2(x + 5, 97, 12, 243), RECESS)
	canvas.draw_line(Vector2(x + 5, 97), Vector2(x + 5, 340), SEAM, 1.0)
	for fin: int in range(19):
		var y: float = 101.0 + float(fin) * 12.0
		canvas.draw_line(Vector2(x + 6, y), Vector2(x + 17, y), Color("e0e8e0"), 3.0)
		canvas.draw_line(Vector2(x + 6, y + 3), Vector2(x + 17, y + 3), Color("aebfc0"), 1.0)
	# Fixed insulated pipe joins the jacket; static for reduced motion.
	canvas.draw_line(Vector2(x + 11, 65), Vector2(x + 11, 81), SEAM, 6.0)
	canvas.draw_line(Vector2(x + 10, 65), Vector2(x + 10, 81), Color("e3e9e2"), 2.0)
	canvas.draw_line(Vector2(x + 11, 356), Vector2(x + 11, 380), SEAM, 6.0)
	canvas.draw_line(Vector2(x + 10, 357), Vector2(x + 10, 378), Color("e3e9e2"), 2.0)

func _draw_service_bay(canvas: Node2D, x: float) -> void:
	canvas.draw_rect(Rect2(x, 402, 100, 63), Color("c0ccca"))
	canvas.draw_rect(Rect2(x + 3, 405, 94, 57), Color("e7eae0"))
	canvas.draw_line(Vector2(x + 4, 406), Vector2(x + 96, 406), SEAM, 1.0)
	# Recessed heat-exchanger ribs and a ceramic junction cap.
	canvas.draw_rect(Rect2(x + 10, 414, 45, 38), RECESS)
	for rib: int in range(5):
		var rib_x: float = x + 14.0 + float(rib) * 8.0
		canvas.draw_line(Vector2(rib_x, 418), Vector2(rib_x, 448), Color("dee6df"), 3.0)
	canvas.draw_line(Vector2(x + 62, 417), Vector2(x + 87, 417), SEAM, 4.0)
	canvas.draw_line(Vector2(x + 87, 417), Vector2(x + 87, 448), SEAM, 4.0)
	canvas.draw_rect(Rect2(x + 66, 430, 18, 19), Color("d8cbbb"))
	canvas.draw_rect(Rect2(x + 69, 431, 12, 15), Color("eee4d3"))
	canvas.draw_line(Vector2(x + 71, 435), Vector2(x + 79, 435), Color("bca88f"), 1.0)
	canvas.draw_line(Vector2(x + 71, 440), Vector2(x + 79, 440), Color("bca88f"), 1.0)
	canvas.draw_line(Vector2(x + 10, 458), Vector2(x + 90, 458), Color("c5d2ce"), 1.0)
