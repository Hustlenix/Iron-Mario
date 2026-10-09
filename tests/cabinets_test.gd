extends SceneTree
## Action/physics drivers observe state but never call win/lose or assign score.
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok: failures.append(detail)

func make_game(entry: Dictionary, difficulty_value: float = 1.0, seed_value: int = 23) -> MicrogameBase:
	var game: MicrogameBase = load(entry.script).new()
	root.add_child(game)
	game.set_process(false)
	game.start(entry, difficulty_value, seed_value)
	return game

func run() -> void:
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://games/cabinets.json"))
	for entry in entries:
		check(entry.tournament_enabled == false, entry.id + " long cabinet excluded from microgame tournament")
		for level in [1.0, 6.0]:
			for seed_value in [23, 94]:
				var game: MicrogameBase = make_game(entry, level, seed_value)
				var result := {"count": 0, "won": false, "score": 0}
				game.completed.connect(func(won: bool, score: int) -> void: result.count += 1; result.won = won; result.score = score)
				verify_controls(game, entry.id)
				game.cancel_input()
				check(not game.finished and result.count == 0, entry.id + " input cancellation never commits a failed action")
				if entry.id == "arc_snake": check(not game.boost, "Snake cancel clears held boost")
				else: check(game.axis == 0 and game.touch_axis == 0, entry.id + " cancel clears keyboard and touch steering")
				var paused_time: float = game.elapsed
				game.active = false
				game.advance(1.0)
				check(game.elapsed == paused_time, entry.id + " pause freezes simulation")
				game.active = true
				# Control check starts a clean real round before the complete driver.
				game.start(entry, level, seed_value)
				play(game, entry.id)
				check(game.finished and result.won, entry.id + " actual win level=" + str(level) + " seed=" + str(seed_value) + " elapsed=" + str(game.elapsed))
				check(result.count == 1 and result.score > 0, entry.id + " emits one positive-score result")
				game.advance(1)
				game.handle_action("action", Vector2(480, 430), Vector2.ZERO)
				check(result.count == 1, entry.id + " terminal result is idempotent")
				result.count = 0
				result.won = false
				game.start(entry, level, seed_value)
				check(not game.finished and game.elapsed == 0 and game.points == 0, entry.id + " same-instance restart resets round")
				play_failure(game, entry.id)
				check(game.finished and not result.won and result.count == 1, entry.id + " real loss after restart")
				var weak: WeakRef = weakref(game)
				game.free()
				check(weak.get_ref() == null, entry.id + " destroy releases round")
	print("CABINET_CHECKS=", checks, " FAILURES=", failures.size())
	for failure in failures: print(failure)
	quit(0 if failures.is_empty() else 1)

func verify_controls(game: MicrogameBase, id: String) -> void:
	match id:
		"arc_snake":
			game.handle_action("direction", Vector2.ZERO, Vector2.UP)
			game.advance(0.17)
			check(game.direction == Vector2i.UP, "Snake cardinal turn changes heading")
			game.handle_action("action", Vector2.ZERO, Vector2.ZERO)
			check(game.boost and game.step_duration() < 0.13, "Snake boost changes actual movement cadence")
			game.handle_action("release", Vector2.ZERO, Vector2.ZERO)
			check(not game.boost, "Snake release stops boost")
		"brick_reactor":
			var before: float = game.paddle.position.x
			game.handle_action("press", Vector2(850, 440), Vector2.ZERO)
			game.advance(0.1)
			check(game.paddle.position.x > before, "Brick touch right moves paddle")
			game.handle_action("release", Vector2(850, 440), Vector2.ZERO)
			game.handle_action("action", Vector2.ZERO, Vector2.ZERO)
			check(game.state == "playing" and game.velocity.length() > 0, "Brick primary action launches ball")
		"tower_bounce":
			var before: float = game.player.x
			game.handle_action("press", Vector2(850, 440), Vector2.ZERO)
			game.advance(0.1)
			check(game.player.x > before, "Tower touch right accelerates character")
			game.handle_action("release", Vector2(850, 440), Vector2.ZERO)
			check(game.touch_axis == 0, "Tower release clears held steering")

func play(game: MicrogameBase, id: String) -> void:
	if id == "brick_reactor": game.handle_action("action", Vector2.ZERO, Vector2.ZERO)
	var tower_plan := {"bounce": -1, "x": 265.0}
	for frame in range(10000):
		if game.finished: break
		match id:
			"arc_snake": drive_snake(game)
			"brick_reactor": drive_bricks(game)
			"tower_bounce": drive_tower(game, tower_plan)
		game.advance(0.01)
	if id == "arc_snake": check(game.collected == 8 and game.snake.size() == 11, "Snake eats eight real foods and grows")
	if id == "brick_reactor": check(not game.brick_alive.has(true) and game.score == 4500, "Brick physical collisions break all forty-five bricks")
	if id == "tower_bounce": check(game.bounces > 8 and game.generated > 12 and game.platforms.size() < 16, "Tower generates reachable new platforms and removes old ones")

func play_failure(game: MicrogameBase, id: String) -> void:
	if id == "brick_reactor":
		game.handle_action("action", Vector2.ZERO, Vector2.ZERO)
		game.handle_action("move", Vector2.ZERO, Vector2.LEFT)
	elif id == "tower_bounce": game.handle_action("move", Vector2.ZERO, Vector2.LEFT)
	for frame in range(10000):
		if game.finished: break
		game.advance(0.01)

func drive_snake(game: MicrogameBase) -> void:
	if not game.moved_since_turn: return
	var head: Vector2i = game.snake[0]
	var queue: Array[Vector2i] = [head]
	var previous := {head: head}
	var forbidden: Array = game.snake.slice(0, game.snake.size() - 1)
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
	var index := 0
	while index < queue.size() and not previous.has(game.food):
		var cell: Vector2i = queue[index]
		index += 1
		for step in directions:
			var next: Vector2i = cell + step
			if next.x < 0 or next.x >= game.COLUMNS or next.y < 0 or next.y >= game.ROWS or previous.has(next) or forbidden.has(next): continue
			if cell == head and step == -game.direction: continue
			previous[next] = cell
			queue.append(next)
	var destination: Vector2i = game.food
	if previous.has(destination):
		while previous[destination] != head: destination = previous[destination]
		game.handle_action("direction", Vector2.ZERO, Vector2(destination - head))
	else:
		for step in directions:
			var next: Vector2i = head + step
			if step != -game.direction and next.x >= 0 and next.x < game.COLUMNS and next.y >= 0 and next.y < game.ROWS and not forbidden.has(next):
				game.handle_action("direction", Vector2.ZERO, Vector2(step))
				return

func drive_bricks(game: MicrogameBase) -> void:
	var target := Vector2(480, 110)
	var closest := INF
	for i in range(game.bricks.size()):
		if not game.brick_alive[i]: continue
		var center: Vector2 = game.bricks[i].get_center()
		var cost: float = absf(center.x - game.ball.x) + (250 - center.y) * 0.4
		if cost < closest: closest = cost; target = center
	var slope: float = clampf((target.x - game.ball.x) / maxf(80, game.paddle.position.y - target.y), -0.8, 0.8)
	var desired: float = game.ball.x - slope / 0.95 * game.paddle.size.x * 0.5
	game.handle_action("drag", Vector2(desired, 370), Vector2.ZERO)

func drive_tower(game: MicrogameBase, plan: Dictionary) -> void:
	# Commit to one reachable platform for the entire jump. Switching targets at
	# the apex would ask a player to land on a platform their jump cannot reach.
	if plan.bounce != game.bounces:
		plan.bounce = game.bounces
		var target: Rect2 = game.platforms[0]
		var selected := false
		var feet: float = game.player.y + game.PLAYER_SIZE.y
		for platform in game.platforms:
			var candidate: bool = platform.position.y >= feet if game.bounces == 0 else (platform.position.y < feet - 8 and platform.position.y > feet - 125)
			if candidate and (not selected or (platform.position.y < target.position.y if game.bounces == 0 else platform.position.y > target.position.y)):
				target = platform
				selected = true
		if selected: plan.x = target.get_center().x
	var offset: float = float(plan.x) - game.player.x - game.PLAYER_SIZE.x * 0.5
	game.handle_action("move", Vector2.ZERO, Vector2(clampf(offset / 30, -1, 1), 0))
