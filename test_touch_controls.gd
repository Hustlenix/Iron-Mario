extends Node

## Phase 2 verification driver. Loads both gameplay scenes, asserts the touch
## layer instantiated, then exercises the button -> action wiring directly.
##
## Run it as a SCENE, not with --script, because this project reaches
## `Global` (an autoload) and autoload identifiers only resolve when a main
## scene is booted:
##
##   godot --headless --path . res://test_touch_controls.tscn
##
## Kept in the repo deliberately -- Phase 4 needs the same pattern for the
## hero-power drivers (see test_flappy.gd convention).

var _failures := 0


func _check(label: String, ok: bool, detail := "") -> void:
	if ok:
		print("  PASS  %s" % label)
	else:
		_failures += 1
		print("  FAIL  %s %s" % [label, detail])


func _ready() -> void:
	print("=== Phase 2 touch controls verification ===")

	for path in ["res://scenes/level_scene.tscn", "res://scenes/flappy_bird.tscn"]:
		print("\n-- %s" % path)
		var packed: PackedScene = load(path)
		_check("scene loads", packed != null)
		if packed == null:
			continue

		var scene: Node = packed.instantiate()
		add_child(scene)
		await get_tree().process_frame

		var touch: CanvasLayer = scene.get_node_or_null("TouchControls")
		_check("TouchControls instantiated", touch != null)
		if touch == null:
			scene.queue_free()
			continue

		_check("script attached", touch.get_script() != null)
		_check("left button found", touch.get_node_or_null("BottomRow/Controls/LeftButton") != null)
		_check("right button found", touch.get_node_or_null("BottomRow/Controls/RightButton") != null)
		_check("jump button found", touch.get_node_or_null("BottomRow/Controls/JumpButton") != null)
		_check("portrait hint found", touch.get_node_or_null("PortraitHint") != null)

		# Hold-capable wiring: press-and-hold must register as a held action,
		# which is what minigames 3 and 4 rely on.
		var jump: Button = touch.get_node("BottomRow/Controls/JumpButton")
		jump.button_down.emit()
		_check("jump pressed -> action held", Input.is_action_pressed("jump"))
		jump.button_up.emit()
		_check("jump released -> action cleared", not Input.is_action_pressed("jump"))

		var left: Button = touch.get_node("BottomRow/Controls/LeftButton")
		left.button_down.emit()
		_check("left pressed -> action held", Input.is_action_pressed("left"))
		left.button_up.emit()
		_check("left released -> action cleared", not Input.is_action_pressed("left"))

		var right: Button = touch.get_node("BottomRow/Controls/RightButton")
		right.button_down.emit()
		_check("right pressed -> action held", Input.is_action_pressed("right"))
		right.button_up.emit()
		_check("right released -> action cleared", not Input.is_action_pressed("right"))

		# Touch targets must clear the 64 px accessibility floor.
		_check("left target >= 64px", left.custom_minimum_size.x >= 64.0 and left.custom_minimum_size.y >= 64.0)
		_check("jump target >= 64px", jump.custom_minimum_size.x >= 64.0 and jump.custom_minimum_size.y >= 64.0)

		# Must draw above gameplay.
		_check("layer above gameplay", touch.layer >= 100)

		# The layer always stays visible because it also hosts the rotate
		# hint; BottomRow is the part the settings toggle gates.
		var bottom_row: Control = touch.get_node("BottomRow")
		var portrait_hint: Control = touch.get_node("PortraitHint")

		# The settings toggle must actually gate visibility. Force the
		# first-touch-seen flag because this is a desktop/headless run with
		# no touchscreen, otherwise the gate is untestable here.
		touch.set("_touch_seen", true)
		Global.touch_controls_enabled = true
		touch.call("_publish_visibility")
		_check("row visible when enabled + touch seen", bottom_row.visible)
		_check("rotate hint hidden in landscape", not portrait_hint.visible)

		Global.touch_controls_enabled = false
		touch.call("_publish_visibility")
		_check("row hidden when setting off", not bottom_row.visible)
		Global.touch_controls_enabled = true

		# In portrait the prompt must be up. It used to be shown and then
		# immediately hidden along with the whole layer, leaving a black
		# screen with no rotate hint at all. Drive the branch directly: the
		# root window size does not reliably change headlessly, so resizing it
		# would silently test nothing.
		touch.call("_apply_visibility", true)
		_check("rotate hint shown in portrait", portrait_hint.visible)
		_check("row hidden in portrait", not bottom_row.visible)
		_check("layer still visible in portrait", touch.visible)

		touch.call("_apply_visibility", false)
		_check("back to landscape clears hint", not portrait_hint.visible)
		_check("row restored in landscape", bottom_row.visible)

		# A held button must not leave the action stuck across a scene change.
		jump.button_down.emit()
		_check("action held before free", Input.is_action_pressed("jump"))
		scene.queue_free()
		await get_tree().process_frame
		_check("stuck action released on free", not Input.is_action_pressed("jump"))

	await _verify_settings()
	_verify_persistence_and_reset()
	_verify_first_touch()
	_verify_orientation_and_keys()

	print("\n=== %s ===" % ("ALL PASS" if _failures == 0 else "%d FAILURE(S)" % _failures))
	get_tree().quit(0 if _failures == 0 else 1)


## A device that reports no touchscreen would otherwise start with the controls
## hidden and no button could ever be pressed to reveal them, so a raw screen
## touch has to reveal the row on its own.
func _verify_first_touch() -> void:
	var packed: PackedScene = load("res://scenes/touch_controls.tscn")
	if packed == null:
		_check("first touch: scene loads", false)
		return
	var touch = packed.instantiate()
	add_child(touch)
	await get_tree().process_frame

	var bottom_row: Control = touch.get_node("BottomRow")
	var saved_enabled := Global.touch_controls_enabled
	Global.touch_controls_enabled = true

	touch.set("_touch_seen", false)
	touch.call("_publish_visibility")
	var starts_hidden := not bottom_row.visible
	if DisplayServer.is_touchscreen_available():
		# A real touchscreen would already show them; only assert the
		# hidden-start path when the device genuinely reports none.
		_check("first touch: hidden before touch", true, "touchscreen present, skipped")
	else:
		_check("first touch: hidden before touch", starts_hidden)

	if not starts_hidden:
		touch.queue_free()
		Global.touch_controls_enabled = saved_enabled
		return

	touch.call("_input", InputEventScreenTouch.new())
	await get_tree().process_frame
	_check("first touch reveals row", bottom_row.visible)
	_check("first touch sets flag", touch.get("_touch_seen") == true)

	# And it must not be a one-shot: a later settings-off still hides it.
	Global.touch_controls_enabled = false
	touch.call("_publish_visibility")
	_check("first touch still respects toggle", not bottom_row.visible)

	Global.touch_controls_enabled = saved_enabled
	touch.queue_free()
	await get_tree().process_frame


## The handheld orientation value is an opaque engine enum, so assert it
## resolves to landscape rather than trusting the number in project.godot.
## Keyboard bindings must survive the touch layer being added.
func _verify_orientation_and_keys() -> void:
	var raw: int = ProjectSettings.get_setting("display/window/handheld/orientation", -1)
	_check("handheld orientation is set", raw >= 0, "raw=%d" % raw)
	_check(
		"handheld orientation resolves to landscape",
		raw == DisplayServer.SCREEN_LANDSCAPE,
		"raw=%d expected=%d (SCREEN_REVERSE_LANDSCAPE=%d, SCREEN_REVERSE_PORTRAIT=%d)" % [
			raw,
			DisplayServer.SCREEN_LANDSCAPE,
			DisplayServer.SCREEN_REVERSE_LANDSCAPE,
			DisplayServer.SCREEN_REVERSE_PORTRAIT,
		]
	)

	for action in ["left", "right", "jump"]:
		_check("keyboard action '%s' exists" % action, InputMap.has_action(action))
		_check("keyboard action '%s' has a key" % action, not InputMap.action_get_events(action).is_empty())

	# Every touch button must map to a real action, so touch and keyboard
	# drive the same code path. Read the constant off the script because the
	# script declares no class_name.
	var script: GDScript = load("res://scenes/touch_controls.gd")
	var consts: Dictionary = script.get_script_constant_map()
	var touched: Array = consts.get("TOUCHED_ACTIONS", [])
	_check("touch exposes 3 bound actions", touched.size() == 3, str(touched))
	for action in touched:
		_check("touch action '%s' is a real action" % action, InputMap.has_action(action))

	# The portrait rule against real device sizes, so the threshold is pinned
	# to hardware rather than to whatever this machine happens to report.
	_check(
		"portrait rule: iPhone 14 portrait",
		script.is_portrait_size(Vector2(390, 844)),
		"390x844"
	)
	_check(
		"portrait rule: iPhone 14 landscape",
		not script.is_portrait_size(Vector2(844, 390)),
		"844x390"
	)
	_check(
		"portrait rule: tablet landscape",
		not script.is_portrait_size(Vector2(1180, 820)),
		"1180x820"
	)
	_check(
		"portrait rule: square window stays landscape",
		not script.is_portrait_size(Vector2(800, 800)),
		"800x800"
	)


func _verify_settings() -> void:
	print("\n-- settings scene toggle")
	var packed: PackedScene = load("res://scenes/settings_scene.tscn")
	_check("settings scene loads", packed != null)
	if packed == null:
		return

	Global.touch_controls_enabled = true
	var scene: Node = packed.instantiate()
	add_child(scene)
	await get_tree().process_frame

	var toggle: CheckButton = scene.get_node_or_null("CenterContainer/VBoxContainer/TouchRow/TouchToggle")
	_check("touch toggle row exists", toggle != null)
	if toggle == null:
		scene.queue_free()
		return

	_check("toggle reflects saved value", toggle.button_pressed == Global.touch_controls_enabled)

	# Player flips it off -> global updates.
	toggle.button_pressed = false
	scene.call("_on_touch_controls_toggled", false)
	_check("toggle off updates global", Global.touch_controls_enabled == false)

	var status: RichTextLabel = scene.get_node("CenterContainer/VBoxContainer/StatusLabel")
	_check("confirmation shown", status.visible and "SAVED" in status.text)

	scene.queue_free()
	await get_tree().process_frame


func _verify_persistence_and_reset() -> void:
	print("\n-- save round-trip and reset()")
	# Leave the value off, save, and force a reload from disk.
	Global.touch_controls_enabled = false
	Global.low_quality = true
	Global.best_streak = 7
	Global.save()

	Global.touch_controls_enabled = true
	Global.low_quality = false
	Global.best_streak = 0
	Global.load_save()
	_check("touch flag persisted", Global.touch_controls_enabled == false)
	_check("low_quality persisted", Global.low_quality == true)
	_check("best_streak persisted", Global.best_streak == 7)

	# reset() clears run state but must NOT clear device/settings flags.
	Global.streak = 4
	Global.loop = 2
	Global.reset()
	_check("reset clears streak", Global.streak == 0)
	_check("reset clears loop", Global.loop == 0)
	_check("reset preserves touch flag", Global.touch_controls_enabled == false)
	_check("reset preserves low_quality", Global.low_quality == true)

	# Restore defaults so a later run is not left with low quality on.
	Global.touch_controls_enabled = true
	Global.low_quality = false
	Global.best_streak = 0
	Global.save()
