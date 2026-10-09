extends SceneTree
## Native Godot event integration, not synthetic calls to game action handlers.
## Event delivery is through Input.parse_input_event -> InputRouter -> module.
const ROUTER = preload("res://core/input_router.gd")
var router
var target
var events: Array[Dictionary] = []
var checks: int = 0
var failures: int = 0
var pause_requests: int = 0
var result: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; print("FAIL MOBILE: ",message)

func names() -> Array:
	return events.map(func(event:Dictionary): return event.action)

func count_action(action: String) -> int:
	var count: int = 0
	for event in events:
		if event.action==action: count+=1
	return count

func native_position(point: Vector2) -> Vector2:
	return router.board.position+point*(router.board.size.x/960.0)

func key(code: int,pressed: bool,echo: bool=false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode=code; event.keycode=code; event.pressed=pressed; event.echo=echo
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func touch(index: int,point: Vector2,pressed: bool,canceled: bool=false) -> void:
	var event := InputEventScreenTouch.new()
	event.index=index; event.position=native_position(point); event.pressed=pressed; event.canceled=canceled
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func drag(index: int,point: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index=index; event.position=native_position(point)
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func joy(button: int,pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device=0; event.button_index=button; event.pressed=pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func stick(axis: int,value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device=0; event.axis=axis; event.axis_value=value
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func touch_tap(point: Vector2) -> void:
	touch(0,point,true); touch(0,point,false)

func bind(script: String,id: String,input_mode: String) -> void:
	unbind()
	router.reset(); router.mode=input_mode; router.enabled=true
	events.clear()
	target=load(script).new()
	root.add_child(target); target.set_process(false)
	target.start({"id":id,"name":id,"duration":60},1,17)
	result={"events":0,"won":false,"score":0}
	var receipt: Dictionary=result
	target.completed.connect(func(won:bool,score:int): receipt.events=int(receipt.events)+1; receipt.won=won; receipt.score=score)
	router.routed.connect(target.handle_action)

func unbind() -> void:
	if is_instance_valid(target):
		router.routed.disconnect(target.handle_action)
		target.free()
		target=null

func simulate(seconds: float) -> void:
	var remaining: float=seconds
	while remaining>0 and not target.finished:
		var dt: float=minf(0.02,remaining)
		target.advance(dt); remaining-=dt

func interrupt_round() -> void:
	# The app's focus/orientation pause contract cancels the module, clears input,
	# disables routing, then stops game time; it must not synthesize release.
	router.enabled=false
	target.cancel_input()
	router.reset()
	target.active=false

func run() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(1600,900)
	router=ROUTER.new()
	root.add_child(router); router.set_process(false); router.enabled=true
	router.set_process_input(true)
	router.board=Rect2(37,91,672,336)
	router.routed.connect(func(action:String,point:Vector2,value:Vector2): events.append({"action":action,"point":point,"value":value}))
	router.pause_requested.connect(func(): pause_requests+=1)
	await process_frame
	raw_event_checks()
	puzzle_checks()
	cancellation_checks()
	parking_checks()
	duel_checks()
	new_game_checks()
	unbind(); router.free()
	print("MOBILE CONTROLS: ",checks," native-event checks; failures=",failures)
	quit(1 if failures>0 else 0)

func raw_event_checks() -> void:
	for board in [Rect2(37,91,672,336),Rect2(90,130,960,480),Rect2(12,260,360,180),Rect2(44,45,1200,600)]:
		router.reset(); events.clear(); router.board=board; router.mode="TAP"
		touch(0,Vector2(325,215),true); touch(0,Vector2(325,215),false)
		check(names()==["press","release"],"screen touch is one pair at scale "+str(board.size.x))
		check(events.size()>=2 and Vector2(events[0].point).is_equal_approx(Vector2(325,215)),"touch maps through board offset and scale")
		check(router.fingers.is_empty(),"touch release cleans its native finger")
	router.board=Rect2(37,91,672,336)
	router.reset(); events.clear(); router.mode="SWIPE"
	touch(4,Vector2(200,180),true); drag(4,Vector2(420,180)); touch(4,Vector2(420,180),false)
	check(names()==["press","drag","swipe","release"],"native drag/swipe lifecycle uses finger index 4")
	check(events.size()>=3 and Vector2(events[2].value).is_equal_approx(Vector2(220,0)),"swipe displacement uses logical pixels")
	router.reset(); events.clear()
	touch(3,Vector2(200,180),true); drag(3,Vector2(420,180)); touch(3,Vector2(420,180),false,true)
	check(names()==["press","drag","cancel"],"canceled native swipe cannot emit swipe or release")
	check(router.fingers.is_empty(),"canceled finger removed")
	events.clear(); touch(3,Vector2(420,180),false); drag(3,Vector2(520,180))
	check(events.is_empty(),"late drag and release after cancellation ignored")
	router.mode="HOLD"; router.reset(); events.clear()
	touch(0,Vector2(250,220),true); touch(1,Vector2(650,220),true); touch(2,Vector2(480,220),true)
	check(router.fingers.size()==2 and count_action("press")==2,"two fingers accepted and third rejected")
	touch(0,Vector2(250,220),false)
	check(router.fingers.size()==1 and count_action("release")==0,"HOLD remains pressed while second finger survives")
	touch(1,Vector2(650,220),false)
	check(router.fingers.is_empty() and count_action("release")==1,"last HOLD finger releases exactly once")
	router.mode="ARCADE"; router.reset(); events.clear()
	for code in [KEY_1,KEY_2,KEY_3,KEY_4]: key(code,true); key(code,false)
	check(names()==["select","select","select","select"],"1-4 canonical selections emit once")
	check(events.size()==4 and events[0].value.x==1 and events[3].value.x==4,"selection values are 1-based")
	events.clear()
	for code in [KEY_R,KEY_U,KEY_E]: key(code,true); key(code,false)
	check(names()==["reset","undo","secondary"],"R/U/E semantic shortcut packets")
	router.reset(); events.clear(); key(KEY_RIGHT,true); router._process(0.05); router._process(0.05)
	check(count_action("direction")==1,"one ARCADE arrow press is one discrete direction")
	check(router.axis==Vector2.RIGHT,"held arrow retains movement axis")
	key(KEY_RIGHT,false); router._process(0.05)
	check(router.axis==Vector2.ZERO,"arrow release neutralizes movement")
	var recorded: int=events.size(); key(KEY_RIGHT,true,true)
	check(events.size()==recorded,"keyboard repeat cannot issue a second command")
	router.reset(); events.clear(); joy(JOY_BUTTON_DPAD_UP,true); router._process(0.05); router._process(0.05)
	check(count_action("direction")==1,"D-pad does not double-trigger on its movement transition")
	joy(JOY_BUTTON_DPAD_UP,false); router._process(0.01)
	check(router.axis==Vector2.ZERO,"D-pad release returns neutral")
	router.reset(); events.clear(); stick(JOY_AXIS_LEFT_X,0.1); router._process(0.01)
	check(router.axis==Vector2.ZERO and count_action("direction")==0,"stick dead zone rejects drift")
	stick(JOY_AXIS_LEFT_X,0.85); router._process(0.02); router._process(0.02)
	check(count_action("direction")==1 and router.axis.x>0.8,"analog threshold emits one command with continuous motion")
	stick(JOY_AXIS_LEFT_X,0); router._process(0.02); stick(JOY_AXIS_LEFT_X,0.9); router._process(0.02)
	check(count_action("direction")==2,"stick neutral rearms the next discrete command")
	stick(JOY_AXIS_LEFT_X,0); router._process(0.01)
	router.reset(); events.clear(); joy(JOY_BUTTON_A,true); joy(JOY_BUTTON_A,false); joy(JOY_BUTTON_B,true); joy(JOY_BUTTON_B,false)
	check(names()==["action","release","secondary"],"controller A/B action, release, secondary")
	router.mode="SWIPE"; router.reset(); events.clear(); router.cursor=Vector2(200,200)
	key(KEY_SPACE,true); key(KEY_RIGHT,true); router._process(0.3); key(KEY_RIGHT,false); router._process(0.01); key(KEY_SPACE,false)
	check(count_action("swipe")==1 and count_action("release")==1,"Space plus arrows creates one precision swipe")
	check(not router.gesture_held,"keyboard gesture ends on release")
	router.reset(); events.clear(); router.enabled=false
	key(KEY_SPACE,true); touch(0,Vector2(480,240),true); joy(JOY_BUTTON_A,true)
	check(events.is_empty() and router.fingers.is_empty(),"disabled input cannot arm gameplay")
	key(KEY_ESCAPE,true); joy(JOY_BUTTON_START,true)
	check(pause_requests==2,"Escape and Start request pause while routing disabled")
	key(KEY_ESCAPE,false); joy(JOY_BUTTON_START,false)
	router.enabled=true; router.mode="TAP"; router.reset(); events.clear()
	var cursor_before: Vector2=router.cursor
	touch(0,Vector2(-150,-200),true); touch(0,Vector2(-150,-200),false)
	check(events.is_empty() and router.fingers.is_empty(),"outside-board touches do not launch actions")
	check(router.cursor==cursor_before,"rejected outside touch preserves the gameplay cursor")
	var emulated := InputEventMouseButton.new()
	emulated.device=-1; emulated.button_index=MOUSE_BUTTON_LEFT; emulated.pressed=true; emulated.position=native_position(Vector2(400,200))
	Input.parse_input_event(emulated)
	check(events.is_empty(),"emulated mouse cannot duplicate a touch")

func puzzle_checks() -> void:
	bind("res://microgames/pack_c.gd","water_sort","ARCADE")
	var original: Array=target.s.tubes.duplicate(true)
	var source: int=-1
	var destination: int=-1
	for i in 4:
		if target.s.tubes[i].is_empty() and destination<0: destination=i
		elif not target.s.tubes[i].is_empty() and source<0: source=i
	key(KEY_1+source,true); key(KEY_1+source,false); key(KEY_1+destination,true); key(KEY_1+destination,false)
	check(target.s.moves==1 and target.s.tubes!=original,"real puzzle pours through 1-4 router keys")
	key(KEY_U,true); key(KEY_U,false)
	check(target.s.tubes==original and target.s.moves==0,"real puzzle undo through U")
	target.cancel_input()
	touch_tap(Vector2(240+source*150,230)); touch_tap(Vector2(240+destination*150,230))
	check(target.s.moves==1,"same puzzle can pour through scaled native touches")
	var elapsed_before: float=target.elapsed
	key(KEY_R,true); key(KEY_R,false)
	check(target.s.tubes==original and target.elapsed==elapsed_before,"R resets board without refilling timer")
	bind("res://microgames/pack_c.gd","minesweeper","ARCADE")
	key(KEY_E,true); key(KEY_E,false)
	check(target.s.flag_mode,"E changes the actual mine tool")
	joy(JOY_BUTTON_B,true); joy(JOY_BUTTON_B,false)
	check(not target.s.flag_mode,"B changes the same mine tool")
	router.cursor=target.cell_center(1)
	key(KEY_SPACE,true); key(KEY_SPACE,false)
	check(target.s.revealed.has(1) and not target.finished,"Space acts at a real puzzle cursor target")
	bind("res://microgames/pack_c.gd","sokoban","ARCADE")
	key(KEY_RIGHT,true); router._process(0.1); key(KEY_RIGHT,false); router._process(0.01)
	check(target.s.player==17,"one keyboard arrow moves the crate player exactly one tile")

func cancellation_checks() -> void:
	bind("res://microgames/pack_a.gd","hold_balance","HOLD")
	key(KEY_SPACE,true); simulate(0.62/0.335)
	check(target.s.held and not target.finished,"keyboard holds an actual charged round at its success level")
	var charged: float=target.s.value
	var paused_at: float=target.elapsed
	interrupt_round(); target.advance(3)
	check(not target.s.held and not target.finished and result.events==0,"focus pause cancels hold without winning")
	check(target.elapsed==paused_at and target.s.value==charged,"pause preserves charge and freezes time")
	check(router.fingers.is_empty() and router.keys.is_empty() and router.axis==Vector2.ZERO,"focus reset clears all controls")
	router.board=Rect2(10,240,360,180); router.enabled=true; target.active=true
	events.clear(); key(KEY_SPACE,false)
	check(count_action("release")==0 and not target.finished,"orphan Space release after focus reset cannot complete charge")
	bind("res://microgames/pack_b.gd","spring_vault","HOLD")
	touch(0,Vector2(200,280),true); simulate(0.7)
	touch(0,Vector2(200,280),false,true)
	check(not target.held and not target.launched and result.events==0,"canceled spring touch clears hold without launching")
	bind("res://microgames/pack_b.gd","spring_vault","HOLD")
	joy(JOY_BUTTON_A,true); simulate(0.5); interrupt_round()
	router.enabled=true; target.active=true; events.clear(); joy(JOY_BUTTON_A,false)
	check(count_action("release")==0 and not target.launched,"orphan controller A release cannot fire a paused spring")
	bind("res://games/classics_b/bridge_builder.gd","bridge_builder","HOLD")
	touch(0,Vector2(480,200),true); simulate(0.5)
	check(target.holding and target.phase=="growing" and target.plank_length>50,"touch grows an actual bridge")
	interrupt_round()
	check(not target.holding and target.phase=="growing" and result.events==0,"orientation/module cancel does not lower a bridge")
	router.enabled=true; target.active=true
	touch(0,Vector2(480,200),false)
	check(target.phase=="growing" and target.crossings==0,"old finger release cannot commit the interrupted bridge")
	bind("res://games/classics_a/catapult_chaos.gd","catapult_chaos","DRAG")
	touch(0,target.anchor,true); drag(0,target.anchor+Vector2(-75,65))
	check(target.pulling and target.aim!=target.anchor,"scaled native drag pulls the real catapult")
	touch(0,target.anchor+Vector2(-75,65),false,true)
	check(not target.pulling and target.balls.is_empty() and target.ammo==5,"canceled drag cannot spend a shot or launch")
	check(count_action("swipe")==0,"canceled catapult has no swipe side effect")
	touch(0,target.anchor,true); drag(0,target.anchor+Vector2(-75,65)); touch(0,target.anchor+Vector2(-75,65),false)
	check(target.balls.size()==1 and target.ammo==4,"a fresh drag still launches after cancellation")
	bind("res://microgames/pack_b.gd","armor_repair","DRAG")
	touch(0,target.items[0],true); drag(0,Vector2(400,140)); touch(0,Vector2(400,140),false,true)
	check(target.selected==-1 and target.progress==0,"canceled repair drag clears selection without placement")
	drag(0,target.marks[0]); touch(0,target.marks[0],false)
	check(target.progress==0,"orphan repair drag and release cannot place a plate")
	touch(0,target.items[0],true); drag(0,target.marks[0]); touch(0,target.marks[0],false)
	check(target.progress==1 and not target.finished,"fresh scaled repair drag places exactly one plate")
	router.board=Rect2(37,91,672,336)

func parking_checks() -> void:
	bind("res://games/chaos.gd","impossible_parking","ARCADE")
	var start_position: Vector2=target.s.p
	touch(0,target.button_area(1).get_center(),true)
	touch(1,target.button_area(3).get_center(),true)
	check(target.s.steer==1 and target.s.throttle==1,"Parking holds steering and gas on two fingers")
	simulate(0.5)
	check(target.s.p.distance_to(start_position)>5 and target.s.angle>0,"two-finger controls produce vehicle motion and steering")
	drag(0,Vector2(930,280)); touch(0,Vector2(930,280),false)
	check(target.s.steer==0 and target.s.throttle==1,"steering release outside its button preserves gas")
	drag(1,Vector2(80,280)); touch(1,Vector2(80,280),false)
	check(target.s.steer==0 and target.s.throttle==0,"gas release outside its button clears the originating control")
	touch(0,target.button_area(0).get_center(),true); touch(1,target.button_area(2).get_center(),true)
	check(target.s.steer==-1 and target.s.throttle==-1,"reverse and opposite steering coexist")
	touch(2,target.button_area(3).get_center(),true)
	check(target.s.throttle==-1 and router.fingers.size()==2,"third finger cannot override the two accepted parking controls")
	interrupt_round()
	check(target.s.steer==0 and target.s.throttle==0 and router.fingers.is_empty(),"parking focus cancellation neutralizes both fingers")
	check(not target.finished and result.events==0,"parking pause does not end the session")

func approach_duel() -> void:
	for step in 250:
		if target.state=="windup": break
		simulate(0.02)
	check(target.state=="windup","duel reaches its actual enemy attack telegraph")
	key(KEY_RIGHT,true); router._process(0.01); simulate(0.2); key(KEY_RIGHT,false); router._process(0.01)
	check(absf(target.enemy_x-target.player_x)<115,"arrow motion closes to a valid melee range")

func duel_checks() -> void:
	bind("res://games/classics_a/shadow_armor_duel.gd","shadow_armor_duel","ARCADE")
	approach_duel()
	var health_before: int=target.health
	var enemy_before: int=target.enemy_hp
	var score_before: int=target.score
	touch(0,target.button_area(2).get_center(),true)
	touch(1,target.button_area(3).get_center(),true)
	check(target.blocking>0 and target.enemy_hp<enemy_before,"two touches block and land a real punch")
	touch(1,target.button_area(3).get_center(),false)
	check(target.blocking>0,"releasing the punch leaves the block active")
	simulate(0.5)
	check(target.health==health_before and target.score>=score_before+25,"block prevents enemy damage and awards confirmed guard score")
	touch(0,target.button_area(2).get_center(),false)
	bind("res://games/classics_a/shadow_armor_duel.gd","shadow_armor_duel","ARCADE")
	approach_duel(); health_before=target.health; enemy_before=target.enemy_hp
	joy(JOY_BUTTON_B,true); joy(JOY_BUTTON_B,false); joy(JOY_BUTTON_A,true); joy(JOY_BUTTON_A,false)
	check(target.blocking>0 and target.enemy_hp<enemy_before,"controller B guards while A punches")
	simulate(0.5)
	check(target.health==health_before,"controller guard survives the actual enemy strike")
	interrupt_round()
	check(target.axis==Vector2.ZERO and not target.held,"duel focus reset stops motion")

func new_game_checks() -> void:
	bind("res://games/classics_a/jetpack_test_lab.gd","jetpack_test_lab","HOLD")
	touch(0,Vector2(210,210),true); touch(1,Vector2(620,210),true)
	check(target.held,"jetpack accepts a two-finger hold")
	touch(0,Vector2(210,210),false)
	check(target.held,"jetpack keeps flying with the second finger")
	touch(1,Vector2(620,210),false)
	check(not target.held,"jetpack falls only after the final finger releases")
	bind("res://games/classics_a/metro_armor_rush.gd","metro_armor_rush","ARCADE")
	var lane: int=target.lane
	key(KEY_LEFT,true); router._process(0.1); key(KEY_LEFT,false); router._process(0.01)
	check(target.lane==maxi(0,lane-1),"runner keyboard moves one lane per press")
	joy(JOY_BUTTON_DPAD_RIGHT,true); router._process(0.05); joy(JOY_BUTTON_DPAD_RIGHT,false); router._process(0.01)
	check(target.lane==lane,"runner D-pad moves one lane back")
	key(KEY_SPACE,true); key(KEY_SPACE,false)
	check(target.jump>0,"runner Space starts the real jump")
	bind("res://games/classics_b/reactor_merge.gd","reactor_merge","ARCADE")
	# A single direction must mutate one move, rather than causing two random spawns.
	var before: Array=target.tiles.duplicate()
	key(KEY_LEFT,true); router._process(0.05); key(KEY_LEFT,false); router._process(0.01)
	check(count_action("direction")==1,"merge receives one discrete arrow command")
	key(KEY_U,true); key(KEY_U,false)
	check(target.tiles==before,"merge U reverses the exact single move")
