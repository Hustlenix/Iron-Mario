git log --oneline b7283f7..73b1533
----
git diff --stat b7283f7..73b1533
----
git diff -U10 b7283f7..73b1533
73b1533 feat(flappy): feather shield pickup
----
 scenes/flappy_bird.gd | 14 ++++++++++++--
 test_flappy.gd        | 52 ++++++++++++++++++++++++++++++++++++++++++++++++++-
 2 files changed, 63 insertions(+), 3 deletions(-)
----
diff --git a/scenes/flappy_bird.gd b/scenes/flappy_bird.gd
index 66f3401..b7b79f7 100644
--- a/scenes/flappy_bird.gd
+++ b/scenes/flappy_bird.gd
@@ -242,22 +242,31 @@ func _spawn_pair() -> void:
 func _place_pair(pair: Node2D, center: float, use_gap: float) -> void:
 	pair.position = Vector2(1400.0, 0.0)
 	var children := pair.get_children()
 	children[0].position.y = center - use_gap * 0.5 - 1000.0
 	children[1].position.y = center - use_gap * 0.5 - PIPE_RIM
 	children[2].position.y = center + use_gap * 0.5
 	children[3].position.y = center + use_gap * 0.5
 	pair.visible = true
 	_pipe_meta[pair] = {"gap_y": center, "gap": use_gap, "scored": false}
 
-func _spawn_pickup_if_due(_center: float, _use_gap: float) -> void:
-	pass
+func _spawn_pickup_if_due(center: float, use_gap: float) -> void:
+	if _spawned <= 3 or _spawned != feather_next_spawn:
+		return
+	var pickup := TextureRect.new()
+	pickup.texture = load("res://assets/web_orb.svg") as Texture2D
+	pickup.custom_minimum_size = Vector2(40.0, 40.0)
+	pickup.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
+	pickup.mouse_filter = Control.MOUSE_FILTER_IGNORE
+	pickup.position = Vector2(1400.0, center - 20.0)
+	pickups_node.add_child(pickup)
+	feather_next_spawn = _spawned + randi_range(feather_every_min, feather_every_max)
 
 func _collides() -> bool:
 	var bird_rect := Rect2(BIRD_X + BIRD_SIZE * HITBOX_SHRINK, bird_y + BIRD_SIZE * HITBOX_SHRINK, BIRD_SIZE * (1.0 - 2.0 * HITBOX_SHRINK), BIRD_SIZE * (1.0 - 2.0 * HITBOX_SHRINK))
 	if bird_y + BIRD_SIZE >= GROUND_Y:
 		return true
 	for pair in pipes_node.get_children():
 		if not pair.visible:
 			continue
 		var meta: Dictionary = _pipe_meta[pair]
 		var top := Rect2(pair.position.x, meta.gap_y - meta.gap * 0.5 - 1000.0, PIPE_WIDTH, 1000.0)
@@ -328,20 +337,21 @@ func _restart() -> void:
 	medals = {}
 	new_best_fired = false
 	_spawned = 0
 	_spawn_timer = randf_range(1.6, 2.4)
 	feather_next_spawn = feather_every_min
 	bird_y = 300.0
 	velocity = 0.0
 	bird.rotation = 0.0
 	bird.modulate.a = 1.0
 	score_label.text = "0"
+	score_label.remove_theme_color_override("font_color")
 	best_label.text = "BEST: %d" % best
 	medal_label.text = ""
 	medal_icon.visible = false
 	hint_label.visible = false
 	state = "title"
 	flap()
 
 func _build_trail() -> void:
 	for i in TRAIL_COUNT:
 		var node := TextureRect.new()
diff --git a/test_flappy.gd b/test_flappy.gd
index 6ef7612..53ef699 100644
--- a/test_flappy.gd
+++ b/test_flappy.gd
@@ -1,20 +1,22 @@
 extends SceneTree
 
 var flappy: Node
 
 func _initialize() -> void:
 	var scene := load("res://scenes/flappy_bird.tscn") as PackedScene
 	flappy = scene.instantiate()
 	root.add_child(flappy)
 	var args := OS.get_cmdline_user_args()
-	if args.has("--medal"):
+	if args.has("--feather"):
+		await _test_feather()
+	elif args.has("--medal"):
 		await _test_medal()
 	elif args.has("--ramp"):
 		await _test_ramp()
 	elif args.has("--flap"):
 		await _test_flap()
 	else:
 		_run_frames(30)
 		if flappy.get_state() == "title":
 			print("FLAPPY BOOT OK")
 			quit(0)
@@ -35,20 +37,68 @@ func _test_ramp() -> void:
 		flappy.set("score", 0)
 		flappy.call("_score")
 		flappy.call("_score")
 		if flappy.get("score") == 2:
 			print("RAMP TEST OK")
 			quit(0)
 			return
 	print("RAMP TEST FAIL: speed %f -> %f" % [ramp_0, ramp_25])
 	quit(1)
 
+func _test_feather() -> void:
+	await process_frame
+	flappy.flap()
+	flappy.set("_spawned", 4)
+	flappy.set("feather_next_spawn", 5)
+	flappy.call("_spawn_pair")
+	await process_frame
+	var pickup_count: int = flappy.get_node("Pickups").get_child_count()
+	if pickup_count == 0:
+		print("FEATHER TEST FAIL: pickup did not spawn")
+		quit(1)
+		return
+	var pickup: Node = flappy.get_node("Pickups").get_child(0)
+	var bird_y: float = flappy.get("bird_y")
+	pickup.position = Vector2(210.0, bird_y + 5.0)
+	for i in 5:
+		await process_frame
+		if flappy.get("feathers") == 1:
+			break
+	if flappy.get("feathers") != 1:
+		print("FEATHER TEST FAIL: not collected (bird_y=%s pickup=%s)" % [flappy.get("bird_y"), pickup.position])
+		quit(1)
+		return
+	flappy.set("invuln_timer", 0.0)
+	flappy.set("bird_y", 700.0)
+	flappy.set("velocity", 900.0)
+	for i in 300:
+		await process_frame
+		if flappy.get("invuln_timer") > 0.0:
+			break
+	if flappy.get_state() == "game_over":
+		print("FEATHER TEST FAIL: shield did not save")
+		quit(1)
+		return
+	flappy.set("invuln_timer", 0.0)
+	flappy.set("bird_y", 700.0)
+	flappy.set("velocity", 900.0)
+	for i in 2000:
+		await process_frame
+		if flappy.get_state() == "game_over":
+			break
+	if flappy.get_state() == "game_over":
+		print("FEATHER TEST OK")
+		quit(0)
+		return
+	print("FEATHER TEST FAIL: second hit did not kill (state=%s)" % flappy.get_state())
+	quit(1)
+
 func _test_medal() -> void:
 	await process_frame
 	flappy.flap()
 	flappy.set("best", 0)
 	flappy.set("new_best_fired", false)
 	flappy.set("score", 4)
 	flappy.call("_score")
 	if flappy.get("medals").size() == 0:
 		flappy.set("score", 5)
 		flappy.call("_score")
