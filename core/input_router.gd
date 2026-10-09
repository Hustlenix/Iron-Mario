class_name InputRouter
extends Node
signal routed(action: String, point: Vector2, value: Vector2)
signal device_changed(device: String)
signal pause_requested
var device: String = 'keyboard'
var mode: String = 'TAP'
var board: Rect2 = Rect2(0,0,960,480)
var enabled: bool = false
var fingers: Dictionary = {}
var pointer := Vector2(480,240)
var cursor := Vector2(480,240)
var axis := Vector2.ZERO
var keys: Dictionary = {}
var gesture_held: bool = false
var gesture_start := Vector2.ZERO
var stick_axis := Vector2.ZERO
var stick_armed: bool = true

func reset() -> void:
	fingers.clear()
	keys.clear()
	axis = Vector2.ZERO
	gesture_held = false
	stick_axis=Vector2.ZERO
	stick_armed=true
	routed.emit('move',pointer,Vector2.ZERO)

func use_device(value: String) -> void:
	if value != device:
		device = value
		device_changed.emit(value)

func local_point(point: Vector2) -> Vector2:
	return (point - board.position) / maxf(board.size.x / 960.0,0.01)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		use_device('keyboard')
		if event.echo: return
		var key: int = event.physical_keycode
		if key == 0: key = event.keycode
		if key == KEY_ESCAPE and event.pressed:
			pause_requested.emit()
			return
		if not enabled: return
		if mode=='ARCADE' and event.pressed and key in [KEY_1,KEY_2,KEY_3,KEY_4]:
			routed.emit('select',cursor,Vector2(key-KEY_0,0))
			return
		if mode=='ARCADE' and event.pressed and key in [KEY_R,KEY_U]:
			routed.emit('reset' if key==KEY_R else 'undo',cursor,Vector2.ZERO)
			return
		if key in [KEY_Z,KEY_BACKSPACE,KEY_E,KEY_SHIFT] and event.pressed:
			routed.emit('secondary',cursor,Vector2.ZERO)
			return
		var was_pressed: bool = keys.get(key,false)
		keys[key] = event.pressed
		var d := Vector2.ZERO
		if key in [KEY_LEFT,KEY_A]: d = Vector2.LEFT
		if key in [KEY_RIGHT,KEY_D]: d = Vector2.RIGHT
		if key in [KEY_UP,KEY_W]: d = Vector2.UP
		if key in [KEY_DOWN,KEY_S]: d = Vector2.DOWN
		if event.pressed and d != Vector2.ZERO and not gesture_held:
			if mode == 'SWIPE': routed.emit('swipe',cursor,d*160)
			else: routed.emit('direction',cursor,d)
		if key in [KEY_SPACE,KEY_ENTER]:
			if not event.pressed and not was_pressed: return
			if mode == 'SWIPE': keyboard_gesture(event.pressed)
			elif mode == 'DRAG': routed.emit('press' if event.pressed else 'release',cursor,Vector2.ZERO)
			else: routed.emit('action' if event.pressed else 'release',cursor,Vector2.ZERO)
	elif event is InputEventJoypadButton:
		use_device('controller')
		if event.button_index == JOY_BUTTON_START and event.pressed:
			pause_requested.emit()
			return
		if not enabled: return
		var was_pressed: bool = keys.get(event.button_index+10000,false)
		keys[event.button_index+10000]=event.pressed
		if event.button_index==JOY_BUTTON_B and event.pressed:
			routed.emit('secondary',cursor,Vector2.ZERO)
			return
		if event.button_index == JOY_BUTTON_A:
			if not event.pressed and not was_pressed: return
			if mode == 'SWIPE': keyboard_gesture(event.pressed)
			else: routed.emit(('press' if mode == 'DRAG' else 'action') if event.pressed else 'release',cursor,Vector2.ZERO)
		var dirs: Dictionary = {JOY_BUTTON_DPAD_LEFT:Vector2.LEFT,JOY_BUTTON_DPAD_RIGHT:Vector2.RIGHT,JOY_BUTTON_DPAD_UP:Vector2.UP,JOY_BUTTON_DPAD_DOWN:Vector2.DOWN}
		if dirs.has(event.button_index):
			keys[event.button_index + 10000] = event.pressed
			if event.pressed and not gesture_held:
				if mode == 'SWIPE': routed.emit('swipe',cursor,dirs[event.button_index]*160)
				else: routed.emit('direction',cursor,dirs[event.button_index])
	elif event is InputEventJoypadMotion:
		if absf(event.axis_value)>0.25: use_device('controller')
		if event.axis==JOY_AXIS_LEFT_X: stick_axis.x=event.axis_value
		if event.axis==JOY_AXIS_LEFT_Y: stick_axis.y=event.axis_value
	elif event is InputEventScreenTouch:
		use_device('touch')
		if event.canceled:
			if fingers.has(event.index):
				fingers.erase(event.index)
				if mode=='HOLD' and not fingers.is_empty(): return
				routed.emit('cancel',local_point(event.position),Vector2.ZERO)
			return
		if enabled: pointer_event(event.index,event.position,event.pressed)
	elif event is InputEventScreenDrag:
		use_device('touch')
		if enabled: pointer_drag(event.index,event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.device == -1: return
		use_device('mouse')
		if enabled: pointer_event(-1,event.position,event.pressed)
	elif event is InputEventMouseMotion:
		if event.device == -1: return
		if enabled:
			pointer = local_point(event.position)
			cursor = pointer
			if fingers.has(-1): pointer_drag(-1,event.position)

func pointer_event(index: int, position: Vector2, pressed: bool) -> void:
	if pressed and (not board.has_point(position) or fingers.size() >= 2): return
	if not pressed and not fingers.has(index): return
	var p := local_point(position)
	pointer = p
	cursor = p
	if pressed:
		if not board.has_point(position) or fingers.size() >= 2: return
		fingers[index] = {'start':p,'point':p}
		routed.emit('press',p,Vector2.ZERO)
	else:
		if not fingers.has(index): return
		var delta: Vector2 = p - fingers[index].start
		var origin: Vector2 = fingers[index].start
		if mode=='HOLD' and fingers.size()>1:
			fingers.erase(index)
			return
		if delta.length() > 40: routed.emit('swipe',p,delta)
		routed.emit('release',origin if mode=='ARCADE' and origin.y>=380 else p,delta)
		fingers.erase(index)

func pointer_drag(index: int, position: Vector2) -> void:
	if not fingers.has(index): return
	var p := local_point(position)
	fingers[index].point = p
	pointer = p
	cursor = p
	routed.emit('drag',p,Vector2.ZERO)

func _process(delta: float) -> void:
	if not enabled: return
	var a := Vector2(float(keys.get(KEY_RIGHT,false) or keys.get(KEY_D,false) or keys.get(JOY_BUTTON_DPAD_RIGHT+10000,false))-float(keys.get(KEY_LEFT,false) or keys.get(KEY_A,false) or keys.get(JOY_BUTTON_DPAD_LEFT+10000,false)),float(keys.get(KEY_DOWN,false) or keys.get(KEY_S,false) or keys.get(JOY_BUTTON_DPAD_DOWN+10000,false))-float(keys.get(KEY_UP,false) or keys.get(KEY_W,false) or keys.get(JOY_BUTTON_DPAD_UP+10000,false)))
	if device == 'controller':
		a += stick_axis
		if a.length()<0.22: a = Vector2.ZERO
		if stick_axis.length()<0.3: stick_armed=true
		elif mode=='ARCADE' and stick_axis.length()>0.65 and stick_armed:
			stick_armed=false
			routed.emit('direction',cursor,Vector2(signf(stick_axis.x),0) if absf(stick_axis.x)>absf(stick_axis.y) else Vector2(0,signf(stick_axis.y)))
	# MOVE games use direct finger tracking. Mixing a virtual movement zone with
	# that same drag caused the basket to drift away from the player's thumb.
	a = a.limit_length()
	if a != axis:
		axis = a
		routed.emit('move',cursor,axis)
	if device in ['keyboard','controller'] and a.length()>0.1:
		cursor = (cursor + a*500*delta).clamp(Vector2(20,20),Vector2(940,460))
		if mode == 'DRAG': routed.emit('drag',cursor,Vector2.ZERO)
		if mode == 'SWIPE' and gesture_held: routed.emit('drag',cursor,Vector2.ZERO)

func keyboard_gesture(pressed: bool) -> void:
	if pressed:
		gesture_held = true
		gesture_start = cursor
		routed.emit('press',cursor,Vector2.ZERO)
	else:
		if not gesture_held: return
		gesture_held = false
		var delta: Vector2 = cursor-gesture_start
		if delta.length()>40: routed.emit('swipe',cursor,delta)
		routed.emit('release',cursor,delta)
