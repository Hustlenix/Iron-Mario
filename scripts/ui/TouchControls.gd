extends Node2D
## Finger ownership is tracked independently; move + jump supports two fingers.
## Events are emitted through InputMap, so keyboard and touch use the same code.
const Paint = preload("res://scripts/ui/Paint.gd")
var game: Node
var regions: Array[Dictionary] = []
var fingers: Dictionary = {}
var enabled := false
var mouse_action := ""
var last_touch := -1000

func _ready() -> void:
	game = get_parent()
	z_index = 150
	enabled = Global.uses_touch()
	visible = enabled
	var mission := game.scene_file_path.get_file().get_basename()
	if mission in ["arc_reactor_dash","laser_tunnel","rocket_rescue"]:
		region(Rect2(40,603,126,99),"move_left","LEFT")
		region(Rect2(183,603,126,99),"move_right","RIGHT")
	if mission in ["arc_reactor_dash","laser_tunnel","reactor_parry"]:
		region(Rect2(1063,603,174,99),"jump","PARRY" if mission == "reactor_parry" else "JUMP")
	region(Rect2(1113,143,125,63),"restart","RETRY")
	region(Rect2(40,143,125,63),"ui_cancel","MENU")

func region(box: Rect2, action: String, label: String) -> void:
	regions.append({"box":box,"action":action,"label":label})

func hit(at: Vector2) -> String:
	for item in regions:
		if item["box"].has_point(at):
			return item["action"]
	return ""

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		last_touch = Time.get_ticks_msec()
		enabled = true
		visible = true
		if event.pressed:
			var action := hit(event.position)
			if not action.is_empty():
				fingers[event.index] = action
				_emit_action(action,true)
				get_viewport().set_input_as_handled()
		elif fingers.has(event.index):
			_release_finger(event.index)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		last_touch = Time.get_ticks_msec()
		if fingers.has(event.index):
			# Sliding out releases the old key; sliding between arrows switches it.
			var previous: String = fingers[event.index]
			var next := hit(event.position)
			if next != previous:
				_release_finger(event.index)
				if not next.is_empty():
					fingers[event.index] = next
					_emit_action(next,true)
			get_viewport().set_input_as_handled()
	elif enabled and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Godot may emulate a mouse event for finger zero. Never activate it twice.
		if Time.get_ticks_msec() - last_touch < 350:
			if not hit(event.position).is_empty():
				get_viewport().set_input_as_handled()
			return
		if event.pressed:
			mouse_action = hit(event.position)
			if not mouse_action.is_empty():
				_emit_action(mouse_action,true)
				get_viewport().set_input_as_handled()
		elif not mouse_action.is_empty():
			_emit_action(mouse_action,false)
			mouse_action = ""
			get_viewport().set_input_as_handled()
	queue_redraw()

func _emit_action(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	if pressed:
		Input.action_press(action)
		if is_instance_valid(game) and game.is_inside_tree():
			game._unhandled_input(event)
	else:
		Input.action_release(action)

func _release_finger(index: int) -> void:
	var action: String = fingers[index]
	fingers.erase(index)
	if not fingers.values().has(action):
		_emit_action(action,false)

func release_all() -> void:
	var actions := fingers.values()
	if not mouse_action.is_empty():
		actions.append(mouse_action)
	fingers.clear()
	mouse_action = ""
	for action in actions:
		_emit_action(action,false)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		release_all()

func _exit_tree() -> void:
	release_all()

func _draw() -> void:
	if not enabled:
		return
	for item in regions:
		var box: Rect2 = item["box"]
		var held: bool = fingers.values().has(item["action"]) or mouse_action == item["action"]
		Paint.rect(self,box,Paint.GOLD if held else Color("fff6dcdf"))
		Paint.rect(self,box,Paint.INK,false,3)
		Paint.text(self,item["label"],box.position+Vector2(8,box.size.y/2+8),23,Paint.INK,box.size.x-16,HORIZONTAL_ALIGNMENT_CENTER)
