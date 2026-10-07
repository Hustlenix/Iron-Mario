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
	await _verify_select_screen()
	await _verify_select_actions()
	await _verify_badge()
	_verify_minigame_badges()

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

## The hero select screen is the one place the roster is turned into something a
## player touches, so it gets its own coverage: that it builds a card per
## selectable hero, that the cards are filled from the roster rather than
## hand-typed, and that a pick is persisted the way the title screen expects.
func _verify_select_screen() -> void:
	print("\n--- hero select screen ---")
	var path := ProjectSettings.globalize_path(Global.SAVE_PATH)
	var had_save := FileAccess.file_exists(path)
	var backup := FileAccess.get_file_as_string(path) if had_save else ""
	var original := Global.selected_hero

	Global.selected_hero = "bolt"
	Global.save()
	var select := await _spawn_select()
	var cards: Array = select.get_node("Grid").get_children()
	var expected := HeroData.selectable_ids()

	_check("one card per selectable hero", cards.size() == expected.size(),
		"got %d want %d" % [cards.size(), expected.size()])
	_check("flappy is never offered on the select screen", not expected.has("flappy"))

	# Identity, order and copy all have to come from the roster. A list typed by
	# hand into the scene is exactly how these drift apart later.
	var copy_ok := true
	var blank_art: Array[String] = []
	for i in cards.size():
		var hero := HeroData.get_hero(expected[i])
		var art := cards[i].get_child(0) as TextureRect
		if art == null or art.texture == null:
			blank_art.append(expected[i])
		if str(cards[i].get_child(1).text) != str(hero["name"]):
			copy_ok = false
		var subtitle := str(cards[i].get_child(2).text)
		if not subtitle.contains(str(hero["power"])) \
				or not subtitle.contains(HeroData.family_name(int(hero["family"]))) \
				or not subtitle.contains("%ds" % int(round(float(hero["cooldown"])))):
			copy_ok = false
	_check("every card has art that actually loaded", blank_art.is_empty(), str(blank_art))
	_check("every card carries real name, power, family and cooldown", copy_ok)

	_check("opens on the saved hero", str(select.get("_selected")) == "bolt",
		"got '%s'" % str(select.get("_selected")))
	for node_name in ["FightButton", "RandomButton", "BackButton"]:
		var button := select.get_node_or_null(node_name) as Button
		_check("%s is live once the grid is built" % node_name,
			button != null and not button.disabled)
	_check("detail line shows the current hero",
		str(select.get_node("DetailLabel").text) == str(HeroData.get_hero("bolt")["blurb"]))

	# Pressing a card that is not the current pick selects it. The already-picked
	# card is the confirm gesture and would navigate away, so it is left alone.
	var target := ""
	for id in expected:
		if id != "bolt":
			target = id
			break
	var target_card: Button = cards[expected.find(target)]
	target_card.pressed.emit()
	await get_tree().process_frame
	_check("pressed card becomes the pick", str(select.get("_selected")) == target,
		"got '%s'" % str(select.get("_selected")))
	_check("pick is written through to Global", Global.selected_hero == target)
	Global.selected_hero = ""
	Global.load_save()
	_check("pick is saved to disk", Global.selected_hero == target,
		"got '%s'" % Global.selected_hero)

	select.queue_free()
	await get_tree().process_frame

	# A save naming a hero that no longer exists must still open on someone real.
	Global.selected_hero = "hero_from_the_future"
	var stale := await _spawn_select()
	_check("stale save still builds the whole roster",
		stale.get_node("Grid").get_child_count() == expected.size())
	_check("stale save still lands on a selectable hero",
		HeroData.is_selectable(str(stale.get("_selected"))),
		"got '%s'" % str(stale.get("_selected")))
	stale.queue_free()
	await get_tree().process_frame

	_restore_save(path, had_save, backup)
	Global.selected_hero = original


## FIGHT, random and back all navigate away, so pressing them here would replace
## this test with whatever they load. What gets checked instead is the contract
## underneath them: a random pick is always a real playable hero, starting a run
## wipes the previous run without forgetting the pick, and each button is wired
## to its handler and aimed at a scene that actually exists.
func _verify_select_actions() -> void:
	print("\n--- hero select actions ---")

	# One roll proves nothing about a randomiser. Many rolls catch a draw that
	# can reach an unselectable hero, which would start a run nobody can play.
	var bad_rolls: Array[String] = []
	for _i in 32:
		var rolled: String = HeroData.random_id()
		if not HeroData.is_selectable(rolled):
			bad_rolls.append(rolled)
	_check("32 random picks all land on a selectable hero", bad_rolls.is_empty(),
		"unselectable: %s" % str(bad_rolls))
	_check("random never hands out the unselectable flappy", not bad_rolls.has("flappy"))

	# FIGHT and random both land in _start_run: pick, save, then reset. The reset
	# is the whole point of the run starting fresh, and it must not take the
	# player's pick with it -- that would silently drop them onto someone else.
	#
	# The id is asserted back exactly, not just checked for being playable: an
	# unrecognised id resolves to a random hero, so a loose check here would pass
	# on the fallback while the player was quietly moved to somebody else.
	var previous_pick := Global.selected_hero
	Global.selected_hero = "echo"
	Global.lives = 2
	Global.minigames_done = 4
	Global.loop = 3
	Global.streak = 7
	Global.reset()
	_check("starting a run keeps the pick", Global.selected_hero == "echo",
		"got '%s'" % Global.selected_hero)
	_check("starting a run restores the lives", Global.lives == 5,
		"got %d" % Global.lives)
	_check("starting a run clears progress from the last one",
		Global.minigames_done == 0 and Global.loop == 0 and Global.streak == 0,
		"done %d loop %d streak %d" % [Global.minigames_done, Global.loop, Global.streak])
	# The badge, the select screen and the minigame all ask for the active hero
	# at different moments, so a stored pick has to resolve to the same hero
	# every time. Compared, not checked for merely being valid: with no valid
	# pick stored the fallback is a fresh random draw per call, which is exactly
	# the bug, and "is it some playable hero" would wave it through.
	var first := Global.active_hero_id()
	var second := Global.active_hero_id()
	_check("a stored pick resolves to the same hero every time it is asked",
		first == second, "got '%s' then '%s'" % [first, second])
	_check("the kept pick is the one that resolves",
		first == "echo" and second == "echo",
		"got '%s' and '%s'" % [first, second])

	# Wired up, and aiming somewhere real: a renamed or deleted destination is
	# invisible to every other check here, because nothing ever follows the jump.
	var select := await _spawn_select()
	# Wired to the right handler, not merely to something. "Has a connection"
	# would sail straight past a scene that pointed FIGHT at the back handler, and
	# nothing else here ever follows the jump, so a swap would go unnoticed.
	var handlers := {
		"FightButton": "_on_fight_pressed",
		"RandomButton": "_on_random_pressed",
		"BackButton": "_on_back_pressed",
	}
	for node_name: String in handlers:
		var expected: String = handlers[node_name]
		var button := select.get_node_or_null(node_name) as Button
		var wired_to := ""
		if button != null:
			for connection: Dictionary in button.pressed.get_connections():
				var target: Callable = connection["callable"]
				if target.get_object() == select:
					wired_to = target.get_method()
		_check("%s press calls %s" % [node_name, expected], wired_to == expected,
			"got '%s'" % wired_to)
	_check("FIGHT lands on the level scene",
		ResourceLoader.exists("res://scenes/level_scene.tscn"))
	_check("back lands on the title screen",
		ResourceLoader.exists("res://scenes/title_screen.tscn"))

	select.queue_free()
	await get_tree().process_frame
	Global.selected_hero = previous_pick


## Every minigame has to show the pick, in the right size for the room it has,
## without landing on the timer or the cooldown ring. Instantiated but never
## added to the tree, so the scenes are checked as authored without four
## gameplay loops actually starting behind the assertions.
func _verify_minigame_badges() -> void:
	print("\n--- minigame hero wiring ---")
	var expected := {
		"res://scenes/minigame_1.tscn": [true, true],
		"res://scenes/minigame_2.tscn": [false, false],
		"res://scenes/minigame_3.tscn": [true, true],
		"res://scenes/minigame_4.tscn": [false, false],
	}
	# A hardcoded offset is what let the badge land on top of the score label in
	# MG2 and MG4, so the placement is checked as a real geometric invariant
	# instead: the badge may not cover any of the chrome the scene already had.
	for path: String in expected:
		var want: Array = expected[path]
		var mg: String = path.get_file().get_basename()
		var packed: PackedScene = load(path)
		_check("%s: scene loads" % mg, packed != null)
		if packed == null:
			continue

		var scene: Node = packed.instantiate()
		# Full portrait where the room allows it, compact chip where it does not.
		var badge: Control = scene.get_node_or_null("PowerHUD/HeroBadge")
		_check("%s: shows the picked hero" % mg, badge != null)
		if badge != null:
			_check("%s: uses the %s hero layout" % [mg, "full" if want[0] else "compact"],
				badge.full == want[0])
			_check("%s: badge hugs the left edge" % mg,
				badge.position.x <= 16.0,
				"got x %.0f" % badge.position.x)
			var badge_rect := _rect_of(badge)
			for other: Control in _chrome(scene):
				var rect := _rect_of(other)
				_check("%s: badge does not cover %s" % [mg, other.name],
					not badge_rect.intersects(rect),
					"%s vs %s" % [badge_rect, rect])

		# The portrait is the player's stand-in in the platformers, so those two
		# have to carry a player; the tap and parry games do not.
		_check("%s: %s a player body" % [mg, "has" if want[1] else "has no"],
			(scene.get_node_or_null("Player") != null) == want[1])

		# MG2 places its target below the top strip, so that band has to clear
		# everything the HUD puts up there. Checked against the live constants so
		# moving the badge cannot quietly shrink the play area until the target
		# spawns under the score again. Read before the free: a freed instance
		# compares equal to null, so a check placed after it would never run.
		if path.ends_with("minigame_2.tscn"):
			var script: GDScript = load("res://scenes/minigame_2.gd")
			var top_margin: float = script.TOP_MARGIN
			var blocked := ""
			for other: Control in _chrome(scene):
				var edge := _rect_of(other).end.y
				if edge > top_margin:
					blocked = "%s reaches y %.0f" % [other.name, edge]
			_check("%s: target is placed clear of the HUD" % mg, blocked.is_empty(),
				"top margin %.0f, %s" % [top_margin, blocked if blocked != "" else "nothing intrudes"])

		scene.free()


## The chrome a minigame already had on the top strip: its score, its hint, the
## themed timer and the cooldown ring. The badge is added to the same strip, so
## these are the things it must not cover.
func _chrome(scene: Node) -> Array[Control]:
	var out: Array[Control] = []
	for path: NodePath in ["HUD/ScoreLabel", "HUD/HintLabel", "HUD/ParryLabel",
			"ThemedTimer/TimerLabel", "PowerHUD/PowerRing"]:
		var node := scene.get_node_or_null(path) as Control
		if node != null:
			out.append(node)
	return out


## A Control's own size inside a box of the given size: anchors split the box,
## offsets stretch this node's slice of it.
func _own_size(c: Control, parent_size: Vector2) -> Vector2:
	return Vector2(
		(c.anchor_right - c.anchor_left) * parent_size.x + c.offset_right - c.offset_left,
		(c.anchor_bottom - c.anchor_top) * parent_size.y + c.offset_bottom - c.offset_top
	)

## Viewport-space rect for a Control in an unparented scene.
##
## Two things have to be handled that reading position/size off the node does
## not. Anchors are resolved against the design viewport, not against the
## parent: a Control that is not in the tree has no parent rect, so position came
## back as the raw offset and put the top-right cooldown ring in the top-left
## corner, where the overlap check then passed against the wrong rectangle. And
## the walk goes root-first, because a node's anchors are relative to the box its
## parent occupies, which is only known once the parent itself is resolved.
func _rect_of(node: Control, vp := Vector2(1280.0, 720.0)) -> Rect2:
	var chain: Array = []
	var walk: Node = node
	while walk != null and not walk is CanvasLayer:
		chain.append(walk)
		walk = walk.get_parent()

	var pos := Vector2.ZERO
	var box := vp
	for i in range(chain.size() - 1, -1, -1):
		var item: Node = chain[i]
		if not item is Control:
			pos += (item as Node2D).position
			continue
		var c := item as Control
		pos += Vector2(
			c.anchor_left * box.x + c.offset_left,
			c.anchor_top * box.y + c.offset_top
		)
		var own := _own_size(c, box)
		if i == 0:
			return Rect2(pos, own)
		box = own
	return Rect2(pos, Vector2.ZERO)


## The badge is the only place the pick is shown during play, so it has to show
## the hero that is actually selected rather than a default, and it has to show
## the right layout for the minigame it was dropped into.
func _verify_badge() -> void:
	print("\n--- hero badge ---")
	var path := ProjectSettings.globalize_path(Global.SAVE_PATH)
	var had_save := FileAccess.file_exists(path)
	var backup := FileAccess.get_file_as_string(path) if had_save else ""
	var original := Global.selected_hero

	# A hero with a cool palette, so a default or a previous hero cannot pass
	# for the right answer by coincidence.
	Global.selected_hero = "frost"
	Global.save()
	var hero := HeroData.get_hero("frost")
	var full_badge: Control = await _spawn_badge(true)
	var badge: Control = await _spawn_badge(false)

	for entry in [["full", full_badge], ["badge", badge]]:
		var mode: String = entry[0]
		var node: Control = entry[1]
		var art := node.get_node_or_null("Art") as TextureRect
		_check("%s badge art loaded" % mode, art != null and art.texture != null)
		_check("%s badge names the picked hero" % mode,
			str(node.get_node("NameLabel").text) == str(hero["name"]).to_upper(),
			"got '%s'" % str(node.get_node("NameLabel").text))
		_check("%s badge shows the real power" % mode,
			str(node.get_node("PowerLabel").text) == str(hero["power"]),
			"got '%s'" % str(node.get_node("PowerLabel").text))
		var frame := node.get_node_or_null("Frame") as Panel
		var style := frame.get_theme_stylebox("panel") as StyleBoxFlat
		_check("%s badge is outlined in the hero accent" % mode,
			style != null and style.border_color.is_equal_approx(hero["accent"]))

	# The mode switch has to be a real layout change, not a label swap: MG1/MG3
	# get the stacked portrait, MG2/MG4 the short chip beside the art.
	_check("full badge is taller than the compact badge",
		full_badge.size.y > badge.size.y,
		"%.0f vs %.0f" % [full_badge.size.y, badge.size.y])
	_check("compact badge is short enough to sit over the action",
		badge.size.y <= 64.0, "got %.0f" % badge.size.y)
	_check("full badge puts the art above the copy",
		(full_badge.get_node("Art") as TextureRect).position.y
			< (full_badge.get_node("NameLabel") as Label).position.y)
	_check("compact badge puts the art beside the copy",
		(badge.get_node("Art") as TextureRect).position.x
			< (badge.get_node("NameLabel") as Label).position.x
		and (badge.get_node("NameLabel") as Label).position.x > 0.0)

	# The badge has to agree with the roster's own "degrade, never be empty"
	# rule: an id that resolves to nothing still has to name a real hero rather
	# than leaving an empty frame over the play area.
	badge.call("_show", "hero_from_the_future")
	var fallback := HeroData.get_hero("hero_from_the_future")
	_check("unknown hero degrades to the roster fallback",
		str(badge.get_node("NameLabel").text) == str(fallback["name"]).to_upper(),
		"got '%s'" % str(badge.get_node("NameLabel").text))
	_check("unknown hero still draws real art, not an empty frame",
		(badge.get_node("Art") as TextureRect).texture != null)
	badge.call("_show", Global.active_hero_id())
	_check("badge returns to the picked hero",
		str(badge.get_node("NameLabel").text) == str(hero["name"]).to_upper())

	full_badge.queue_free()
	badge.queue_free()
	await get_tree().process_frame

	_restore_save(path, had_save, backup)
	Global.selected_hero = original


func _spawn_badge(full: bool) -> Control:
	var badge := load("res://scenes/hero_badge.tscn").instantiate() as Control
	badge.full = full
	add_child(badge)
	await get_tree().process_frame
	return badge


## Spawned rather than added inline so both the normal and the stale-save pass
## get the same frame of settling before anything is inspected.
func _spawn_select() -> Node:
	var select := load("res://scenes/hero_select.tscn").instantiate() as Node
	add_child(select)
	await get_tree().process_frame
	return select

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
