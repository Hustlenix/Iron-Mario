### Task 3: Scene skeleton + test driver

**Files:**
- Create: `C:\Users\LalithReddy.b\Iron-Mario\scenes\flappy_bird.tscn`
- Create: `C:\Users\LalithReddy.b\Iron-Mario\scenes\flappy_bird.gd` (skeleton â€” states, constants, node refs, `_ready`, `_process` empty)
- Create: `C:\Users\LalithReddy.b\Iron-Mario\test_flappy.gd` (headless driver, boot mode)

**Interfaces:**
- Consumes: `assets/bg_game.svg`, `assets/hero.svg`, `assets/shard.svg`, `assets/audio/bgm.wav`, `scripts/juice/screen_shake.gd`, `scripts/juice/scene_fade.gd` (class_name `SceneFade`), `scripts/juice/juice.gd` (class_name `Juice`)
- Produces (used by later tasks): scene node paths `$Pipes`, `$Pickups`, `$Trail`, `$Bird`, `$HUD/ScoreLabel`, `$HUD/BestLabel`, `$HUD/MedalLabel`, `$HUD/FeatherIcon`, `$HUD/HintLabel`, `$SfxFlap`, `$SfxScore`, `$SfxHit`, `$SfxPickup`, `$SfxWin`, `$Bgm`, `$ShakeCam`; script API `get_state() -> String` returning `"title" | "playing" | "game_over"`, `flap()` method, tunable vars `feather_every_min`, `feather_every_max`, `feather_next_spawn` (all `var` so the driver can `set()` them)

- [ ] **Step 1: Write the scene file**

`scenes/flappy_bird.tscn`:

```
[gd_scene load_steps=7 format=3]

[ext_resource type="Script" path="res://scenes/flappy_bird.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://assets/bg_game.svg" id="2_bg"]
[ext_resource type="Texture2D" path="res://assets/hero.svg" id="3_hero"]
[ext_resource type="Texture2D" path="res://assets/shard.svg" id="4_shard"]
[ext_resource type="AudioStreamWAV" path="res://assets/audio/bgm.wav" id="5_bgm"]
[ext_resource type="Script" path="res://scripts/juice/screen_shake.gd" id="6_shake"]

[node name="FlappyBird" type="Node2D"]
script = ExtResource("1_script")

[node name="Background" type="TextureRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
texture = ExtResource("2_bg")
expand_mode = 1
stretch_mode = 6

[node name="HUD" type="Control" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="ScoreLabel" type="RichTextLabel" parent="HUD"]
layout_mode = 0
offset_left = 20.0
offset_top = 20.0
offset_right = 320.0
offset_bottom = 90.0
mouse_filter = 2
theme_override_font_sizes/font_size = 48
theme_override_constants/outline_size = 20
theme_override_colors/font_outline_color = Color(0, 0, 0, 1)
scroll_active = false
text = "0"

[node name="BestLabel" type="RichTextLabel" parent="HUD"]
layout_mode = 0
offset_left = 20.0
offset_top = 92.0
offset_right = 320.0
offset_bottom = 140.0
mouse_filter = 2
theme_override_font_sizes/font_size = 26
theme_override_constants/outline_size = 10
theme_override_colors/font_outline_color = Color(0, 0, 0, 1)
scroll_active = false
text = "BEST: 0"

[node name="MedalLabel" type="RichTextLabel" parent="HUD"]
layout_mode = 0
offset_left = 960.0
offset_top = 20.0
offset_right = 1280.0
offset_bottom = 80.0
mouse_filter = 2
theme_override_font_sizes/font_size = 34
theme_override_constants/outline_size = 14
theme_override_colors/font_outline_color = Color(0, 0, 0, 1)
scroll_active = false
text = ""

[node name="FeatherIcon" type="TextureRect" parent="HUD"]
layout_mode = 0
offset_left = 20.0
offset_top = 150.0
offset_right = 68.0
offset_bottom = 198.0
mouse_filter = 2
visible = false
texture = ExtResource("4_shard")
expand_mode = 1
stretch_mode = 5

[node name="HintLabel" type="RichTextLabel" parent="HUD"]
layout_mode = 0
offset_left = 240.0
offset_top = 330.0
offset_right = 1040.0
offset_bottom = 400.0
mouse_filter = 2
theme_override_font_sizes/font_size = 40
theme_override_constants/outline_size = 18
theme_override_colors/font_outline_color = Color(0, 0, 0, 1)
scroll_active = false
text = "TAP / SPACE TO FLAP"

[node name="Pipes" type="Node2D" parent="."]

[node name="Pickups" type="Node2D" parent="."]

[node name="Trail" type="Node2D" parent="."]

[node name="Bird" type="TextureRect" parent="."]
layout_mode = 0
offset_left = 200.0
offset_top = 300.0
offset_right = 270.0
offset_bottom = 370.0
mouse_filter = 2
texture = ExtResource("3_hero")
expand_mode = 1
stretch_mode = 5

[node name="SfxFlap" type="AudioStreamPlayer" parent="."]
volume_db = -6.0

[node name="SfxScore" type="AudioStreamPlayer" parent="."]
volume_db = -6.0

[node name="SfxHit" type="AudioStreamPlayer" parent="."]
volume_db = -4.0

[node name="SfxPickup" type="AudioStreamPlayer" parent="."]
volume_db = -6.0

[node name="SfxWin" type="AudioStreamPlayer" parent="."]
volume_db = -4.0

[node name="Bgm" type="AudioStreamPlayer" parent="."]
volume_db = -14.0
stream = ExtResource("5_bgm")

[node name="ShakeCam" type="Camera2D" parent="."]
script = ExtResource("6_shake")
```

- [ ] **Step 2: Write the skeleton script**

`scenes/flappy_bird.gd`:

```gdscript
extends Node2D

const GRAVITY := 1400.0
const MAX_FALL := 900.0
const FLAP_VELOCITY := -420.0
const BIRD_X := 200.0
const BIRD_SIZE := 70.0
const GROUND_Y := 620.0
const PIPE_WIDTH := 110.0
const PIPE_RIM := 16.0
const PIPE_BODY_COLOR := Color(0.07, 0.12, 0.25)
const PIPE_RIM_COLOR := Color(0.31, 0.82, 1.0)
const GAP_MIN_CENTER := 200.0
const GAP_MAX_CENTER := 560.0
const PIPE_POOL := 6
const TRAIL_COUNT := 10
const HITBOX_SHRINK := 0.075

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
var _first_delay := 0.0
var _score_flash := 0.0
var _trail_index := 0
var _trail_timer := 0.0

@onready var pipes_node: Node2D = $Pipes
@onready var pickups_node: Node2D = $Pickups
@onready var trail_node: Node2D = $Trail
@onready var bird: TextureRect = $Bird
@onready var score_label: RichTextLabel = $HUD/ScoreLabel
@onready var best_label: RichTextLabel = $HUD/BestLabel
@onready var medal_label: RichTextLabel = $HUD/MedalLabel
@onready var feather_icon: TextureRect = $HUD/FeatherIcon
@onready var hint_label: RichTextLabel = $HUD/HintLabel
@onready var sfx_flap: AudioStreamPlayer = $SfxFlap
@onready var sfx_score: AudioStreamPlayer = $SfxScore
@onready var sfx_hit: AudioStreamPlayer = $SfxHit
@onready var sfx_pickup: AudioStreamPlayer = $SfxPickup
@onready var sfx_win: AudioStreamPlayer = $SfxWin
@onready var bgm: AudioStreamPlayer = $Bgm

func _ready() -> void:
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
	pass

func build_sounds() -> void:
	pass

func _build_pipe_pool() -> void:
	pass

func _build_trail() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	pass
```

- [ ] **Step 3: Write the headless driver (boot mode)**

`test_flappy.gd`:

```gdscript
extends SceneTree

var flappy: Node

func _initialize() -> void:
	var scene := load("res://scenes/flappy_bird.tscn") as PackedScene
	flappy = scene.instantiate()
	root.add_child(flappy)
	_run_frames(30)
	if flappy.get_state() == "title":
		print("FLAPPY BOOT OK")
		quit(0)
	else:
		print("FLAPPY BOOT FAIL: state=%s" % flappy.get_state())
		quit(1)

func _run_frames(count: int) -> void:
	for i in count:
		await process_frame
```

- [ ] **Step 4: Run the driver**

Run: `& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --script res://test_flappy.gd`
Expected: prints `FLAPPY BOOT OK`, exits 0, no SCRIPT ERROR. If it errors, fix before committing.

- [ ] **Step 5: Commit**

```bash
git add scenes/flappy_bird.tscn scenes/flappy_bird.gd test_flappy.gd
git commit -m "feat(flappy): scene skeleton + headless test driver"
```

---
