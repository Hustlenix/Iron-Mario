extends Control
var category: String = ''
func _ready() -> void:
	custom_minimum_size = Vector2(48,48)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var ink := Color('#242333')
	var gold := Color('#ffc857')
	var blue := Color('#4a8de0')
	match category.to_lower():
		'aim','reaction','reflex':
			draw_circle(Vector2(24,24),18,gold)
			draw_arc(Vector2(24,24),18,0,TAU,12,ink,3)
			draw_line(Vector2(2,24),Vector2(46,24),ink,3)
			draw_line(Vector2(24,2),Vector2(24,46),ink,3)
		'timing','rhythm':
			draw_arc(Vector2(24,25),18,0,TAU,12,ink,3)
			draw_line(Vector2(24,9),Vector2(24,26),ink,4)
			draw_line(Vector2(24,26),Vector2(34,30),ink,4)
			draw_rect(Rect2(17,1,15,5),gold)
		'memory','puzzle','sorting':
			for i in 4:
				var rect := Rect2(3+(i%2)*23,3+(i/2)*23,18,18)
				draw_rect(rect,gold if i%2==0 else blue)
				draw_rect(rect,ink,false,3)
		'physics':
			draw_line(Vector2(3,44),Vector2(45,44),ink,4)
			draw_circle(Vector2(29,16),12,blue)
			draw_arc(Vector2(29,16),12,0,TAU,10,ink,3)
			draw_line(Vector2(8,15),Vector2(18,27),ink,3)
		_:
			var points := PackedVector2Array([Vector2(4,25),Vector2(24,5),Vector2(24,16),Vector2(44,16),Vector2(43,34),Vector2(24,34),Vector2(24,44)])
			draw_colored_polygon(points,gold)
			points.append(points[0])
			draw_polyline(points,ink,3)
