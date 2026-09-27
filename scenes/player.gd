extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = 500.0
const GRAVITY := 980.0

var was_on_floor := true

# Scripted motion, driven by hero powers. While a motion is live it replaces
# normal input and gravity entirely so every power arc is deterministic and
# readable, and control returns cleanly the moment it expires.
var _motion_time := 0.0
var _motion_velocity := Vector2.ZERO
var _motion_gravity := 0.0
var _motion_to_point := false
var _motion_point := Vector2.ZERO
var _motion_speed := 0.0
var _motion_reach := 6.0
var _invincible_time := 0.0
var _shielded := false

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	$PlayerArea.add_to_group("player_area")

func _physics_process(delta: float) -> void:
	_tick_invincibility(delta)
	if _motion_time > 0.0:
		_apply_motion(delta)
	else:
		_apply_control(delta)
	was_on_floor = is_on_floor()
	move_and_slide()

func _tick_invincibility(delta: float) -> void:
	if _invincible_time > 0.0:
		_invincible_time = maxf(0.0, _invincible_time - delta)

func _apply_control(delta: float) -> void:
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
	velocity.y += GRAVITY * delta

func _apply_motion(delta: float) -> void:
	_motion_time = maxf(0.0, _motion_time - delta)
	if _motion_to_point:
		var to_point := _motion_point - global_position
		var step := _motion_speed * delta
		if to_point.length() <= step + _motion_reach:
			_motion_time = 0.0
			velocity = Vector2.ZERO
		else:
			velocity = to_point.normalized() * _motion_speed
	else:
		velocity = _motion_velocity
		velocity.y += _motion_gravity * delta
	if absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x < 0.0

## Launch the player on a fixed scripted velocity for `duration` seconds.
func burst(velocity: Vector2, duration: float, invincible := false) -> void:
	_motion_to_point = false
	_motion_velocity = velocity
	_motion_gravity = 0.0
	_motion_time = duration
	if invincible:
		grant_invincibility(duration)

## Fly the player toward `point` at `speed` until it is reached or `timeout` lapses.
func pull_to(point: Vector2, speed: float, timeout: float, invincible := false) -> void:
	_motion_to_point = true
	_motion_point = point
	_motion_speed = speed
	_motion_time = timeout
	if invincible:
		grant_invincibility(timeout)

## Aim a burst straight at `point` without homing, so the arc stays readable.
func burst_toward(point: Vector2, speed: float, duration: float, invincible := false) -> void:
	var direction := (point - global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	burst(direction * speed, duration, invincible)

func stop_motion() -> void:
	_motion_time = 0.0
	_motion_to_point = false
	velocity = Vector2.ZERO

func motion_active() -> bool:
	return _motion_time > 0.0

func grant_invincibility(duration: float) -> void:
	_invincible_time = maxf(_invincible_time, duration)

func is_invincible() -> bool:
	return _invincible_time > 0.0 or _shielded

	## Aegis ward: soak the next hazard hit, then break.
func grant_shield() -> void:
	_shielded = true

func has_shield() -> bool:
	return _shielded

func consume_shield() -> bool:
	if not _shielded:
		return false
	_shielded = false
	grant_invincibility(0.5)
	_squash(Vector2(0.8, 1.2))
	return true

func _squash(stretch: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", stretch, 0.06)
	tween.tween_property(self, "scale", Vector2.ONE, 0.14)

func _dust() -> void:
	Juice.burst(get_parent(), global_position + Vector2(0, 8), Color(0.7, 0.78, 0.9), 6, 130.0, 0.4)
