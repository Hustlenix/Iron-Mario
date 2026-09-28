class_name PaintButton
extends Button
var ink := Color('#242333')
var fill := Color('#fff4d7')
var accent: bool = false
func _ready() -> void:
	custom_minimum_size.y = maxf(custom_minimum_size.y,64)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ['normal','hover','pressed','focus','disabled']:
		add_theme_stylebox_override(state,StyleBoxEmpty.new())
	add_theme_color_override('font_color',ink)
	add_theme_color_override('font_hover_color',ink)
	add_theme_color_override('font_pressed_color',ink)
	if not has_theme_font_size_override('font_size'): add_theme_font_size_override('font_size',22)
	custom_minimum_size.x = maxf(custom_minimum_size.x,get_theme_font('font').get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,get_theme_font_size('font_size')).x+28)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
func _draw() -> void:
	var offset: float = 3 if button_pressed else 0
	var r := Rect2(Vector2(0,offset),size-Vector2(4,5))
	var p := PackedVector2Array([r.position+Vector2(3,0),r.position+Vector2(r.size.x,2),r.end-Vector2(2,0),r.position+Vector2(0,r.size.y-2)])
	var shadow := PackedVector2Array()
	for pt in p: shadow.append(pt+Vector2(4,5))
	draw_colored_polygon(shadow,ink)
	draw_colored_polygon(p,fill.lightened(0.13) if is_hovered() else fill)
	p.append(p[0])
	draw_polyline(p,ink,3)
	if has_focus(): draw_rect(Rect2(7,7,size.x-18,size.y-20),Color('#4a8de0'),false,3)
	var text_color: Color = ink if not disabled else Color(ink, 0.42)
	var text_size: int = get_theme_font_size('font_size')
	while text_size > 16 and get_theme_font('font').get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,text_size).x > size.x-22:
		text_size -= 1
	var baseline: float = (size.y + text_size * 0.62) * 0.5 + offset
	draw_string(get_theme_font('font'),Vector2(10,baseline),text,HORIZONTAL_ALIGNMENT_CENTER,size.x-20,text_size,text_color)
