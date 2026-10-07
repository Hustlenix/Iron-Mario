extends Node2D

## Tower Bounce is the first standalone arcade cabinet. It keeps the rule set
## tiny: steer left/right, land on hand-drawn platforms, and keep climbing.
## The vertical scroll is simulated by moving the platform field, which keeps
## collision deterministic and cheap on the Web export.

const PLAYER_SIZE := Vector2(34, 42)
const GRAVITY := 1350.0
const BOUNCE_VELOCITY := -610.0
const HORIZONTAL_SPEED := 310.0
const PLATFORM_HEIGHT := 18.0
const PLATFORM_WIDTH_MIN := 110.0
const PLATFORM_WIDTH_MAX := 190.0
const START_POSITION := Vector2(240, 520)

var player := START_POSITION
var velocity := Vector2.ZERO
var platforms: Array[Rect2] = []
var height_climbed := 0.0
var best_height := 0
var state := "playing"
var _previous_bottom := 0.0
var _last_platform_y := 580.0
var _rng := RandomNumberGenerator.new()

@onready var score_label: Label = $HUD/ScoreLabel
@onready var best_label: Label = $HUD/BestLabel
@onready var message_label: Label = $HUD/MessageLabel

func _ready() -> void:
	_rng.seed = 99173
	best_height = Global.tower_bounce_best
	_build_platforms()
	message_label.text = "STEER  ·  LAND  ·  CLIMB"
	SceneFade.fade_in(self)
	Music.play("gauntlet", 0.8, -8.0)
	_update_hud()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_return_to_library()
		return
	if state == "game_over" and Input.is_action_just_pressed("jump"):
		_restart()

func _physics_process(delta: float) -> void:
	if state != "playing":
		return
	var direction := Input.get_axis("left", "right")
	velocity.x = move_toward(velocity.x, direction * HORIZONTAL_SPEED, 1600.0 * delta)
	velocity.y = minf(velocity.y + GRAVITY * delta, 900.0)
	_previous_bottom = player.y + PLAYER_SIZE.y
	player += velocity * delta
	player.x = clampf(player.x, 20.0, 1260.0 - PLAYER_SIZE.x)
	if velocity.y > 0.0:
		_try_land()
	if player.y < 235.0:
		var shift := 235.0 - player.y
		player.y = 235.0
		for i in platforms.size():
			platforms[i].position.y += shift
		height_climbed += shift
		_generate_until_full()
	if player.y > 760.0:
		_die()
	_update_hud()
	queue_redraw()

func _build_platforms() -> void:
	platforms.clear()
	platforms.append(Rect2(150, 620, 300, PLATFORM_HEIGHT))
	_last_platform_y = 620.0
	_generate_until_full()

func _generate_until_full() -> void:
	while _last_platform_y > -180.0:
		var gap := _rng.randf_range(82.0, 132.0)
		_last_platform_y -= gap
		var width := _rng.randf_range(PLATFORM_WIDTH_MIN, PLATFORM_WIDTH_MAX)
		var x := _rng.randf_range(24.0, 1256.0 - width)
		platforms.append(Rect2(x, _last_platform_y, width, PLATFORM_HEIGHT))
	if platforms.size() > 28:
		platforms = platforms.slice(platforms.size() - 28)

func _try_land() -> void:
	var player_rect := Rect2(player, PLAYER_SIZE)
	for platform in platforms:
		if _previous_bottom <= platform.position.y and player_rect.end.y >= platform.position.y:
			var horizontal := player_rect.end.x > platform.position.x and player_rect.position.x < platform.end.x
			if horizontal:
				player.y = platform.position.y - PLAYER_SIZE.y
				velocity.y = BOUNCE_VELOCITY
				Juice.burst(self, Vector2(player.x + PLAYER_SIZE.x * 0.5, platform.position.y), Color(1, 0.83, 0.3), 5, 120.0)
				return

func _die() -> void:
	if state != "playing":
		return
	state = "game_over"
	best_height = maxi(best_height, int(height_climbed))
	Global.tower_bounce_best = best_height
	if GameLauncher.has_return_scene():
		GameLauncher.record_result("tower_bounce", int(height_climbed / 10.0), false)
	Global.save()
	message_label.text = "FELL %dm\nPRESS JUMP TO RETRY  ·  ESC FOR ARCADE" % int(height_climbed / 10.0)
	Juice.hit_stop(self)
	Juice.shake(self, 0.6)
	Juice.burst(self, player + PLAYER_SIZE * 0.5, Color(1, 0.3, 0.3), 18, 260.0)
	_update_hud()
	queue_redraw()

func _restart() -> void:
	state = "playing"
	player = START_POSITION
	velocity = Vector2.ZERO
	height_climbed = 0.0
	_last_platform_y = 620.0
	_rng.seed = _rng.randi()
	_build_platforms()
	message_label.text = "STEER  ·  LAND  ·  CLIMB"
	_update_hud()
	queue_redraw()

func _update_hud() -> void:
	score_label.text = "HEIGHT  %04dm" % int(height_climbed / 10.0)
	best_label.text = "BEST  %04dm" % int(best_height / 10.0)

func _return_to_library() -> void:
	await SceneFade.fade_out(self)
	if GameLauncher.has_return_scene():
		GameLauncher.return_to_library()
	else:
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.035, 0.05, 0.12))
	for i in 9:
		var x := float(i * 170 - 30)
		var y := 150.0 + float((i * 47) % 160)
		draw_circle(Vector2(x, y), 2.5, Color(1, 0.83, 0.3, 0.6))
	for platform in platforms:
		var fill := Color(0.16, 0.27, 0.52) if int(platform.position.y) % 2 == 0 else Color(0.22, 0.43, 0.49)
		draw_rect(platform, Color(0.02, 0.03, 0.08))
		draw_rect(Rect2(platform.position + Vector2(3, 3), platform.size - Vector2(6, 6)), fill)
		draw_line(platform.position + Vector2(6, 3), platform.end - Vector2(6, platform.size.y - 3), Color(1, 0.83, 0.3), 3.0)
	var body := Rect2(player + Vector2(4, 8), Vector2(26, 30))
	draw_rect(body, Color(0.02, 0.03, 0.08))
	draw_rect(Rect2(body.position + Vector2(4, 4), body.size - Vector2(8, 8)), Color(0.91, 0.25, 0.25))
	draw_circle(player + Vector2(17, 8), 10.0, Color(0.02, 0.03, 0.08))
	draw_circle(player + Vector2(17, 8), 6.0, Color(0.45, 0.85, 1.0))
	draw_line(player + Vector2(3, 39), player + Vector2(-5, 48), Color(1, 0.83, 0.3), 4.0)
	draw_line(player + Vector2(31, 39), player + Vector2(39, 48), Color(1, 0.83, 0.3), 4.0)
