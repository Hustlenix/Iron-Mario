extends SceneTree

var app: Control
var profile: Node
var failures: Array[String] = []
var checks: int = 0
var saved_data: Dictionary
var saved_path: String

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition: failures.append(message)

func frames(count: int = 3) -> void:
	for i in range(count): await process_frame

func run_tests() -> void:
	profile = root.get_node("Profile")
	saved_data = profile.data.duplicate(true)
	saved_path = profile.profile_path
	profile.profile_path = "user://qa_app_profile.json"
	profile.data = profile._defaults()
	profile.data.onboarded = true
	profile.data.settings.shake = false
	profile._refresh_daily()
	root.size = Vector2i(1280, 720)
	app = load("res://ui/main.tscn").instantiate()
	root.add_child(app)
	await frames()
	check(app.registry.games.size() >= 50, "At least 50 games registered")
	for page_name in ["HOME", "GAMES", "HEROES", "MISSIONS", "SHOP", "PROFILE", "SETTINGS"]:
		app.show_page(page_name)
		await frames()
		check(app.current_page == page_name, "Navigation " + page_name)
		check(app.current_game == null and not app.router.enabled, "No live gameplay on " + page_name)
		check(app.page.get_parent() == app, "Page attached " + page_name)
		check_horizontal_bounds(app.page, page_name)
	app.show_page("GAMES")
	app.search_text = "Armor Repair"
	app.show_page("GAMES")
	await frames()
	check(count_buttons(app.page, "PLAY") == 1, "Search returns exact game")
	profile.toggle_favorite("armor_repair")
	app.search_text = ""
	app.category = "FAVORITES"
	app.show_page("GAMES")
	await frames()
	check(count_buttons(app.page, "PLAY") == 1, "Favorites filters library")
	app.category = "ALL"
	for mode in ["single", "quick"]:
		var before: int = int(profile.data.total_plays)
		app.start_run(mode, "armor_repair")
		await ready_to_play()
		check(app.run.current_id == "armor_repair", mode + " has director current ID")
		check(app.router.enabled and app.current_game.active, mode + " starts input")
		complete_repair()
		await create_timer(0.8).timeout
		check(app.current_game == null, mode + " reaches result page")
		check(app.run.round_index == 1 and app.run.score > 0, mode + " result records round and score")
		check(int(profile.data.total_plays) == before + 1, mode + " profile records one play")
		check(app.run_xp == 30 and app.run_coins == 12, mode + " awards win rewards")
		var stored: Dictionary = profile._read(profile.profile_path)
		check(int(stored.total_plays) == int(profile.data.total_plays), mode + " persists play count")
	# Use one real microgame as a deterministic fixture for both marathon modes.
	for mode in ["tournament", "daily"]:
		app.start_run(mode)
		await frames()
		app.run.begin(mode, ["armor_repair"], "2026-09-27")
		app.current_id = app.run.next_id()
		app.launch_game()
		await ready_to_play()
		var expected: int = 6 if mode == "tournament" else 10
		for round_number in range(expected):
			if mode == "daily" or round_number == 0:
				complete_repair()
			else:
				app.current_game.advance(app.current_game.duration + 0.1)
			await create_timer(0.75).timeout
			if round_number < expected - 1: await ready_to_play()
		check(app.current_game == null and app.run.finished, mode + " concludes at terminal condition")
		check(app.run.round_index == expected, mode + " expected number of rounds")
		check(app.run.score > 0, mode + " preserves score")
		check(int(profile.data.tournament_best if mode == "tournament" else profile.data.daily.best) > 0, mode + " saves best score")
	app.start_run("single", "armor_repair")
	await ready_to_play()
	app.toggle_pause()
	var elapsed_before: float = app.current_game.elapsed
	await frames(8)
	check(not app.current_game.active and not app.router.enabled, "Pause disables simulation and input")
	check(app.current_game.elapsed == elapsed_before, "Paused timer is frozen")
	check(is_instance_valid(app.modal), "Pause modal visible")
	app.toggle_pause()
	check(app.current_game.active and app.router.enabled, "Resume restores play")
	app.size = Vector2(390, 844)
	app.layout_game()
	check(app.orientation_pause and not app.current_game.active, "Portrait rotates and pauses")
	check(is_instance_valid(app.rotate_cover), "Portrait guard visible")
	app.size = Vector2(1280, 720)
	app.layout_game()
	check(not app.orientation_pause and app.current_game.active, "Landscape resumes simulation")
	for dimensions in [Vector2(1280,720), Vector2(1024,768), Vector2(1558,720)]:
		app.size = dimensions
		await frames()
		app.layout_game()
		check(app.router.board.size.x > 0 and app.router.board.size.y > 0, "Positive arena at " + str(dimensions))
		check(absf(app.router.board.size.x / app.router.board.size.y - 2.0) < 0.01, "Arena aspect at " + str(dimensions))
	# Interrupt intro and result timers repeatedly; stale callbacks must be ignored.
	for i in range(12):
		app.start_run("single", "armor_repair")
		await frames()
		app.show_page("HOME")
	await create_timer(0.9).timeout
	check(app.current_page == "HOME" and app.current_game == null and not app.router.enabled, "Interrupted launches do not resurrect gameplay")
	check(app.get_child_count() < 9, "Repeated launches leave bounded scene children")
	profile.data = saved_data
	profile.profile_path = saved_path
	app.queue_free()
	await frames()
	print("APP_CHECKS=", checks, " FAILURES=", failures.size())
	for failure in failures: print(failure)
	quit(0 if failures.is_empty() else 1)

func ready_to_play() -> void:
	await create_timer(0.85).timeout
	app.manual_pause = false
	app.refresh_pause()

func complete_repair() -> void:
	var game: Node = app.current_game
	for i in range(3):
		app.route_action("press", game.items[i], Vector2.ZERO)
		app.route_action("drag", game.marks[i], Vector2.ZERO)
		app.route_action("release", game.marks[i], Vector2.ZERO)

func count_buttons(node: Node, wanted: String) -> int:
	var result: int = 1 if node is Button and node.text == wanted else 0
	for child in node.get_children(): result += count_buttons(child, wanted)
	return result

func check_horizontal_bounds(node: Node, page_name: String) -> void:
	if node is Control and node.visible and (node is Button or node is Label or node is LineEdit or node is OptionButton):
		var bounds: Rect2 = node.get_global_rect()
		# Vertical scrolling is intentional; horizontal overflow is never intentional.
		if bounds.size.x > 0:
			check(bounds.position.x >= -1 and bounds.end.x <= app.size.x + 1, page_name + " horizontal clipping " + node.name + " " + str(bounds))
	for child in node.get_children(): check_horizontal_bounds(child, page_name)
