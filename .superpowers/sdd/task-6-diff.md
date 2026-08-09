git log --oneline 9a35fef..b7283f7
----
git diff --stat 9a35fef..b7283f7
----
git diff -U10 9a35fef..b7283f7
b7283f7 feat(flappy): milestone medals + NEW BEST moment
----
 scenes/flappy_bird.gd | 33 +++++++++++++++++++++++++++++++++
 test_flappy.gd        | 33 ++++++++++++++++++++++++++++++++-
 2 files changed, 65 insertions(+), 1 deletion(-)
----
diff --git a/scenes/flappy_bird.gd b/scenes/flappy_bird.gd
index 35cacfb..66f3401 100644
--- a/scenes/flappy_bird.gd
+++ b/scenes/flappy_bird.gd
@@ -7,20 +7,27 @@ const BIRD_X := 200.0
 const BIRD_SIZE := 70.0
 const GROUND_Y := 620.0
 const PIPE_WIDTH := 110.0
 const PIPE_RIM := 16.0
 const GAP_MIN_CENTER := 200.0
 const GAP_MAX_CENTER := 560.0
 const PIPE_POOL := 6
 const TRAIL_COUNT := 10
 const HITBOX_SHRINK := 0.075
 
+const _MEDALS := [
+	{"score": 5, "name": "BRONZE", "color": Color(0.72, 0.45, 0.22), "icon": "res://assets/medal_bronze.svg"},
+	{"score": 10, "name": "SILVER", "color": Color(0.8, 0.8, 0.85), "icon": "res://assets/medal_silver.svg"},
+	{"score": 20, "name": "GOLD", "color": Color(1.0, 0.84, 0.3), "icon": "res://assets/medal_gold.svg"},
+	{"score": 40, "name": "PLATINUM", "color": Color(0.55, 0.9, 1.0), "icon": "res://assets/medal_platinum.svg"},
+]
+
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
@@ -258,20 +265,46 @@ func _collides() -> bool:
 		if bird_rect.intersects(top) or bird_rect.intersects(bottom):
 			return true
 	return false
 
 func _score() -> void:
 	score += 1
 	score_label.text = "%d" % score
 	sfx_score.play()
 	Juice.text(self, "+1", Vector2(BIRD_X + 40.0, bird_y), Color(0.6, 1.0, 0.65), 30)
 	Juice.shake(self, 0.05)
+	_check_medal()
+	_check_new_best()
+
+func _check_medal() -> void:
+	for medal in _MEDALS:
+		if score >= int(medal.score) and not medals.has(medal.name):
+			medals[medal.name] = true
+			medal_label.text = medal.name
+			medal_icon.texture = load(medal.icon) as Texture2D
+			medal_icon.visible = true
+			medal_label.add_theme_color_override("font_color", medal.color)
+			Juice.burst(self, Vector2(1100.0, 60.0), medal.color, 16, 260.0)
+			Juice.text(self, medal.name, Vector2(1180.0, 90.0), medal.color, 34)
+			sfx_score.play()
+
+func _check_new_best() -> void:
+	if not new_best_fired and score > best:
+		new_best_fired = true
+		best = score
+		Global.flappy_best = best
+		Global.save()
+		best_label.text = "BEST: %d" % best
+		score_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.3))
+		sfx_win.play()
+		Juice.burst(self, Vector2(BIRD_X, bird_y), Color(1.0, 0.84, 0.3), 22, 320.0)
+		Juice.text(self, "NEW BEST!", Vector2(BIRD_X + 30.0, bird_y - 30.0), Color(1.0, 0.84, 0.3), 38)
 
 func _die() -> void:
 	state = "dying"
 	sfx_hit.play()
 	Juice.hit_stop(self)
 	Juice.shake(self, 0.6)
 	Juice.burst(self, Vector2(BIRD_X, bird_y + BIRD_SIZE * 0.5), Color(1.0, 0.3, 0.3), 18, 300.0)
 	var tween := create_tween()
 	tween.tween_property(bird, "rotation", PI, 0.45)
 	await get_tree().create_timer(0.45).timeout
diff --git a/test_flappy.gd b/test_flappy.gd
index 6be8845..6ef7612 100644
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
-	if args.has("--ramp"):
+	if args.has("--medal"):
+		await _test_medal()
+	elif args.has("--ramp"):
 		await _test_ramp()
 	elif args.has("--flap"):
 		await _test_flap()
 	else:
 		_run_frames(30)
 		if flappy.get_state() == "title":
 			print("FLAPPY BOOT OK")
 			quit(0)
 		else:
 			print("FLAPPY BOOT FAIL: state=%s" % flappy.get_state())
@@ -33,20 +35,49 @@ func _test_ramp() -> void:
 		flappy.set("score", 0)
 		flappy.call("_score")
 		flappy.call("_score")
 		if flappy.get("score") == 2:
 			print("RAMP TEST OK")
 			quit(0)
 			return
 	print("RAMP TEST FAIL: speed %f -> %f" % [ramp_0, ramp_25])
 	quit(1)
 
+func _test_medal() -> void:
+	await process_frame
+	flappy.flap()
+	flappy.set("best", 0)
+	flappy.set("new_best_fired", false)
+	flappy.set("score", 4)
+	flappy.call("_score")
+	if flappy.get("medals").size() == 0:
+		flappy.set("score", 5)
+		flappy.call("_score")
+	var medal_text: String = flappy.get_node("HUD/MedalLabel").text
+	if medal_text != "BRONZE":
+		print("MEDAL TEST FAIL: label=%s" % medal_text)
+		quit(1)
+		return
+	flappy.set("best", 0)
+	flappy.set("new_best_fired", false)
+	flappy.set("score", 1)
+	flappy.call("_score")
+	var fired: bool = flappy.get("new_best_fired")
+	var global_node: Node = root.get_node("Global")
+	var saved: int = global_node.flappy_best
+	if fired and saved == 2:
+		print("MEDAL TEST OK")
+		quit(0)
+		return
+	print("MEDAL TEST FAIL: new_best fired=%s saved=%d" % [fired, saved])
+	quit(1)
+
 func _test_flap() -> void:
 	await process_frame
 	flappy.flap()
 	await process_frame
 	_run_frames(30)
 	if flappy.get_state() == "playing":
 		print("FLAP TEST OK")
 		quit(0)
 	else:
 		print("FLAP TEST FAIL: state=%s" % flappy.get_state())
