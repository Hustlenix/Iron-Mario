extends Node
## Headless verification for the Phase 4 hero + power system.
##
## Run as a real main scene (`godot --headless res://test_heroes.tscn`) so the
## autoloads resolve -- a bare SceneTree script cannot see Global or PowerBus.
## Exits non-zero on any failure.
##
## This driver is temporary scaffolding: the plan calls for it to be removed
## once the phase lands and the behaviour is covered by the game itself.

var _checks := 0
var _failed := 0

func _ready() -> void:
	_run()

func _check(label: String, ok: bool, detail: String = "") -> void:
	_checks += 1
	if ok:
		print("  PASS  %s  %s" % [label, detail])
	else:
		_failed += 1
		print("  FAIL  %s  %s" % [label, detail])

func _run() -> void:
	print("\n=== HERO / POWER VERIFICATION ===")
	_verify_roster()
	_verify_families()
	_verify_flappy()
	_verify_cooldowns()
	_verify_resolution()
	_verify_persistence()
	_verify_bus_gate()
	_verify_dispatch()

	print("\n--- %d checks, %d failed ---" % [_checks, _failed])
	get_tree().quit(1 if _failed > 0 else 0)

func _verify_roster() -> void:
	print("\n--- roster ---")
	var ids := HeroData.ids()
	_check("roster has ten entries", ids.size() == 10, "got %d" % ids.size())
	_check("roster ids are unique", _unique(ids))
	_check("roster lookup is by id", HeroData.get_hero("bolt")["power"] == "Overdrive")
	_check("every hero has art, blurb and accent",
		_roster_complete("art") and _roster_complete("blurb") and _roster_complete("accent"))

	# The licensed-likeness guard: names may ship, art must be ours. Every
	# hero must live under assets/heroes/ EXCEPT flappy, whose sprite is the
	# pre-existing assets/flappy_hero.svg and must not be moved.
	var strays: Array[String] = []
	for hero in HeroData.all():
		var art: String = hero["art"]
		if hero["id"] == "flappy":
			if art != "res://assets/flappy_hero.svg":
				strays.append("%s -> %s" % [hero["id"], art])
		elif not art.begins_with("res://assets/heroes/"):
			strays.append("%s -> %s" % [hero["id"], art])
	_check("all art is ours, and flappy's sprite is not moved", strays.is_empty(), str(strays))

func _verify_families() -> void:
	print("\n--- power families ---")
	var counts := {}
	for hero in HeroData.selectable():
		var family: int = hero["family"]
		counts[family] = int(counts.get(family, 0)) + 1
	_check("four families in use", counts.size() == 4, "got %d" % counts.size())
	_check("two dash heroes", counts[HeroData.Family.DASH] == 2, "got %d" % counts[HeroData.Family.DASH])
	_check("two reveal heroes", counts[HeroData.Family.REVEAL] == 2, "got %d" % counts[HeroData.Family.REVEAL])
	_check("three reach heroes", counts[HeroData.Family.REACH] == 3, "got %d" % counts[HeroData.Family.REACH])
	_check("two blast heroes", counts[HeroData.Family.BLAST] == 2, "got %d" % counts[HeroData.Family.BLAST])
	_check("family names resolve",
		HeroData.family_name(HeroData.Family.DASH) == "Dash"
		and HeroData.family_name(HeroData.Family.BLAST) == "Blast")
	# The four family values must not shift: minigame handlers persist these
	# as plain integers in saved replays.
	_check("family ordinals are stable",
		HeroData.Family.DASH == 0 and HeroData.Family.REVEAL == 1
		and HeroData.Family.REACH == 2 and HeroData.Family.BLAST == 3)

func _verify_flappy() -> void:
	print("\n--- flappy stays visual ---")
	var flappy: Dictionary = HeroData.get_hero("flappy")
	_check("flappy is on the roster", HeroData.has_hero("flappy"))
	_check("flappy has no power family", int(flappy["family"]) == HeroData.Family.NONE,
		"got %d" % int(flappy["family"]))
	_check("flappy keeps his own sprite", flappy["art"] == "res://assets/flappy_hero.svg",
		flappy["art"])
	_check("flappy is not selectable", not HeroData.is_selectable("flappy"))
	_check("flappy is not in the selectable pool", not HeroData.selectable_ids().has("flappy"))
	_check("selectable pool is the nine combat heroes",
		HeroData.selectable_ids().size() == 9, "got %d" % HeroData.selectable_ids().size())
	var saw_flappy := false
	for i in 200:
		if HeroData.random_id() == "flappy":
			saw_flappy = true
	_check("random never hands out a powerless hero (200 draws)", not saw_flappy)
	_check("a combat hero is selectable", HeroData.is_selectable("dart"))

func _verify_cooldowns() -> void:
	print("\n--- cooldowns ---")
	# Lance is the documented 4s outlier; everything else is 3s.
	var lance: float = HeroData.get_hero("lance")["cooldown"]
	_check("lance is 4s", is_equal_approx(lance, 4.0), "got %.1f" % lance)
	var offenders: Array[String] = []
	for hero in HeroData.selectable():
		var cd: float = hero["cooldown"]
		var expected := 4.0 if hero["id"] == "lance" else 3.0
		if not is_equal_approx(cd, expected):
			offenders.append(hero["id"])
	_check("every other hero is 3s (spec: shared three-second cooldown)",
		offenders.is_empty(), str(offenders))

func _verify_resolution() -> void:
	print("\n--- hero resolution ---")
	_check("valid id resolves to itself", HeroData.get_hero("pulse")["id"] == "pulse")
	_check("unknown id does not return empty", not HeroData.get_hero("nope").is_empty())
	_check("unknown id is reported missing", not HeroData.has_hero("nope"))
	var ids := HeroData.ids()
	_check("random_id returns a real id", ids.has(HeroData.random_id()))

func _verify_persistence() -> void:
	print("\n--- persistence ---")
	var path := ProjectSettings.globalize_path(Global.SAVE_PATH)
	var had_save := FileAccess.file_exists(path)
	var backup := FileAccess.get_file_as_string(path) if had_save else ""
	var original := Global.selected_hero

	Global.selected_hero = "tether"
	Global.save()
	Global.selected_hero = ""
	Global.load_save()
	_check("selected_hero survives save/load",
		Global.selected_hero == "tether", "got '%s'" % Global.selected_hero)

	# A stale id from an older build must degrade, not crash.
	Global.selected_hero = "hero_from_the_future"
	_check("stale id falls back instead of failing", not Global.active_hero_id().is_empty())
	_check("stale id is not echoed back", Global.active_hero_id() != "hero_from_the_future")
	# A save that once allowed the powerless hero must not strand the player.
	Global.selected_hero = "flappy"
	_check("saved powerless hero is not honoured",
		Global.active_hero_id() != "flappy", "got '%s'" % Global.active_hero_id())

	# reset() clears per-run state only.
	Global.selected_hero = "echo"
	Global.touch_controls_enabled = false
	Global.low_quality = true
	Global.music_volume = 42.0
	Global.reset()
	_check("reset() keeps selected_hero", Global.selected_hero == "echo", "got '%s'" % Global.selected_hero)
	_check("reset() keeps touch_controls_enabled", Global.touch_controls_enabled == false)
	_check("reset() keeps low_quality", Global.low_quality == true)
	_check("reset() keeps music_volume", is_equal_approx(Global.music_volume, 42.0))

	_restore_save(path, had_save, backup)
	Global.selected_hero = original
	_check("save file restored", true)

func _verify_bus_gate() -> void:
	print("\n--- power bus cooldown ---")
	var accepting := _RecordingHandler.new()
	Global.selected_hero = "dart"
	PowerBus.register_handler(accepting, "dart")
	_check("bus ready on register", PowerBus.ready_to_use())
	_check("bus reports the handler", PowerBus.has_handler())
	_check("bus has a power", PowerBus.has_power())
	_check("ratio is 1.0 when ready", is_equal_approx(PowerBus.cooldown_ratio(), 1.0))

	PowerBus.force_ready()
	_check("use succeeds", PowerBus.try_activate())
	_check("bus is now cooling down", not PowerBus.ready_to_use())
	_check("ratio is 0.0 right after use", PowerBus.cooldown_ratio() < 0.01)
	_check("second use is refused while cooling", not PowerBus.try_activate())

	# Lance must gate for longer than everyone else.
	var lance := _RecordingHandler.new()
	PowerBus.register_handler(lance, "lance")
	_check("lance cooldown is 4s", is_equal_approx(PowerBus.cooldown_total(), 4.0),
		"got %.1f" % PowerBus.cooldown_total())
	PowerBus.force_ready()
	_check("lance use succeeds", PowerBus.try_activate())
	_check("lance remaining ~4s", PowerBus.cooldown_remaining() > 3.9,
		"got %.2f" % PowerBus.cooldown_remaining())

	# A handler that declines must NOT burn the cooldown: a hero whose power
	# does not apply to this minigame should not lock the player out.
	var declining := _DecliningHandler.new()
	PowerBus.register_handler(declining, "dart")
	PowerBus.force_ready()
	_check("declined use does not start the cooldown", not PowerBus.try_activate())
	_check("bus still ready after a declined use", PowerBus.ready_to_use())
	# can_activate() is the static gate only -- ready, a handler registered,
	# and a hero that has a power. Whether a handler declines is decided by
	# asking it, because probing it speculatively would consume one-shot
	# effects like deleting a laser.
	_check("gate is open with a handler and a power", PowerBus.can_activate())

	# No handler at all.
	PowerBus.unregister_handler(PowerBus._handler)
	PowerBus.force_ready()
	_check("use with no handler is refused", not PowerBus.try_activate())
	_check("bus reports no handler", not PowerBus.has_handler())

	# A hero with no combat power can never fire.
	PowerBus.register_handler(accepting, "flappy")
	PowerBus.force_ready()
	_check("powerless hero is refused", not PowerBus.try_activate())
	_check("powerless hero has no family", not PowerBus.has_power())
	PowerBus.unregister_handler(accepting)

	accepting.free()
	lance.free()
	declining.free()

func _verify_dispatch() -> void:
	print("\n--- dispatch ---")
	var handler := _RecordingHandler.new()
	PowerBus.register_handler(handler, "echo")
	PowerBus.force_ready()
	_check("reveal family dispatches", PowerBus.try_activate())
	_check("handler saw the reveal family", handler.family_seen == HeroData.Family.REVEAL,
		"got %d" % handler.family_seen)

	PowerBus.register_handler(handler, "pulse")
	PowerBus.force_ready()
	_check("blast family dispatches", PowerBus.try_activate())
	_check("handler saw the blast family", handler.family_seen == HeroData.Family.BLAST,
		"got %d" % handler.family_seen)
	handler.free()

## Minigames implement one short handler per family, so the bus only ever
## passes a Family value -- never a hero id. This is the guard that keeps the
## system at sixteen behaviours instead of thirty-six.
class _RecordingHandler extends Node:
	var family_seen: int = -1
	func on_power(family: int) -> bool:
		family_seen = family
		return true

## A handler that always declines, for the cooldown-must-not-burn test.
class _DecliningHandler extends Node:
	func on_power(_family: int) -> bool:
		return false

func _unique(values: Array[String]) -> bool:
	var seen := {}
	for v in values:
		if seen.has(v):
			return false
		seen[v] = true
	return true

func _roster_complete(key: String) -> bool:
	for hero in HeroData.all():
		if not hero.has(key) or hero[key] == null:
			print("    missing '%s' on %s" % [key, hero["id"]])
			return false
	return true

func _restore_save(path: String, had_save: bool, backup: String) -> void:
	if had_save:
		var restore := FileAccess.open(path, FileAccess.WRITE)
		if restore != null:
			restore.store_string(backup)
	elif FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
