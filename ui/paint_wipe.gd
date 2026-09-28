extends Control
var progress: float = 0.0
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 60
	var tween := create_tween()
	tween.tween_property(self,'progress',1.0,0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_free)
func _process(_delta: float) -> void:
	queue_redraw()
func _draw() -> void:
	for i in 12:
		var edge: float = size.x*progress*1.2+sin(i*7.0)*20
		draw_rect(Rect2(edge,size.y*i/12.0,size.x,size.y/12.0+2),Color('#ffc857'))
		draw_line(Vector2(edge,size.y*i/12.0),Vector2(edge+4,size.y*(i+1)/12.0),Color('#242333'),4)
