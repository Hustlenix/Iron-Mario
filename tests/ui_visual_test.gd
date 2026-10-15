extends SceneTree
## Real application navigation and input. Headless layout/state evidence, not phone certification.
var app: Control
var profile: Node
var checks: int = 0
var failures: Array[String] = []
var saved_data: Dictionary
var saved_path: String
var layouts: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run_tests")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		print("FAIL hero UI: ", message)

func frames(count: int = 6) -> void:
	for i in range(count): await process_frame

func selector() -> Control:
	for child in app.page.get_children():
		if child.get_script() != null and child.get_script().resource_path == "res://ui/hero_selection.gd": return child
	return null

func key(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code; event.physical_keycode = code; event.pressed = true
	root.push_input(event, true)
	event = InputEventKey.new()
	event.keycode = code; event.physical_keycode = code; event.pressed = false
	root.push_input(event, true)
	await frames(2)

func joy(code: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = code; event.pressed = true
	root.push_input(event, true)
	event = InputEventJoypadButton.new()
	event.button_index = code; event.pressed = false
	root.push_input(event, true)
	await frames(2)

func click(button: Button, touch: bool = false) -> void:
	var s := selector()
	if s:
		s.scroll.ensure_control_visible(button)
		await frames()
	var point := button.get_global_rect().get_center()
	check(Rect2(Vector2.ZERO, Vector2(root.size)).has_point(point), "Click target visible: " + button.text)
	if touch:
		# Input.parse_input_event enters the engine's touch-to-mouse path used by Godot buttons.
		var event := InputEventScreenTouch.new()
		event.index = 0; event.position = point; event.pressed = true
		Input.parse_input_event(event)
		await frames(2)
		event = InputEventScreenTouch.new()
		event.index = 0; event.position = point; event.pressed = false
		Input.parse_input_event(event)
	else:
		var motion := InputEventMouseMotion.new()
		motion.position = point; motion.global_position = point
		root.push_input(motion, true)
		var event := InputEventMouseButton.new()
		event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true
		root.push_input(event, true)
		event = InputEventMouseButton.new()
		event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = false
		root.push_input(event, true)
	await frames()

func open_selector(dimensions: Vector2i) -> Control:
	root.size = dimensions
	app.show_page("HEROES")
	await frames(10)
	return selector()

func run_tests() -> void:
	profile = root.get_node("Profile")
	saved_data = profile.data.duplicate(true); saved_path = profile.profile_path
	profile.profile_path = "res://build/visual-after/hero_ui_test_profile.json"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/visual-after"))
	profile.data = profile._defaults(); profile.data.onboarded = true
	profile.data.settings.volume = 0; profile.data.settings.music_volume = 0
	profile.data.settings.reduced_motion = false
	profile._refresh_daily()
	check(profile.save_profile(), "Isolated test profile created")
	root.min_size = Vector2i.ZERO
	app = load("res://ui/main.tscn").instantiate(); root.add_child(app)
	await frames()
	var s := await open_selector(Vector2i(1280, 900))
	check(s != null, "HEROES creates functioning selector")
	if s == null:
		finish(); return
	check(HeroRoster.HEROES.size() == 6 and s.portraits.size() == 6, "All six town characters are selectable")
	check(s.size.is_equal_approx(Vector2(1280,900)), "Hero screen preserves the native interactive viewport dimensions")
	check(not app.orientation_pause and not app.router.enabled, "Selector is usable and gameplay input is disabled")
	for index in range(HeroRoster.HEROES.size()):
		await click(s.portraits[index])
		var spec := HeroRoster.hero(index)
		check(s.selected == index and s.hero_name.text == spec.name, spec.name + " actual portrait click switches details")
		check(s.stage.entry.id == spec.id and s.stage.art.texture != null, spec.name + " portrait loaded")
		var atlas: AtlasTexture = s.stage.art.texture as AtlasTexture
		check(s.stage.last_art_path == "res://assets/shared_foundation/town_cast/cast_idles.png" and atlas != null and atlas.region == Rect2(index * 32, 0, 32, 32), spec.name + " uses its own town portrait")
		var motions: SpriteFrames = CharacterVisual.frames(spec.id)
		for facing: String in ['left','up','right','down']:
			for action: String in ['idle','idle_animated','walk','run','hit','hurt']:
				var animation := StringName(action+'_'+facing)
				check(motions.has_animation(animation) and motions.get_frame_count(animation)>0, spec.name + " has usable " + String(animation))
		var walk_frame := motions.get_frame_texture(&'walk_down',0) as AtlasTexture
		check(walk_frame != null and walk_frame.atlas.resource_path.ends_with('_aseprite.png') and walk_frame.region.size == Vector2(16,32), spec.name + " runtime animation consumes the Aseprite atlas at native scale")
		if profile.data.hero != spec.id: await click(s.equip_button)
		check(profile.data.hero == spec.id and s.equip_button.disabled, spec.name + " equipped once with status")
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(profile.profile_path))
		var persisted: Dictionary = parsed if parsed is Dictionary else {}
		check(persisted.get("hero", "") == spec.id, spec.name + " equipment written to disk")
		app.show_page("HEROES"); await frames(); s = selector()
		check(s.selected == index, spec.name + " selection survives page recreation")
		profile.data.hero = "not-the-persisted-hero"
		profile.load_profile()
		check(profile.data.hero == spec.id, spec.name + " equipment survives sanitized disk reload")
		app.show_page("HEROES"); await frames(); s = selector()
		var demonstrations: int = s.stage.demo_count
		await click(s.demo_button)
		await create_timer(0.15).timeout
		check(s.stage.demo_count == demonstrations + 1 and s.stage.demo_time > 0, spec.name + " demo advances with real elapsed frames")
		check(s.stage.art.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, spec.name + " stage sprite uses nearest-neighbor pixels")
		await check_stage_pixels(s.stage, spec.name, false)
		await create_timer(2.25).timeout
		check(s.stage.demo_time < 0 and s.demo_button.text == "CELEBRATE", spec.name + " celebration completes and returns to idle")
	# Engine-dispatched keyboard/controller events, including wrap-around and held-key echo.
	s.select_hero(0, false)
	await key(KEY_LEFT); check(s.selected == 5, "Keyboard left wraps to the sixth character")
	await key(KEY_RIGHT); check(s.selected == 0, "Keyboard right wraps selection")
	await key(KEY_RIGHT); check(s.selected == 1, "Keyboard chooses second hero")
	await key(KEY_ENTER); check(profile.data.hero == "bolt", "Keyboard Enter equips selected hero")
	var before: int = s.stage.demo_count
	await key(KEY_SPACE); check(s.stage.demo_count == before + 1, "Keyboard Space activates power")
	await joy(JOY_BUTTON_DPAD_RIGHT); check(s.selected == 2, "Controller D-pad switches hero")
	await joy(JOY_BUTTON_A); check(profile.data.hero == "echo", "Controller A equips")
	before = s.stage.demo_count
	await joy(JOY_BUTTON_X); check(s.stage.demo_count == before + 1, "Controller X activates power")
	await joy(JOY_BUTTON_LEFT_SHOULDER); check(s.selected == 1, "Controller shoulder navigation")
	s.select_hero(0, false)
	await joy(JOY_BUTTON_DPAD_LEFT); check(s.selected == 5, "Controller left wraps to the sixth character")
	await joy(JOY_BUTTON_DPAD_RIGHT); check(s.selected == 0, "Controller right wraps to the first character")
	for index in range(1,HeroRoster.HEROES.size()):
		await joy(JOY_BUTTON_DPAD_RIGHT)
		check(s.selected == index, "Controller reaches character " + str(index))
		await joy(JOY_BUTTON_A)
		check(profile.data.hero == HeroRoster.hero(index).id, "Controller equips character " + str(index))
	await click(s.motion_button)
	check(profile.data.settings.get("reduced_motion", false), "Reduced motion toggle persists setting")
	profile.load_profile(); check(profile.data.settings.get("reduced_motion", false), "Reduced motion survives disk sanitizer")
	await click(s.demo_button)
	await create_timer(0.12).timeout
	var still_position: Vector2 = s.stage.art.position
	var still_scale: Vector2 = s.stage.art.scale
	await create_timer(0.2).timeout
	check(s.stage.reduced_motion and s.stage.art.rotation == 0, "Reduced motion disables decorative sprite movement")
	check(s.stage.art.position.is_equal_approx(still_position) and s.stage.art.scale.is_equal_approx(still_scale) and s.stage.art.rotation == 0 and s.stage.art.modulate.a == 1, "Reduced motion keeps art stable during power preview")
	check(s.stage.demo_time >= 0, "Reduced motion retains visible power activation feedback")
	await check_stage_pixels(s.stage, "Reduced motion", true)
	for dimensions in [Vector2i(375,812), Vector2i(390,844), Vector2i(430,932), Vector2i(844,390)]:
		s = await open_selector(dimensions)
		await check_layout(s, dimensions)
		for index in range(HeroRoster.HEROES.size()):
			await click(s.portraits[index], dimensions.x < 720)
			check(s.selected == index, str(dimensions) + " portrait " + str(index) + " routes real pointer/touch")
		if dimensions.x < 720:
			before = s.stage.demo_count
			await click(s.stage_power, true)
			check(s.stage.demo_count == before + 1, str(dimensions) + " stage preview touch works after scroll")
		await click(s.equip_button)
		check(profile.data.hero == HeroRoster.hero(s.selected).id, str(dimensions) + " mobile equip target works")
		# PLAY enters an existing real game; portrait gameplay is guarded until rotation.
		var expected_game: String = HeroRoster.hero(s.selected).game
		await click(s.play_button)
		check(app.current_page == "PLAY" and is_instance_valid(app.current_game) and app.current_id == expected_game, str(dimensions) + " Play launches matching game")
		check(root.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS and root.content_scale_size == Vector2i(960,540), "Gameplay scale restored after hero selector")
		if dimensions.y > dimensions.x:
			check(app.orientation_pause and not app.current_game.active and not app.router.enabled, "Portrait gameplay waits safely for rotation")
		root.size = Vector2i(844,390); await frames()
		app.transitioning = false; app.close_modal(); app.refresh_pause()
		check(not app.orientation_pause and app.current_game.active, "Game resumes in landscape")
		var game_ref: WeakRef = weakref(app.current_game)
		app.show_page("HOME"); await frames()
		check(game_ref.get_ref() == null and app.current_game == null and not app.router.enabled, "Home disposes launched game and routing")
		await check_menu_bounds()
	await save_failure_fixture()
	finish()

func check_menu_bounds() -> void:
	# Menus use viewport pixels, while the gameplay assertion above preserves
	# the logical 960x540 board. Verify both real menu routes after game disposal.
	var valid: bool = true
	for destination in ["HOME", "GAMES"]:
		var previous: WeakRef = weakref(app.page)
		app.show_page(destination)
		await frames()
		var expected := Rect2(Vector2.ZERO, Vector2(root.size))
		var screen: Control = null
		for child in app.page.get_children():
			if child is Control and child.get_script() != null and child.get_script().resource_path in ["res://ui/arcade_home.gd", "res://ui/arcade_library.gd"]: screen = child
		valid = valid and previous.get_ref() == null and screen != null
		valid = valid and root.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS and root.content_scale_size == Vector2i.ZERO
		valid = valid and app.page.get_global_rect().is_equal_approx(expected)
		if screen != null: valid = valid and screen.get_global_rect().is_equal_approx(expected)
		valid = valid and not app.router.enabled and app.current_game == null and not app.orientation_pause
	check(valid, "Home/library use viewport bounds, dispose previous pages and disable game input")
	app.show_page("HOME")
	await frames()

func save_failure_fixture() -> void:
	# A real regular file blocks directory creation. No fake save result or mocked storage.
	var blocker_path: String = "res://build/visual-after/hero_save_directory_blocker"
	var blocker := FileAccess.open(blocker_path, FileAccess.WRITE)
	check(blocker != null, "Owned regular-file save obstruction created")
	if blocker == null: return
	blocker.store_string("Hero save failure fixture: this is a file, not a directory.")
	blocker.close()
	var s := await open_selector(Vector2i(1280,900))
	var previous_hero: String = profile.data.hero
	var previous_path: String = profile.profile_path
	var target_index: int = (int(s.selected) + 1) % HeroRoster.HEROES.size()
	s.select_hero(target_index, false)
	var proposed_hero: String = HeroRoster.hero(target_index).id
	profile.profile_path = blocker_path.path_join("profile.json")
	check(not profile.equip_hero(proposed_hero) and profile.data.hero == previous_hero, "Failed real save returns false and rolls back equipped hero")
	check(not s.equip(), "Selector propagates equipment save failure")
	check(profile.data.hero == previous_hero and not s.equip_button.disabled and s.equip_button.text != "EQUIPPED", "Failed selection retains active hero and avoids false equipped status")
	check(not profile.last_error.is_empty() and s.status.text.contains("Could not save"), "Failed selection displays actionable save error")
	await click(s.play_button)
	check(app.current_page == "HEROES" and app.current_game == null and not app.router.enabled, "Actual Play click cannot launch newly selected hero after save failure")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(previous_path))
	check(parsed is Dictionary and parsed.get("hero", "") == previous_hero, "Failed equipment does not replace last readable saved hero")
	profile.profile_path = previous_path

func check_layout(s: Control, dimensions: Vector2i) -> void:
	var tag := str(dimensions)
	check(s.size.is_equal_approx(Vector2(dimensions)), tag + " actual selector canvas matches requested pixels")
	check(not app.orientation_pause and not is_instance_valid(app.rotate_cover), tag + " hero screen has no rotation overlay")
	check(s.column.get_combined_minimum_size().x <= dimensions.x + 1, tag + " content minimum width fits viewport")
	var controls: Array[Button] = s.portraits.duplicate()
	controls.append_array([s.equip_button, s.demo_button, s.play_button, s.motion_button])
	if s.stage_power.visible: controls.append(s.stage_power)
	for button in controls:
		s.scroll.ensure_control_visible(button); await frames()
		var rect := button.get_global_rect()
		check(rect.position.x >= -1 and rect.end.x <= dimensions.x + 1, tag + " horizontal bounds " + button.text)
		check(rect.position.y >= -1 and rect.end.y <= dimensions.y + 1, tag + " reachable after scroll " + button.text)
		check(rect.size.y >= 44 and rect.size.x >= 44, tag + " touch target >=44px " + button.text)
	layouts.append({"viewport":tag,"selector_size":str(s.size),"content_minimum_width":s.column.get_combined_minimum_size().x,"scroll_max":s.scroll.get_v_scroll_bar().max_value})

func check_stage_pixels(stage: Control, tag: String, frozen: bool) -> void:
	var viewport: SubViewport
	for child in stage.get_children():
		if child is SubViewport: viewport = child
	check(viewport != null and viewport.size == Vector2i(320,180), tag + " uses the actual 320x180 pixel stage")
	if viewport == null: return
	# The old cinematic TextureRect is hidden. Compare the actual displayed
	# SubViewport instead; keep room-clock decoration identical across samples.
	if DisplayServer.get_name() == "headless": return
	var previous_clock: float = stage.clock
	var previous_demo: float = stage.demo_time
	stage.set_process(false)
	stage.clock = 0.25; stage.demo_time = 0.0
	await frames(2); await RenderingServer.frame_post_draw
	var first: PackedByteArray = viewport.get_texture().get_image().get_data()
	stage.clock = 3.5 if frozen else 0.25; stage.demo_time = 0.6
	await frames(2); await RenderingServer.frame_post_draw
	var second: PackedByteArray = viewport.get_texture().get_image().get_data()
	check(not first.is_empty() and (first == second if frozen else first != second), tag + (" freezes actual rendered stage pixels" if frozen else " celebration changes actual rendered character pixels"))
	stage.clock = previous_clock; stage.demo_time = previous_demo
	stage.set_process(true)

func finish() -> void:
	if is_instance_valid(app): app.free()
	profile.data = saved_data; profile.profile_path = saved_path
	var file := FileAccess.open("res://build/visual-after/hero_ui_test_report.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"checks":checks,"failures":failures,"layouts":layouts,"scope":"Native engine input, state, persistence and layout. No physical touchscreen/controller claim."},"\t")); file.close()
	print("HERO_UI_CHECKS=",checks," FAILURES=",failures.size())
	quit(0 if failures.is_empty() else 1)
