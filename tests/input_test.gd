extends SceneTree
const ROUTER = preload("res://core/input_router.gd")
const GAME = preload("res://microgames/pack_a.gd")
var failures: int=0
var checks: int=0
var events: Array=[]

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks+=1
	if not value:
		failures+=1
		print("FAIL input: ",message)

func key(router, code: int, pressed: bool) -> void:
	var event: InputEventKey=InputEventKey.new()
	event.physical_keycode=code
	event.pressed=pressed
	router._input(event)

func names() -> Array:
	return events.map(func(event:Dictionary): return event.action)

func run() -> void:
	var router=ROUTER.new()
	root.add_child(router)
	router.set_process(false)
	router.enabled=true
	router.board=Rect2(100,50,960,480)
	router.routed.connect(func(action:String,point:Vector2,value:Vector2): events.append({"action":action,"point":point,"value":value}))
	check(router.local_point(Vector2(580,290))==Vector2(480,240),"board coordinate mapping")
	router.mode="SWIPE"
	key(router,KEY_RIGHT,true)
	check(names()==["swipe"],"SWIPE keyboard emits exactly one swipe")
	check(events[0].value==Vector2(160,0),"SWIPE keyboard direction")
	key(router,KEY_RIGHT,false)
	router.reset()
	events.clear()
	router.mode="DIRECTIONAL"
	router.pointer_event(0,Vector2(280,430),true)
	check(names()==["press"],"DIRECTIONAL pointer uses explicit board affordance only")
	router.pointer_event(0,Vector2(280,430),false)
	check(names()==["press","release"],"directional tap is one press/release pair")
	events.clear()
	key(router,KEY_UP,true)
	check(names()==["direction"],"direction key emits one direction")
	key(router,KEY_UP,false)
	router.reset()
	events.clear()
	router.mode="SWIPE"
	router.pointer_event(0,Vector2(580,290),true)
	router.pointer_drag(0,Vector2(780,290))
	router.pointer_event(0,Vector2(780,290),false)
	check(names()==["press","drag","swipe","release"],"touch swipe event order")
	check(events[2].value==Vector2(200,0),"touch swipe displacement")
	check(router.fingers.is_empty(),"released finger clears")
	events.clear()
	router.pointer_event(0,Vector2(200,150),true)
	router.pointer_event(1,Vector2(400,150),true)
	router.pointer_event(2,Vector2(600,150),true)
	check(router.fingers.size()==2,"two simultaneous fingers accepted, third ignored")
	check(names()==["press","press"],"third finger has no action")
	key(router,KEY_LEFT,true)
	router.reset()
	check(router.fingers.is_empty() and router.keys.is_empty() and router.axis==Vector2.ZERO,"reset clears fingers, keys and axis")
	check(events[-1].action=="move" and events[-1].value==Vector2.ZERO,"reset emits neutral movement")
	events.clear()
	router.pointer_event(0,Vector2(-50,-50),true)
	check(events.is_empty() and router.fingers.is_empty(),"outside-board touch ignored")
	router.mode="HOLD"
	key(router,KEY_SPACE,true)
	key(router,KEY_SPACE,false)
	check(names()==["action","release"],"keyboard HOLD preserves release")
	events.clear()
	router.mode="DRAG"
	key(router,KEY_SPACE,true)
	key(router,KEY_SPACE,false)
	check(names()==["press","release"],"keyboard DRAG uses press/release")
	events.clear()
	router.enabled=false
	key(router,KEY_SPACE,true)
	check(events.is_empty(),"disabled router cannot affect a round")
	router.enabled=true
	integration_checks(router)
	router.free()
	print("INPUT: ",checks," checks; failures=",failures)
	quit(1 if failures>0 else 0)

func integration_checks(router) -> void:
	for id in ["safe_dial","word_sort","shield_turn","hold_balance","trace_wire","target_lock"]:
		router.reset()
		var game=GAME.new()
		root.add_child(game)
		game.set_process(false)
		game.start({"id":id,"duration":8},6.0,17)
		router.routed.connect(game.handle_action)
		match id:
			"safe_dial":
				router.mode="SWIPE"
				var turn: int=int(game.s.seq[0])
				router.pointer_event(0,Vector2(580,290),true)
				router.pointer_drag(0,Vector2(580+turn*180,290))
				router.pointer_event(0,Vector2(580+turn*180,290),false)
				check(game.s.n==1 and not game.finished,"safe dial physical touch swipe advances exactly once")
				key(router,KEY_RIGHT if int(game.s.seq[1])==1 else KEY_LEFT,true)
				check(game.s.n==2 and not game.finished,"safe dial keyboard swipe advances exactly once")
			"word_sort":
				router.mode="SWIPE"
				router.pointer_event(0,Vector2(580,290),true)
				router.pointer_drag(0,Vector2(380,290))
				router.pointer_event(0,Vector2(380,290),false)
				check(game.s.n==1 and not game.finished,"word sort swipe start does not commit wrong category")
			"shield_turn":
				router.mode="DIRECTIONAL"
				var pos: Vector2=Vector2(280+int(game.s.seq[0])*200,430)
				router.pointer_event(0,pos,true)
				router.pointer_event(0,pos,false)
				check(game.s.n==1 and not game.finished,"direction pad advances exactly once")
			"hold_balance":
				router.mode="HOLD"
				key(router,KEY_SPACE,true)
				game.advance(0.62/(0.30+6.0*0.035))
				key(router,KEY_SPACE,false)
				check(game.finished and game.points>0,"hold keyboard press and release can win")
			"trace_wire":
				router.mode="DRAG"
				router.pointer_event(0,Vector2(game.s.path[0])+Vector2(100,50),true)
				for i in range(1,game.s.path.size()): router.pointer_drag(0,Vector2(game.s.path[i])+Vector2(100,50))
				router.pointer_event(0,Vector2(game.s.path[-1])+Vector2(100,50),false)
				check(game.finished and game.points>0,"complete touch drag path wins")
			"target_lock":
				router.mode="TAP"
				for i in range(game.s.goal):
					router.cursor=game.s.target
					key(router,KEY_SPACE,true)
					key(router,KEY_SPACE,false)
				check(game.finished and game.points>0,"virtual cursor Space targets can win")
		router.routed.disconnect(game.handle_action)
		game.free()
