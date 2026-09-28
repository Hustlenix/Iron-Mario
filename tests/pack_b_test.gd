extends SceneTree

var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func make_game(entry: Dictionary, difficulty_value: float = 1.0) -> Node:
	var game: Node = load("res://microgames/pack_b.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.start(entry, difficulty_value, 1204)
	return game

func act(game: Node, kind: String, pos: Vector2 = Vector2.ZERO, val: Vector2 = Vector2.ZERO) -> void:
	game.handle_action(kind, pos, val)

func run() -> void:
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://microgames/pack_b.json"))
	for entry in entries:
		for d in [1.0, 6.0]:
			var g: Node = make_game(entry, d)
			play(g)
			checks += 1
			if not g.success_seen: failures.append("WIN " + str(entry.id) + " difficulty " + str(d) + " t=" + str(g.t) + " p=" + str(g.p))
			g.free()
		var failed: Node = make_game(entry)
		# Let the real physics and time limit fail an unattended game.
		for frame in range(1100):
			if failed.finished: break
			failed.advance(0.01)
		checks += 1
		if failed.success_seen or not failed.failure_seen: failures.append("FAIL PATH " + str(entry.id))
		failed.free()
	print("PACK_B_CHECKS=", checks, " FAILURES=", failures.size())
	for failure in failures: print(failure)
	quit(0 if failures.is_empty() else 1)

func play(g: Node) -> void:
	var id: String = g.game
	match id:
		"armor_repair", "conveyor_sort":
			for i in range(3):
				act(g, "press", g.items[i])
				act(g, "drag", g.marks[i])
				act(g, "release", g.marks[i])
		"rocket_rescue":
			for i in range(3):
				act(g, "drag", g.items[i])
				g.advance(0.01)
			act(g, "drag", g.target)
		"rope_bridge", "paint_skate":
			for destination in g.marks:
				var start: Vector2 = g.p
				for j in range(1, 21): act(g, "drag", start.lerp(destination, j / 20.0))
		"river_hop":
			for destination in g.marks: act(g, "direction", Vector2.ZERO, (destination - g.p).normalized())
		"ice_slide": act(g, "swipe", g.p, Vector2(326, 0))
		"comet_curl": act(g, "swipe", g.p, Vector2(267, -228))
		"swing_rescue": act(g, "swipe", g.p, Vector2(265, -90))
		"boulder_push":
			for i in range(5): act(g, "swipe", g.p, Vector2(170, 0))
		"spring_vault": act(g, "press")
		"cloud_ferry": act(g, "drag", g.items[0] + Vector2(0, 35))
		"magnet_haul": act(g, "drag", g.items[0] - Vector2(0, 45))
	for frame in range(1000):
		if g.finished: break
		match id:
			"arc_dash":
				for obstacle in g.items:
					if obstacle.x > g.p.x and obstacle.x < g.p.x + 95 and absf(obstacle.y - g.p.y) < 60: act(g, "press")
			"laser_tunnel":
				for beam in g.items:
					if beam.x > g.p.x - 38 and beam.x < g.p.x + 90:
						act(g, "press" if beam.y == 275 else "release")
			"flappy_bonus":
				var center: float = 240
				for gate in g.items:
					if gate.x > g.p.x - 40:
						center = gate.y
						break
				if g.p.y > center + 12 and g.v.y > 0: act(g, "press")
			"meteor_dodge": act(g, "drag", Vector2(60, 380))
			"parcel_catch":
				var next: Vector2 = Vector2(-1000, -1000)
				for parcel in g.items:
					if parcel.x > 0 and parcel.y > next.y: next = parcel
				if next.x > 0: act(g, "drag", next)
			"rail_grind":
				for hurdle in g.items:
					if hurdle.x > g.p.x and hurdle.x < g.p.x + 115 and g.p.y >= 335: act(g, "press")
			"balloon_lift": act(g, "press" if g.p.y > 135 else "release")
			"magnet_haul":
				if g.launched: act(g, "drag", g.target)
			"cloud_ferry":
				if g.launched: act(g, "drag", g.target)
			"shield_surf":
				for bolt in g.items:
					if bolt.x > 0 and bolt.y > 300: act(g, "swipe", g.p, Vector2(0, -100))
			"glider_gust":
				if g.p.y > 265 and g.v.y > 0: act(g, "swipe", g.p, Vector2(0, -100))
			"orbit_escape":
				if not g.launched and absf(g.angle) < 0.02: act(g, "press")
			"spring_vault":
				if not g.launched and g.charge >= 0.86: act(g, "release")
			"parachute_drop": act(g, "drag", g.target)
			"pinball_rescue":
				if g.p.y > 320 and g.v.y > 0: act(g, "press")
		g.advance(0.01)
