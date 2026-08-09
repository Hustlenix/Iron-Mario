git log --oneline 73b1533..6f14810
----
git diff --stat 73b1533..6f14810
----
git diff -U10 73b1533..6f14810
6f14810 feat(flappy): synthesized SFX
----
 scenes/flappy_bird.gd | 25 ++++++++++++++++++++++++-
 test_flappy.gd        | 25 ++++++++++++++++++++++++-
 2 files changed, 48 insertions(+), 2 deletions(-)
----
diff --git a/scenes/flappy_bird.gd b/scenes/flappy_bird.gd
index b7b79f7..4417f80 100644
--- a/scenes/flappy_bird.gd
+++ b/scenes/flappy_bird.gd
@@ -79,21 +79,44 @@ func flap() -> void:
 			state = "playing"
 			hint_label.visible = false
 			_spawn_timer = randf_range(1.6, 2.4)
 			velocity = FLAP_VELOCITY
 			_do_flap_visuals()
 		"playing":
 			velocity = FLAP_VELOCITY
 			_do_flap_visuals()
 
 func build_sounds() -> void:
-	pass
+	sfx_flap.stream = _make_beep(620.0, 0.07, 0.5)
+	sfx_score.stream = _make_beep(880.0, 0.09, 0.45)
+	sfx_hit.stream = _make_beep(160.0, 0.3, 0.7, 1.2)
+	sfx_pickup.stream = _make_beep(1040.0, 0.1, 0.5)
+	sfx_win.stream = _make_beep(660.0, 0.4, 0.6, 0.4)
+
+func _make_beep(freq: float, duration: float, volume: float, wobble := 0.0) -> AudioStreamWAV:
+	var sr := 22050
+	var n := int(sr * duration)
+	var data := PackedByteArray()
+	data.resize(n * 2)
+	var slide := 1.0 + wobble
+	for i in n:
+		var t := float(i) / float(sr)
+		var env := minf(t / 0.01, 1.0) * maxf(1.0 - t / duration, 0.0)
+		var f := freq * (1.0 + (slide - 1.0) * t / duration)
+		var s := sin(TAU * f * t) * env * volume
+		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
+	var wav := AudioStreamWAV.new()
+	wav.format = AudioStreamWAV.FORMAT_16_BITS
+	wav.mix_rate = sr
+	wav.stereo = false
+	wav.data = data
+	return wav
 
 func _unhandled_input(event: InputEvent) -> void:
 	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
 		if event.pressed:
 			Input.action_press("jump")
 		else:
 			Input.action_release("jump")
 
 func _process(delta: float) -> void:
 	if Input.is_action_just_pressed("ui_cancel"):
diff --git a/test_flappy.gd b/test_flappy.gd
index 53ef699..ff55e2f 100644
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
-	if args.has("--feather"):
+	if args.has("--over"):
+		await _test_over()
+	elif args.has("--feather"):
 		await _test_feather()
 	elif args.has("--medal"):
 		await _test_medal()
 	elif args.has("--ramp"):
 		await _test_ramp()
 	elif args.has("--flap"):
 		await _test_flap()
 	else:
 		_run_frames(30)
 		if flappy.get_state() == "title":
@@ -37,20 +39,41 @@ func _test_ramp() -> void:
 		flappy.set("score", 0)
 		flappy.call("_score")
 		flappy.call("_score")
 		if flappy.get("score") == 2:
 			print("RAMP TEST OK")
 			quit(0)
 			return
 	print("RAMP TEST FAIL: speed %f -> %f" % [ramp_0, ramp_25])
 	quit(1)
 
+func _test_over() -> void:
+	await process_frame
+	flappy.flap()
+	_run_frames(60)
+	flappy.set("bird_y", 700.0)
+	flappy.set("velocity", 900.0)
+	for i in 600:
+		await process_frame
+		if flappy.get_state() == "game_over":
+			break
+	if flappy.get_state() == "game_over":
+		var flap_stream: AudioStreamWAV = flappy.get_node("SfxFlap").stream
+		if flap_stream != null:
+			print("GAME OVER TEST OK")
+			quit(0)
+			return
+		print("GAME OVER TEST FAIL: no synthesized flap stream")
+		quit(1)
+	print("GAME OVER TEST FAIL: state=%s" % flappy.get_state())
+	quit(1)
+
 func _test_feather() -> void:
 	await process_frame
 	flappy.flap()
 	flappy.set("_spawned", 4)
 	flappy.set("feather_next_spawn", 5)
 	flappy.call("_spawn_pair")
 	await process_frame
 	var pickup_count: int = flappy.get_node("Pickups").get_child_count()
 	if pickup_count == 0:
 		print("FEATHER TEST FAIL: pickup did not spawn")
