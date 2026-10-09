extends "res://microgames/microgame_base.gd"
## Preserved cabinet: grid movement, growing tail, reactor food, optional boost.
const CELL := 32
const COLUMNS := 24
const ROWS := 9
const BOARD := Rect2(96, 93, 768, 288)
const LEFT_BUTTON := Rect2(30, 387, 210, 90)
const BOOST_BUTTON := Rect2(375, 387, 210, 90)
const RIGHT_BUTTON := Rect2(720, 387, 210, 90)
var snake: Array[Vector2i] = []
var direction := Vector2i.RIGHT
var next_direction := Vector2i.RIGHT
var food := Vector2i.ZERO
var score := 0
var collected := 0
var boost := false
var step_clock := 0.0
var moved_since_turn := true

func setup() -> void:
	snake = [Vector2i(8, 4), Vector2i(7, 4), Vector2i(6, 4)]
	direction = Vector2i.RIGHT
	next_direction = direction
	score = 0
	collected = 0
	boost = false
	step_clock = 0.0
	moved_since_turn = true
	place_food()

func step_duration() -> float:
	return maxf(0.085, 0.16 - collected * 0.005 - (difficulty - 1.0) * 0.005) * (0.72 if boost else 1.0)

func tick(delta: float) -> void:
	step_clock += delta
	while step_clock >= step_duration() and not finished:
		step_clock -= step_duration()
		direction = next_direction
		var head: Vector2i = snake[0] + direction
		var grows: bool = head == food
		# The tail vacates its cell on a non-growing step, so that cell is legal.
		var occupied: Array[Vector2i] = snake.duplicate()
		if not grows: occupied.pop_back()
		if head.x < 0 or head.x >= COLUMNS or head.y < 0 or head.y >= ROWS or occupied.has(head):
			lose()
			return
		snake.push_front(head)
		if grows:
			collected += 1
			score += 100
			feedback(cell_center(head))
			if collected >= 8: win(score); return
			place_food()
		else: snake.pop_back()
		moved_since_turn = true

func place_food() -> void:
	var available: Array[Vector2i] = []
	for y in range(ROWS):
		for x in range(COLUMNS):
			var cell := Vector2i(x, y)
			if not snake.has(cell): available.append(cell)
	if available.is_empty(): win(score); return
	food = available[rng.randi_range(0, available.size() - 1)]

func lose() -> void:
	if finished: return
	finished = true
	points = score
	completed.emit(false, score)

func turn(wanted: Vector2i) -> void:
	if moved_since_turn and wanted != -direction and wanted != Vector2i.ZERO:
		next_direction = wanted
		moved_since_turn = false

func handle_action(action: String, point: Vector2, value: Vector2) -> void:
	if finished: return
	if action == "cancel": boost = false
	elif action == "direction":
		turn(Vector2i(value.round()))
	elif action == "action": boost = true
	elif action == "release": boost = false
	elif action == "press":
		if LEFT_BUTTON.has_point(point): turn(Vector2i(direction.y, -direction.x))
		elif RIGHT_BUTTON.has_point(point): turn(Vector2i(-direction.y, direction.x))
		elif BOOST_BUTTON.has_point(point): boost = true

func cell_center(cell: Vector2i) -> Vector2:
	return BOARD.position + Vector2(cell) * CELL + Vector2.ONE * CELL * 0.5

func paint() -> void:
	text_at(Vector2(30, 43), "ARC SNAKE", 31)
	text_at(Vector2(520, 43), "CORES %d / 8   SCORE %d" % [collected, score], 25)
	box(BOARD.grow(5), INK)
	draw_rect(BOARD, Color("e4edda"))
	for x in range(COLUMNS + 1): draw_line(BOARD.position + Vector2(x * CELL, 0), BOARD.position + Vector2(x * CELL, BOARD.size.y), Color("cbd7bc"))
	for y in range(ROWS + 1): draw_line(BOARD.position + Vector2(0, y * CELL), BOARD.position + Vector2(BOARD.size.x, y * CELL), Color("cbd7bc"))
	disc(cell_center(food), 10, BLUE)
	for i in range(snake.size()): box(Rect2(cell_center(snake[i]) - Vector2(12, 12), Vector2(24, 24)), RED if i == 0 else GOLD)
	for item in [[LEFT_BUTTON, "TURN LEFT"], [BOOST_BUTTON, "BOOST"], [RIGHT_BUTTON, "TURN RIGHT"]]:
		box(item[0], GOLD if item[1] == "BOOST" and boost else BLUE)
		text_at(item[0].position + Vector2(30, 50), item[1], 24)
	text_at(Vector2(96, 84), "Arrows: turn. Space: boost. Eat eight cores. Avoid walls and your tail.", 20)
