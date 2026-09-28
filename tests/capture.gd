extends SceneTree

var app: Control
var output: String = "res://build/qa"

func _initialize() -> void:
	call_deferred("capture_all")

func settle() -> void:
	for frame in range(5): await process_frame
	await RenderingServer.frame_post_draw

func save_view(name: String) -> void:
	await settle()
	var result: Error = root.get_texture().get_image().save_png(output + "/" + name + ".png")
	print("CAPTURE ", name, " ", result)

func capture_all() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var profile: Node = root.get_node("Profile")
	profile.profile_path = output + "/capture_profile.json"
	profile.data = profile._defaults()
	profile.data.onboarded = true
	profile.data.settings.shake = false
	profile._refresh_daily()
	app = load("res://ui/main.tscn").instantiate()
	root.add_child(app)
	for dimensions in [Vector2i(1280,720), Vector2i(1024,768), Vector2i(844,390), Vector2i(390,844)]:
		root.size = dimensions
		root.content_scale_size = Vector2i(960,540)
		var suffix: String = str(dimensions.x) + "x" + str(dimensions.y)
		for page in ["HOME", "GAMES", "HEROES"]:
			app.show_page(page)
			await save_view(page.to_lower() + "_" + suffix)
		app.start_run("single", "rocket_rescue")
		await create_timer(0.9).timeout
		app.manual_pause = false
		app.refresh_pause()
		if is_instance_valid(app.current_game): app.current_game.active = false
		await save_view("gameplay_" + suffix)
		app.show_page("HOME")
	root.size = Vector2i(1280,720)
	for id in ["armor_repair", "flappy_bonus", "comet_curl", "spring_vault", "orbit_escape", "shield_surf"]:
		app.start_run("single", id)
		await create_timer(0.85).timeout
		app.manual_pause = false
		app.close_modal()
		app.refresh_pause()
		if is_instance_valid(app.current_game): app.current_game.active = false
		await save_view("game_" + id)
	print("CAPTURE_DONE ", ProjectSettings.globalize_path(output))
	quit()
