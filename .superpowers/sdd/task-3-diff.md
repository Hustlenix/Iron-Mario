git log --oneline 9ca599b..HEAD
----
git diff --stat 9ca599b..HEAD
----
git diff -U10 9ca599b..HEAD
300adfd chore(sdd): task 2 ledger line
00a9ff9 feat(flappy): scene skeleton + headless test driver
----
 .superpowers/sdd/progress.md |   2 +
 scenes/flappy_bird.gd        |  85 +++++++++++++++++++++++++
 scenes/flappy_bird.tscn      | 146 +++++++++++++++++++++++++++++++++++++++++++
 test_flappy.gd               |  19 ++++++
 4 files changed, 252 insertions(+)
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
new file mode 100644
index 0000000..d3e3249
--- /dev/null
+++ b/scenes/flappy_bird.gd
@@ -0,0 +1,85 @@
+extends Node2D
+
+const GRAVITY := 1400.0
+const MAX_FALL := 900.0
+const FLAP_VELOCITY := -420.0
+const BIRD_X := 200.0
+const BIRD_SIZE := 70.0
+const GROUND_Y := 620.0
+const PIPE_WIDTH := 110.0
+const PIPE_RIM := 16.0
+const GAP_MIN_CENTER := 200.0
+const GAP_MAX_CENTER := 560.0
+const PIPE_POOL := 6
+const TRAIL_COUNT := 10
+const HITBOX_SHRINK := 0.075
+
+var state := "title"
+var score := 0
+var velocity := 0.0
+var bird_y := 300.0
+var best := 0
+var new_best_fired := false
+var medals := {}
+var feathers := 0
+var invuln_timer := 0.0
+var feather_next_spawn := 8
+
+var feather_every_min := 8
+var feather_every_max := 12
+
+var _pipe_meta := {}
+var _spawn_timer := 0.0
+var _spawned := 0
+var _first_delay := 0.0
+var _score_flash := 0.0
+var _trail_index := 0
+var _trail_timer := 0.0
+
+@onready var pipes_node: Node2D = $Pipes
+@onready var pickups_node: Node2D = $Pickups
+@onready var trail_node: Node2D = $Trail
+@onready var bird: TextureRect = $Bird
+@onready var score_label: RichTextLabel = $HUD/ScoreLabel
+@onready var best_label: RichTextLabel = $HUD/BestLabel
+@onready var medal_label: RichTextLabel = $HUD/MedalLabel
+@onready var medal_icon: TextureRect = $HUD/MedalIcon
+@onready var feather_icon: TextureRect = $HUD/FeatherIcon
+@onready var hint_label: RichTextLabel = $HUD/HintLabel
+@onready var sfx_flap: AudioStreamPlayer = $SfxFlap
+@onready var sfx_score: AudioStreamPlayer = $SfxScore
+@onready var sfx_hit: AudioStreamPlayer = $SfxHit
+@onready var sfx_pickup: AudioStreamPlayer = $SfxPickup
+@onready var sfx_win: AudioStreamPlayer = $SfxWin
+@onready var bgm: AudioStreamPlayer = $Bgm
+
+func _ready() -> void:
+	SceneFade.fade_in(self)
+	best = Global.flappy_best
+	best_label.text = "BEST: %d" % best
+	build_sounds()
+	_build_pipe_pool()
+	_build_trail()
+	bgm.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
+	bgm.play()
+
+func get_state() -> String:
+	return state
+
+func flap() -> void:
+	pass
+
+func build_sounds() -> void:
+	pass
+
+func _build_pipe_pool() -> void:
+	pass
+
+func _build_trail() -> void:
+	pass
+
+func _process(delta: float) -> void:
+	pass
+
+func _unhandled_input(event: InputEvent) -> void:
+	pass
diff --git a/scenes/flappy_bird.tscn b/scenes/flappy_bird.tscn
new file mode 100644
index 0000000..fc4833b
--- /dev/null
+++ b/scenes/flappy_bird.tscn
@@ -0,0 +1,146 @@
+[gd_scene load_steps=7 format=3]
+
+[ext_resource type="Script" path="res://scenes/flappy_bird.gd" id="1_script"]
+[ext_resource type="Texture2D" path="res://assets/flappy_bg.svg" id="2_bg"]
+[ext_resource type="Texture2D" path="res://assets/flappy_hero.svg" id="3_hero"]
+[ext_resource type="Texture2D" path="res://assets/web_orb.svg" id="4_shard"]
+[ext_resource type="AudioStreamWAV" path="res://assets/audio/bgm.wav" id="5_bgm"]
+[ext_resource type="Script" path="res://scripts/juice/screen_shake.gd" id="6_shake"]
+
+[node name="FlappyBird" type="Node2D"]
+script = ExtResource("1_script")
+
+[node name="Background" type="TextureRect" parent="."]
+layout_mode = 1
+anchors_preset = 15
+anchor_right = 1.0
+anchor_bottom = 1.0
+grow_horizontal = 2
+grow_vertical = 2
+mouse_filter = 2
+texture = ExtResource("2_bg")
+expand_mode = 1
+stretch_mode = 6
+
+[node name="HUD" type="Control" parent="."]
+layout_mode = 1
+anchors_preset = 15
+anchor_right = 1.0
+anchor_bottom = 1.0
+grow_horizontal = 2
+grow_vertical = 2
+mouse_filter = 2
+
+[node name="ScoreLabel" type="RichTextLabel" parent="HUD"]
+layout_mode = 0
+offset_left = 20.0
+offset_top = 20.0
+offset_right = 320.0
+offset_bottom = 90.0
+mouse_filter = 2
+theme_override_font_sizes/font_size = 48
+theme_override_constants/outline_size = 20
+theme_override_colors/font_outline_color = Color(0, 0, 0, 1)
+scroll_active = false
+text = "0"
+
+[node name="BestLabel" type="RichTextLabel" parent="HUD"]
+layout_mode = 0
+offset_left = 20.0
+offset_top = 92.0
+offset_right = 320.0
+offset_bottom = 140.0
+mouse_filter = 2
+theme_override_font_sizes/font_size = 26
+theme_override_constants/outline_size = 10
+theme_override_colors/font_outline_color = Color(0, 0, 0, 1)
+scroll_active = false
+text = "BEST: 0"
+
+[node name="MedalLabel" type="RichTextLabel" parent="HUD"]
+layout_mode = 0
+offset_left = 960.0
+offset_top = 20.0
+offset_right = 1280.0
+offset_bottom = 80.0
+mouse_filter = 2
+theme_override_font_sizes/font_size = 34
+theme_override_constants/outline_size = 14
+theme_override_colors/font_outline_color = Color(0, 0, 0, 1)
+scroll_active = false
+text = ""
+
+[node name="MedalIcon" type="TextureRect" parent="HUD"]
+layout_mode = 0
+offset_left = 900.0
+offset_top = 20.0
+offset_right = 948.0
+offset_bottom = 68.0
+mouse_filter = 2
+visible = false
+expand_mode = 1
+stretch_mode = 5
+
+[node name="FeatherIcon" type="TextureRect" parent="HUD"]
+layout_mode = 0
+offset_left = 20.0
+offset_top = 150.0
+offset_right = 68.0
+offset_bottom = 198.0
+mouse_filter = 2
+visible = false
+texture = ExtResource("4_shard")
+expand_mode = 1
+stretch_mode = 5
+
+[node name="HintLabel" type="RichTextLabel" parent="HUD"]
+layout_mode = 0
+offset_left = 240.0
+offset_top = 330.0
+offset_right = 1040.0
+offset_bottom = 400.0
+mouse_filter = 2
+theme_override_font_sizes/font_size = 40
+theme_override_constants/outline_size = 18
+theme_override_colors/font_outline_color = Color(0, 0, 0, 1)
+scroll_active = false
+text = "TAP / SPACE TO FLAP"
+
+[node name="Pipes" type="Node2D" parent="."]
+
+[node name="Pickups" type="Node2D" parent="."]
+
+[node name="Trail" type="Node2D" parent="."]
+
+[node name="Bird" type="TextureRect" parent="."]
+layout_mode = 0
+offset_left = 200.0
+offset_top = 300.0
+offset_right = 270.0
+offset_bottom = 370.0
+mouse_filter = 2
+texture = ExtResource("3_hero")
+expand_mode = 1
+stretch_mode = 5
+
+[node name="SfxFlap" type="AudioStreamPlayer" parent="."]
+volume_db = -6.0
+
+[node name="SfxScore" type="AudioStreamPlayer" parent="."]
+volume_db = -6.0
+
+[node name="SfxHit" type="AudioStreamPlayer" parent="."]
+volume_db = -4.0
+
+[node name="SfxPickup" type="AudioStreamPlayer" parent="."]
+volume_db = -6.0
+
+[node name="SfxWin" type="AudioStreamPlayer" parent="."]
+volume_db = -4.0
+
+[node name="Bgm" type="AudioStreamPlayer" parent="."]
+volume_db = -14.0
+stream = ExtResource("5_bgm")
+
+[node name="ShakeCam" type="Camera2D" parent="."]
+script = ExtResource("6_shake")
diff --git a/test_flappy.gd b/test_flappy.gd
new file mode 100644
index 0000000..44358d8
--- /dev/null
+++ b/test_flappy.gd
@@ -0,0 +1,19 @@
+extends SceneTree
+
+var flappy: Node
+
+func _initialize() -> void:
+	var scene := load("res://scenes/flappy_bird.tscn") as PackedScene
+	flappy = scene.instantiate()
+	root.add_child(flappy)
+	_run_frames(30)
+	if flappy.get_state() == "title":
+		print("FLAPPY BOOT OK")
+		quit(0)
+	else:
+		print("FLAPPY BOOT FAIL: state=%s" % flappy.get_state())
+		quit(1)
+
+func _run_frames(count: int) -> void:
+	for i in count:
+		await process_frame
