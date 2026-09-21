extends Node2D

const GRAVITY := 1400.0
const MAX_FALL := 900.0
const FLAP_VELOCITY := -420.0
const BIRD_X := 200.0
const BIRD_SIZE := 70.0
const GROUND_Y := 620.0
const PIPE_WIDTH := 110.0
const PIPE_RIM := 16.0
const GAP_MIN_CENTER := 200.0
const GAP_MAX_CENTER := 560.0
const PIPE_POOL := 6
const TRAIL_COUNT := 10
const HITBOX_SHRINK := 0.075

const _MEDALS := [
	{"score": 5, "name": "BRONZE", "color": Color(0.72, 0.45, 0.22), "icon": "res://assets/medal_bronze.svg"},
	{"score": 10, "name": "SILVER", "color": Color(0.8, 0.8, 0.85), "icon": "res://assets/medal_silver.svg"},
	{"score": 20, "name": "GOLD", "color": Color(1.0, 0.84, 0.3), "icon": "res://assets/medal_gold.svg"},
	{"score": 40, "name": "PLATINUM", "color": Color(0.55, 0.9, 1.0), "icon": "res://assets/medal_platinum.svg"},
]

var state := "title"
var score := 0
var velocity := 0.0
var bird_y := 300.0
var best := 0
var new_best_fired := false
var medals := {}
var feathers := 0
var invuln_timer := 0.0
var feather_next_spawn := 8

var feather_every_min := 8
var feather_every_max := 12

var _pipe_meta := {}
var _spawn_timer := 0.0
var _spawned := 0
var last_gap_center := 300.0
var leaving := false
var _trail_index := 0
var _trail_timer := 0.0

@onready var pipes_node: Node2D = $Pipes
@onready var pickups_node: Node2D = $Pickups
@onready var trail_node: Node2D = $Trail
@onready var bird: TextureRect = $Bird
@onready var score_label: RichTextLabel = $HUD/ScoreLabel
@onready var best_label: RichTextLabel = $HUD/BestLabel
@onready var medal_label: RichTextLabel = $HUD/MedalLabel
@onready var medal_icon: TextureRect = $HUD/MedalIcon
@onready var feather_icon: TextureRect = $HUD/FeatherIcon
@onready var hint_label: RichTextLabel = $HUD/HintLabel
@onready var sfx_flap: AudioStreamPlayer = $SfxFlap
@onready var sfx_score: AudioStreamPlayer = $SfxScore
@onready var sfx_hit: AudioStreamPlayer = $SfxHit
@onready var sfx_pickup: AudioStreamPlayer = $SfxPickup
@onready var sfx_win: AudioStreamPlayer = $SfxWin
@onready var bgm: AudioStreamPlayer = $Bgm

func _ready() -> void:
	for visual in [$Background, $HUD, bird, pipes_node, pickups_node, trail_node]:
		visual.modulate = Color.TRANSPARENT
	bird.modulate = Color.WHITE
	bird.self_modulate = Color.TRANSPARENT
	add_child(preload("res://scripts/ui/FlappyPaint.gd").new())
	SceneFade.fade_in(self)
	best = Global.flappy_best
	best_label.text = "BEST: %d" % best
	build_sounds()
	_build_pipe_pool()
	_build_trail()
	bgm.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	bgm.play()

func get_state() -> String:
	return state

func flap() -> void:
	match state:
		"title":
			state = "playing"
			hint_label.visible = false
			_spawn_timer = randf_range(1.6, 2.4)
			velocity = FLAP_VELOCITY
			_do_flap_visuals()
		"playing":
			velocity = FLAP_VELOCITY
			_do_flap_visuals()

func build_sounds() -> void:
	sfx_flap.stream = _make_beep(620.0, 0.07, 0.5)
	sfx_score.stream = _make_beep(880.0, 0.09, 0.45)
	sfx_hit.stream = _make_beep(160.0, 0.3, 0.7, 1.2)
	sfx_pickup.stream = _make_beep(1040.0, 0.1, 0.5)
	sfx_win.stream = _make_beep(660.0, 0.4, 0.6, 0.4)

func _make_beep(freq: float, duration: float, volume: float, wobble := 0.0) -> AudioStreamWAV:
	var sr := 22050
	var n := int(sr * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	var slide := 1.0 + wobble
	for i in n:
		var t := float(i) / float(sr)
		var env := minf(t / 0.01, 1.0) * maxf(1.0 - t / duration, 0.0)
		var f := freq * (1.0 + (slide - 1.0) * t / duration)
		var s := sin(TAU * f * t) * env * volume
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sr
	wav.stereo = false
	wav.data = data
	return wav

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or leaving:
		return
	if event.is_action_pressed("ui_cancel"):
		_go_menu()
	elif event.is_action_pressed("restart") and state == "game_over":
		_restart()
	elif event.is_action_pressed("click") or event.is_action_pressed("jump"):
		if state == "game_over":
			_restart()
		elif state in ["title", "playing"]:
			flap()
	else:
		return
	get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if leaving or state == "title":
		return

	if state == "dying":
		velocity = minf(velocity + GRAVITY * delta, MAX_FALL)
		bird_y = minf(GROUND_Y - BIRD_SIZE, bird_y + velocity * delta)
		_apply_bird()
		return
	if state == "game_over":
		return
	velocity = minf(velocity + GRAVITY * delta, MAX_FALL)
	bird_y += velocity * delta
	if bird_y < 0.0:
		bird_y = 0.0
		velocity = 0.0
	_apply_bird()
	if invuln_timer > 0.0:
		invuln_timer -= delta
		bird.modulate.a = 0.3 if fmod(invuln_timer, 0.2) < 0.1 else 1.0
	else:
		bird.modulate.a = 1.0
	_move_pipes(delta)
	_move_pickups(delta)
	_update_trail(delta)
	if bird_y + BIRD_SIZE >= GROUND_Y:
		_die()
		return
	if invuln_timer <= 0.0 and _collides():
		if feathers > 0:
			feathers -= 1
			feather_icon.visible = false
			invuln_timer = 1.0
			Juice.burst(self, Vector2(BIRD_X, bird_y + BIRD_SIZE * 0.5), Color(0.31, 0.82, 1.0), 18, 300.0)
			Juice.shake(self, 0.3)
			sfx_pickup.play()
		else:
			_die()

func _do_flap_visuals() -> void:
	sfx_flap.play()
	Juice.burst(self, Vector2(BIRD_X - 24.0, bird_y + 30.0), Color(0.31, 0.82, 1.0), 3, 160.0)
	var tween := create_tween()
	tween.tween_property(bird, "scale", Vector2(1.25, 0.75), 0.09)
	tween.tween_property(bird, "scale", Vector2.ONE, 0.16)

func _apply_bird() -> void:
	bird.position.y = bird_y
	var target_rot := clampf(velocity / MAX_FALL, -1.0, 1.0) * 0.6
	bird.rotation = lerpf(bird.rotation, target_rot, 0.12)
	var stretch := 0.85 if velocity > 0.0 else 1.0
	bird.scale.y = lerpf(bird.scale.y, stretch, 0.1)
	bird.scale.x = lerpf(bird.scale.x, 1.0 / maxf(stretch, 0.01), 0.1)

func _build_pipe_pool() -> void:
	var bodies := [
		load("res://assets/pipe_body_red.svg") as Texture2D,
		load("res://assets/pipe_body_blue.svg") as Texture2D,
	]
	var rims := [
		load("res://assets/pipe_rim_red.svg") as Texture2D,
		load("res://assets/pipe_rim_blue.svg") as Texture2D,
	]
	for i in PIPE_POOL:
		var pair := Node2D.new()
		var top_body := TextureRect.new()
		top_body.texture = bodies[i % 2]
		top_body.size = Vector2(PIPE_WIDTH, 1000.0)
		top_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pair.add_child(top_body)
		var top_rim := TextureRect.new()
		top_rim.texture = rims[i % 2]
		top_rim.size = Vector2(PIPE_WIDTH, PIPE_RIM)
		top_rim.position = Vector2(0.0, 1000.0 - PIPE_RIM)
		top_rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pair.add_child(top_rim)
		var bottom_body := TextureRect.new()
		bottom_body.texture = bodies[i % 2]
		bottom_body.size = Vector2(PIPE_WIDTH, 1000.0)
		bottom_body.position = Vector2(0.0, 1024.0)
		bottom_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pair.add_child(bottom_body)
		var bottom_rim := TextureRect.new()
		bottom_rim.texture = rims[i % 2]
		bottom_rim.size = Vector2(PIPE_WIDTH, PIPE_RIM)
		bottom_rim.position = Vector2(0.0, 1024.0)
		bottom_rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pair.add_child(bottom_rim)
		pair.visible = false
		pipes_node.add_child(pair)
		_pipe_meta[pair] = {"gap_y": 0.0, "gap": 280.0, "scored": false}

func _move_pipes(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_pair()
		_spawn_timer = _ramp_interval()
	var active := false
	for pair in pipes_node.get_children():
		if not pair.visible:
			continue
		active = true
		pair.position.x -= _ramp_speed() * delta
		var meta: Dictionary = _pipe_meta[pair]
		if not meta.scored and pair.position.x + PIPE_WIDTH < BIRD_X:
			meta.scored = true
			_score()
		if pair.position.x + PIPE_WIDTH < -80.0:
			pair.visible = false
	if not active and _spawned > 0:
		_spawn_timer = minf(_spawn_timer, 0.5)

func _ramp_factor() -> float:
	return clampf(score / 25.0, 0.0, 1.0)

func _ramp_speed() -> float:
	return lerpf(240.0, 330.0, _ramp_factor())

func _ramp_gap() -> float:
	return lerpf(280.0, 210.0, _ramp_factor())

func _ramp_interval() -> float:
	return lerpf(1.5, 1.1, _ramp_factor())

func _spawn_pair() -> void:
	var pair: Node2D
	for p in pipes_node.get_children():
		if not p.visible:
			pair = p
			break
	if pair == null:
		return
	_spawned += 1
	var use_gap := _ramp_gap() if _spawned > 3 else maxf(_ramp_gap(), 280.0)
	var low := maxf(90.0 + use_gap * 0.5, last_gap_center - 95.0)
	var high := minf(GROUND_Y - 36.0 - use_gap * 0.5, last_gap_center + 95.0)
	var center := clampf(300.0, low, high) if _spawned == 1 else randf_range(low, high)
	last_gap_center = center
	_place_pair(pair, center, use_gap)
	_spawn_pickup_if_due(center, use_gap)

func _place_pair(pair: Node2D, center: float, use_gap: float) -> void:
	pair.position = Vector2(1400.0, 0.0)
	var children := pair.get_children()
	children[0].position.y = center - use_gap * 0.5 - 1000.0
	children[1].position.y = center - use_gap * 0.5 - PIPE_RIM
	children[2].position.y = center + use_gap * 0.5
	children[3].position.y = center + use_gap * 0.5
	pair.visible = true
	_pipe_meta[pair] = {"gap_y": center, "gap": use_gap, "scored": false}

func _spawn_pickup_if_due(center: float, use_gap: float) -> void:
	if _spawned <= 3 or _spawned != feather_next_spawn:
		return
	var pickup := TextureRect.new()
	pickup.texture = load("res://assets/web_orb.svg") as Texture2D
	pickup.custom_minimum_size = Vector2(40.0, 40.0)
	pickup.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pickup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pickup.position = Vector2(1400.0, center - 20.0)
	pickups_node.add_child(pickup)
	feather_next_spawn = _spawned + randi_range(feather_every_min, feather_every_max)

func _collides() -> bool:
	var bird_rect := Rect2(BIRD_X + BIRD_SIZE * HITBOX_SHRINK, bird_y + BIRD_SIZE * HITBOX_SHRINK, BIRD_SIZE * (1.0 - 2.0 * HITBOX_SHRINK), BIRD_SIZE * (1.0 - 2.0 * HITBOX_SHRINK))
	if bird_y + BIRD_SIZE >= GROUND_Y:
		return true
	for pair in pipes_node.get_children():
		if not pair.visible:
			continue
		var meta: Dictionary = _pipe_meta[pair]
		var top := Rect2(pair.position.x, meta.gap_y - meta.gap * 0.5 - 1000.0, PIPE_WIDTH, 1000.0)
		var bottom := Rect2(pair.position.x, meta.gap_y + meta.gap * 0.5, PIPE_WIDTH, 1000.0)
		if bird_rect.intersects(top) or bird_rect.intersects(bottom):
			return true
	return false

func _score() -> void:
	score += 1
	score_label.text = "%d" % score
	sfx_score.play()
	Juice.text(self, "+1", Vector2(BIRD_X + 40.0, bird_y), Color(0.6, 1.0, 0.65), 30)
	Juice.shake(self, 0.05)
	_check_medal()
	_check_new_best()

func _check_medal() -> void:
	for medal in _MEDALS:
		if score >= int(medal.score) and not medals.has(medal.name):
			medals[medal.name] = true
			medal_label.text = medal.name
			medal_icon.texture = load(medal.icon) as Texture2D
			medal_icon.visible = true
			medal_label.add_theme_color_override("font_color", medal.color)
			Juice.burst(self, Vector2(1100.0, 60.0), medal.color, 16, 260.0)
			Juice.text(self, medal.name, Vector2(1180.0, 90.0), medal.color, 34)
			sfx_score.play()

func _check_new_best() -> void:
	if score > best:
		best = score
		Global.flappy_best = best
		Global.save()
		best_label.text = "BEST: %d" % best
		if new_best_fired:
			return
		new_best_fired = true
		score_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.3))
		sfx_win.play()
		Juice.burst(self, Vector2(BIRD_X, bird_y), Color(1.0, 0.84, 0.3), 22, 320.0)
		Juice.text(self, "NEW BEST!", Vector2(BIRD_X + 30.0, bird_y - 30.0), Color(1.0, 0.84, 0.3), 38)

func _die() -> void:
	if state != "playing":
		return
	state = "dying"
	sfx_hit.play()
	Juice.hit_stop(self)
	Juice.shake(self, 0.6)
	Juice.burst(self, Vector2(BIRD_X, bird_y + BIRD_SIZE * 0.5), Color(1.0, 0.3, 0.3), 18, 300.0)
	var tween := create_tween()
	tween.tween_property(bird, "rotation", PI, 0.45)
	await get_tree().create_timer(0.45).timeout
	state = "game_over"
	_show_game_over()

func _show_game_over() -> void:
	hint_label.text = "SCORE %d   BEST %d\nTAP / SPACE TO RETRY   ESC FOR MENU" % [score, best]
	hint_label.visible = true
	best_label.text = "BEST: %d" % best

func _restart() -> void:
	for pair in pipes_node.get_children():
		pair.visible = false
	for pickup in pickups_node.get_children():
		pickup.queue_free()
	score = 0
	feathers = 0
	feather_icon.visible = false
	invuln_timer = 0.0
	medals = {}
	new_best_fired = false
	_spawned = 0
	last_gap_center = 300.0
	_trail_index = 0
	_trail_timer = 0.0
	for ghost in trail_node.get_children():
		ghost.modulate.a = 0.0
	_spawn_timer = randf_range(1.6, 2.4)
	feather_next_spawn = feather_every_min
	bird_y = 300.0
	velocity = 0.0
	bird.rotation = 0.0
	bird.modulate.a = 1.0
	score_label.text = "0"
	score_label.remove_theme_color_override("font_color")
	best_label.text = "BEST: %d" % best
	medal_label.text = ""
	medal_icon.visible = false
	hint_label.visible = false
	state = "title"
	flap()

func _build_trail() -> void:
	for i in TRAIL_COUNT:
		var node := TextureRect.new()
		node.texture = load("res://assets/flappy_hero.svg") as Texture2D
		node.size = Vector2(BIRD_SIZE, BIRD_SIZE)
		node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.modulate = Color(0.31, 0.82, 1.0, 0.0)
		trail_node.add_child(node)

func _update_trail(delta: float) -> void:
	_trail_timer += delta
	if _trail_timer >= 0.035:
		_trail_timer = 0.0
		var node := trail_node.get_child(_trail_index) as TextureRect
		_trail_index = (_trail_index + 1) % TRAIL_COUNT
		node.position = Vector2(BIRD_X - BIRD_SIZE * 0.5 - 14.0, bird_y - BIRD_SIZE * 0.5)
		node.rotation = bird.rotation
		node.modulate.a = 0.35
		var tween := create_tween()
		tween.tween_property(node, "modulate:a", 0.0, 0.3)

func _move_pickups(delta: float) -> void:
	for pickup in pickups_node.get_children():
		pickup.position.x -= _ramp_speed() * delta
		var bird_rect := Rect2(BIRD_X + BIRD_SIZE * HITBOX_SHRINK, bird_y + BIRD_SIZE * HITBOX_SHRINK, BIRD_SIZE * (1.0 - 2.0 * HITBOX_SHRINK), BIRD_SIZE * (1.0 - 2.0 * HITBOX_SHRINK))
		if bird_rect.intersects(Rect2(pickup.position, Vector2(40.0, 40.0))) and feathers == 0:
			feathers += 1
			feather_icon.visible = true
			sfx_pickup.play()
			Juice.burst(self, pickup.position + Vector2(20.0, 20.0), Color(0.31, 0.82, 1.0), 14, 240.0)
			pickup.queue_free()
		elif pickup.position.x < -80.0:
			pickup.queue_free()

func _go_menu() -> void:
	if leaving:
		return
	leaving = true
	await SceneFade.fade_out(self).finished
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _exit_tree() -> void:
	Engine.time_scale = 1.0
