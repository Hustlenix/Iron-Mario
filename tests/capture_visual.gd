extends SceneTree
## Native GPU rendering of the shipped selector. Screenshots are QA artifacts.
var output: String = "res://build/visual-after"
var errors: Array[String] = []
var shots: Array[Dictionary] = []
var app: Control

func _initialize() -> void:
	call_deferred("capture")

func frames(count: int = 8) -> void:
	for i in range(count): await process_frame
	await RenderingServer.frame_post_draw

func selector() -> Control:
	for child in app.page.get_children():
		if child.get_script() != null and child.get_script().resource_path == "res://ui/hero_selection.gd": return child
	return null

func save(name: String, description: String) -> void:
	await frames()
	var image: Image = root.get_texture().get_image()
	var result: Error = image.save_png(output + "/" + name + ".png")
	if result != OK: errors.append(name + " save error " + str(result))
	var s := selector()
	shots.append({"file":name+".png","pixels":str(image.get_size()),"description":description,"content_minimum_width":s.column.get_combined_minimum_size().x if s else 0,"scroll_y":s.scroll.scroll_vertical if s else 0})

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var profile: Node = root.get_node("Profile")
	var saved_data: Dictionary = profile.data.duplicate(true)
	var saved_path: String = profile.profile_path
	profile.profile_path = output + "/hero_capture_profile.json"
	profile.data = profile._defaults(); profile.data.onboarded = true
	profile.data.settings.volume = 0; profile.data.settings.music_volume = 0
	profile.data.settings.shake = false; profile.data.settings.reduced_motion = false
	profile._refresh_daily()
	root.min_size = Vector2i.ZERO
	root.size = Vector2i(1280,900)
	app = load("res://ui/main.tscn").instantiate(); root.add_child(app)
	app.show_page("HEROES"); await frames()
	var s := selector()
	for index in range(4):
		s.select_hero(index, false)
		await create_timer(0.5).timeout
		await save("hero_" + String(HeroRoster.hero(index).name).to_lower() + "_1280x900", "Original hero idle presentation")
		s.demonstrate(); await create_timer(0.72).timeout
		await save("hero_" + String(HeroRoster.hero(index).name).to_lower() + "_power_1280x900", "Actual active power preview at elapsed time ~0.72s")
	profile.data.settings.reduced_motion = true
	s.select_hero(3, false); s.demonstrate()
	await create_timer(0.15).timeout
	await save("hero_prism_reduced_motion_1280x900", "Reduced motion power feedback with stable art and disabled cloth motion")
	profile.data.settings.reduced_motion = false
	for dimensions in [Vector2i(375,812),Vector2i(390,844),Vector2i(430,932),Vector2i(844,390)]:
		root.size = dimensions
		app.show_page("HEROES"); await frames(12); s = selector()
		s.select_hero(0,false); await create_timer(0.4).timeout
		s.scroll.scroll_vertical = 0
		var suffix := str(dimensions.x) + "x" + str(dimensions.y)
		await save("heroes_top_" + suffix, "Hero roster, stage and mobile initial view")
		if dimensions.x < 720:
			s.scroll.ensure_control_visible(s.stage_power)
			s.demonstrate(); await create_timer(0.72).timeout
			await save("heroes_power_" + suffix, "Mobile power preview with reachable stage button")
		s.scroll.ensure_control_visible(s.play_button); await frames()
		await save("heroes_actions_" + suffix, "Scrolled details, equipment and matching-game launch controls")
	# Real selected-hero launch and a safe return to the established arcade viewport.
	root.size = Vector2i(1280,900); app.show_page("HEROES"); await frames()
	s = selector(); s.select_hero(2,false); s.launch(); await frames()
	app.transitioning = false; app.close_modal(); app.refresh_pause()
	await save("hero_umbra_matching_game_1280x900", "Selected Umbra launches the actual Shadow Armor Duel module")
	app.show_page("HOME"); await save("hero_return_home_1280x900", "Hero selection returns to arcade with restored canvas scale")
	app.free()
	profile.data = saved_data; profile.profile_path = saved_path
	var file := FileAccess.open(output + "/hero_capture_manifest.json",FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"shots":shots,"errors":errors,"limitation":"Native GPU screenshots at exact window dimensions; browser and physical-phone results are separate."},"\t")); file.close()
	else: errors.append("Cannot save manifest")
	print("HERO_VISUAL_CAPTURES=",shots.size()," ERRORS=",errors.size()," OUTPUT=",ProjectSettings.globalize_path(output))
	for detail in errors: print(detail)
	quit(0 if errors.is_empty() else 1)
