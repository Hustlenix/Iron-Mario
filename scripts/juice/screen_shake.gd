class_name ScreenShake
extends Camera2D

const TRAUMA_DECAY := 1.6
const MAX_OFFSET := 18.0
const MAX_ROTATION := 0.02

var trauma := 0.0

func _ready() -> void:
	add_to_group("shake_cam")
	make_current()

func add_trauma(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)

func _process(delta: float) -> void:
	if trauma <= 0.0:
		offset = Vector2.ZERO
		rotation = 0.0
		return
	trauma = maxf(trauma - TRAUMA_DECAY * delta, 0.0)
	var shake := trauma * trauma
	offset = Vector2(
		randf_range(-MAX_OFFSET, MAX_OFFSET) * shake,
		randf_range(-MAX_OFFSET, MAX_OFFSET) * shake
	)
	rotation = randf_range(-MAX_ROTATION, MAX_ROTATION) * shake
