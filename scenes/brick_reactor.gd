extends Node2D

## A compact Breakout cabinet with the arcade's hand-drawn vocabulary. The
## paddle is driven by the shared left/right actions, and the shared action
## button launches/restarts the ball on touch devices.

const BOARD := Rect2(80, 108, 1120, 560)
const PADDLE_SIZE := Vector2(210, 22)
const BALL_RADIUS := 10.0
const BRICK_SIZE := Vector2(96, 28)
const BRICK_GAP := 14.0
const COLUMNS := 9
const ROWS := 5
const START_SPEED := 390.0
const BRICK_COLORS: Array[Color] = [
	Color(0.91, 0.25, 0.25),
	Color(1.0, 0.55, 0.25),
	Color(1.0, 0.83, 0.3),
	Color(0.45, 0.85, 1.0),
	Color(0.55, 1.0, 0.7),
]

var paddle := Rect2(535, 610, PADDLE_SIZE.x, PADDLE_SIZE.y)
var ball := Vector2(640, 585)
var velocity := Vector2.ZERO
var bricks: Array[Rect2] = []
var brick_alive: Array[bool] = []
var score := 0
var best := 0
var state := "ready"

@onready var score_label: Label = $HUD/ScoreLabel
@onready var best_label: Label = $HUD/BestLabel
@onready var message_label: Label = $HUD/MessageLabel

func _ready() -> void:
	best = Global.brick_reactor_best
	_build_bricks()
	_update_hud()
	SceneFade.fade_in(self)
	Music.play("gauntlet", 0.8, -8.0)
	queue_redraw()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_return_to_library()
		return
	if (state == "game_over" or state == "win") and Input.is_action_just_pressed("jump"):
		_restart()

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("left", "right")
	paddle.position.x = clampf(paddle.position.x + direction * 520.0 * delta, BOARD.position.x, BOARD.end.x - paddle.size.x)
	if state == "ready":
		ball = Vector2(paddle.get_center().x, paddle.position.y - BALL_RADIUS - 3.0)
		if Input.is_action_just_pressed("jump"):
			_start_ball()
		queue_redraw()
		return
	if state != "playing":
		return

	var previous := ball
	ball += velocity * delta
	if ball.x - BALL_RADIUS <= BOARD.position.x:
		ball.x = BOARD.position.x + BALL_RADIUS
		velocity.x = absf(velocity.x)
	elif ball.x + BALL_RADIUS >= BOARD.end.x:
		ball.x = BOARD.end.x - BALL_RADIUS
		velocity.x = -absf(velocity.x)
	if ball.y - BALL_RADIUS <= BOARD.position.y:
		ball.y = BOARD.position.y + BALL_RADIUS
		velocity.y = absf(velocity.y)
	if velocity.y > 0.0 and Rect2(ball - Vector2(BALL_RADIUS, BALL_RADIUS), Vector2(BALL_RADIUS * 2.0, BALL_RADIUS * 2.0)).intersects(paddle):
		ball.y = paddle.position.y - BALL_RADIUS
		var hit := (ball.x - paddle.get_center().x) / (paddle.size.x * 0.5)
		velocity = Vector2(hit * START_SPEED * 0.9, -absf(velocity.y)).normalized() * START_SPEED
		Juice.burst(self, ball, Color(0.45, 0.85, 1.0), 5, 120.0)
	if ball.y - BALL_RADIUS > BOARD.end.y:
		_end_round(false)
		return
	_hit_brick(previous)
	_update_hud()
	queue_redraw()

func _build_bricks() -> void:
	bricks.clear()
	brick_alive.clear()
	var total_width := COLUMNS * BRICK_SIZE.x + (COLUMNS - 1) * BRICK_GAP
	var left := BOARD.position.x + (BOARD.size.x - total_width) * 0.5
	for row in ROWS:
		for column in COLUMNS:
			bricks.append(Rect2(left + column * (BRICK_SIZE.x + BRICK_GAP), 150.0 + row * (BRICK_SIZE.y + BRICK_GAP), BRICK_SIZE.x, BRICK_SIZE.y))
			brick_alive.append(true)

func _start_ball() -> void:
	state = "playing"
	message_label.text = "BREAK THE CORE"
	velocity = Vector2(0.55, -1.0).normalized() * START_SPEED

func _hit_brick(previous: Vector2) -> void:
	var ball_rect := Rect2(ball - Vector2(BALL_RADIUS, BALL_RADIUS), Vector2(BALL_RADIUS * 2.0, BALL_RADIUS * 2.0))
	for i in bricks.size():
		if not brick_alive[i] or not ball_rect.intersects(bricks[i]):
			continue
		brick_alive[i] = false
		score += 100
		var brick_center := bricks[i].get_center()
		var entered_from_side := previous.x < bricks[i].position.x or previous.x > bricks[i].end.x
		if entered_from_side:
			velocity.x *= -1.0
		else:
			velocity.y *= -1.0
		Juice.burst(self, brick_center, Color(1, 0.83, 0.3), 12, 240.0)
		Juice.text(self, "+100", brick_center + Vector2(-24, -8), Color(1, 0.9, 0.35), 24)
		if not brick_alive.has(true):
			_end_round(true)
		return

func _end_round(won: bool) -> void:
	if state != "playing":
		return
	state = "win" if won else "game_over"
	best = maxi(best, score)
	Global.brick_reactor_best = best
	if GameLauncher.has_return_scene():
		GameLauncher.record_result("brick_reactor", score, won)
	Global.save()
	message_label.text = "CORE BROKEN!\nSCORE %d  ·  PRESS LAUNCH TO PLAY AGAIN" % score if won else "CORE LOST\nSCORE %d  ·  PRESS LAUNCH TO RETRY" % score
	Juice.shake(self, 0.7 if won else 0.45)
	Juice.burst(self, ball, Color(1, 0.83, 0.3) if won else Color(1, 0.3, 0.3), 24, 320.0)
	_update_hud()
	queue_redraw()

func _restart() -> void:
	score = 0
	paddle.position = Vector2(535, 610)
	ball = Vector2(paddle.get_center().x, paddle.position.y - BALL_RADIUS - 3.0)
	velocity = Vector2.ZERO
	state = "ready"
	_build_bricks()
	message_label.text = "LAUNCH  ·  BREAK EVERY BRICK"
	_update_hud()
	queue_redraw()

func _update_hud() -> void:
	score_label.text = "SCORE  %04d" % score
	best_label.text = "BEST  %04d" % best

func _return_to_library() -> void:
	await SceneFade.fade_out(self)
	if GameLauncher.has_return_scene():
		GameLauncher.return_to_library()
	else:
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.035, 0.05, 0.12))
	draw_rect(BOARD, Color(0.02, 0.03, 0.08), false, 4.0)
	for row in ROWS:
		for column in COLUMNS:
			var index := row * COLUMNS + column
			if not brick_alive[index]:
				continue
			var fill: Color = BRICK_COLORS[row]
			draw_rect(bricks[index], Color(0.01, 0.02, 0.06))
			draw_rect(Rect2(bricks[index].position + Vector2(3, 3), bricks[index].size - Vector2(6, 6)), fill)
			draw_line(bricks[index].position + Vector2(5, 4), bricks[index].end - Vector2(5, bricks[index].size.y - 4), Color(1, 0.95, 0.75), 2.0)
	draw_rect(paddle, Color(0.02, 0.03, 0.08))
	draw_rect(Rect2(paddle.position + Vector2(5, 4), paddle.size - Vector2(10, 8)), Color(0.45, 0.85, 1.0))
	draw_circle(ball, BALL_RADIUS + 4.0, Color(1, 0.83, 0.3, 0.25))
	draw_circle(ball, BALL_RADIUS, Color(1, 0.95, 0.72))
