extends Node2D

const Paint = preload("res://scripts/ui/Paint.gd")
const Backdrop = preload("res://scripts/ui/MissionBackdrop.gd")
var countdown := 3.0
var launched := false
var game_data: Dictionary
var last_count := 4
var load_progress := 0.0
var prepared: PackedScene
var load_failed := false
var threaded := false

func _ready() -> void:
	game_data = GameManager.get_upcoming_game()
	Music.play_theme(Global.hero_id, "briefing")
	var hero := preload("res://scripts/ui/IronHero.gd").new()
	hero.position = Vector2(225, 367)
	hero.scale = Vector2(4.2,4.2)
	hero.pose = "jump" if game_data["scene"].contains("rescue") else "victory"
	add_child(hero)
	SoundFX.play_start()
	var error := ResourceLoader.load_threaded_request(game_data["scene"], "PackedScene")
	threaded = error == OK
	if not threaded:
		_fallback_load.call_deferred()

func _fallback_load() -> void:
	# Render the briefing before loading on platforms without loader threads.
	await get_tree().process_frame
	prepared = load(game_data["scene"]) as PackedScene
	load_progress = 1.0 if prepared != null else 0.0
	load_failed = prepared == null

func _process(delta: float) -> void:
	if launched:
		return
	countdown = maxf(0.0, countdown - delta)
	if threaded and prepared == null and not load_failed:
		var progress: Array = []
		var status := ResourceLoader.load_threaded_get_status(game_data["scene"], progress)
		if not progress.is_empty():
			load_progress = float(progress[0])
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			prepared = ResourceLoader.load_threaded_get(game_data["scene"]) as PackedScene
			load_progress = 1.0
		elif status in [ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE]:
			load_failed = true
	var visible_count := maxi(1, ceili(countdown))
	if visible_count != last_count:
		last_count = visible_count
		SoundFX.play_countdown(visible_count)
	queue_redraw()
	if countdown <= 0.0 and prepared != null:
		launched = true
		GameManager.launch_current_minigame(prepared)
	elif load_failed and not has_node("BackButton"):
		var back := preload("res://scripts/ui/PixelButton.gd").make("BACK TO TITLE", Vector2(660,605),Vector2(330,55),Paint.GOLD)
		back.name = "BackButton"
		back.pressed.connect(GameManager.return_to_title)
		add_child(back)

func _draw() -> void:
	var mission := String(game_data.get("scene", "arc_reactor_dash")).get_file().get_basename()
	Backdrop.draw(self, mission, 3.0-countdown)
	Paint.rect(self,Rect2(30,25,1220,63),Paint.PAPER)
	Paint.text(self, Global.hero_data()["name"] + " / " + Global.pilot_name,Vector2(55,66),23,Paint.INK,675)
	Paint.text(self,"MISSION %d / 7    LOOP %d" % [GameManager.round_index+1,Global.current_loop],Vector2(765,66),23)
	Paint.rect(self,Rect2(421,174,819,427),Paint.INK)
	Paint.rect(self,Rect2(415,166,815,427),Paint.PAPER)
	Paint.rect(self,Rect2(415,166,815,427),Paint.INK,false,4)
	Paint.text(self,Global.hero_data()["place"] + " / NEXT MISSION",Vector2(453,216),20,Paint.INK,725)
	Paint.text(self,String(game_data.get("name","MISSION")),Vector2(452,277),40,Paint.INK,728)
	Paint.text(self,String(game_data.get("instruction","GET READY!")),Vector2(453,337),21,Paint.INK,728)
	Paint.text(self,"STARTS IN " + str(maxi(1,ceili(countdown))) if countdown > 0 else "LOADING...",Vector2(453,416),30)
	Paint.text(self,"LIVES %d    SCORE %05d    STREAK %d" % [Global.lives,Global.score,Global.streak],Vector2(453,467),19)
	var ready_fraction := minf(load_progress, clampf(1.0-countdown/3.0,0,1))
	Paint.rect(self,Rect2(453,505,730,28),Paint.INK)
	Paint.rect(self,Rect2(458,510,720*ready_fraction,18),Paint.CYAN)
	Paint.text(self,"COULD NOT LOAD MISSION" if load_failed else "PREPARING MISSION  %d%%" % int(ready_fraction*100),Vector2(453,568),20)

func _exit_tree() -> void:
	# Complete an abandoned request when a preview/test closes mid-briefing.
	if threaded and prepared == null:
		var status := ResourceLoader.load_threaded_get_status(game_data["scene"])
		if status in [ResourceLoader.THREAD_LOAD_IN_PROGRESS, ResourceLoader.THREAD_LOAD_LOADED]:
			ResourceLoader.load_threaded_get(game_data["scene"])
