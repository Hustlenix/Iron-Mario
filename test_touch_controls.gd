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


## Stands in for a minigame. The power button only offers a press when some
## scene can actually consume it, so the powered-hero cases need a real handler
## rather than the null pin the bus also accepts for hero overrides.
class StubHandler extends Node:
	func on_power(_family: int) -> bool:
		return true


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
		_check("power button found", touch.get_node_or_null("BottomRow/Controls/PowerButton") != null)
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

		# The power button drives the same InputMap action the minigames poll,
		# so touch and keyboard reach an identical code path.
		var power: Button = touch.get_node("BottomRow/Controls/PowerButton")
		power.button_down.emit()
		_check("power pressed -> action held", Input.is_action_pressed("power"))
		power.button_up.emit()
		_check("power released -> action cleared", not Input.is_action_pressed("power"))

		# Touch targets must clear the 64 px accessibility floor.
		_check("left target >= 64px", left.custom_minimum_size.x >= 64.0 and left.custom_minimum_size.y >= 64.0)
		_check("jump target >= 64px", jump.custom_minimum_size.x >= 64.0 and jump.custom_minimum_size.y >= 64.0)
		_check("power target >= 64px", power.custom_minimum_size.x >= 64.0 and power.custom_minimum_size.y >= 64.0)

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
	await _verify_first_touch()
	_verify_orientation_and_keys()
	await _verify_power_button()
	await _verify_layout()

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
	_check("touch exposes 4 bound actions", touched.size() == 4, str(touched))
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


## The power button must never lie to the player: it shows the active hero's
## real power name, disables itself while the shared cooldown runs, and hides
## entirely for a hero with no power. Exercised through the same per-frame poll
## the real layer uses, so a hero swap is proven to correct the label.
func _verify_power_button() -> void:
	print("\n-- power button state")
	var packed: PackedScene = load("res://scenes/touch_controls.tscn")
	if packed == null:
		_check("power button: scene loads", false)
		return

	var saved_hero := Global.selected_hero
	var touch = packed.instantiate()
	add_child(touch)
	await get_tree().process_frame

	var power: Button = touch.get_node("BottomRow/Controls/PowerButton")

	# A hero with a power, in a scene that can consume the press: labelled with
	# that hero's own power, usable.
	var stub := StubHandler.new()
	add_child(stub)
	PowerBus.register_handler(stub)
	Global.selected_hero = "dart"
	PowerBus._resolve_hero()
	await get_tree().process_frame
	_check("power button visible for a powered hero", power.visible)
	_check("power button enabled when ready", not power.disabled)
	_check("power button shows hero power name", power.text == "LUNGE", power.text)

	# level_scene and flappy_bird instance these buttons but register no handler,
	# so a press there is rejected as "no target" every time. The button must not
	# advertise a power it cannot fire.
	PowerBus.register_handler(null)
	await get_tree().process_frame
	_check("power button hidden with no handler to consume it", not power.visible)

	PowerBus.register_handler(stub)
	await get_tree().process_frame
	_check("power button returns once a handler exists", power.visible)

	# Mid-cooldown: still on screen, but it must refuse the tap.
	PowerBus.set("_cooldown_remaining", 2.0)
	await get_tree().process_frame
	_check("power button visible while cooling", power.visible)
	_check("power button disabled while cooling", power.disabled)
	PowerBus.force_ready()
	await get_tree().process_frame
	_check("power button re-enabled when ready again", not power.disabled)

	# A hero with no power must hide the button rather than offer a dead tap.
	# Flappy is the only such hero and is deliberately NOT selectable, so it can
	# never arrive through Global.active_hero_id() -- that path falls through to
	# a powered hero. Drive the bus's own hero pin to reach this branch, which
	# is how DEFAULT_HERO and any future visual-only hero would land here.
	PowerBus.register_handler(stub, "flappy")
	await get_tree().process_frame
	_check("power button hidden for a powerless hero", not power.visible)

	# Un-pin the hero override while keeping the handler registered.
	PowerBus.register_handler(stub, "")
	Global.selected_hero = saved_hero
	PowerBus._resolve_hero()
	await get_tree().process_frame
	_check("power button returns for a powered hero", power.visible)

	PowerBus.register_handler(null)
	touch.queue_free()
	await get_tree().process_frame


## Adding a fourth button is a layout risk, not just a wiring one: the row can
## silently overflow the 1280-wide design frame or squeeze a target under the
## 64 px floor. This measures the real laid-out rectangles after the container
## has resolved them, so a regression shows up as numbers rather than as a
## screenshot nobody diffs.
func _verify_layout() -> void:
	print("\n-- button layout")
	# The headless dummy driver hands back a 64x64 window, which is portrait,
	# so the row hides itself and every measurement below would be degenerate.
	# Pin the real design resolution first so this asserts against the same
	# frame a player sees rather than against whatever the driver reports.
	get_window().size = Vector2i(1280, 720)
	for i in range(4):
		await get_tree().process_frame

	var packed: PackedScene = load("res://scenes/touch_controls.tscn")
	if packed == null:
		_check("layout: scene loads", false)
		return

	var touch = packed.instantiate()
	add_child(touch)
	# The power button hides without a handler, and a hidden child is skipped by
	# the HBox layout, so its rect would be stale rather than measured. Register
	# a handler so all four buttons are actually placed, which is the state a
	# minigame -- the only place the power button appears -- runs in.
	var layout_stub := StubHandler.new()
	add_child(layout_stub)
	PowerBus.register_handler(layout_stub)
	# Two frames: one to build the container tree, one to resolve the layout.
	await get_tree().process_frame
	await get_tree().process_frame

	var row: Control = touch.get_node("BottomRow/Controls")
	var names := ["LeftButton", "RightButton", "PowerButton", "JumpButton"]
	var bottom: Control = touch.get_node("BottomRow")

	_check("layout viewport is the design frame", get_viewport().size == Vector2i(1280, 720),
		str(get_viewport().size))
	_check("control row is not portrait at the design frame",
		not touch.is_portrait_size(get_viewport().get_visible_rect().size),
		str(get_viewport().get_visible_rect().size))

	# On a device with no touchscreen the row correctly stays hidden, so the
	# first real touch has to reveal it. Drive that path with a synthetic touch
	# rather than forcing `show()`, so the reveal is covered and the container
	# below gets a real layout pass to measure.
	if not (DisplayServer.is_touchscreen_available() or touch._touch_seen):
		_check("control row stays hidden without a touchscreen", not bottom.visible)
		var ev := InputEventScreenTouch.new()
		ev.pressed = true
		ev.index = 0
		Input.parse_input_event(ev)
		await get_tree().process_frame
		await get_tree().process_frame
	_check("control row is shown once a touch is seen", bottom.visible)

	var frame := 1280.0
	_check("control row fits the design frame", row.size.x <= frame + 0.5,
		"row=%.1f frame=%.1f" % [row.size.x, frame])

	var rects: Array = []
	for name in names:
		var b: Button = row.get_node(name)
		rects.append({"name": name, "rect": b.get_global_rect()})
		# Measured size, not the authored minimum: this is what a finger hits.
		_check("%s measured target >= 64px" % name,
			b.size.x >= 64.0 and b.size.y >= 64.0,
			"%.1fx%.1f" % [b.size.x, b.size.y])
		_check("%s is fully inside the control row" % name,
			b.get_global_rect().end.x <= row.get_global_rect().end.x + 0.5)

	# No two buttons may share pixels, or a tap hits the wrong control.
	for i in range(rects.size()):
		for j in range(i + 1, rects.size()):
			var a: Rect2 = rects[i]["rect"]
			var c: Rect2 = rects[j]["rect"]
			_check("%s does not overlap %s" % [rects[i]["name"], rects[j]["name"]],
				not a.intersects(c),
				"%s %s" % [a, c])

	# The power button must sit with the other action, not the movement pair.
	var power: Button = row.get_node("PowerButton")
	var jump: Button = row.get_node("JumpButton")
	var left: Button = row.get_node("LeftButton")
	_check("power button sits on the action side of the row",
		power.get_global_rect().get_center().x > left.get_global_rect().get_center().x)
	_check("power button neighbours the jump button",
		absf(power.get_global_rect().position.x - jump.get_global_rect().position.x) < 400.0)

	PowerBus.register_handler(null)
	touch.queue_free()
	layout_stub.queue_free()
	await get_tree().process_frame


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
