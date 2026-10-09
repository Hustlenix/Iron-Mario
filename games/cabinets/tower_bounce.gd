extends "res://microgames/microgame_base.gd"
## Preserved cabinet: auto-bounce, acceleration, one-way platforms, vertical climb.
const PLAYER_SIZE := Vector2(25, 31)
const GRAVITY := 1000.0
const BOUNCE := -490.0
const HORIZONTAL_SPEED := 320.0
const START := Vector2(250, 299)
const LEFT_BUTTON := Rect2(30, 387, 230, 90)
const RIGHT_BUTTON := Rect2(700, 387, 230, 90)
var player := START
var velocity := Vector2.ZERO
var platforms: Array[Rect2] = []
var height_climbed := 0.0
var last_platform_y := 360.0
var last_platform_x := 230.0
var axis := 0.0
var touch_axis := 0.0
var bounces := 0
var generated := 0

func setup() -> void:
	player = START
	velocity = Vector2.ZERO
	height_climbed = 0.0
	last_platform_y = 360.0
	last_platform_x = 230.0
	axis = 0.0
	touch_axis = 0.0
	bounces = 0
	generated = 0
	platforms = [Rect2(160, 360, 210, 16)]
	generate_platforms()

func generate_platforms() -> void:
	while last_platform_y > -130:
		var gap: float = rng.randf_range(76, 99)
		last_platform_y -= gap
		# Maximum jump rise is 120px. Keep consecutive centers reachable by steering.
		last_platform_x = clampf(last_platform_x + rng.randf_range(-145, 145), 120, 840)
		var width: float = rng.randf_range(140, 185)
		platforms.append(Rect2(last_platform_x - width / 2, last_platform_y, width, 16))
		generated += 1
	platforms = platforms.filter(func(platform: Rect2) -> bool: return platform.position.y < 375)

func lose() -> void:
	if finished: return
	finished = true
	points = int(height_climbed)
	completed.emit(false, points)

func tick(delta: float) -> void:
	var steps: int = maxi(1, int(ceil(delta / 0.008)))
	var dt: float = delta / steps
	for step in range(steps):
		if finished: break
		velocity.x = move_toward(velocity.x, clampf(axis + touch_axis, -1, 1) * HORIZONTAL_SPEED, 1800 * dt)
		velocity.y = minf(velocity.y + GRAVITY * dt, 850)
		var previous_bottom: float = player.y + PLAYER_SIZE.y
		player += velocity * dt
		player.x = clampf(player.x, 16, 944 - PLAYER_SIZE.x)
		if velocity.y > 0:
			for platform in platforms:
				if previous_bottom <= platform.position.y and player.y + PLAYER_SIZE.y >= platform.position.y and player.x + PLAYER_SIZE.x > platform.position.x and player.x < platform.end.x:
					player.y = platform.position.y - PLAYER_SIZE.y
					velocity.y = BOUNCE
					bounces += 1
					feedback(player + PLAYER_SIZE / 2)
					break
		if player.y < 172:
			var shift: float = 172 - player.y
			player.y = 172
			for i in range(platforms.size()): platforms[i].position.y += shift
			# The old cabinet moved platforms without moving this generation cursor.
			last_platform_y += shift
			height_climbed += shift
			generate_platforms()
		if player.y > 360: lose(); return
		if height_climbed >= 1000: win(int(height_climbed)); return

func handle_action(action: String, point: Vector2, value: Vector2) -> void:
	if finished: return
	if action == "cancel": axis = 0.0; touch_axis = 0.0
	elif action == "move": axis = value.x
	elif action == "release": touch_axis = 0
	elif action == "press":
		if LEFT_BUTTON.has_point(point): touch_axis = -1
		elif RIGHT_BUTTON.has_point(point): touch_axis = 1
	elif action == "drag": axis = clampf((point.x - player.x - PLAYER_SIZE.x / 2) / 90, -1, 1)

func paint() -> void:
	text_at(Vector2(30, 42), "TOWER BOUNCE", 31)
	text_at(Vector2(560, 42), "CLIMB %dm / 100m" % int(height_climbed / 10), 25)
	for i in range(12): draw_line(Vector2(i * 90, 70), Vector2(i * 90 + 4, 402), Color("eadbc0"), 2)
	for platform in platforms:
		if platform.position.y > 55 and platform.position.y < 375: box(platform, BLUE)
	hero(player + Vector2(PLAYER_SIZE.x / 2, 10), 0.55)
	box(LEFT_BUTTON, GOLD)
	box(RIGHT_BUTTON, GOLD)
	text_at(LEFT_BUTTON.position + Vector2(78, 49), "LEFT", 28)
	text_at(RIGHT_BUTTON.position + Vector2(68, 49), "RIGHT", 28)
	text_at(Vector2(295, 439), "STEER. LAND. KEEP CLIMBING.", 20)
