extends Button

const Paint = preload("res://scripts/ui/Paint.gd")
var paint_color := Paint.GOLD

func focus_when_ready() -> void:
	if is_inside_tree() and not is_queued_for_deletion():
		grab_focus()

func _ready() -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color", "font_hover_pressed_color"]:
		add_theme_color_override(state, Color.TRANSPARENT)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)

func _draw() -> void:
	var offset := Vector2(3, 3) if is_pressed() else Vector2.ZERO
	Paint.rect(self, Rect2(Vector2(5, 5), size - Vector2(8, 8)), Paint.INK)
	var fill := Paint.PAPER if is_hovered() else paint_color
	Paint.rect(self, Rect2(offset, size - Vector2(6, 6)), fill)
	Paint.rect(self, Rect2(offset, size - Vector2(6, 6)), Paint.INK, false, 3)
	Paint.text(self, text, Vector2(12, size.y * 0.5 + 8) + offset, 22, Paint.INK, size.x - 30, HORIZONTAL_ALIGNMENT_CENTER)
	if has_focus():
		Paint.line(self, Vector2(15,size.y-11),Vector2(size.x-24,size.y-14),Paint.INK,2)
