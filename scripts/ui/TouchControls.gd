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
var pad_finger := -1
var pad_enabled := false
var pad_knob := Vector2(180,665)
const PAD := Rect2(30,620,320,88)

func _ready() -> void:
	game = get_parent()
	z_index = 150
	enabled = Global.uses_touch()
	visible = enabled
	var mission := game.scene_file_path.get_file().get_basename()
	if mission in ["arc_reactor_dash","laser_tunnel","rocket_rescue"]:
		pad_enabled = true
	if mission in ["arc_reactor_dash","laser_tunnel","reactor_parry"]:
		region(Rect2(410,545,820,160) if mission == "reactor_parry" else Rect2(1020,620,225,88),"jump","PARRY" if mission == "reactor_parry" else "JUMP")
	region(Rect2(40,143,125,63),"ui_cancel","HOME")

func region(box: Rect2, action: String, label: String) -> void:
	regions.append({"box":box,"action":action,"label":label})

func hit(at: Vector2) -> String:
	if pad_enabled and PAD.has_point(at):
		return "move_left" if at.x < 156 else ("move_right" if at.x > 204 else "")
	for item in regions:
		if item["box"].has_point(at):
			return item["action"]
	return ""

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		last_touch = Time.get_ticks_msec()
		enabled = true
		visible = true
		if event.canceled:
			if fingers.has(event.index):
				_release_finger(event.index)
			get_viewport().set_input_as_handled()
			return
		if event.pressed:
			if pad_enabled and PAD.has_point(event.position) and pad_finger == -1:
				pad_finger = event.index
				fingers[event.index] = ""
				_slide_pad(event.position)
				get_viewport().set_input_as_handled()
				queue_redraw()
				return
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
		if event.index == pad_finger:
			_slide_pad(event.position)
			get_viewport().set_input_as_handled()
		elif fingers.has(event.index):
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

func _slide_pad(at: Vector2) -> void:
	var next := "move_left" if at.x < 156 else ("move_right" if at.x > 204 else "")
	var previous: String = fingers[pad_finger]
	if previous != next:
		fingers[pad_finger] = next
		if not fingers.values().has(previous):
			_emit_action(previous,false)
		_emit_action(next,true)
	pad_knob = Vector2(clampf(at.x,90,270),665)
	queue_redraw()

func _emit_action(action: String, pressed: bool) -> void:
	if action.is_empty():
		return
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
	if index == pad_finger:
		pad_finger = -1
		pad_knob = Vector2(180,665)
	fingers.erase(index)
	if not fingers.values().has(action):
		_emit_action(action,false)

func release_all() -> void:
	var actions := fingers.values()
	if not mouse_action.is_empty():
		actions.append(mouse_action)
	pad_finger = -1
	pad_knob = Vector2(180,665)
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
	if pad_enabled:
		Paint.rect(self,PAD,Color("fff6dcdf"))
		Paint.rect(self,PAD,Paint.INK,false,3)
		Paint.text(self,"<             >",Vector2(55,675),31)
		Paint.circle(self,pad_knob,29,Paint.GOLD if pad_finger >= 0 else Paint.CYAN)
		Paint.circle(self,pad_knob,29,Paint.INK,false,3)
	for item in regions:
		var box: Rect2 = item["box"]
		var held: bool = fingers.values().has(item["action"]) or mouse_action == item["action"]
		Paint.rect(self,box,Paint.GOLD if held else Color("fff6dcdf"))
		Paint.rect(self,box,Paint.INK,false,3)
		Paint.text(self,item["label"],box.position+Vector2(8,box.size.y/2+8),23,Paint.INK,box.size.x-16,HORIZONTAL_ALIGNMENT_CENTER)
