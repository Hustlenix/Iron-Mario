extends SceneTree
var app: Control
var output := "res://build/visual-after/"
func get_selector() -> Control:
	for child in app.page.get_children():
		if child.get_script()!=null and child.get_script().resource_path=="res://ui/hero_selection.gd": return child
	return null
func _initialize() -> void: call_deferred("capture")
func settle() -> void:
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
func save_shot(name: String) -> void:
	await settle()
	assert(root.get_texture().get_image().save_png(output+name+".png")==OK)
func capture() -> void:
	var profile: Node=root.get_node("Profile")
	profile.profile_path=output+"town_test_profile.json"
	profile.data=profile._defaults(); profile.data.onboarded=true
	profile.data.settings.volume=0; profile.data.settings.music_volume=0
	root.min_size=Vector2i.ZERO; root.size=Vector2i(1280,900)
	app=load("res://ui/main.tscn").instantiate(); root.add_child(app)
	app.show_page("HEROES"); await settle()
	var selector: Control=get_selector()
	for i in HeroRoster.HEROES.size():
		selector.select_hero(i,true)
		assert(selector.equip())
		assert(profile.data.hero==HeroRoster.hero(i).id)
		selector.demonstrate(); await create_timer(0.4).timeout
		await save_shot("town_"+String(HeroRoster.hero(i).name).to_lower())
	profile.data.settings.reduced_motion=true
	await save_shot("town_reduced_motion")
	root.size=Vector2i(390,844); app.show_page("HEROES"); await settle()
	selector=get_selector()
	await save_shot("town_mobile_top")
	selector.scroll.ensure_control_visible(selector.play_button)
	await save_shot("town_mobile_actions")
	root.size=Vector2i(1280,900); app.show_page("HOME")
	await save_shot("town_arcade_home")
	print("TOWN_CAPTURE: six characters selected, equipped and celebrated; desktop/mobile screenshots saved")
	quit()
