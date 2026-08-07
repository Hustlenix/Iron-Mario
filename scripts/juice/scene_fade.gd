class_name SceneFade
extends CanvasLayer

const FADE_COLOR := Color(0.02, 0.02, 0.05)

static func fade_in(root: Node, duration := 0.3) -> void:
	var layer := _make_layer(root)
	var rect: ColorRect = layer.get_child(0)
	var tween: Tween = layer.create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, duration)
	tween.finished.connect(layer.queue_free)

static func fade_out(root: Node, duration := 0.3) -> Tween:
	var layer := _make_layer(root)
	var rect: ColorRect = layer.get_child(0)
	rect.modulate.a = 0.0
	var tween: Tween = layer.create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, duration)
	tween.finished.connect(layer.queue_free)
	return tween

static func _make_layer(root: Node) -> SceneFade:
	var layer := SceneFade.new()
	layer.name = "SceneFadeLayer"
	root.add_child(layer)
	var rect := ColorRect.new()
	rect.color = FADE_COLOR
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.modulate.a = 1.0
	layer.add_child(rect)
	return layer
