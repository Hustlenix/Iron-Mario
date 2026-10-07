extends Node

## Phase 4 verification driver for the shared power system.
##
## Run it as a SCENE, not with --script, because the bus and the roster are
## autoloads and autoload identifiers only resolve once a main scene is booted:
##
##   godot --headless --path C:\Users\LalithReddy.b\Iron-Mario res://test_powers.tscn
##
## Kept in the repo deliberately, alongside verify_music and
## test_touch_controls. The power system is the one part of Phase 4 that a
## human reviewer cannot eyeball, so it gets permanent coverage rather than
## temporary scaffolding.
##
## What this pins down:
##   1. `power` is a real InputMap action bound to Shift and E.
##   2. All four minigames expose on_power(family) -> bool -- sixteen handlers.
##   3. The bus routes each of the nine heroes to its correct family.
##   4. A shared cooldown starts only on success, and blocks the second press.
##   5. Flappy has no power, so the press is refused without spending anything.
##
## The minigame countdown has a five-second floor, so every check below runs
## inside the first few frames and the tree quits long before a round could
## ever time out into a fail-and-advance.

var _failures := 0

const MINIGAME_SCENES := {
	"shards": "res://scenes/minigame_1.tscn",
	"tap": "res://scenes/minigame_2.tscn",
	"dodge": "res://scenes/minigame_3.tscn",
	"parry": "res://scenes/minigame_4.tscn",
}

## The four combat families, in the order the design lists them.
const COMBAT_FAMILIES := [
	HeroData.Family.DASH,
	HeroData.Family.REVEAL,
	HeroData.Family.REACH,
	HeroData.Family.BLAST,
]


## Stands in for a minigame so the bus routing and the cooldown contract can be
## checked without depending on any one minigame's scene layout.
class SpyHandler extends Node:
	var calls := 0
	var last_family := -1
	var result := true

	func on_power(family: int) -> bool:
		calls += 1
		last_family = family
		return result


## Records the bus signals so the HUD contract (ratio 1.0 ready -> 0.0 used)
## can be asserted rather than assumed.
class SignalRecorder extends Node:
	var cooldown: Array = []
	var used: Array = []
	var rejected: Array = []

	func on_cooldown(remaining: float, ratio: float) -> void:
		cooldown.append({"remaining": remaining, "ratio": ratio})

	func on_used(hero_id: String, family: int) -> void:
		used.append({"hero": hero_id, "family": family})

	func on_rejected(reason: String) -> void:
		rejected.append(reason)

	func reset() -> void:
		cooldown.clear()
		used.clear()
		rejected.clear()


func _check(label: String, ok: bool, detail := "") -> void:
	if ok:
		print("  PASS  %s" % label)
	else:
		_failures += 1
		print("  FAIL  %s %s" % [label, detail])


func _ready() -> void:
	print("=== Phase 4 power system verification ===")

	_verify_power_action()
	_verify_bus_routes_every_hero()
	_verify_cooldown_only_on_success()
	_verify_cooldown_blocks_second_press()
	_verify_flappy_has_no_power()
	await _verify_sixteen_handlers()
	await _verify_tap_target_returns_after_blast()
	await _verify_dodge_freed_laser_leaves_nothing_queued()
	await _verify_parry_in_flight_does_not_land_after_finish()

	print("\n=== %s ===" % ("ALL PASS" if _failures == 0 else "%d FAILURE(S)" % _failures))
	get_tree().quit(0 if _failures == 0 else 1)


## Both bindings have to survive: Shift is the physical key the design names for
## the big red dash button, and E is the laptop-friendly alternative. A single
## binding would leave half the intended keyboards dead.
func _verify_power_action() -> void:
	print("\n-- power input action")
	_check("power action exists", InputMap.has_action("power"))
	if not InputMap.has_action("power"):
		return

	var events: Array[InputEventKey] = []
	for ev in InputMap.action_get_events("power"):
		var key := ev as InputEventKey
		if key != null:
			events.append(key)

	_check("power is bound to at least one key", not events.is_empty(), "count=%d" % events.size())

	# project.godot declares both bindings via physical_keycode, which is the
	# correct choice for a WASD-shaped layout because it follows the physical
	# key position on non-QWERTY boards. Accept either field so the test pins
	# the intended KEY rather than the current declaration style.
	var has_shift := false
	var has_e := false
	for key in events:
		var codes := [key.keycode, key.physical_keycode]
		if codes.has(KEY_SHIFT):
			has_shift = true
		if codes.has(KEY_E):
			has_e = true

	_check("power bound to Shift", has_shift, str(events))
	_check("power bound to E", has_e, str(events))


## Nine heroes, four families. This is the assertion that would catch a
## mis-typed family column in the roster, which is otherwise invisible until a
## player picks a hero and presses the wrong power.
func _verify_bus_routes_every_hero() -> void:
	print("\n-- hero -> family routing")
	var spy := SpyHandler.new()
	add_child(spy)
	var recorder := SignalRecorder.new()
	add_child(recorder)
	PowerBus.cooldown_changed.connect(recorder.on_cooldown)
	PowerBus.power_used.connect(recorder.on_used)

	var ids := HeroData.selectable_ids()
	_check("roster exposes 9 selectable heroes", ids.size() == 9, "count=%d" % ids.size())

	for id in ids:
		var hero := HeroData.get_hero(id)
		var expected: int = int(hero["family"])

		recorder.reset()
		spy.calls = 0
		spy.last_family = -1
		PowerBus.register_handler(spy, id)

		_check(
			"%s pins its hero on the bus" % id,
			PowerBus.hero_id() == id,
			"got '%s'" % PowerBus.hero_id()
		)
		_check(
			"%s reports family %s" % [id, HeroData.family_name(expected)],
			PowerBus.family() == expected,
			"got %s" % HeroData.family_name(PowerBus.family())
		)
		_check(
			"%s cooldown is the hero's own" % id,
			is_equal_approx(PowerBus.cooldown_total(), float(hero["cooldown"])),
			"got %.2f expected %.2f" % [PowerBus.cooldown_total(), float(hero["cooldown"])]
		)

		var fired: bool = PowerBus.try_activate()
		_check("%s power fires" % id, fired)
		_check(
			"%s handler received family %s" % [id, HeroData.family_name(expected)],
			spy.calls == 1 and spy.last_family == expected,
			"calls=%d family=%s" % [spy.calls, HeroData.family_name(spy.last_family)]
		)
		_check(
			"%s usage emitted with hero id" % id,
			recorder.used.size() == 1 and recorder.used[0]["hero"] == id,
			str(recorder.used)
		)
		_check(
			"%s usage emitted with family %s" % [id, HeroData.family_name(expected)],
			recorder.used.size() == 1 and int(recorder.used[0]["family"]) == expected,
			str(recorder.used)
		)
		# Ratio must collapse to 0.0 the instant the power is spent, because
		# that is what empties the radial fill.
		_check(
			"%s ring reads empty right after use" % id,
			_powerbus_just_used_ratio_is_zero(recorder),
			str(recorder.cooldown)
		)
		_check("%s is now cooling down" % id, not PowerBus.ready_to_use())

	PowerBus.unregister_handler(spy)


## The design's one economy rule that players notice immediately: a press with
## nothing in range must not cost the real cooldown.
func _verify_cooldown_only_on_success() -> void:
	print("\n-- cooldown only starts on success")
	var spy := SpyHandler.new()
	add_child(spy)
	var recorder := SignalRecorder.new()
	add_child(recorder)
	PowerBus.cooldown_changed.connect(recorder.on_cooldown)
	PowerBus.power_rejected.connect(recorder.on_rejected)

	spy.result = false
	recorder.reset()
	PowerBus.register_handler(spy, "pulse")

	var fired: bool = PowerBus.try_activate()
	_check("declined press reports false", not fired)
	_check("handler was still consulted", spy.calls == 1, "calls=%d" % spy.calls)
	_check("no cooldown was started", PowerBus.ready_to_use())
	_check("ratio still full after a decline", is_equal_approx(PowerBus.cooldown_ratio(), 1.0))
	_check(
		"rejection explained as nothing in range",
		recorder.rejected.has("nothing in range"),
		str(recorder.rejected)
	)

	# The same press must still work once something IS in range, which proves
	# the decline did not silently black the power out.
	spy.result = true
	recorder.reset()
	_check("press works after a decline", PowerBus.try_activate())
	_check("cooldown started on the successful press", not PowerBus.ready_to_use())

	PowerBus.unregister_handler(spy)


func _verify_cooldown_blocks_second_press() -> void:
	print("\n-- shared cooldown gate")
	var spy := SpyHandler.new()
	add_child(spy)
	PowerBus.register_handler(spy, "dart")

	_check("first press fires", PowerBus.try_activate())
	var after_first: float = PowerBus.cooldown_remaining()
	_check("cooldown armed", after_first > 0.0, "remaining=%.3f" % after_first)
	_check("can_activate is false while cooling", not PowerBus.can_activate())

	_check("second press refused", not PowerBus.try_activate())
	_check("handler not called again", spy.calls == 1, "calls=%d" % spy.calls)

	# Force_ready is the documented test affordance and must not fake a use.
	PowerBus.force_ready()
	_check("force_ready re-arms", PowerBus.ready_to_use())
	_check("ratio returns to full", is_equal_approx(PowerBus.cooldown_ratio(), 1.0))

	PowerBus.unregister_handler(spy)


## Flappy is on the roster so the art swap works, but offering a cooldown ring
## that can never fire would be a dead control.
func _verify_flappy_has_no_power() -> void:
	print("\n-- flappy has no combat power")
	var spy := SpyHandler.new()
	add_child(spy)
	PowerBus.register_handler(spy, HeroData.FLAPPY_ID)

	_check("flappy is not offered as a pick", not HeroData.is_selectable(HeroData.FLAPPY_ID))
	_check("flappy reports no power", not PowerBus.has_power())
	_check("flappy is not activatable", not PowerBus.can_activate())
	_check("flappy press refused", not PowerBus.try_activate())
	_check("flappy press did not reach a handler", spy.calls == 0, "calls=%d" % spy.calls)
	_check("flappy press cost no cooldown", PowerBus.ready_to_use())

	PowerBus.unregister_handler(spy)
	spy.queue_free()


## The sixteen behaviours. Each minigame must expose one handler per family,
## and every handler must return a real bool so the bus can tell a resolved
## press from a wasted one.
##
## REVEAL is also asserted to SUCCEED in all four scenes: it only needs a target
## to exist, and every minigame spawns with one. That is what proves the
## handler is genuinely wired to the scene rather than present-but-inert.
func _verify_sixteen_handlers() -> void:
	print("\n-- sixteen handlers (4 minigames x 4 families)")

	for label in MINIGAME_SCENES:
		print("\n  [%s]" % label)
		var mg := _spawn(MINIGAME_SCENES[label])
		if mg == null:
			continue

		# The cooldown ring is self-contained: it reads PowerBus directly, so
		# nothing else in the project would notice if its script stopped
		# parsing. Mounting it and loading its script is the only honest proof,
		# and this is the check that would have caught a broken draw_string().
		var ring := _find_ring(mg)
		_check("%s mounts a PowerRing" % label, ring != null)
		if ring != null:
			_check("%s PowerRing script loads" % label, ring.get_script() != null)
			_check(
				"%s PowerRing sits in screen space" % label,
				ring.get_parent() is CanvasLayer
			)

		_check("%s exposes on_power" % label, mg.has_method("on_power"))
		if mg.has_method("on_power"):
			for family in COMBAT_FAMILIES:
				var name: String = HeroData.family_name(family)
				var result: Variant = mg.call("on_power", family)
				_check(
					"%s / %s returns a bool" % [label, name],
					typeof(result) == TYPE_BOOL,
					"got %s (%s)" % [str(result), type_string(typeof(result))]
				)
			var revealed: Variant = mg.call("on_power", HeroData.Family.REVEAL)
			_check(
				"%s / Reveal resolves a target that exists at spawn" % label,
				revealed is bool and revealed == true,
				"got %s" % str(revealed)
			)

		PowerBus.unregister_handler(mg)
		mg.queue_free()
		await get_tree().process_frame
		_check("%s released from the bus after free" % label, not PowerBus.has_handler())


## Pulse vaporises the tap game's target, and the only thing that brings it back
## is the reposition at the end of the blast. Get that wrong and the target
## stays invisible for the rest of the round while every handler still returns
## a real bool, so the sweep above reports a healthy game. This is the one place
## the tap game is checked for what actually happens rather than for shape.
func _verify_tap_target_returns_after_blast() -> void:
	print("\n-- tap: Pulse vaporises, then the target comes back")
	var mg := _spawn(MINIGAME_SCENES["tap"])
	if mg == null:
		return
	await get_tree().process_frame

	var target := mg.get_node_or_null("Target") as TextureRect
	_check("tap: the round has a target on screen", target != null)
	if target == null:
		mg.queue_free()
		return
	_check("tap: the target starts visible", target.visible)

	# Two blasts, not one: the target has to survive being hit again, which is
	# the case a one-shot check would wave through.
	var script: GDScript = load("res://scenes/minigame_2.gd")
	for _shot in 2:
		var blast: Variant = mg.call("on_power", HeroData.Family.BLAST)
		_check("tap / Blast reports a resolved press", blast is bool and blast == true,
			"got %s" % str(blast))
		await get_tree().process_frame
		_check("tap: the target is back on screen after Pulse", target.visible)
		_check("tap: the target is placed clear of the HUD",
			target.position.y >= script.TOP_MARGIN,
			"y %.1f, margin %.1f" % [target.position.y, script.TOP_MARGIN])

	PowerBus.unregister_handler(mg)
	mg.queue_free()
	await get_tree().process_frame
	_check("tap: released from the bus after free", not PowerBus.has_handler())


## Blast resolves its parry from a tween callback, so the parry happens ~0.25s
## after the press. If the round ends inside that gap the callback still lands.
## The jump and the other powers are guarded by the `finished` check at the top
## of their entry points; a callback already in flight has to be stopped at the
## other end, or it banks a parry and restarts the sweep on a dying scene.
func _verify_parry_in_flight_does_not_land_after_finish() -> void:
	print("\n-- parry: a parry in flight does not land after the round ends")
	var mg := _spawn(MINIGAME_SCENES["parry"])
	if mg == null:
		return
	await get_tree().process_frame

	var blast: Variant = mg.call("on_power", HeroData.Family.BLAST)
	_check("parry / Blast reports a resolved press", blast is bool and blast == true,
		"got %s" % str(blast))
	_check("parry: the blast has not banked its parry yet", mg.parries == 0,
		"got %d" % mg.parries)
	_check("parry: the blast killed the running sweep", mg.sweep_tween == null)

	# The countdown ending the round, without the navigation it would trigger.
	mg.finished = true
	await get_tree().create_timer(0.45).timeout

	_check("parry: a parry in flight does not bank after the round ends",
		mg.parries == 0, "got %d" % mg.parries)
	_check("parry: a parry in flight does not restart the sweep on a dying scene",
		mg.sweep_tween == null)

	PowerBus.unregister_handler(mg)
	mg.queue_free()
	await get_tree().process_frame


## MG3 arms its lasers on staggered SceneTree timers, and SONAR adds a second
## tween on the laser it lights. Both timers outlive the laser they were handed,
## so freeing a laser has to take its queued work with it -- otherwise a tween is
## left writing to a node that no longer exists.
func _verify_dodge_freed_laser_leaves_nothing_queued() -> void:
	print("\n-- dodge: freeing a laser clears everything queued against it")
	var mg := _spawn(MINIGAME_SCENES["dodge"])
	if mg == null:
		return
	await get_tree().process_frame

	var tracked := ["_sweeps", "_reveals"]
	var lasers: Node = mg.get_node_or_null("Hazards")
	_check("dodge: the round spawns lasers to work on", lasers != null and lasers.get_child_count() > 0)
	if lasers == null:
		mg.queue_free()
		return

	# Sonar first, so the laser that gets vaporised is also carrying a reveal
	# blink: two tweens on one node, and only one of them was being tracked.
	var sonar: Variant = mg.call("on_power", HeroData.Family.REVEAL)
	_check("dodge / Sonar reports a resolved press", sonar is bool and sonar == true,
		"got %s" % str(sonar))
	# Stand the player on the last laser so the blast lands on the one whose
	# staggered arm timer is still queued -- the only way to reach the window
	# where a timer outlives the laser it was handed.
	var pending: Node = lasers.get_child(lasers.get_child_count() - 1)
	mg.get_node("Player").global_position = pending.global_position
	# Straight into a blast, still inside the first arm tick.
	var blast: Variant = mg.call("on_power", HeroData.Family.BLAST)
	_check("dodge / Blast resolves before any laser has armed",
		blast is bool and blast == true, "got %s" % str(blast))

	# Checked once the free has actually landed, but while the reveal blink is
	# still looping: queue_free() is deferred, so the laser is still valid on this
	# same frame, and the reveal tidies itself away at ~0.9s. The gap in between
	# is the only window where a tween is still running against a freed laser, and
	# it is where this has to be looked for.
	await get_tree().create_timer(0.25).timeout
	_check("dodge: the blast leaves no freed laser tracked", _freed_tracked(mg, tracked).is_empty(),
		"; ".join(_freed_tracked(mg, tracked)))

	# Past the last staggered arm delay, so every timer handed to the freed laser
	# has fired and had its chance to touch it.
	await get_tree().create_timer(1.6).timeout

	var stale := _freed_tracked(mg, tracked)
	_check("dodge: no freed laser is left queued or tracked", stale.is_empty(),
		"; ".join(stale))

	# The surviving lasers must still be sweeping, so the cleanup above did not
	# quietly disarm the round.
	var live := 0
	for laser: Area2D in mg._sweeps:
		if is_instance_valid(laser):
			live += 1
	_check("dodge: the lasers that survived are still sweeping", live > 0,
		"%d live sweeps" % live)

	PowerBus.unregister_handler(mg)
	mg.queue_free()
	await get_tree().process_frame


## Names every group that is still holding a laser which has already been freed.
## The loop is deliberately untyped: a typed `for laser: Area2D in entries`
## silently skips freed values, because a freed node no longer resolves to the
## declared type -- which would hide exactly the thing this is here to find.
func _freed_tracked(mg: Node, groups: Array) -> Array:
	var stale: Array = []
	for group: String in groups:
		var entries: Dictionary = mg.get(group)
		for laser in entries:
			if not is_instance_valid(laser):
				stale.append("%s held a freed laser" % group)
	return stale


## Find the mounted cooldown ring anywhere under a spawned minigame. The ring
## lives under a CanvasLayer named "PowerHUD", so a plain recursive walk is
## enough and keeps the check independent of scene layout order.
func _find_ring(root: Node) -> Node:
	if root.name == "PowerRing":
		return root
	for child in root.get_children():
		var found := _find_ring(child)
		if found != null:
			return found
	return null


## Instantiate into this scene, not the scene tree root, so the test owns the
## lifecycle and nothing can navigate away from the running test.
func _spawn(path: String) -> Node:
	var packed: PackedScene = load(path)
	_check("%s loads" % path.get_file(), packed != null)
	if packed == null:
		return null
	var node: Node = packed.instantiate()
	add_child(node)
	return node


## The recorded cooldown ticks include the arm (ratio 0.0), so the check is
## that an empty reading exists, not that the last value happens to be zero.
func _powerbus_just_used_ratio_is_zero(recorder: SignalRecorder) -> bool:
	for entry in recorder.cooldown:
		if is_zero_approx(float(entry["ratio"])):
			return true
	return false
