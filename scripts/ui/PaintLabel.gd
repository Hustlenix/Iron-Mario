extends Control

const Paint = preload("res://scripts/ui/Paint.gd")
var text := ""
var font_size := 18.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var y := font_size
	for row in text.split("\n"):
		Paint.text(self, row, Vector2(0, y), font_size, Paint.INK, size.x)
		y += font_size * 1.4
