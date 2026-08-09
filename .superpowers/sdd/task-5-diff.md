git log --oneline 97510f3..9a35fef
----
git diff --stat 97510f3..9a35fef
----
git diff -U10 97510f3..9a35fef
9a35fef test(flappy): ramp verification
----
 test_flappy.gd | 24 +++++++++++++++++++++++-
 1 file changed, 23 insertions(+), 1 deletion(-)
----
diff --git a/test_flappy.gd b/test_flappy.gd
index d1de97d..6be8845 100644
--- a/test_flappy.gd
+++ b/test_flappy.gd
@@ -1,30 +1,52 @@
 extends SceneTree
 
 var flappy: Node
 
 func _initialize() -> void:
 	var scene := load("res://scenes/flappy_bird.tscn") as PackedScene
 	flappy = scene.instantiate()
 	root.add_child(flappy)
 	var args := OS.get_cmdline_user_args()
-	if args.has("--flap"):
+	if args.has("--ramp"):
+		await _test_ramp()
+	elif args.has("--flap"):
 		await _test_flap()
 	else:
 		_run_frames(30)
 		if flappy.get_state() == "title":
 			print("FLAPPY BOOT OK")
 			quit(0)
 		else:
 			print("FLAPPY BOOT FAIL: state=%s" % flappy.get_state())
 			quit(1)
 
+func _test_ramp() -> void:
+	await process_frame
+	flappy.flap()
+	flappy.set("score", 0)
+	await process_frame
+	var ramp_0: float = flappy.call("_ramp_speed")
+	flappy.set("score", 25)
+	await process_frame
+	var ramp_25: float = flappy.call("_ramp_speed")
+	if ramp_0 == 240.0 and ramp_25 == 330.0:
+		flappy.set("score", 0)
+		flappy.call("_score")
+		flappy.call("_score")
+		if flappy.get("score") == 2:
+			print("RAMP TEST OK")
+			quit(0)
+			return
+	print("RAMP TEST FAIL: speed %f -> %f" % [ramp_0, ramp_25])
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
