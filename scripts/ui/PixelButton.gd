extends RefCounted

const PaintButton = preload("res://scripts/ui/PaintButton.gd")

static func make(text_value: String, at: Vector2, size_value: Vector2, color: Color) -> Button:
	var button := PaintButton.new()
	button.text = text_value
	button.position = at
	button.size = size_value
	button.paint_color = color
	button.focus_mode = Control.FOCUS_ALL
	return button
