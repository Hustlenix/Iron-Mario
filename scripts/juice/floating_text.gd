class_name FloatingText
extends Node2D

const RISE_DISTANCE := 70.0
const LIFETIME := 0.9

func setup(text: String, color: Color, font_size: int) -> void:
	z_index = 60
	var label := Label.new()
	label.text = text
	label.modulate = color
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(0, -RISE_DISTANCE), LIFETIME)
	tween.tween_property(label, "modulate:a", 0.0, LIFETIME).set_delay(0.25)
	tween.finished.connect(queue_free)
