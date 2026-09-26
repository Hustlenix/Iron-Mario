# Phase 2 — Mobile support

**Goal:** make Super-Mario genuinely playable on a phone in landscape, and installable as a PWA, without regressing desktop keyboard play.

**Status:** Shipped. Tasks 1–8 complete and verified.

## Constraints carried from the design

- Landscape-only. Portrait shows a rotate prompt instead of a broken layout.
- Phase 2 ships `left` / `right` / `jump` touch controls. The `power` button arrives in Phase 4.
- Touch UI appears on first touch, on a real touchscreen device, and only when the touch-controls setting is on.
- Touch targets at least 64 px, anchored to the bottom corners.
- `stretch/aspect="keep"` (already set) letterboxes rather than distorting.
- A `power` input action is deliberately NOT added now — Phase 4 owns it.

## Key facts discovered while planning

These drive every decision below.

1. **`level_scene.tscn` and `flappy_bird.tscn` are `Node2D` roots.** Neither has a `CanvasLayer`, so overlay UI is not a pattern used in this project yet. The touch layer will be a `CanvasLayer` with `layer = 100` so it draws over gameplay.
2. **Both scenes already receive input via actions, not via `_input()`.** `minigame_*.gd` scripts use `Input.is_action_pressed("left"/"right")` style polling or `input` signals, so emitting the existing actions from touch makes touch work everywhere with no gameplay-code change.
3. **`settings_scene.gd` is a `Control` with a `CenterContainer/VBoxContainer` layout** — the touch toggle is a sibling row, not a redesign.
4. **The three input actions are `jump`, `left`, `right`.** Confirmed from `project.godot`. There is no `power` action yet.
5. **Title screen has menu buttons; on a phone it needs a tap anywhere to start, plus working settings access.** The touch layer is instantiated in gameplay scenes only, not the title screen.
6. **`Global.reset()` clears run state but must not clear device/settings flags.** Phase 4 has the same constraint for `selected_hero`.

## Files

**New**
- `scenes/touch_controls.tscn` — `CanvasLayer` + three buttons + portrait prompt
- `scenes/touch_controls.gd` — visibility rules, touch→action emission, portrait prompt

**Modified**
- `scenes/level_scene.tscn` — instance `TouchControls`
- `scenes/flappy_bird.tscn` — instance `TouchControls`
- `scenes/settings_scene.tscn` + `settings_scene.gd` — touch-controls toggle row
- `project.godot` — PWA orientation
- `export_presets.cfg` — PWA enabled, landscape, mobile texture compression
- `README.md` — note the landscape requirement
- `default_env.tres` if present — skip otherwise

## Tasks

### Task 1: Baseline

```powershell
& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path "C:\Users\LalithReddy.b\Iron-Mario" --quit-after 30
```

Expect exit `0`, no `SCRIPT ERROR` / `ERROR:`. Working tree clean at `bb0c494`.

### Task 2: `touch_controls.gd`

```gdscript
extends CanvasLayer

const MIN_TARGET_PX := 64.0
const PORTRAIT_MIN_ASPECT := 1.2   # height/width above this means portrait

@onready var left_button: Button = $LeftButton
@onready var right_button: Button = $RightButton
@onready var jump_button: Button = $JumpButton
@onready var portrait_hint: Control = $PortraitHint

var _touch_seen := false


func _ready() -> void:
	# Never poll input in the background; the game must not steal keys from other apps.
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	set_process_input(false)

	for action in ["jump", "left", "right"]:
		if not InputMap.has_action(action):
			push_error("touch_controls: missing input action '%s'" % action)
			return

	_bind_held("left", left_button)
	_bind_held("right", right_button)
	_bind_held("jump", jump_button)
	_publish_visibility()
	get_viewport().size_changed.connect(_publish_visibility)
	tree_exiting.connect(_release_all)


func _bind_held(action: String, button: Button) -> void:
	button.button_down.connect(func () -> void: Input.action_press(action))
	button.button_up.connect(func () -> void: Input.action_release(action))


func _release_all() -> void:
	for action in ["jump", "left", "right"]:
		Input.action_release(action)


func _is_portrait() -> bool:
	var size := get_viewport().get_visible_rect().size
	return size.y / maxf(size.x, 1.0) > PORTRAIT_MIN_ASPECT


func _publish_visibility() -> void:
	var portrait := _is_portrait()
	portrait_hint.visible = portrait
	if portrait:
		hide()
		return
	if Global.touch_controls_enabled and (is_touchscreen_available() or _touch_seen):
		show()
	else:
		hide()
```

Requirements this script must satisfy:

- `_is_portrait()` compares the viewport size: `size.y / size.x > PORTRAIT_MIN_ASPECT`.
- Touch visibility = setting AND (touchscreen present OR a touch was already observed), AND not portrait.
- Buttons are `Button` with `mouse_filter = IGNORE` on the *layer* but `STOP` on the buttons, so the layer never eats gameplay clicks.
- Each button emits the matching action via `Input.action_press` / `Input.action_release` on `button_down` / `button_up`. Holding a button must keep the action held — that is what makes minigame 3 and 4 (which need sustained left/right) work.
- A short **tap** anywhere in the portrait prompt is not required; the prompt is informational.
- A **tap anywhere on the title screen** in Phase 2 is out of scope — the title screen already has large buttons and works by touch as-is.

Wiring table (exact):

| Control | Action | Note |
|---|---|---|
| `LeftButton` | `left` | hold-capable |
| `RightButton` | `right` | hold-capable |
| `JumpButton` | `jump` | hold-capable; several minigames check `just_pressed` |

### Task 3: `touch_controls.tscn`

- Root `CanvasLayer`, `layer = 100`.
- Three `Button` nodes in a `HBoxContainer` bottom-anchored, plus a `PortraitHint` `Control`.
- Each button: `custom_minimum_size = Vector2(96, 96)` (comfortably above the 64 px floor), flat transparent style, large glyph label (`◀` / `▶` / `JUMP`).
- `PortraitHint`: full-rect `ColorRect` at ~70% black with a centered `Label` reading `ROTATE YOUR DEVICE` and a smaller sub-line `Super-Mario plays in landscape`.
- Buttons live in a `BottomRow` `MarginContainer` so they clear the notches on phones.

### Task 4: Verify the wiring, then instantiate in the two gameplay scenes

Task 2 already contains the complete `_bind_held` implementation, so there is no separate binding step. This task is the check that the three buttons really emit the three actions, then the scene integration.

Add to `level_scene.tscn` and `flappy_bird.tscn`:

```
[ext_resource type="PackedScene" uid="uid://..." path="res://scenes/touch_controls.tscn" id="99_touch"]
[ext_resource type="Script" path="res://scenes/touch_controls.gd" id="98_touch"]

[node name="TouchControls" parent="." instance=ExtResource("99_touch")]
script = ExtResource("98_touch")
```

The uid is not knowable before the file exists — create the scene, then read the uid Godot assigns, then insert. Do not guess a uid.

### Task 5: `Global` flags

`scripts/Global.gd`:

```gdscript
var touch_controls_enabled: bool = true
var low_quality: bool = false
```

Persist both in `save()` / `load_save()` using the existing JSON pattern, defaulting sensibly when a key is absent. Do **not** add them to `reset()` — `reset()` is run-state only, and clearing a player's device preference at the start of a gauntlet is a bug.

### Task 6: Settings toggle

`settings_scene.tscn`: add a row alongside the volume row with a `CheckButton` labelled `TOUCH CONTROLS`. `settings_scene.gd` binds it to `Global.touch_controls_enabled`, calls `Global.save()`, and shows the existing `StatusLabel` confirmation so the player gets feedback like the reset button gives.

### Task 7: PWA + landscape export

`project.godot` under `[display]`, add:

```
window/handheld/orientation=0
```

`project.godot` stores this as an int, not the string name. `0` is `SCREEN_LANDSCAPE`. Do **not** use `3` — that is `SCREEN_REVERSE_PORTRAIT`, which points the phone the wrong way.

`export_presets.cfg` in the `Web` preset:

```
progressive_web_app/enable=true
progressive_web_app/ensure_cross_origin_isolation_headers=true
progressive_web_app/offline_page=""
```

Two settings that are required rather than optional, both found the hard way:

```
progressive_web_app/orientation=1          # landscape in the generated manifest
vram_texture_compression/for_mobile=false  # see below
```

`for_mobile=true` breaks Web export outright, with a bare
`Cannot export project with preset "Web" due to configuration errors:` and no useful detail. It belongs in the Android/iOS presets, not Web.

The output folder must exist before exporting — Godot will not create the parent directory for you.

Confirm the export still succeeds after the change — PWA generation can fail on a missing icon and only surfaces at export time.

### Task 8: Verification

1. Headless boot — exit `0`, no script errors.
2. Rename check from Phase 1 still passes (regression guard).
3. Export Web preset — exit `0`, and an `index.manifest.json` appears in `build/web/`. Godot names it after the export target, **not** the web-standard `manifest.webmanifest`, so a missing `manifest.webmanifest` is not a failure. Check the manifest carries `display: standalone`, `orientation: landscape`, and all three icon entries.
4. Landscape phone layout — at 844×390 confirm the canvas letterboxes, no scrollbars, and the three buttons are reachable with a thumb.
5. Rotate to portrait in the same browser check — confirm `ROTATE YOUR DEVICE` shows and the buttons are gone.
6. Keyboard regression at 1280×720 — confirm `A`/`D`/`W`/arrows still drive the player and no touch buttons appear on a non-touch viewport.

#### What verification actually ran

Steps 1–3 and 6 are covered by `test_touch_controls.tscn` (81 checks, exit `0`), a headless 30-frame boot, and a real Web export.

Steps 4–5 could not be done headlessly. The headless `DisplayServer` pins the viewport to 1280×720 no matter what `window.size` or `--resolution` says, so a portrait check that resized the root window was silently testing nothing. The real path is a windowed run (`--resolution 844x390` with no `--headless`), which is how the stretch scale and the on-screen button rectangles below were measured.

#### The 64 px floor is a physical-pixel problem, not a layout problem

The project stretches with `canvas_items` / `keep`, so the logical viewport stays 1280×720 and content is **scaled down** to fit a phone. On an 844×390 screen the scale is `0.541`, which turned the authored 112 px-wide buttons into **~61 physical px — under the accessibility floor**, even though the scene file looked correct.

So the buttons are sized against the render scale, and the floor is 88 physical px rather than 64 for margin. Authored sizes are a floor, never a ceiling, so desktop is unaffected:

| Window | Scale | Button (content) | Button (physical) |
| --- | --- | --- | --- |
| 740×360 | 0.500 | 176×176 | 88×88 |
| 844×390 | 0.541 | 163×163 | 88×88 |
| 915×412 | 0.572 | 154×154 | 88×88 |
| 1280×720 | 1.000 | 112×112 / 160×112 (authored) | unchanged |

A scene-file assertion like `custom_minimum_size.x >= 64` passes while the real target is too small on-device. Check the multiplied size, not the authored one.

## Out of scope for Phase 2

- The `power` touch button (Phase 4).
- Native Android / iOS builds and store submission.
- `low_quality` actually degrading anything — the flag is defined and persisted here, used in Phase 3.
- Music (Phase 3), heroes (Phase 4).
