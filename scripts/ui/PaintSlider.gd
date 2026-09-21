extends HSlider

const Paint = preload("res://scripts/ui/Paint.gd")

func _ready() -> void:
	for state in ["slider", "grabber_area", "grabber_area_highlight"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["grabber", "grabber_highlight", "grabber_disabled"]:
		add_theme_icon_override(state, ImageTexture.new())
	value_changed.connect(func(_value): queue_redraw())
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func _draw() -> void:
	Paint.rect(self, Rect2(0, 15, size.x, 12), Paint.INK)
	Paint.rect(self, Rect2(0, 17, size.x * ratio, 8), Paint.CYAN)
	Paint.rect(self, Rect2((size.x - 24) * ratio, 3, 24, 36), Paint.GOLD)
	Paint.rect(self, Rect2((size.x - 24) * ratio, 3, 24, 36), Paint.INK, false, 3)
	if has_focus():
		Paint.line(self, Vector2(0, 48), Vector2(size.x, 45), Paint.INK, 2)
