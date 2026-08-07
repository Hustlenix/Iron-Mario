extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = 500.0
const GRAVITY := 980.0

var was_on_floor := true

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	$PlayerArea.add_to_group("player_area")

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * speed
		sprite.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = -jump_velocity
		_squash(Vector2(1.25, 0.75))
		_dust()
	elif not was_on_floor and is_on_floor():
		_squash(Vector2(0.75, 1.25))
		_dust()
	was_on_floor = is_on_floor()
	velocity.y += GRAVITY * delta
	move_and_slide()

func _squash(stretch: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", stretch, 0.06)
	tween.tween_property(self, "scale", Vector2.ONE, 0.14)

func _dust() -> void:
	Juice.burst(get_parent(), global_position + Vector2(0, 8), Color(0.7, 0.78, 0.9), 6, 130.0, 0.4)
