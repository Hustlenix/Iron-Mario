extends Node2D
const Paint = preload("res://scripts/ui/Paint.gd")
const Catalog = preload("res://scripts/arcade/ArcadeCatalog.gd")
@export var game_id = "dino_dash"
signal game_finished(won: bool)
var score = 0
var lives = 3
var stage = 1
var elapsed = 0.0
var ended = false
var won = false
var paused = false
var preparing = false
var message = ""
var status = ""
var hint = ""
var primary_label = "ACTION"
var secondary_label = "Z"
var use_secondary = false
var use_primary = true
var pointer = Vector2(640,350)
var pointer_down = false
var held: Dictionary = {}
var pressed: Dictionary = {}
var fingers: Dictionary = {}
var pointer_finger = -1
var invulnerable = 0.0
var rng = RandomNumberGenerator.new()
var metadata: Dictionary
const BOARD = Rect2(65,145,1150,390)
const DIRECTIONS = [Vector2i.LEFT,Vector2i.UP,Vector2i.DOWN,Vector2i.RIGHT]

func _ready() -> void:
	metadata = Catalog.get_game(game_id)
	hint = metadata["hint"]
	rng.seed = hash(game_id) + int(Time.get_ticks_msec())
	setup()
	preparing = game_id != "adventure"
	Music.play_theme("ember" if game_id == "adventure" else Global.hero_id,"boss" if game_id=="adventure" and stage==4 else "mission")
	if OS.has_feature("web"):
		print("ARCADE_READY " + game_id)
	queue_redraw()

func setup() -> void:
	pass
func tick(_delta: float) -> void:
	pass
func draw_game() -> void:
	pass
func on_action(_action: String) -> void:
	pass
func on_pointer(_at: Vector2,_down: bool) -> void:
	pass
func on_drag(_at: Vector2) -> void:
	pass
func waiting_for_next() -> bool:
	return false
func next_button_label() -> String:
	return "CONTINUE"
func begin_play() -> void:
	if not preparing: return
	preparing = false
	release_controls()
	SoundFX.play_start()
	if OS.has_feature("web"): print("ARCADE_STARTED " + game_id)
	queue_redraw()
func pointer_event(at: Vector2,active: bool) -> void:
	if active and waiting_for_next():
		on_action("primary")
	else:
		on_pointer(at,active)

func _physics_process(delta: float) -> void:
	if preparing or paused or ended:
		return
	var step = minf(delta,0.05)
	elapsed += step
	invulnerable = maxf(0,invulnerable-step)
	tick(step)
	pressed.clear()
	queue_redraw()

func down(action: String) -> bool:
	return bool(held.get(action,false)) or Input.is_action_pressed("arcade_"+action)
func just(action: String) -> bool:
	return bool(pressed.get(action,false))
func axis_x() -> float:
	return float(down("right"))-float(down("left"))
func axis_y() -> float:
	return float(down("down"))-float(down("up"))
func direction_pressed() -> Vector2i:
	for index in range(4):
		if just(["left","up","down","right"][index]): return DIRECTIONS[index]
	return Vector2i.ZERO
func action_event(action: String,active: bool) -> void:
	if preparing:
		if active and action == "primary": begin_play()
		return
	held[action] = active
	if active and not paused and not ended:
		pressed[action] = true
		on_action(action)
	queue_redraw()

func control_at(at: Vector2) -> String:
	if Rect2(1130,20,130,75).has_point(at): return "pause"
	if use_primary and Rect2(1030,570,220,138).has_point(at): return "primary"
	if use_secondary and Rect2(855,610,155,95).has_point(at): return "secondary"
	if Rect2(135,545,100,65).has_point(at): return "up"
	if Rect2(135,645,100,65).has_point(at): return "down"
	if Rect2(25,610,110,100).has_point(at): return "left"
	if Rect2(235,610,110,100).has_point(at): return "right"
	return ""

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo: return
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION: return
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("restart"):
		restart_game()
		get_viewport().set_input_as_handled()
		return
	if (paused or ended) and event.is_action_pressed("ui_accept"):
		if ended: restart_game()
		else: toggle_pause()
		get_viewport().set_input_as_handled()
		return
	for action in ["left","right","up","down","primary","secondary"]:
		var mapped = "arcade_"+action
		if game_id == "adventure" and action in ["primary","secondary"]:
			mapped = "jump" if action == "primary" else "action"
		if event.is_action(mapped):
			action_event(action,event.is_pressed())
			get_viewport().set_input_as_handled()
	if event is InputEventScreenTouch:
		if not event.pressed or event.canceled:
			if fingers.has(event.index):
				var action: String = fingers[event.index]
				fingers.erase(event.index)
				if not fingers.values().has(action): action_event(action,false)
			if pointer_finger == event.index:
				pointer_down = false
				pointer_event(event.position,false)
				pointer_finger = -1
		elif overlay_click(event.position):
			pass
		else:
			var action = control_at(event.position)
			if action == "pause": toggle_pause()
			elif not action.is_empty():
				fingers[event.index] = action
				action_event(action,true)
			elif pointer_finger == -1 and not paused and not ended:
				pointer_finger = event.index
				pointer = event.position
				pointer_down = true
				pointer_event(pointer,true)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if fingers.has(event.index):
			var previous: String = fingers[event.index]
			var next = control_at(event.position)
			if next != previous:
				fingers[event.index] = next
				if not fingers.values().has(previous): action_event(previous,false)
				if not next.is_empty() and next != "pause": action_event(next,true)
		elif pointer_finger == event.index:
			pointer = event.position
			on_drag(pointer)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pointer = event.position
		if event.pressed and overlay_click(pointer): return
		if event.pressed and control_at(pointer) == "pause": toggle_pause(); return
		if not paused and not ended:
			pointer_down = event.pressed
			pointer_event(pointer,pointer_down)
	elif event is InputEventMouseMotion:
		pointer = event.position
		if not paused and not ended: on_drag(pointer)

func overlay_click(at: Vector2) -> bool:
	if not preparing and not paused and not ended: return false
	if Rect2(350,415,280,90).has_point(at):
		if paused: toggle_pause()
		elif preparing: begin_play()
		else: restart_game()
	elif Rect2(660,415,280,90).has_point(at):
		GameManager.open_menu("res://scenes/arcade_library.tscn" if game_id != "adventure" else GameManager.TITLE_SCENE)
	return true
func toggle_pause() -> void:
	if ended: return
	paused = not paused
	if OS.has_feature("web"): print("ARCADE_PAUSE "+game_id+" "+str(paused))
	release_controls()
	queue_redraw()
func release_controls() -> void:
	held.clear()
	pressed.clear()
	fingers.clear()
	pointer_finger = -1
	pointer_down = false
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		release_controls()
func _exit_tree() -> void:
	release_controls()
func restart_game() -> void:
	GameManager.open_menu(scene_file_path)
func damage(reason = "OUT OF HULLS!") -> bool:
	if invulnerable > 0 or ended: return false
	lives -= 1
	invulnerable = 1.25
	SoundFX.play_failure()
	if lives <= 0: complete(false,reason)
	return true
func complete(success: bool,reason: String) -> void:
	if ended: return
	ended = true
	won = success
	message = reason
	release_controls()
	if game_id != "adventure": Global.record_arcade(game_id,score,success,stage)
	SoundFX.play_success() if success else SoundFX.play_failure()
	game_finished.emit(success)
	if OS.has_feature("web"): print("ARCADE_RESULT "+game_id+" "+str(success))
	queue_redraw()
func panel(box: Rect2,color: Color = Paint.PAPER) -> void:
	Paint.rect(self,box,color)
	Paint.rect(self,box,Paint.INK,false,3)
func text(value: String,at: Vector2,size_value = 22,color: Color = Paint.INK,width = -1.0) -> void:
	Paint.text(self,value,at,size_value,color,width)
func dot(at: Vector2,radius: float,color: Color) -> void:
	Paint.circle(self,at,radius,color)
	Paint.circle(self,at,radius,Paint.INK,false,2)
func line(a: Vector2,b: Vector2,color: Color = Paint.INK,width = 3.0) -> void:
	Paint.line(self,a,b,color,width)
func _draw() -> void:
	Paint.rect(self,Rect2(0,0,1280,720),Color("d5e2dc"))
	draw_game()
	panel(Rect2(15,12,1100,102))
	text(metadata.get("name","IRON MARIO"),Vector2(35,48),28)
	text(hint,Vector2(35,80),18,Paint.INK,780)
	text("SCORE %d" % score,Vector2(835,45),20)
	text("LIVES %d / STAGE %d" % [lives,stage],Vector2(835,80),17)
	panel(Rect2(1130,20,130,75),Paint.CYAN)
	text("PAUSE",Vector2(1143,65),21)
	if not status.is_empty(): text(status,Vector2(380,563),19,Paint.INK,610)
	if Global.uses_touch() and not preparing and not paused and not ended:
		var controls = [[Rect2(25,610,110,100),"left","<"],[Rect2(135,545,100,65),"up","↑"],[Rect2(135,645,100,65),"down","↓"],[Rect2(235,610,110,100),"right",">"]]
		if use_primary: controls.append([Rect2(1030,570,220,138),"primary",next_button_label() if waiting_for_next() else primary_label])
		for item in controls:
			panel(item[0],Paint.GOLD if down(item[1]) else Paint.PAPER)
			text(item[2],item[0].position+Vector2(12,item[0].size.y/2+8),23)
		if use_secondary:
			panel(Rect2(855,610,155,95),Paint.CYAN)
			text(secondary_label,Vector2(865,665),20)
	else:
		text(metadata.get("controls","A/D: MOVE   SPACE / W: JUMP   E: BLAST")+"   ESC: PAUSE   R: RETRY",Vector2(35,680),18,Paint.INK,1210)
	if preparing or paused or ended:
		Paint.rect(self,Rect2(0,0,1280,720),Color(0.08,0.1,0.16,0.72))
		panel(Rect2(270,205,740,330))
		text("PAUSED" if paused else (metadata["name"] if preparing else (("MISSION COMPLETE" if won else "SUIT POWERED DOWN") if game_id=="adventure" else ("CLEAR!" if won else "RUN COMPLETE"))),Vector2(320,270),42,Paint.INK,650)
		text(metadata["hint"] if preparing else ("TAKE A BREATH, HERO." if paused else message),Vector2(320,327),22,Paint.INK,650)
		if preparing or paused:
			text(metadata.get("touch_controls" if Global.uses_touch() else "controls",hint),Vector2(320,377),20,Paint.INK,650)
		else:
			text("SCORE %d" % score,Vector2(320,377),23)
		panel(Rect2(350,415,280,90),Paint.GOLD)
		panel(Rect2(660,415,280,90),Paint.CYAN)
		text("RESUME" if paused else ("PLAY" if preparing else "PLAY AGAIN"),Vector2(375,467),23)
		text("HOME" if game_id == "adventure" else "ARCADE",Vector2(700,467),23)
