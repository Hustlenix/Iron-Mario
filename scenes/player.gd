extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = 500.0
const GRAVITY := 980.0

func _ready() -> void:
	$PlayerArea.add_to_group("player_area")

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = -jump_velocity
	velocity.y += GRAVITY * delta
	move_and_slide()
