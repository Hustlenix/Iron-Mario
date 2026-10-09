extends "res://microgames/microgame_base.gd"
## Preserved cabinet: launch, steer paddle, bounce, break all forty-five bricks.
const BOARD := Rect2(45, 65, 870, 316)
const PADDLE_SIZE := Vector2(150, 18)
const BALL_RADIUS := 8.0
const COLUMNS := 9
const ROWS := 5
const SPEED := 425.0
const LEFT_BUTTON := Rect2(30, 387, 210, 90)
const LAUNCH_BUTTON := Rect2(375, 387, 210, 90)
const RIGHT_BUTTON := Rect2(720, 387, 210, 90)
var paddle := Rect2(405, 350, 150, 18)
var ball := Vector2(480, 339)
var velocity := Vector2.ZERO
var bricks: Array[Rect2] = []
var brick_alive: Array[bool] = []
var score := 0
var state := "ready"
var axis := 0.0
var touch_axis := 0.0

func setup() -> void:
	paddle = Rect2(405, 350, PADDLE_SIZE.x, PADDLE_SIZE.y)
	ball = Vector2(480, 339)
	velocity = Vector2.ZERO
	score = 0
	state = "ready"
	axis = 0.0
	touch_axis = 0.0
	bricks.clear()
	brick_alive.clear()
	for row in range(ROWS):
		for column in range(COLUMNS):
			bricks.append(Rect2(72 + column * 91, 91 + row * 35, 84, 26))
			brick_alive.append(true)

func launch() -> void:
	if state != "ready": return
	state = "playing"
	velocity = Vector2(0.4, -1.0).normalized() * SPEED

func lose() -> void:
	if finished: return
	finished = true
	points = score
	completed.emit(false, score)

func tick(delta: float) -> void:
	# Substeps keep collision fair across low frame rates and faster difficulties.
	var steps: int = maxi(1, int(ceil(delta / 0.005)))
	var dt: float = delta / steps
	for i in range(steps):
		if finished: break
		paddle.position.x = clampf(paddle.position.x + clampf(axis + touch_axis, -1, 1) * 590 * dt, BOARD.position.x, BOARD.end.x - paddle.size.x)
		if state == "ready":
			ball = Vector2(paddle.get_center().x, paddle.position.y - BALL_RADIUS - 3)
			continue
		var previous: Vector2 = ball
		ball += velocity * dt
		if ball.x - BALL_RADIUS <= BOARD.position.x:
			ball.x = BOARD.position.x + BALL_RADIUS
			velocity.x = absf(velocity.x)
		elif ball.x + BALL_RADIUS >= BOARD.end.x:
			ball.x = BOARD.end.x - BALL_RADIUS
			velocity.x = -absf(velocity.x)
		if ball.y - BALL_RADIUS <= BOARD.position.y:
			ball.y = BOARD.position.y + BALL_RADIUS
			velocity.y = absf(velocity.y)
		if velocity.y > 0 and ball.y + BALL_RADIUS >= paddle.position.y and previous.y + BALL_RADIUS <= paddle.position.y and ball.x >= paddle.position.x - BALL_RADIUS and ball.x <= paddle.end.x + BALL_RADIUS:
			ball.y = paddle.position.y - BALL_RADIUS
			var offset: float = clampf((ball.x - paddle.get_center().x) / (paddle.size.x * 0.5), -0.95, 0.95)
			velocity = Vector2(offset * 0.95, -1).normalized() * SPEED
			feedback(ball)
		if ball.y - BALL_RADIUS > BOARD.end.y: lose(); return
		hit_brick(previous)

func hit_brick(previous: Vector2) -> void:
	var shape := Rect2(ball - Vector2.ONE * BALL_RADIUS, Vector2.ONE * BALL_RADIUS * 2)
	for i in range(bricks.size()):
		if not brick_alive[i] or not shape.intersects(bricks[i]): continue
		brick_alive[i] = false
		score += 100
		if previous.y + BALL_RADIUS <= bricks[i].position.y:
			ball.y = bricks[i].position.y - BALL_RADIUS
			velocity.y = -absf(velocity.y)
		elif previous.y - BALL_RADIUS >= bricks[i].end.y:
			ball.y = bricks[i].end.y + BALL_RADIUS
			velocity.y = absf(velocity.y)
		else: velocity.x *= -1
		feedback(bricks[i].get_center())
		if not brick_alive.has(true): win(score)
		return

func handle_action(action: String, point: Vector2, value: Vector2) -> void:
	if finished: return
	if action == "cancel": axis = 0.0; touch_axis = 0.0
	elif action == "move": axis = value.x
	elif action == "release": touch_axis = 0.0
	elif action == "action": launch()
	elif action == "press":
		if LEFT_BUTTON.has_point(point): touch_axis = -1
		elif RIGHT_BUTTON.has_point(point): touch_axis = 1
		else: launch()
	elif action == "drag" and BOARD.has_point(point): paddle.position.x = clampf(point.x - paddle.size.x / 2, BOARD.position.x, BOARD.end.x - paddle.size.x)

func paint() -> void:
	text_at(Vector2(30, 40), "BRICK REACTOR", 30)
	text_at(Vector2(620, 40), "BRICKS %d / 45" % (score / 100), 25)
	box(BOARD, Color("e0eaf5"))
	var colors: Array[Color] = [RED, Color("f39a53"), GOLD, BLUE, GREEN]
	for i in range(bricks.size()):
		if brick_alive[i]: box(bricks[i], colors[i / COLUMNS])
	box(paddle, BLUE)
	disc(ball, BALL_RADIUS, RED)
	if state == "ready": text_at(Vector2(290, 320), "PRESS LAUNCH TO START", 26)
	for item in [[LEFT_BUTTON, "LEFT"], [LAUNCH_BUTTON, "LAUNCH"], [RIGHT_BUTTON, "RIGHT"]]:
		box(item[0], GOLD if item[1] == "LAUNCH" else BLUE)
		text_at(item[0].position + Vector2(55, 50), item[1], 25)
