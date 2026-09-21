extends RefCounted

var position := Vector2.ZERO
var velocity := Vector2.ZERO
var size := Vector2(44, 64)
var speed := 360.0
var jump_force := 700.0
var gravity := 1600.0
var grounded := false
var jump_buffer := 0.0
var coyote_time := 0.0

func request_jump() -> void:
	jump_buffer = 0.12

func step(delta: float, surfaces: Array[Rect2], allow_jump: bool = true) -> void:
	var axis := Input.get_axis("move_left", "move_right")
	velocity.x = axis * speed
	if Input.is_action_just_pressed("jump"):
		request_jump()
	coyote_time = 0.10 if grounded else maxf(0.0, coyote_time - delta)
	if allow_jump and jump_buffer > 0.0 and coyote_time > 0.0:
		velocity.y = -jump_force
		grounded = false
		jump_buffer = 0.0
		coyote_time = 0.0
	jump_buffer = maxf(0.0, jump_buffer - delta)
	velocity.y += gravity * delta
	var previous := position
	position += velocity * delta
	position.x = clampf(position.x, 12.0, 1280.0 - size.x - 12.0)
	grounded = false
	if velocity.y >= 0.0:
		for surface in surfaces:
			var previous_bottom := previous.y + size.y
			var current_bottom := position.y + size.y
			var overlaps_x := position.x + size.x > surface.position.x and position.x < surface.end.x
			if overlaps_x and previous_bottom <= surface.position.y + 6.0 and current_bottom >= surface.position.y:
				position.y = surface.position.y - size.y
				velocity.y = 0.0
				grounded = true
				break

func rect() -> Rect2:
	return Rect2(position, size)
