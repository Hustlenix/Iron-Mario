# Flappy Bird (Standalone Mode) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a full standalone endless Flappy Bird game to Iron-Mario, reachable from the title screen, with difficulty ramp, milestone medals, feather pickups, and persistent best score.

**Architecture:** One new scene `scenes/flappy_bird.tscn` with all gameplay in `flappy_bird.gd` (manual physics, pooled pipes, no physics engine). Entry via a new FLAPPY button on the title screen. Best score persists through the existing `Global` JSON save (`user://save.dat`), following the codebase's existing save pattern (a refinement of the spec's standalone ConfigFile — one save file, existing load path, `Global.flappy_best` readable by the title screen). Verification via a headless SceneTree driver script that grows task-by-task.

**Tech Stack:** Godot 4.7.1 (GDScript), existing SVG assets (`hero.svg`, `bg_game.svg`, `shard.svg`), existing `Juice`/`SceneFade` classes, `AudioStreamWAV` synthesized in code.

## Global Constraints

- Godot binary: `C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe` (always run headless with `--headless --path C:\Users\LalithReddy.b\Iron-Mario`)
- Viewport 1280x720; ground death at bird bottom >= 620; ceiling clamps at y=0 (no death)
- Physics: gravity 1400 px/s², terminal velocity 900, flap velocity -420; flap action = `jump` (Space/W) + left mouse click; ESC = `ui_cancel`
- Difficulty ramp: score 0..25 lerps gap 280→210, speed 240→330 px/s, spawn interval 1.5→1.1s; first 3 pipes gap >= 280; first pipe delay random 1.6–2.4s (must NOT be overridden by any catch-up logic)
- Medals: 5 bronze, 10 silver, 20 gold, 40 platinum (reactor.svg icon tinted)
- Feather pickup: every 8–12 pipes (never in first 3), one held max, shield-pop on next hit + 1s invulnerability (collisions fully ignored while blinking)
- Collision hitboxes shrunk 15%; best score persisted via `Global.flappy_best` in `user://save.dat`
- Code style: GDScript 4, tabs, snake_case, NO comments in code
- No new art files; no changes to minigame flow (`Global.minigames_done` untouched)
- Commit after every task; push + export + CI only in the final task

---

### Task 1: Persist `flappy_best` in Global

**Files:**
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\scripts\Global.gd` (lines 3-8 add var; lines 37, 48 add key)

**Interfaces:**
- Consumes: existing `Global.save()` / `Global.load_save()` JSON round-trip (`SAVE_PATH = "user://save.dat"`, keys `best_streak`, `volume`)
- Produces: `Global.flappy_best: int` (loaded in `_ready` via `load_save()`, persisted by `save()`)

- [ ] **Step 1: Add the field and persist it**

In `scripts/Global.gd`, after line 7 (`var best_streak: int = 0`) add:

```gdscript
var flappy_best: int = 0
```

In `save()` change `{"best_streak": best_streak, "volume": volume}` to:

```gdscript
	file.store_string(JSON.stringify({"best_streak": best_streak, "volume": volume, "flappy_best": flappy_best}))
```

In `load_save()` after `volume = float(data.get("volume", 80.0))` add:

```gdscript
		flappy_best = int(data.get("flappy_best", 0))
```

- [ ] **Step 2: Verify parse + boot**

Run: `& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --quit-after 30`
Expected: exits 0, no SCRIPT ERROR in output. (Main scene `title_screen.tscn` boots; Global is an autoload so its script parses on boot.)

- [ ] **Step 3: Commit**

```bash
git add scripts/Global.gd
git commit -m "feat(flappy): persist flappy_best in Global save"
```

---

### Task 2: Title screen FLAPPY button

**Files:**
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\scenes\title_screen.tscn`
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\scenes\title_screen.gd`

**Interfaces:**
- Consumes: `Global.flappy_best` (Task 1), `SceneFade.fade_out(root)`, existing button handler pattern (`_on_start_button_pressed`)
- Produces: `MenuButtons/FlappyButton` (text `FLAPPY  BEST: N`, set in `_ready`), `_on_flappy_button_pressed()` → `res://scenes/flappy_bird.tscn`

- [ ] **Step 1: Add the button to the scene**

In `scenes/title_screen.tscn`, after the `StartButton` node block (line 47), insert:

```
[node name="FlappyButton" type="Button" parent="MenuButtons"]
layout_mode = 2
custom_minimum_size = Vector2(200, 60)
text = "FLAPPY  BEST: 0"
```

After the `StartButton` connection line (line 59) add:

```
[connection signal="pressed" from="MenuButtons/FlappyButton" to="." method="_on_flappy_button_pressed"]
```

- [ ] **Step 2: Wire the handler + best label**

In `scenes/title_screen.gd`, in `_ready()` after line 7 (`$StreakLabel.text = ...`) add:

```gdscript
	$MenuButtons/FlappyButton.text = "FLAPPY  BEST: %d" % Global.flappy_best
```

Add at the end of the file:

```gdscript
func _on_flappy_button_pressed() -> void:
	await SceneFade.fade_out(self)
	get_tree().change_scene_to_file("res://scenes/flappy_bird.tscn")
```

- [ ] **Step 3: Verify boot**

Run: `& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --quit-after 30`
Expected: exits 0, no SCRIPT ERROR. (Scene references `flappy_bird.tscn` only at press time, so it need not exist yet — change_scene_to_file is deferred; boot stays clean. If it errors, create an empty `scenes/flappy_bird.tscn` with a Node2D root now and proceed.)

- [ ] **Step 4: Commit**

```bash
git add scenes/title_screen.tscn scenes/title_screen.gd
git commit -m "feat(flappy): FLAPPY button on title screen"
```

---

### Task 3: Scene skeleton + test driver

**Files:**
- Create: `C:\Users\LalithReddy.b\Iron-Mario\scenes\flappy_bird.tscn`
- Create: `C:\Users\LalithReddy.b\Iron-Mario\scenes\flappy_bird.gd` (skeleton — states, constants, node refs, `_ready`, `_process` empty)
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

### Task 4: Core gameplay loop

**Files:**
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\scenes\flappy_bird.gd`
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\test_flappy.gd`

**Interfaces:**
- Consumes: Task 3 skeleton, node paths, `get_state()`, `flap()`
- Produces: `_process` state machine (`title` → first flap → `playing`; ground/pipe hit → `dying` 0.45s → `game_over`), pipe pool spawning/movement/recycling, gap-center stored per pair in `_pipe_meta` keyed by pair instance, `_collides() -> bool`, `_die()`, `_restart()`, `_score()`

- [ ] **Step 1: Add the failing test to the driver**

Replace the whole `test_flappy.gd` content with:

```gdscript
extends SceneTree

var flappy: Node

func _initialize() -> void:
	var scene := load("res://scenes/flappy_bird.tscn") as PackedScene
	flappy = scene.instantiate()
	root.add_child(flappy)
	var args := OS.get_cmdline_user_args()
	if args.has("flap"):
		await _test_flap()
	else:
		_run_frames(30)
		if flappy.get_state() == "title":
			print("FLAPPY BOOT OK")
			quit(0)
		else:
			print("FLAPPY BOOT FAIL: state=%s" % flappy.get_state())
			quit(1)

func _test_flap() -> void:
	flappy.flap()
	await process_frame
	_run_frames(30)
	if flappy.get_state() == "playing":
		print("FLAP TEST OK")
		quit(0)
	else:
		print("FLAP TEST FAIL: state=%s" % flappy.get_state())
		quit(1)

func _run_frames(count: int) -> void:
	for i in count:
		await process_frame
```

- [ ] **Step 2: Run the flap test — expect FAIL**

Run: `& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --script res://test_flappy.gd -- --flap`
Expected: FAIL — `state=title` (flap() is a no-op).

- [ ] **Step 3: Implement the core loop**

Replace the skeleton `flap`, `_process`, `_unhandled_input`, `_build_pipe_pool`, `_build_trail` in `scenes/flappy_bird.gd` with:

```gdscript
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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			Input.action_press("jump")
		else:
			Input.action_release("jump")

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_go_menu()
		return
	if state == "title":
		if Input.is_action_just_pressed("jump"):
			flap()
		return
	if Input.is_action_just_pressed("jump"):
		if state == "game_over":
			_restart()
		else:
			flap()
	if state == "dying":
		velocity = minf(velocity + GRAVITY * delta, MAX_FALL)
		bird_y += velocity * delta
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
	for i in PIPE_POOL:
		var pair := Node2D.new()
		var top_body := ColorRect.new()
		top_body.color = PIPE_BODY_COLOR
		top_body.size = Vector2(PIPE_WIDTH, 1000.0)
		top_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pair.add_child(top_body)
		var top_rim := ColorRect.new()
		top_rim.color = PIPE_RIM_COLOR
		top_rim.size = Vector2(PIPE_WIDTH, PIPE_RIM)
		top_rim.position = Vector2(0.0, 1000.0 - PIPE_RIM)
		top_rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pair.add_child(top_rim)
		var bottom_body := ColorRect.new()
		bottom_body.color = PIPE_BODY_COLOR
		bottom_body.size = Vector2(PIPE_WIDTH, 1000.0)
		bottom_body.position = Vector2(0.0, 1024.0)
		bottom_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pair.add_child(bottom_body)
		var bottom_rim := ColorRect.new()
		bottom_rim.color = PIPE_RIM_COLOR
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
	var center := randf_range(GAP_MIN_CENTER, GAP_MAX_CENTER)
	_place_pair(pair, center, use_gap)
	_spawn_pickup_if_due(center, use_gap)

func _place_pair(pair: Node2D, center: float, use_gap: float) -> void:
	pair.position = Vector2(1400.0, 0.0)
	for child in pair.get_children():
		if child.position.y < 512.0:
			child.position.y = center - use_gap * 0.5 - 1000.0
		else:
			child.position.y = center + use_gap * 0.5
	pair.visible = true
	_pipe_meta[pair] = {"gap_y": center, "gap": use_gap, "scored": false}

func _spawn_pickup_if_due(_center: float, _use_gap: float) -> void:
	pass

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

func _die() -> void:
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
	_spawn_timer = randf_range(1.6, 2.4)
	feather_next_spawn = feather_every_min
	bird_y = 300.0
	velocity = 0.0
	bird.rotation = 0.0
	bird.modulate.a = 1.0
	score_label.text = "0"
	best_label.text = "BEST: %d" % best
	medal_label.text = ""
	hint_label.visible = false
	state = "title"
	flap()

func _build_trail() -> void:
	for i in TRAIL_COUNT:
		var node := TextureRect.new()
		node.texture = load("res://assets/hero.svg") as Texture2D
		node.custom_minimum_size = Vector2(BIRD_SIZE, BIRD_SIZE)
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
	await SceneFade.fade_out(self)
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
```

- [ ] **Step 4: Run the flap test — expect PASS**

Run: `& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --script res://test_flappy.gd -- --flap`
Expected: `FLAP TEST OK`, exit 0.

Also run boot: `... --script res://test_flappy.gd` → `FLAPPY BOOT OK`.

- [ ] **Step 5: Commit**

```bash
git add scenes/flappy_bird.gd test_flappy.gd
git commit -m "feat(flappy): core loop, pipe pool, scoring, collisions"
```

---

### Task 5: Difficulty ramp verification

**Files:**
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\test_flappy.gd`

**Interfaces:**
- Consumes: `_ramp_speed()` / `_ramp_gap()` / `_ramp_interval()` (Task 4), `score` var, `_score()`
- Produces: `"ramp"` driver mode asserting the ramp functions actually scale with score

- [ ] **Step 1: Add the failing test**

Extend `_initialize` in `test_flappy.gd`:

```gdscript
	if args.has("ramp"):
		await _test_ramp()
	elif args.has("flap"):
		await _test_flap()
	else:
		...
```

and add:

```gdscript
func _test_ramp() -> void:
	flappy.flap()
	flappy.set("score", 0)
	await process_frame
	var ramp_0 := flappy.call("_ramp_speed")
	flappy.set("score", 25)
	await process_frame
	var ramp_25 := flappy.call("_ramp_speed")
	if ramp_0 == 240.0 and ramp_25 == 330.0:
		flappy.set("score", 0)
		flappy.call("_score")
		flappy.call("_score")
		if flappy.get("score") == 2:
			print("RAMP TEST OK")
			quit(0)
			return
	print("RAMP TEST FAIL: speed %f -> %f" % [ramp_0, ramp_25])
	quit(1)
```

- [ ] **Step 2: Run — expect FAIL**

Run: `& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --script res://test_flappy.gd -- --ramp`
Expected: FAIL — `_ramp_speed` not defined on the skeleton (boot mode only) or wrong values.

- [ ] **Step 3: No game change needed**

The ramp functions were implemented in Task 4 (`_ramp_factor` / `_ramp_speed` / `_ramp_gap` / `_ramp_interval`). If the FAIL persists after Task 4 is in place, debug the values directly.

- [ ] **Step 4: Run — expect PASS**

Run: `... --script res://test_flappy.gd -- --ramp`
Expected: `RAMP TEST OK`.

- [ ] **Step 5: Commit**

```bash
git add test_flappy.gd
git commit -m "test(flappy): ramp verification"
```

---

### Task 6: Medals + NEW BEST moment

**Files:**
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\scenes\flappy_bird.gd`
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\test_flappy.gd`

**Interfaces:**
- Consumes: `_score()` (Task 4), `medal_label`, `sfx_win`, `best`, `new_best_fired`, `medals`
- Produces: `_MEDALS` const (ordered array), `_check_medal()` called from `_score()`, `_check_new_best()` called from `_score()`

- [ ] **Step 1: Add the failing test**

Extend `_initialize`:

```gdscript
	if args.has("medal"):
		await _test_medal()
```

and add:

```gdscript
func _test_medal() -> void:
	flappy.flap()
	flappy.set("best", 0)
	flappy.set("new_best_fired", false)
	flappy.set("score", 4)
	flappy.call("_score")
	if flappy.get("medals").size() == 0:
		flappy.set("score", 5)
		flappy.call("_score")
	var medal_text := flappy.get_node("HUD/MedalLabel").text
	if medal_text != "BRONZE":
		print("MEDAL TEST FAIL: label=%s" % medal_text)
		quit(1)
		return
	flappy.set("best", 0)
	flappy.set("new_best_fired", false)
	flappy.set("score", 1)
	flappy.call("_score")
	var fired: bool = flappy.get("new_best_fired")
	var saved: int = Global.flappy_best
	if fired and saved == 2:
		print("MEDAL TEST OK")
		quit(0)
		return
	print("MEDAL TEST FAIL: new_best fired=%s saved=%d" % [fired, saved])
	quit(1)
```

- [ ] **Step 2: Run — expect FAIL**

Run: `... --script res://test_flappy.gd -- --medal`
Expected: FAIL — `medal_label.text` is `""`.

- [ ] **Step 3: Implement medals + new best**

Add after the consts block in `scenes/flappy_bird.gd`:

```gdscript
const _MEDALS := [
	{"score": 5, "name": "BRONZE", "color": Color(0.72, 0.45, 0.22)},
	{"score": 10, "name": "SILVER", "color": Color(0.8, 0.8, 0.85)},
	{"score": 20, "name": "GOLD", "color": Color(1.0, 0.84, 0.3)},
	{"score": 40, "name": "PLATINUM", "color": Color(0.55, 0.9, 1.0)},
]
```

Add at the end of `_score()`:

```gdscript
	_check_medal()
	_check_new_best()
```

Add methods:

```gdscript
func _check_medal() -> void:
	for medal in _MEDALS:
		if score >= int(medal.score) and not medals.has(medal.name):
			medals[medal.name] = true
			medal_label.text = medal.name
			medal_label.add_theme_color_override("font_color", medal.color)
			Juice.burst(self, Vector2(1100.0, 60.0), medal.color, 16, 260.0)
			Juice.text(self, medal.name, Vector2(1180.0, 90.0), medal.color, 34)
			sfx_score.play()

func _check_new_best() -> void:
	if not new_best_fired and score > best:
		new_best_fired = true
		best = score
		Global.flappy_best = best
		Global.save()
		best_label.text = "BEST: %d" % best
		score_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.3))
		sfx_win.play()
		Juice.burst(self, Vector2(BIRD_X, bird_y), Color(1.0, 0.84, 0.3), 22, 320.0)
		Juice.text(self, "NEW BEST!", Vector2(BIRD_X + 30.0, bird_y - 30.0), Color(1.0, 0.84, 0.3), 38)
```

- [ ] **Step 4: Run — expect PASS**

Run: `... --script res://test_flappy.gd -- --medal`
Expected: `MEDAL TEST OK`.

- [ ] **Step 5: Commit**

```bash
git add scenes/flappy_bird.gd test_flappy.gd
git commit -m "feat(flappy): milestone medals + NEW BEST moment"
```

---

### Task 7: Feather pickups

**Files:**
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\scenes\flappy_bird.gd`
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\test_flappy.gd`

**Interfaces:**
- Consumes: `_spawn_pair` (calls `_spawn_pickup_if_due`), `_move_pickups`, `_collides` (shield-pop branch), `pickups_node`, `feather_icon`, `feather_next_spawn`, `feather_every_min/max`, `_spawned`
- Produces: full `_spawn_pickup_if_due(center, use_gap)` that spawns a 40x40 `shard.svg` TextureRect at the gap center when `_spawned > 3 and _spawned == feather_next_spawn`, then sets `feather_next_spawn = _spawned + randi_range(min,max)`

- [ ] **Step 1: Add the failing test**

Extend `_initialize`:

```gdscript
	if args.has("feather"):
		await _test_feather()
```

and add:

```gdscript
func _test_feather() -> void:
	flappy.flap()
	flappy.set("_spawned", 4)
	flappy.set("feather_next_spawn", 5)
	flappy.call("_spawn_pair")
	await process_frame
	var pickup_count := flappy.get_node("Pickups").get_child_count()
	if pickup_count == 0:
		print("FEATHER TEST FAIL: pickup did not spawn")
		quit(1)
		return
	flappy.set("bird_y", 250.0)
	flappy.set("velocity", 0.0)
	var pickup := flappy.get_node("Pickups").get_child(0)
	pickup.position = Vector2(220.0, 230.0)
	_run_frames(10)
	if flappy.get("feathers") != 1:
		print("FEATHER TEST FAIL: not collected")
		quit(1)
		return
	flappy.set("invuln_timer", 0.0)
	flappy.set("bird_y", 700.0)
	flappy.set("velocity", 900.0)
	_run_frames(30)
	if flappy.get_state() == "game_over":
		print("FEATHER TEST FAIL: shield did not save")
		quit(1)
		return
	flappy.set("invuln_timer", 0.0)
	flappy.set("bird_y", 700.0)
	flappy.set("velocity", 900.0)
	_run_frames(120)
	if flappy.get_state() == "game_over":
		print("FEATHER TEST OK")
		quit(0)
		return
	print("FEATHER TEST FAIL: second hit did not kill (state=%s)" % flappy.get_state())
	quit(1)
```

- [ ] **Step 2: Run — expect FAIL**

Run: `... --script res://test_flappy.gd -- --feather`
Expected: FAIL — pickup did not spawn (no-op).

- [ ] **Step 3: Implement**

Replace the `_spawn_pickup_if_due` no-op in `scenes/flappy_bird.gd`:

```gdscript
func _spawn_pickup_if_due(center: float, use_gap: float) -> void:
	if _spawned <= 3 or _spawned != feather_next_spawn:
		return
	var pickup := TextureRect.new()
	pickup.texture = load("res://assets/shard.svg") as Texture2D
	pickup.custom_minimum_size = Vector2(40.0, 40.0)
	pickup.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pickup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pickup.position = Vector2(1400.0, center - 20.0)
	pickups_node.add_child(pickup)
	feather_next_spawn = _spawned + randi_range(feather_every_min, feather_every_max)
```

- [ ] **Step 4: Run — expect PASS**

Run: `... --script res://test_flappy.gd -- --feather`
Expected: `FEATHER TEST OK`.

- [ ] **Step 5: Commit**

```bash
git add scenes/flappy_bird.gd test_flappy.gd
git commit -m "feat(flappy): feather shield pickup"
```

---

### Task 8: Game over polish + audio synthesis

**Files:**
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\scenes\flappy_bird.gd`
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\test_flappy.gd`

**Interfaces:**
- Consumes: `build_sounds()` skeleton (Task 3), `_die()`, `_show_game_over()`
- Produces: `build_sounds()` fills `sfx_*` streams with synthesized `AudioStreamWAV` beeps; `_make_beep(freq, duration, volume, wobble) -> AudioStreamWAV`

- [ ] **Step 1: Add the failing test**

Extend `_initialize`:

```gdscript
	if args.has("over"):
		await _test_over()
```

and add:

```gdscript
func _test_over() -> void:
	flappy.flap()
	_run_frames(60)
	flappy.set("bird_y", 700.0)
	flappy.set("velocity", 900.0)
	_run_frames(120)
	if flappy.get_state() == "game_over":
		var flap_stream := flappy.get_node("SfxFlap").stream
		if flap_stream != null and flap_stream is AudioStreamWAV:
			print("GAME OVER TEST OK")
			quit(0)
			return
		print("GAME OVER TEST FAIL: no synthesized flap stream")
		quit(1)
	print("GAME OVER TEST FAIL: state=%s" % flappy.get_state())
	quit(1)
```

- [ ] **Step 2: Run — expect FAIL**

Run: `... --script res://test_flappy.gd -- --over`
Expected: FAIL — `SfxFlap.stream` is null (game-over may already work, but the stream assertion fails).

- [ ] **Step 3: Implement audio synthesis**

Replace `build_sounds()` no-op in `scenes/flappy_bird.gd`:

```gdscript
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
```

- [ ] **Step 4: Run — expect PASS**

Run: `... --script res://test_flappy.gd -- --over`
Expected: `GAME OVER TEST OK`.

Also run all modes so far to confirm no regressions: `--boot`, `--flap`, `--ramp`, `--medal`, `--feather`.

- [ ] **Step 5: Commit**

```bash
git add scenes/flappy_bird.gd test_flappy.gd
git commit -m "feat(flappy): synthesized SFX"
```

---

### Task 9: Full E2E harness + exports + push

**Files:**
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\test_flappy.gd`
- New artifacts: `build\windows\Iron-Mario.exe` + `.pck`, `build\web\`, `exports\Iron-Mario-web.zip`

**Interfaces:**
- Consumes: everything from Tasks 1–8
- Produces: green E2E run; fresh exports; commit; push; CI run verified

- [ ] **Step 1: Add the E2E mode (score, game over, retry, ESC, persistence)**

Extend `_initialize`:

```gdscript
	if args.has("e2e"):
		await _test_e2e()
```

and add:

```gdscript
func _test_e2e() -> void:
	flappy.flap()
	flappy.set("best", 0)
	flappy.set("new_best_fired", false)
	flappy.call("_score")
	flappy.call("_score")
	var score_early: int = flappy.get("score")
	flappy.set("bird_y", 700.0)
	flappy.set("velocity", 900.0)
	_run_frames(120)
	if flappy.get_state() != "game_over":
		print("E2E FAIL: no game over")
		quit(1)
		return
	if score_early != 2:
		print("E2E FAIL: score=%d" % score_early)
		quit(1)
		return
	if flappy.get("best") < 2:
		print("E2E FAIL: best not saved (%d)" % flappy.get("best"))
		quit(1)
		return
	Input.action_press("jump")
	_run_frames(2)
	Input.action_release("jump")
	_run_frames(60)
	if flappy.get_state() != "playing":
		print("E2E FAIL: retry did not restart (state=%s)" % flappy.get_state())
		quit(1)
		return
	Input.action_press("ui_cancel")
	_run_frames(30)
	Input.action_release("ui_cancel")
	for i in 300:
		await process_frame
		if current_scene != null and current_scene.name != "FlappyBird":
			print("E2E OK (score=%d best=%d scene=%s)" % [score_early, flappy.get("best"), current_scene.name])
			quit(0)
			return
	print("E2E FAIL: ESC did not return to title")
	quit(1)
```

- [ ] **Step 2: Run full suite**

Run each:

```powershell
& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --script res://test_flappy.gd
& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --script res://test_flappy.gd -- --flap
& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --script res://test_flappy.gd -- --ramp
& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --script res://test_flappy.gd -- --medal
& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --script res://test_flappy.gd -- --feather
& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --script res://test_flappy.gd -- --over
& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --script res://test_flappy.gd -- --e2e
```

Expected: all seven print their `OK` lines, exit 0, no SCRIPT ERROR output.

- [ ] **Step 3: Delete the harness (it did its job)**

Delete `C:\Users\LalithReddy.b\Iron-Mario\test_flappy.gd` (and its auto-generated `test_flappy.gd.uid` if present).

- [ ] **Step 4: Clean import + boot check**

Run: `& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --import`
Expected: completes without errors.
Then: `& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --quit-after 30`
Expected: exits 0, clean boot log.

- [ ] **Step 5: Commit + push**

```bash
git add -A
git status
git commit -m "feat(flappy): standalone Flappy Bird mode"
git push origin main
```

Verify push: `git log --oneline -3` shows the new commit on `origin/main` (or use `git status` showing "up to date").

- [ ] **Step 6: Rebuild exports**

Windows: `& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --export-release "Windows Desktop" build/windows/Iron-Mario.exe`
Web: `& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --export-release "Web" build/web/index.html`
Then re-zip: `Compress-Archive -Path "build\web\*" -DestinationPath "exports\Iron-Mario-web.zip" -Force`
Verify: `Get-Item build\windows\Iron-Mario.exe, build\web\index.wasm, exports\Iron-Mario-web.zip | Select-Object Name, Length, LastWriteTime`

- [ ] **Step 7: CI verify**

Fetch: `https://api.github.com/repos/Hustlenix/Iron-Mario/actions/runs` — wait for the Deploy Web run for the new head_sha to show `conclusion=success`. Then `https://hustlenix.github.io/Iron-Mario/` returns 200.

- [ ] **Step 8: Final report**

Summarize: feature list, test results, commit hash, export sizes, live URL, CI status.

---

## Self-Review Notes

- Spec coverage: entry point (T2), scene (T3), core loop/physics (T4), ramp + fair starts (T4/T5), medals + NEW BEST (T6), feather (T7), juice/trail/squash (T4/T6 visuals), zero-downtime restart + ESC (T4/T9), persistence (T1), audio (T8), testing (T3–T9), files list (all tasks). Out-of-scope items are not implemented by design.
- First-pipe delay: `_move_pipes` catch-up is gated by `_spawned > 0` so the 1.6–2.4s generous first delay is never overridden (found in pre-flight review).
- Invulnerability: collisions fully skipped while `invuln_timer > 0` — the shield-pop's blink is a real free pass (found in pre-flight review).
- Keyboard start: `_process` handles `jump` in `title` state so Space/W starts the game without a mouse (found in pre-flight review).
- Trail cast: `as TextureRect` on pooled trail children (typed-var safety, found in pre-flight review).
- Driver tests are deterministic: no reliance on random scoring or pipe geometry — they set score/state/positions directly and call internal methods.
- Type consistency: `_ramp_speed()`/`_ramp_gap()`/`_ramp_interval()` defined in T4 and used consistently; `_pipe_meta` stores `gap_y` + `gap` per pair; `feather_next_spawn` initialized in T3 skeleton and reset in `_restart()`; `medals` dict reset in `_restart()`.
