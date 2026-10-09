extends SceneTree
## This measures native headless simulation CPU cost, not GPU frame time/FPS.
const SAMPLE_FRAMES := 120
var failures: Array[String] = []
var checks := 0
var records: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok: failures.append(detail)

func run() -> void:
	var registry := GameRegistry.new()
	var started: int = Time.get_ticks_usec()
	var count_before: int = root.get_child_count()
	for spec in registry.games:
		var object_before: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
		var static_before: int = int(Performance.get_monitor(Performance.MEMORY_STATIC))
		var creation_started: int = Time.get_ticks_usec()
		var game: MicrogameBase = registry.create(spec.id)
		check(game != null, spec.id + " performance module resolves")
		if game == null: continue
		root.add_child(game)
		game.set_process(false)
		game.start(spec, 1.0, 171)
		var init_usec: int = Time.get_ticks_usec() - creation_started
		for warmup in range(20):
			if game.finished: game.start(spec, 1.0, 171 + warmup)
			game.advance(1.0 / 60.0)
		var samples: Array[int] = []
		var resets := 0
		for frame in range(SAMPLE_FRAMES):
			if game.finished:
				# Exclude reset cost from update timings and avoid measuring only
				# the no-op terminal guard after a short game has already failed.
				game.start(spec, 1.0, frame + 172)
				resets += 1
			var sample_started: int = Time.get_ticks_usec()
			game.advance(1.0 / 60.0)
			samples.append(Time.get_ticks_usec() - sample_started)
		check(game.elapsed > 0 and game.elapsed <= game.duration + 1, spec.id + " update executes valid bounded simulation")
		check(game.points >= 0, spec.id + " score remains valid during sample")
		samples.sort()
		var total := 0
		for value in samples: total += value
		var weak: WeakRef = weakref(game)
		game.free()
		check(weak.get_ref() == null and root.get_child_count() == count_before, spec.id + " cleanup returns scene-node count to baseline")
		records.append({"id": spec.id, "initialization_usec": init_usec,
			"sample_count": samples.size(), "mean_update_usec": float(total) / samples.size(),
			"median_update_usec": samples[samples.size() / 2],
			"p95_update_usec": samples[int(ceil(samples.size() * 0.95)) - 1],
			"max_update_usec": samples.back(), "terminal_resets": resets,
			"scene_children_delta_after_free": root.get_child_count() - count_before,
			"object_count_delta": int(Performance.get_monitor(Performance.OBJECT_COUNT)) - object_before,
			"tracked_static_bytes_delta": int(Performance.get_monitor(Performance.MEMORY_STATIC)) - static_before})
	# Repeat registry switching to exercise resource reuse after scripts are cached.
	for cycle in range(3):
		for spec in registry.games:
			var game: MicrogameBase = registry.create(spec.id)
			root.add_child(game)
			game.set_process(false)
			game.start(spec, 1.0, 33 + cycle)
			game.advance(0.016)
			game.cancel_input()
			game.free()
		check(root.get_child_count() == count_before, "Registry switching cycle %d leaves bounded scene nodes" % cycle)
	var directory: String = "res://build/catalog-qa"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var report := {"measurement": "native headless simulation CPU timings; GPU/WebGL/browser FPS not measured",
		"engine": Engine.get_version_info().string, "module_count": records.size(),
		"sample_frames_per_module": SAMPLE_FRAMES, "simulation_delta_seconds": 1.0 / 60.0,
		"wall_seconds": (Time.get_ticks_usec() - started) / 1000000.0,
		"memory_note": "Object/static deltas include legitimate cached script resources; scene-node cleanup is asserted. This is not a browser heap or physical-phone memory trace.",
		"records": records, "checks": checks, "failures": failures}
	var file: FileAccess = FileAccess.open(directory + "/performance_report.json", FileAccess.WRITE)
	check(file != null, "Performance report opens for writing")
	if file:
		report.checks = checks
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	var slowest: Dictionary = {}
	for record in records:
		if slowest.is_empty() or record.p95_update_usec > slowest.p95_update_usec: slowest = record
	print("PERFORMANCE_CHECKS=", checks, " MODULES=", records.size(), " FAILURES=", failures.size())
	if not slowest.is_empty(): print("SIMULATION_CPU_SLOWEST_P95=", slowest.id, " ", slowest.p95_update_usec, " usec; this is not rendered FPS")
	for failure in failures: print(failure)
	quit(0 if failures.is_empty() else 1)
