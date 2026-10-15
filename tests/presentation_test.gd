extends SceneTree
## Shared integration evidence only. Appearance needs per-game image review.
const Bridge = preload("res://ui/game_presentation.gd")
var checks: int = 0
var failures: Array[String] = []
var pending: Array[String] = []
var tested: Array[String] = []
var render_compare: bool = false
var viewport: SubViewport

class MinimalPresentation:
	extends RefCounted
	func draw_background(_canvas: Node2D, _context: Dictionary) -> void: pass

class ProbeCanvas:
	extends Node2D
	var presenter: RefCounted
	var context: Dictionary
	var calls: int = 0
	var context_unchanged: bool = true
	var global_rng_unchanged: bool = true
	func _draw() -> void:
		var before: Dictionary = context.duplicate(true)
		seed(674912)
		var expected: int = randi()
		seed(674912)
		presenter.call("draw_background", self, context)
		global_rng_unchanged = global_rng_unchanged and randi() == expected
		context_unchanged = context_unchanged and context == before
		calls += 1

func _initialize() -> void: call_deferred("run")

func check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok: failures.append(detail); print("FAIL presentation: ", detail)

func frames(count: int = 3) -> void:
	for i in range(count): await process_frame

func snapshot(game: MicrogameBase) -> Dictionary:
	var state: Dictionary = {}
	for property in game.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE == 0: continue
		var value: Variant = game.get(property.name)
		if value is Object: continue
		state[property.name] = value.duplicate(true) if value is Array or value is Dictionary else value
	state["rng_state"] = game.rng.state
	state["transform"] = game.transform
	state["children"] = game.get_child_count()
	return state

func image_hash() -> String:
	await RenderingServer.frame_post_draw
	var image: Image = viewport.get_texture().get_image()
	if image == null or image.is_empty(): return ""
	return image.get_data().hex_encode().sha256_text()

func run() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var require_all: bool = "--require-all" in arguments
	render_compare = "--render-compare" in arguments
	check(not render_compare or DisplayServer.get_name() != "headless", "GPU comparison requires a visible rendering backend")
	for invalid in ["", "../arc_dash", "arc_dash.gd", "res://ui/game_presentations/arc_dash", "ARC_DASH", "arc-dash", "arc/dash", "arc\\dash", "arc dash", "arc_dash%00", "é"]:
		check(Bridge.load_for_id(invalid) == null, "Loader rejects arbitrary/non-identifier path: " + invalid)
	check(Bridge.load_for_id("qa_nonexistent_presentation_674912") == null, "Absent safe ID returns null for legacy background fallback")
	check(Bridge.describe(null).is_empty(), "Null presentation metadata is optional")
	var minimal := MinimalPresentation.new()
	check(Bridge.describe(minimal).is_empty(), "A valid presenter can omit all metadata constants")
	var metadata: Dictionary = {"id":"arc_dash", "category":"Movement", "nested":{"kept":true}}
	var metadata_before: Dictionary = metadata.duplicate(true)
	var context: Dictionary = Bridge.context_for(metadata, 2.75, "classic", true)
	check(metadata == metadata_before and context.id == "arc_dash" and context.category == "Movement", "Context construction preserves game metadata and identity")
	check(context.elapsed == 2.75 and context.reduced_motion and context.cosmetic == "classic" and context.board_rect == Rect2(0,0,960,480), "Context uses actual elapsed, motion setting, cosmetic and board coordinates")
	viewport = SubViewport.new()
	viewport.size = Vector2i(960,480)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var registry := GameRegistry.new()
	check(registry.games.size() == 105, "The preserved catalog contains exactly 105 existing games")
	for spec in registry.games:
		var id: String = spec.id
		var source_exists: bool = FileAccess.file_exists(Bridge.DIRECTORY + id + ".gd")
		if not source_exists:
			pending.append(id)
			if require_all: check(false, id + " required presentation source missing")
			continue
		var presenter: RefCounted = Bridge.load_for_id(id)
		check(presenter != null, id + " owns an instantiable RefCounted presenter")
		if presenter == null: continue
		tested.append(id)
		var description: Dictionary = Bridge.describe(presenter)
		check(not description.has("title") or description.title is String, id + " optional TITLE has the consumer's string type")
		check(not description.has("setting") or description.setting is String, id + " optional SETTING has the consumer's string type")
		check(not description.has("accent") or description.accent is Color, id + " optional ACCENT has the consumer's Color type")
		var probe := ProbeCanvas.new()
		probe.presenter = presenter
		probe.context = Bridge.context_for(spec, 0.0, "classic", false)
		viewport.add_child(probe)
		probe.queue_redraw(); await frames()
		check(probe.calls > 0, id + " actual draw callback executes")
		var paused_context: Dictionary = probe.context.duplicate(true)
		probe.queue_redraw(); await frames()
		check(probe.context == paused_context, id + " repeat paused elapsed context remains unchanged")
		var first_hash: String = ""
		if render_compare: first_hash = await image_hash()
		probe.queue_redraw(); await frames()
		if render_compare: check(not first_hash.is_empty() and first_hash == await image_hash(), id + " paused rendered pixels remain identical")
		probe.context = Bridge.context_for(spec, 0.0, "classic", true)
		probe.queue_redraw(); await frames()
		if render_compare: first_hash = await image_hash()
		probe.context = Bridge.context_for(spec, 4.0, "classic", true)
		probe.queue_redraw(); await frames()
		if render_compare: check(not first_hash.is_empty() and first_hash == await image_hash(), id + " reduced motion freezes elapsed-driven decorative pixels")
		check(probe.context_unchanged and probe.global_rng_unchanged, id + " normal, paused and reduced-motion drawing preserves context and global RNG")
		check(probe.transform == Transform2D.IDENTITY and probe.get_child_count() == 0, id + " drawing preserves canvas transform and creates no nodes")
		probe.free()
		var game: MicrogameBase = registry.create(id)
		check(game != null, id + " existing gameplay module still instantiates")
		if game == null: continue
		viewport.add_child(game); game.set_process(false)
		game.start(spec, 1.0, 28)
		check(game.presentation != null and game.presentation.get_script().resource_path == Bridge.DIRECTORY + id + ".gd", id + " existing game start loads its individual presenter")
		var before: Dictionary = snapshot(game)
		game.queue_redraw(); await frames()
		check(snapshot(game) == before, id + " actual integrated paint preserves gameplay state and seeded RNG")
		game.active = false; before = snapshot(game)
		game.advance(0.5); game.queue_redraw(); await frames()
		check(snapshot(game) == before and game.elapsed == 0.0, id + " paused game redraw freezes simulation and presentation elapsed")
		game.reduced_motion = true; before = snapshot(game)
		game.queue_redraw(); await frames()
		check(snapshot(game) == before, id + " reduced-motion integrated paint preserves state and seeded RNG")
		var reference: WeakRef = weakref(game)
		game.free()
		check(reference.get_ref() == null and viewport.get_child_count() == 0, id + " presenter lifecycle leaves no gameplay/canvas nodes")
	viewport.free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/visual-after"))
	var file := FileAccess.open("res://build/visual-after/presentation_test_report.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"checks":checks,"failures":failures,"tested":tested,"pending":pending,"require_all":require_all,"gpu_pixel_comparison":render_compare,"scope":"Loader, actual engine drawing, context/state/RNG isolation and pause. Optional GPU equality covers frozen decoration; visual acceptance and physical-device tests remain separate."}, "\t")); file.close()
	print("PRESENTATION_CHECKS=",checks," TESTED=",tested.size()," PENDING=",pending.size()," FAILURES=",failures.size())
	quit(0 if failures.is_empty() else 1)
