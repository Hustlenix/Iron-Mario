extends SceneTree
## Per-entry lifecycle regression for the fifty deployed baseline games.
## Full winning sequences are covered by pack_a_test and pack_b_test. This
## checks every registered module's controls, freeze/resume, reset, termination,
## instance isolation and cleanup rather than repeating only Armor Repair.
const BASELINE_PACKS := ["res://microgames/pack_a.json", "res://microgames/pack_b.json"]
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok: failures.append(detail)

func run() -> void:
	var registry := GameRegistry.new()
	var ids := {}
	var initial_children: int = root.get_child_count()
	for path in BASELINE_PACKS:
		var entries: Array = JSON.parse_string(FileAccess.get_file_as_string(path))
		for entry in entries:
			var id: String = entry.id
			check(not ids.has(id), id + " has a unique stable ID")
			ids[id] = true
			var spec: Dictionary = registry.get_game(id)
			check(not spec.is_empty() and spec.script == entry.script, id + " registry resolves the preserved implementation")
			check(spec.input in ["TAP", "HOLD", "DRAG", "MOVE", "SWIPE", "DIRECTIONAL"] and spec.duration > 0 and not String(spec.hint).is_empty(), id + " complete launch metadata")
			check(FileAccess.file_exists(spec.script), id + " local script exists")
			var game: MicrogameBase = registry.create(id)
			check(game != null, id + " module instantiates")
			if game == null: continue
			root.add_child(game)
			game.set_process(false)
			var result := {"count": 0, "won": false, "score": 0}
			game.completed.connect(func(won: bool, score: int) -> void: result.count += 1; result.won = won; result.score = score)
			game.start(spec, 1.0, 23)
			check(game.active and not game.finished and game.elapsed == 0, id + " initializes and starts a clean round")
			var initial: Dictionary = snapshot(game)
			game.active = false
			game.advance(0.5)
			check(game.elapsed == 0 and snapshot(game) == initial, id + " pause freezes all simulation state")
			game.active = true
			game.advance(0.01)
			check(game.elapsed > 0 and not game.finished, id + " resume advances time")
			var before_control: Dictionary = snapshot(game)
			primary_control(game, id)
			check(snapshot(game) != before_control or game.finished, id + " primary control changes actual gameplay state")
			game.start(spec, 1.0, 23)
			check(snapshot(game) == initial and not game.finished and game.points == 0, id + " same-instance restart resets seeded round")
			result.count = 0
			for step in range(1600):
				if game.finished: break
				game.advance(0.01)
			check(game.finished and result.count == 1 and not result.won and result.score == 0, id + " unattended gameplay reaches a single valid failure result")
			game.advance(10)
			primary_control(game, id)
			check(result.count == 1, id + " terminal input cannot report a second result")
			var other: MicrogameBase = registry.create(id)
			root.add_child(other)
			other.set_process(false)
			other.start(spec, 1.0, 23)
			check(snapshot(other) == initial and not other.finished, id + " a new instance is isolated from the finished round")
			var weak_game: WeakRef = weakref(game)
			var weak_other: WeakRef = weakref(other)
			game.free()
			other.free()
			check(weak_game.get_ref() == null and weak_other.get_ref() == null and root.get_child_count() == initial_children, id + " exit destroys both instances without stray nodes")
	check(ids.size() == 50, "All fifty deployed baseline entries audited; additional cabinets are separate")
	for entry in registry.games:
		if ids.has(entry.id): continue
		check(FileAccess.file_exists(entry.script) and entry.input in ["TAP", "HOLD", "DRAG", "MOVE", "SWIPE", "DIRECTIONAL", "ARCADE"] and entry.duration > 0, entry.id + " additional game has complete real module metadata")
	await app_lifecycle(registry, registry.ids())
	print("CATALOG_AUDIT_CHECKS=", checks, " BASELINE_GAMES=", ids.size(), " APP_GAMES=", registry.games.size(), " FAILURES=", failures.size())
	for failure in failures: print(failure)
	quit(0 if failures.is_empty() else 1)

func frames(count: int = 3) -> void:
	for i in range(count): await process_frame

func app_lifecycle(registry: GameRegistry, ids: Array) -> void:
	var profile: Node = root.get_node("Profile")
	var saved_data: Dictionary = profile.data.duplicate(true)
	var saved_path: String = profile.profile_path
	profile.data = profile._defaults()
	profile.data.onboarded = true
	profile.data.settings.shake = false
	profile.profile_path = "user://qa_catalog_profile.json"
	profile._refresh_daily()
	root.size = Vector2i(1280, 720)
	var app: Control = load("res://ui/main.tscn").instantiate()
	root.add_child(app)
	await frames()
	var menu_children: int = app.get_child_count()
	for id in ids:
		app.start_run("single", id)
		await frames()
		app.manual_pause = false
		app.transitioning = false
		app.refresh_pause()
		check(is_instance_valid(app.current_game) and app.current_game.spec.id == id and app.router.enabled, id + " app launches the real module with routed input")
		app.toggle_pause()
		var game: MicrogameBase = app.current_game
		var frozen: float = game.elapsed
		await frames(3)
		check(game.elapsed == frozen and not game.active and not app.router.enabled and is_instance_valid(app.modal), id + " app pause modal freezes timer and input")
		app.toggle_pause()
		check(game.active and app.router.enabled, id + " app resume restores simulation and input")
		# A real restart uses a fresh module and invalidates the prior intro timer.
		var previous_game: WeakRef = weakref(game)
		app.start_run("single", id)
		await frames()
		app.manual_pause = false
		app.transitioning = false
		app.refresh_pause()
		check(previous_game.get_ref() == null and app.current_game.spec.id == id and not app.current_game.finished, id + " app restart destroys the old round and launches a clean one")
		var before_plays: int = profile.data.total_plays
		app.current_game.set_process(false)
		app.current_game.start(registry.get_game(id), 1.0, 123)
		var budget: int = int(ceil(app.current_game.duration / 0.02)) + 100
		for step in range(budget):
			if app.current_game.finished: break
			app.current_game.advance(0.02)
		await create_timer(0.72).timeout
		check(app.current_game == null and app.run.finished and app.run.round_index == 1 and app.run.score >= 0, id + " real idle gameplay reaches shared results with valid retained score")
		check(profile.data.total_plays == before_plays + 1, id + " app records exactly one result in profile")
		app.show_page("HOME")
		await frames()
		check(app.current_page == "HOME" and app.current_game == null and not app.router.enabled and app.get_child_count() <= menu_children + 1, id + " result exits to menu with bounded nodes and no live input")
	# Late intro/completion callbacks from any registered module cannot revive.
	await create_timer(0.85).timeout
	check(app.current_page == "HOME" and app.current_game == null, "All-entry late callbacks leave the menu intact")
	app.queue_free()
	await frames()
	profile.data = saved_data
	profile.profile_path = saved_path

func snapshot(game: MicrogameBase) -> Dictionary:
	if game.spec.script.ends_with("pack_a.gd"): return game.s.duplicate(true)
	return {"p": game.p, "v": game.v, "target": game.target, "items": game.items.duplicate(true), "marks": game.marks.duplicate(true), "t": game.t, "progress": game.progress, "held": game.held, "launched": game.launched, "charge": game.charge, "angle": game.angle, "axis": game.axis, "selected": game.selected, "success": game.success_seen, "failure": game.failure_seen, "banked": game.banked}

func primary_control(game: MicrogameBase, id: String) -> void:
	if game.finished: return
	match id:
		"target_lock": tap(game, game.s.target)
		"power_sequence":
			game.advance(float(game.s.goal) * 0.52 + 0.41)
			tap(game, Vector2(180 + int(game.s.seq[0]) * 200, 380))
		"odd_one": tap(game, Vector2(255 + (int(game.s.answer) % 4) * 150, 155 + (int(game.s.answer) / 4) * 100))
		"whack_mole": tap(game, Vector2(290 + (int(game.s.answer) % 3) * 180, 175 + (int(game.s.answer) / 3) * 145))
		"coin_catch": game.handle_action("drag", Vector2(210, 390), Vector2.ZERO)
		"shield_turn", "mirror_match": game.handle_action("direction", Vector2.ZERO, Vector2.RIGHT)
		"trace_wire": game.handle_action("press", game.s.path[0], Vector2.ZERO)
		"color_switch": tap(game, Vector2(180 + int(game.s.answer) * 200, 380))
		"number_order":
			var cell: int = game.s.order.find(1)
			tap(game, Vector2(290 + (cell % 3) * 180, 175 + (cell / 3) * 145))
		"light_out": tap(game, Vector2(380, 135))
		"safe_dial": game.handle_action("swipe", Vector2(480, 240), Vector2(int(game.s.seq[0]) * 100, 0))
		"fuse_cut": tap(game, Vector2(480, 141 + int(game.s.answer) * 72))
		"pixel_repair": tap(game, Vector2(597, 142))
		"maze_runner": game.handle_action("move", Vector2.ZERO, Vector2.UP)
		"word_sort": game.handle_action("swipe", Vector2(480, 240), Vector2.LEFT)
		"echo_taps":
			game.advance(2.39)
			tap(game, Vector2(480, 240))
		"armor_repair", "conveyor_sort": game.handle_action("press", game.items[0], Vector2.ZERO)
		"rocket_rescue", "meteor_dodge", "parcel_catch", "magnet_haul", "cloud_ferry", "parachute_drop": game.handle_action("drag", Vector2(260, 270), Vector2.ZERO)
		"swing_rescue", "ice_slide", "comet_curl": game.handle_action("swipe", Vector2(480, 240), Vector2(270, -100))
		"rope_bridge", "paint_skate": game.handle_action("drag", game.marks[0], Vector2.ZERO)
		"shield_surf":
			game.advance(2.0)
			game.handle_action("swipe", Vector2(480, 370), Vector2(0, -100))
		"boulder_push": game.handle_action("swipe", Vector2(480, 240), Vector2(170, 0))
		"river_hop": game.handle_action("direction", Vector2.ZERO, (game.marks[0] - game.p).normalized())
		"glider_gust": game.handle_action("swipe", Vector2(480, 240), Vector2(0, -100))
		"pinball_rescue":
			while game.p.y < 320 and not game.finished: game.advance(0.01)
			game.handle_action("press", Vector2.ZERO, Vector2.ZERO)
		_: game.handle_action("press", Vector2(480, 240), Vector2.ZERO)

func tap(game: MicrogameBase, point: Vector2) -> void:
	game.handle_action("press", point, Vector2.ZERO)
	game.handle_action("release", point, Vector2.ZERO)
