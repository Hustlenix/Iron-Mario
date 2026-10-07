extends Node2D

## Arc Snake is a fast, original grid snake: turn at the last second, harvest
## reactor orbs, and use BOOST to raise the score ceiling without adding a second
## control scheme. Shared left/right/BOOST actions make it touch-ready.

const CELL := 32
const BOARD := Rect2(96, 112, 1088, 544)
const COLUMNS := 34
const ROWS := 17
const BASE_STEP := 0.145
const MIN_STEP := 0.07

var snake: Array[Vector2i] = []
var direction := Vector2i.RIGHT
var food := Vector2i.ZERO
var score := 0
var best := 0
var state := "playing"
var _step_timer := 0.0
var _rng := RandomNumberGenerator.new()

@onready var score_label: Label = $HUD/ScoreLabel
@onready var best_label: Label = $HUD/BestLabel
@onready var message_label: Label = $HUD/MessageLabel

func _ready() -> void:
	_rng.seed = 71429
	best = Global.arc_snake_best
	_restart()
	SceneFade.fade_in(self)
	Music.play("gauntlet", 0.8, -8.0)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_return_to_library()
		return
	if state == "game_over":
		if Input.is_action_just_pressed("jump"):
			_restart()
		return
	_handle_turn_input()

func _physics_process(delta: float) -> void:
	if state != "playing":
		return
	_step_timer -= delta
	if _step_timer > 0.0:
		return
	_step_timer = _step_duration()
	_step()
	queue_redraw()

func _handle_turn_input() -> void:
	if Input.is_action_just_pressed("left") or Input.is_action_just_pressed("ui_left"):
		_turn_left()
	elif Input.is_action_just_pressed("right") or Input.is_action_just_pressed("ui_right"):
		_turn_right()
	elif Input.is_action_just_pressed("ui_up") and direction != Vector2i.DOWN:
		direction = Vector2i.UP
	elif Input.is_action_just_pressed("ui_down") and direction != Vector2i.UP:
		direction = Vector2i.DOWN
	elif Input.is_action_just_pressed("ui_right") and direction != Vector2i.LEFT:
		direction = Vector2i.RIGHT
	elif Input.is_action_just_pressed("ui_left") and direction != Vector2i.RIGHT:
		direction = Vector2i.LEFT

func _turn_left() -> void:
	if direction == Vector2i.RIGHT:
		direction = Vector2i.UP
	elif direction == Vector2i.UP:
		direction = Vector2i.LEFT
	elif direction == Vector2i.LEFT:
		direction = Vector2i.DOWN
	else:
		direction = Vector2i.RIGHT

func _turn_right() -> void:
	if direction == Vector2i.RIGHT:
		direction = Vector2i.DOWN
	elif direction == Vector2i.DOWN:
		direction = Vector2i.LEFT
	elif direction == Vector2i.LEFT:
		direction = Vector2i.UP
	else:
		direction = Vector2i.RIGHT

func _step_duration() -> float:
	var speed := lerpf(BASE_STEP, MIN_STEP, clampf(float(score) / 2500.0, 0.0, 1.0))
	if Input.is_action_pressed("jump"):
		speed *= 0.72
	return speed

func _step() -> void:
	var head := snake[0] + direction
	if head.x < 0 or head.x >= COLUMNS or head.y < 0 or head.y >= ROWS or snake.has(head):
		_die()
		return
	snake.push_front(head)
	if head == food:
		score += 100
		_place_food()
		Juice.burst(self, _cell_center(head), Color(0.45, 0.85, 1.0), 12, 220.0)
		Juice.text(self, "+100", _cell_center(head) + Vector2(-25, -18), Color(0.6, 1.0, 0.8), 24)
	else:
		snake.pop_back()
	_update_hud()

func _place_food() -> void:
	for _attempt in 100:
		var candidate := Vector2i(_rng.randi_range(1, COLUMNS - 2), _rng.randi_range(1, ROWS - 2))
		if not snake.has(candidate):
			food = candidate
			return

func _restart() -> void:
	state = "playing"
	score = 0
	direction = Vector2i.RIGHT
	_step_timer = BASE_STEP
	snake = [Vector2i(8, 8), Vector2i(7, 8), Vector2i(6, 8)]
	_place_food()
	message_label.text = "TURN  ·  BOOST  ·  EAT ARC ORBS"
	_update_hud()
	queue_redraw()

func _die() -> void:
	if state != "playing":
		return
	state = "game_over"
	best = maxi(best, score)
	Global.arc_snake_best = best
	if GameLauncher.has_return_scene():
		GameLauncher.record_result("arc_snake", score, false)
	Global.save()
	message_label.text = "SIGNAL LOST\nSCORE %d  ·  BOOST TO RETRY  ·  ESC FOR ARCADE" % score
	Juice.hit_stop(self)
	Juice.shake(self, 0.55)
	Juice.burst(self, _cell_center(snake[0]), Color(1, 0.3, 0.3), 20, 300.0)
	_update_hud()
	queue_redraw()

func _update_hud() -> void:
	score_label.text = "SCORE  %04d" % score
	best_label.text = "BEST  %04d" % best

func _cell_center(cell: Vector2i) -> Vector2:
	return BOARD.position + Vector2(cell.x * CELL + CELL * 0.5, cell.y * CELL + CELL * 0.5)

func _return_to_library() -> void:
	await SceneFade.fade_out(self)
	if GameLauncher.has_return_scene():
		GameLauncher.return_to_library()
	else:
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.035, 0.05, 0.12))
	draw_rect(BOARD, Color(0.02, 0.03, 0.08), false, 4.0)
	for x in COLUMNS + 1:
		draw_line(BOARD.position + Vector2(x * CELL, 0), BOARD.position + Vector2(x * CELL, BOARD.size.y), Color(0.14, 0.18, 0.3, 0.18), 1.0)
	for y in ROWS + 1:
		draw_line(BOARD.position + Vector2(0, y * CELL), BOARD.position + Vector2(BOARD.size.x, y * CELL), Color(0.14, 0.18, 0.3, 0.18), 1.0)
	draw_circle(_cell_center(food), 12.0, Color(0.45, 0.85, 1.0, 0.25))
	draw_circle(_cell_center(food), 7.0, Color(0.6, 1.0, 0.8))
	for i in snake.size():
		var color := Color(0.91, 0.25, 0.25) if i == 0 else Color(1.0, 0.83, 0.3)
		var cell := Rect2(BOARD.position + Vector2(snake[i].x * CELL + 3, snake[i].y * CELL + 3), Vector2(CELL - 6, CELL - 6))
		draw_rect(cell, Color(0.02, 0.03, 0.08))
		draw_rect(Rect2(cell.position + Vector2(3, 3), cell.size - Vector2(6, 6)), color)
