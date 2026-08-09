git log --oneline 00a9ff9..HEAD
----
git diff --stat 00a9ff9..HEAD
----
git diff -U10 00a9ff9..HEAD
97510f3 fix(flappy): await ready frame before flap in test driver
7129ce2 feat(flappy): core loop, pipe pool, scoring, collisions
300adfd chore(sdd): task 2 ledger line
----
 .superpowers/sdd/progress.md |   2 +
 scenes/flappy_bird.gd        | 276 ++++++++++++++++++++++++++++++++++++++++++-
 test_flappy.gd               |  22 +++-
 3 files changed, 291 insertions(+), 9 deletions(-)
----
diff --git a/.superpowers/sdd/progress.md b/.superpowers/sdd/progress.md
index f7169db..9ddfbff 100644
--- a/.superpowers/sdd/progress.md
+++ b/.superpowers/sdd/progress.md
@@ -1,2 +1,4 @@
 ∩╗┐Task 1: complete (commits 6d15361..718570d, review clean; Minor: line-length nit inherited from brief)
+Task 2: complete (commit 3adb4af, FLAPPY button on title screen); formal review superseded by the art overhaul ΓÇö restyle commit 3259f17 rebuilt the title screen (bigger hero, web emblem, comic buttons) and was verified headless (import + boot exit 0, texture dimensions checked)
 Art overhaul (Iron-Slinger themed assets + title screen restyle) applied between Task 2 and Task 3; plan & briefs 3/4/6/7 updated to consume the new assets; Task 4 _place_pair rim-placement bug fixed in plan (visual only).
+Task 2: complete (commit 3adb4af + restyle 3259f17; FLAPPY button verified inside restyled title screen; headless boot clean).
diff --git a/scenes/flappy_bird.gd b/scenes/flappy_bird.gd
index d3e3249..35cacfb 100644
--- a/scenes/flappy_bird.gd
+++ b/scenes/flappy_bird.gd
@@ -60,26 +60,290 @@ func _ready() -> void:
 	build_sounds()
 	_build_pipe_pool()
 	_build_trail()
 	bgm.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
 	bgm.play()
 
 func get_state() -> String:
 	return state
 
 func flap() -> void:
-	pass
+	match state:
+		"title":
+			state = "playing"
+			hint_label.visible = false
+			_spawn_timer = randf_range(1.6, 2.4)
+			velocity = FLAP_VELOCITY
+			_do_flap_visuals()
+		"playing":
+			velocity = FLAP_VELOCITY
+			_do_flap_visuals()
 
 func build_sounds() -> void:
 	pass
 
+func _unhandled_input(event: InputEvent) -> void:
+	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
+		if event.pressed:
+			Input.action_press("jump")
+		else:
+			Input.action_release("jump")
+
+func _process(delta: float) -> void:
+	if Input.is_action_just_pressed("ui_cancel"):
+		_go_menu()
+		return
+	if state == "title":
+		if Input.is_action_just_pressed("jump"):
+			flap()
+		return
+	if Input.is_action_just_pressed("jump"):
+		if state == "game_over":
+			_restart()
+		else:
+			flap()
+	if state == "dying":
+		velocity = minf(velocity + GRAVITY * delta, MAX_FALL)
+		bird_y += velocity * delta
+		_apply_bird()
+		return
+	if state == "game_over":
+		return
+	velocity = minf(velocity + GRAVITY * delta, MAX_FALL)
+	bird_y += velocity * delta
+	if bird_y < 0.0:
+		bird_y = 0.0
+		velocity = 0.0
+	_apply_bird()
+	if invuln_timer > 0.0:
+		invuln_timer -= delta
+		bird.modulate.a = 0.3 if fmod(invuln_timer, 0.2) < 0.1 else 1.0
+	else:
+		bird.modulate.a = 1.0
+	_move_pipes(delta)
+	_move_pickups(delta)
+	_update_trail(delta)
+	if invuln_timer <= 0.0 and _collides():
+		if feathers > 0:
+			feathers -= 1
+			feather_icon.visible = false
+			invuln_timer = 1.0
+			Juice.burst(self, Vector2(BIRD_X, bird_y + BIRD_SIZE * 0.5), Color(0.31, 0.82, 1.0), 18, 300.0)
+			Juice.shake(self, 0.3)
+			sfx_pickup.play()
+		else:
+			_die()
+
+func _do_flap_visuals() -> void:
+	sfx_flap.play()
+	Juice.burst(self, Vector2(BIRD_X - 24.0, bird_y + 30.0), Color(0.31, 0.82, 1.0), 3, 160.0)
+	var tween := create_tween()
+	tween.tween_property(bird, "scale", Vector2(1.25, 0.75), 0.09)
+	tween.tween_property(bird, "scale", Vector2.ONE, 0.16)
+
+func _apply_bird() -> void:
+	bird.position.y = bird_y
+	var target_rot := clampf(velocity / MAX_FALL, -1.0, 1.0) * 0.6
+	bird.rotation = lerpf(bird.rotation, target_rot, 0.12)
+	var stretch := 0.85 if velocity > 0.0 else 1.0
+	bird.scale.y = lerpf(bird.scale.y, stretch, 0.1)
+	bird.scale.x = lerpf(bird.scale.x, 1.0 / maxf(stretch, 0.01), 0.1)
+
 func _build_pipe_pool() -> void:
+	var bodies := [
+		load("res://assets/pipe_body_red.svg") as Texture2D,
+		load("res://assets/pipe_body_blue.svg") as Texture2D,
+	]
+	var rims := [
+		load("res://assets/pipe_rim_red.svg") as Texture2D,
+		load("res://assets/pipe_rim_blue.svg") as Texture2D,
+	]
+	for i in PIPE_POOL:
+		var pair := Node2D.new()
+		var top_body := TextureRect.new()
+		top_body.texture = bodies[i % 2]
+		top_body.size = Vector2(PIPE_WIDTH, 1000.0)
+		top_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
+		pair.add_child(top_body)
+		var top_rim := TextureRect.new()
+		top_rim.texture = rims[i % 2]
+		top_rim.size = Vector2(PIPE_WIDTH, PIPE_RIM)
+		top_rim.position = Vector2(0.0, 1000.0 - PIPE_RIM)
+		top_rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
+		pair.add_child(top_rim)
+		var bottom_body := TextureRect.new()
+		bottom_body.texture = bodies[i % 2]
+		bottom_body.size = Vector2(PIPE_WIDTH, 1000.0)
+		bottom_body.position = Vector2(0.0, 1024.0)
+		bottom_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
+		pair.add_child(bottom_body)
+		var bottom_rim := TextureRect.new()
+		bottom_rim.texture = rims[i % 2]
+		bottom_rim.size = Vector2(PIPE_WIDTH, PIPE_RIM)
+		bottom_rim.position = Vector2(0.0, 1024.0)
+		bottom_rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
+		pair.add_child(bottom_rim)
+		pair.visible = false
+		pipes_node.add_child(pair)
+		_pipe_meta[pair] = {"gap_y": 0.0, "gap": 280.0, "scored": false}
+
+func _move_pipes(delta: float) -> void:
+	_spawn_timer -= delta
+	if _spawn_timer <= 0.0:
+		_spawn_pair()
+		_spawn_timer = _ramp_interval()
+	var active := false
+	for pair in pipes_node.get_children():
+		if not pair.visible:
+			continue
+		active = true
+		pair.position.x -= _ramp_speed() * delta
+		var meta: Dictionary = _pipe_meta[pair]
+		if not meta.scored and pair.position.x + PIPE_WIDTH < BIRD_X:
+			meta.scored = true
+			_score()
+		if pair.position.x + PIPE_WIDTH < -80.0:
+			pair.visible = false
+	if not active and _spawned > 0:
+		_spawn_timer = minf(_spawn_timer, 0.5)
+
+func _ramp_factor() -> float:
+	return clampf(score / 25.0, 0.0, 1.0)
+
+func _ramp_speed() -> float:
+	return lerpf(240.0, 330.0, _ramp_factor())
+
+func _ramp_gap() -> float:
+	return lerpf(280.0, 210.0, _ramp_factor())
+
+func _ramp_interval() -> float:
+	return lerpf(1.5, 1.1, _ramp_factor())
+
+func _spawn_pair() -> void:
+	var pair: Node2D
+	for p in pipes_node.get_children():
+		if not p.visible:
+			pair = p
+			break
+	if pair == null:
+		return
+	_spawned += 1
+	var use_gap := _ramp_gap() if _spawned > 3 else maxf(_ramp_gap(), 280.0)
+	var center := randf_range(GAP_MIN_CENTER, GAP_MAX_CENTER)
+	_place_pair(pair, center, use_gap)
+	_spawn_pickup_if_due(center, use_gap)
+
+func _place_pair(pair: Node2D, center: float, use_gap: float) -> void:
+	pair.position = Vector2(1400.0, 0.0)
+	var children := pair.get_children()
+	children[0].position.y = center - use_gap * 0.5 - 1000.0
+	children[1].position.y = center - use_gap * 0.5 - PIPE_RIM
+	children[2].position.y = center + use_gap * 0.5
+	children[3].position.y = center + use_gap * 0.5
+	pair.visible = true
+	_pipe_meta[pair] = {"gap_y": center, "gap": use_gap, "scored": false}
+
+func _spawn_pickup_if_due(_center: float, _use_gap: float) -> void:
 	pass
 
+func _collides() -> bool:
+	var bird_rect := Rect2(BIRD_X + BIRD_SIZE * HITBOX_SHRINK, bird_y + BIRD_SIZE * HITBOX_SHRINK, BIRD_SIZE * (1.0 - 2.0 * HITBOX_SHRINK), BIRD_SIZE * (1.0 - 2.0 * HITBOX_SHRINK))
+	if bird_y + BIRD_SIZE >= GROUND_Y:
+		return true
+	for pair in pipes_node.get_children():
+		if not pair.visible:
+			continue
+		var meta: Dictionary = _pipe_meta[pair]
+		var top := Rect2(pair.position.x, meta.gap_y - meta.gap * 0.5 - 1000.0, PIPE_WIDTH, 1000.0)
+		var bottom := Rect2(pair.position.x, meta.gap_y + meta.gap * 0.5, PIPE_WIDTH, 1000.0)
+		if bird_rect.intersects(top) or bird_rect.intersects(bottom):
+			return true
+	return false
+
+func _score() -> void:
+	score += 1
+	score_label.text = "%d" % score
+	sfx_score.play()
+	Juice.text(self, "+1", Vector2(BIRD_X + 40.0, bird_y), Color(0.6, 1.0, 0.65), 30)
+	Juice.shake(self, 0.05)
+
+func _die() -> void:
+	state = "dying"
+	sfx_hit.play()
+	Juice.hit_stop(self)
+	Juice.shake(self, 0.6)
+	Juice.burst(self, Vector2(BIRD_X, bird_y + BIRD_SIZE * 0.5), Color(1.0, 0.3, 0.3), 18, 300.0)
+	var tween := create_tween()
+	tween.tween_property(bird, "rotation", PI, 0.45)
+	await get_tree().create_timer(0.45).timeout
+	state = "game_over"
+	_show_game_over()
+
+func _show_game_over() -> void:
+	hint_label.text = "SCORE %d   BEST %d\nTAP / SPACE TO RETRY   ESC FOR MENU" % [score, best]
+	hint_label.visible = true
+	best_label.text = "BEST: %d" % best
+
+func _restart() -> void:
+	for pair in pipes_node.get_children():
+		pair.visible = false
+	for pickup in pickups_node.get_children():
+		pickup.queue_free()
+	score = 0
+	feathers = 0
+	feather_icon.visible = false
+	invuln_timer = 0.0
+	medals = {}
+	new_best_fired = false
+	_spawned = 0
+	_spawn_timer = randf_range(1.6, 2.4)
+	feather_next_spawn = feather_every_min
+	bird_y = 300.0
+	velocity = 0.0
+	bird.rotation = 0.0
+	bird.modulate.a = 1.0
+	score_label.text = "0"
+	best_label.text = "BEST: %d" % best
+	medal_label.text = ""
+	medal_icon.visible = false
+	hint_label.visible = false
+	state = "title"
+	flap()
+
 func _build_trail() -> void:
-	pass
+	for i in TRAIL_COUNT:
+		var node := TextureRect.new()
+		node.texture = load("res://assets/flappy_hero.svg") as Texture2D
+		node.custom_minimum_size = Vector2(BIRD_SIZE, BIRD_SIZE)
+		node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
+		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
+		node.modulate = Color(0.31, 0.82, 1.0, 0.0)
+		trail_node.add_child(node)
 
-func _process(delta: float) -> void:
-	pass
+func _update_trail(delta: float) -> void:
+	_trail_timer += delta
+	if _trail_timer >= 0.035:
+		_trail_timer = 0.0
+		var node := trail_node.get_child(_trail_index) as TextureRect
+		_trail_index = (_trail_index + 1) % TRAIL_COUNT
+		node.position = Vector2(BIRD_X - BIRD_SIZE * 0.5 - 14.0, bird_y - BIRD_SIZE * 0.5)
+		node.rotation = bird.rotation
+		node.modulate.a = 0.35
+		var tween := create_tween()
+		tween.tween_property(node, "modulate:a", 0.0, 0.3)
 
-func _unhandled_input(event: InputEvent) -> void:
-	pass
+func _move_pickups(delta: float) -> void:
+	for pickup in pickups_node.get_children():
+		pickup.position.x -= _ramp_speed() * delta
+		var bird_rect := Rect2(BIRD_X + BIRD_SIZE * HITBOX_SHRINK, bird_y + BIRD_SIZE * HITBOX_SHRINK, BIRD_SIZE * (1.0 - 2.0 * HITBOX_SHRINK), BIRD_SIZE * (1.0 - 2.0 * HITBOX_SHRINK))
+		if bird_rect.intersects(Rect2(pickup.position, Vector2(40.0, 40.0))) and feathers == 0:
+			feathers += 1
+			feather_icon.visible = true
+			sfx_pickup.play()
+			Juice.burst(self, pickup.position + Vector2(20.0, 20.0), Color(0.31, 0.82, 1.0), 14, 240.0)
+			pickup.queue_free()
+		elif pickup.position.x < -80.0:
+			pickup.queue_free()
+
+func _go_menu() -> void:
+	await SceneFade.fade_out(self)
+	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
diff --git a/test_flappy.gd b/test_flappy.gd
index 44358d8..d1de97d 100644
--- a/test_flappy.gd
+++ b/test_flappy.gd
@@ -1,19 +1,35 @@
 extends SceneTree
 
 var flappy: Node
 
 func _initialize() -> void:
 	var scene := load("res://scenes/flappy_bird.tscn") as PackedScene
 	flappy = scene.instantiate()
 	root.add_child(flappy)
+	var args := OS.get_cmdline_user_args()
+	if args.has("--flap"):
+		await _test_flap()
+	else:
+		_run_frames(30)
+		if flappy.get_state() == "title":
+			print("FLAPPY BOOT OK")
+			quit(0)
+		else:
+			print("FLAPPY BOOT FAIL: state=%s" % flappy.get_state())
+			quit(1)
+
+func _test_flap() -> void:
+	await process_frame
+	flappy.flap()
+	await process_frame
 	_run_frames(30)
-	if flappy.get_state() == "title":
-		print("FLAPPY BOOT OK")
+	if flappy.get_state() == "playing":
+		print("FLAP TEST OK")
 		quit(0)
 	else:
-		print("FLAPPY BOOT FAIL: state=%s" % flappy.get_state())
+		print("FLAP TEST FAIL: state=%s" % flappy.get_state())
 		quit(1)
 
 func _run_frames(count: int) -> void:
 	for i in count:
 		await process_frame
