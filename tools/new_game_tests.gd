extends Node
var failures: Array[String] = []
var assertions := 0
var saved := ""
var had_save := false
func check(value: bool,label: String) -> void:
	assertions+=1
	print(("PASS " if value else "FAIL ")+label)
	if not value:failures.append(label)
func _ready() -> void:
	had_save=FileAccess.file_exists(Global.SAVE_PATH)
	if had_save:saved=FileAccess.get_file_as_string(Global.SAVE_PATH)
	call_deferred("run")
func fresh(id: String,auto_start: bool = true):
	GameManager.transition_locked=true
	var game=load("res://scenes/arcade/"+id+".tscn").instantiate()
	add_child(game)
	game.set_physics_process(false)
	if auto_start:game.begin_play()
	return game
func frame(game,delta: float) -> void:
	var steps=maxi(1,ceili(delta/0.016667))
	for i in range(steps):game._physics_process(delta/steps)
func run() -> void:
	for entry in preload("res://scripts/arcade/ArcadeCatalog.gd").GAMES:
		var game=fresh(entry[0],false)
		await get_tree().process_frame
		check(game.game_id==entry[0] and not game.ended,"Cabinet loads and draws: "+entry[1])
		check(game.preparing and not game.metadata["controls"].is_empty() and not game.metadata["touch_controls"].is_empty(),"Cabinet has a playable keyboard and phone briefing: "+entry[0])
		frame(game,0.5)
		check(game.elapsed==0 and not game.ended,"Reading the briefing cannot lose a life or advance time: "+entry[0])
		game.action_event("primary",true)
		check(not game.preparing and game.held.is_empty(),"Start press is consumed before gameplay: "+entry[0])
		frame(game,1.0/60)
		game.toggle_pause()
		var clock:float=game.elapsed
		frame(game,0.5)
		check(game.elapsed==clock,"Pause freezes cabinet: "+entry[0])
		game.toggle_pause()
		game.free()
	test_cabinet_regressions()
	test_input_regressions()
	var game=fresh("dino_dash")
	for i in range(3):game.spawn_clock=0;frame(game,0.01)
	var ground_only:=true
	for obstacle in game.obstacles:
		if obstacle["flyer"]:ground_only=false
	check(ground_only and game.obstacles.size()==3,"Dino opening teaches three ground obstacles")
	game.on_action("primary")
	check(game.runner_v<0,"Dino jump responds immediately")
	game.runner_y=446;game.runner_v=0;game.obstacles.assign([{"rect":Rect2(180,480,28,20),"flyer":false}])
	frame(game,0.01)
	check(game.ended and not game.won and game.lives==0,"Dino ground collision ends an endless run and consumes its life")
	game.free()
	game=fresh("grid_x")
	var guard:=0
	while not game.ended and guard<40:
		guard+=1
		if game.awaiting:game.on_action("primary");continue
		var best:=1000;var choice:=-1
		for i in range(9):
			if game.cells[i]!=0:continue
			var copy:Array=game.cells.duplicate();copy[i]=1
			var result:int=game.minimax(copy,true)
			if result<best:best=result;choice=i
		if choice>=0:game.place_x(choice)
	check(game.won and game.stage==3,"Grid X: actual placements clear three opponents with wins or draws")
	game.free()
	game=fresh("paddle_panic")
	game.ball_v=Vector2(-350,0);game.paddle_return(1,0);var center_angle:float=absf(game.ball_v.y)
	game.paddle_return(1,0.9)
	check(absf(game.ball_v.y)>center_angle,"Paddle edges change the return angle")
	for i in range(5):game.ready_ball=false;game.ball=Vector2(1230,300);game.ball_v=Vector2(350,0);frame(game,0.01)
	check(game.won and game.player_points==5,"Paddle first-to-five scoring ends the match")
	game.free()
	game=fresh("sidecourt")
	game.lob=true;game.hit_tennis(true);var lob_velocity:float=game.ball_v.y
	game.lob=false;game.hit_tennis(true)
	check(lob_velocity<game.ball_v.y,"Tennis lob has a higher arc than drive")
	for i in range(5):game.ready_ball=false;game.ball=Vector2(900,506);game.ball_v=Vector2(0,50);game.bounces=[0,1];frame(game,0.01)
	check(game.won and game.player_points==5,"Tennis two bounces award points and first to five wins")
	game.free()
	game=fresh("brick_burst")
	var brick:Dictionary=game.bricks[0]
	game.ready_ball=false;game.ball=brick["rect"].get_center();game.ball_v=Vector2(0,-350)
	frame(game,0.01)
	check(game.score>0,"Brick ball collision damages a brick")
	game.chips.assign([{"at":Vector2(game.paddle_x,490),"wide":true}])
	frame(game,0.01)
	check(game.wide_time>7,"WIDE pickup applies a timed paddle effect")
	for i in range(3):game.ready_ball=false;game.ball=Vector2(600,550);game.ball_v=Vector2(0,350);frame(game,0.01)
	check(game.ended and not game.won,"Brick Burst ends after three lost balls")
	game.free()
	game=fresh("dark_cavern")
	for target in [1,2,8]:cavern_walk(game,target)
	game.tunnel=game.neighbors(game.room).find(7);game.on_action("secondary");game.on_action("primary")
	check(not game.creature_alive and game.bolts==2,"Cavern aimed bolt defeats the adjacent creature")
	game.on_action("secondary")
	for target in [7,6,0,11,10,11,0]:cavern_walk(game,target)
	check(game.won and game.found.size()==2,"Cavern deduction route recovers both caches and returns to entrance")
	game.free()
	game=fresh("byte_munch")
	game.snake.assign([Vector2i(2,2),Vector2i(2,3),Vector2i(1,3),Vector2i(1,2)])
	game.direction=Vector2i.LEFT;game.food=Vector2i(20,2)
	frame(game,0.21)
	check(not game.ended and game.snake[0]==Vector2i(1,2),"Snake may enter the tail cell vacated on the same step")
	game.queue_turn(Vector2i.RIGHT)
	check(game.turns.is_empty(),"Snake rejects an immediate reverse turn")
	game.snake.assign([Vector2i(0,0),Vector2i(1,0)]);game.direction=Vector2i.LEFT;frame(game,0.21)
	check(game.ended and game.lives==0,"Snake wall collision ends survival and consumes its life")
	game.free()
	game=fresh("dot_gobbler")
	for level in [1,2]:
		game.stage=level;game.make_maze()
		var seen:Dictionary={Vector2i(1,1):true};var queue:Array=[Vector2i(1,1)]
		while not queue.is_empty():
			var at:Vector2i=queue.pop_front()
			for dir in game.DIRECTIONS:
				var next:Vector2i=at+dir
				if not game.walls.has(next) and not seen.has(next):seen[next]=true;queue.append(next)
		check(seen.size()==game.grid.size()+1,"Original maze %d has no unreachable dots" % level)
		game.grid={Vector2i(2,1):true};game.player=Vector2i(1,1);game.requested=Vector2i.RIGHT;game.step_clock=0
		frame(game,0.14)
	check(game.won,"Both maze clears reach a proper ending")
	game.free()
	game=fresh("hopway")
	check(game.lives==4,"Hopway starts with four lives")
	for round_value in range(3):
		for col in [1,4,8,11]:game.frog=Vector2(col*34+17,17);frame(game,0.01)
	check(game.won and game.stage==3,"Hopway requires twelve unique home arrivals across three rounds")
	game.free()
	game=fresh("color_steps")
	for level in range(3):
		for coat in range(game.coats):
			var seen:Dictionary={}
			paint_walk(game,seen)
		if level<2:game.on_action("primary")
	check(game.won and game.coats==2,"Diagonal hopping paints all three pyramids, including final double coat")
	game.free()
	game=fresh("crate_shift")
	var solutions=JSON.parse_string(FileAccess.get_file_as_string("res://tools/warehouse_solutions.json"))
	for level in range(5):
		for action in solutions[level]:game.on_action(action)
		check(game.awaiting or game.won,"Warehouse %d is solved through legal directional pushes" % (level+1))
		if level<4:game.on_action("primary")
	check(game.won,"All five warehouse rooms reach a clear ending")
	game.free()
	game=fresh("crate_shift")
	var origin:Vector2i=game.player
	game.on_action("left");game.on_action("secondary")
	check(game.player==origin and not game.awaiting,"Warehouse undo restores player and crate state")
	game.free()
	game=fresh("stackfall")
	for group in range(6):
		game.grid.clear()
		for y in range(14,18):
			for x in range(9):game.grid[Vector2i(x,y)]=1
		game.piece_kind=0;game.piece.assign(game.SHAPES[0]);game.piece_at=Vector2i(9,15)
		game.rotate_piece(1);game.lock_piece()
	check(game.won and game.lines_cleared==24,"Six legal vertical I pieces clear exactly 24 rows")
	game.free()
	for id in ["orbit_duel","rock_drift"]:
		game=fresh(id)
		game.velocity=Vector2(120,0);game.held["secondary"]=true;frame(game,0.016)
		check(game.velocity.length()<120,"Space brake counters momentum: "+id)
		game.free()
	game=fresh("orbit_duel")
	for rival in range(3):
		for hit in range(3):game.bullets.assign([{"at":game.rival,"v":Vector2.ZERO,"life":1.0,"enemy":false}]);frame(game,0)
	check(game.won,"Orbit Duel destroys three rival drones via projectile hits")
	game.free()
	game=fresh("rock_drift")
	var rock:Dictionary=game.rocks[0];game.split_rock(rock)
	check(not rock["alive"] and game.rocks.size()==5,"Large drifting rock splits into two smaller threats")
	game.free()
	game=fresh("soft_landing")
	game.ship=Vector2(game.pad_x,491);game.velocity=Vector2(20.1,20);frame(game,0)
	check(game.lives==2 and game.waiting and not game.landed and game.stage==1,"Lander rejects sideways speed above 20 and preserves current pad")
	game.on_action("primary")
	for pad in range(3):
		game.ship=Vector2(game.pad_x,490);game.velocity=Vector2(20,28);game.angle=0;frame(game,0)
		if pad<2:game.on_action("primary")
	check(game.won and game.stage==3,"Lander accepts boundary-safe speeds and completes three pads")
	game.free()
	game=fresh("armored_arena")
	game.shots.assign([{"at":Vector2(330,300),"v":Vector2(470,0),"enemy":false,"life":1.0}])
	frame(game,0.05)
	check(game.shots.is_empty(),"Arena walls stop friendly shells")
	for enemy in game.enemies:
		var embedded:=false
		for wall in game.walls:
			if wall.has_point(enemy["at"]):embedded=true
		check(not embedded,"Arena enemy spawn is outside all walls")
	game.free()
	game=fresh("invader_patrol")
	var block:Dictionary=game.barriers[0]
	game.shots.assign([{"at":block["rect"].get_center(),"v":Vector2.ZERO,"enemy":true,"life":1.0}])
	frame(game,0)
	check(block["hp"]==1,"Protective barrier absorbs and wears under incoming fire")
	game.free()
	game=fresh("flag_run")
	game.fuel=50;game.on_action("primary")
	check(game.fuel==38,"Flag Run smoke costs exactly 12 fuel")
	for district in range(3):
		for pickup in game.pickups:
			if pickup["flag"]:game.player=pickup["at"];frame(game,0)
		game.player=Vector2(130,480);frame(game,0)
	check(game.won,"Six flags and return to exit complete each of three districts")
	game.free()
	game=fresh("sky_shield")
	game.enemy_clock=99;game.aim=Vector2(640,300);game.enemies.assign([{"at":Vector2(640,305),"v":Vector2.ZERO,"target":1,"alive":true},{"at":Vector2(655,305),"v":Vector2.ZERO,"target":1,"alive":true}])
	game.on_action("primary")
	for i in range(70):frame(game,0.016)
	check(game.ammo==19 and game.score==200,"One expanding interceptor catches two missiles with limited ammo")
	game.free()
	game=fresh("bug_blaster")
	game.mushrooms={Vector2i(5,4):2}
	game.shots.assign([{"at":Vector2(90+5*52+20,150+4*37+10),"v":Vector2.ZERO,"life":1.0,"enemy":false}])
	frame(game,0)
	check(game.mushrooms[Vector2i(5,4)]==1,"Garden mushrooms absorb shots before enemies")
	game.free()
	for id in ["armored_arena","invader_patrol","bug_blaster"]:
		game=fresh(id)
		var cabinet_guard:=0
		while not game.ended and cabinet_guard<400:
			cabinet_guard+=1
			if game.waiting:game.on_action("primary");continue
			if game.enemies.is_empty():frame(game,0);continue
			var target:Vector2=game.enemies[0]["at"]
			game.shots.append({"at":target,"v":Vector2.ZERO,"enemy":false,"life":1.0})
			frame(game,0)
		check(game.won and game.stage==3,"Projectile kills progress through all three stages: "+id)
		game.free()
	game=fresh("rock_drift")
	var rock_guard:=0
	while not game.ended and rock_guard<300:
		rock_guard+=1
		if game.waiting:game.on_action("primary");continue
		if game.rocks.is_empty():frame(game,0);continue
		game.bullets.append({"at":game.rocks[0]["at"],"v":Vector2.ZERO,"enemy":false,"life":1.0})
		frame(game,0)
	check(game.won and game.stage==3,"Rock splitting and real hits clear all three debris fields")
	game.free()
	game=fresh("sky_shield")
	var marked:Array=[]
	for i in range(60*60):
		if game.waiting:game.on_action("primary");marked.clear()
		for missile in game.enemies:
			if not marked.has(missile):
				marked.append(missile)
				var flight:float=Vector2(missile["at"]).distance_to(Vector2(640,515))/460
				game.aim=Vector2(missile["at"])+Vector2(missile["v"])*flight
				game.on_action("primary")
		frame(game,1.0/60)
		if game.ended:break
	check(game.won and game.stage==3,"Interception pilot protects outposts through all three missile waves")
	game.free()
	await test_adventure()
	Global.record_arcade("dino_dash",1234,false,2)
	Global.arcade_records.clear();Global.load_data()
	check(Global.arcade_records.get("dino_dash",{}).get("best",0)>=1234,"Arcade best records survive save/reload")
	if had_save:
		var f=FileAccess.open(Global.SAVE_PATH,FileAccess.WRITE);f.store_string(saved);f.close()
	else:DirAccess.remove_absolute(Global.SAVE_PATH)
	Music.stop_music()
	await get_tree().create_timer(0.5).timeout
	print("NEW GAME TESTS: %d assertions, %d failures" % [assertions,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
func cavern_walk(game,target: int) -> void:
	game.tunnel=game.neighbors(game.room).find(target)
	game.on_action("primary")
func test_cabinet_regressions() -> void:
	var game=fresh("grid_x",false)
	var start=InputEventKey.new()
	start.physical_keycode=KEY_ENTER;start.pressed=true
	game._input(start)
	check(not game.preparing,"Enter starts a cabinet through the actual InputMap")
	game.cursor=2;game.on_action("right")
	check(game.cursor==2,"Grid X selection stops at the right edge of a row")
	game.cursor=6;game.on_action("left")
	check(game.cursor==6,"Grid X selection stops at the left edge of a row")
	game.invulnerable=1;game._physics_process(2)
	check(is_equal_approx(game.elapsed,0.05) and is_equal_approx(game.invulnerable,0.95),"A slow frame advances timers by the same bounded simulation step")
	game.stage=2;game.cells=[2,2,2,0,1,0,1,0,0];game.finish_x()
	game.pointer_event(Vector2(450,220),true)
	check(game.stage==2 and not game.awaiting and game.cells.count(0)==9,"A board tap retries the lost Grid X terminal without losing earlier clears")
	game.free()
	game=fresh("sidecourt")
	game.player_points=4;game.last_hit=0;game.ready_ball=false
	game.ball=Vector2(1220,506);game.ball_v=Vector2(0,50);game.bounces=[0,1]
	frame(game,0)
	check(game.won and game.player_points==5 and game.rival_points==0,"A tennis bounce beyond the boundary awards exactly one point")
	game.free()
	game=fresh("flag_run")
	var touch=InputEventScreenTouch.new()
	touch.index=7;touch.pressed=true;touch.position=Vector2(500,480)
	game._input(touch)
	frame(game,0.25)
	var one_drag_x:float=game.player.x
	check(one_drag_x>190,"Holding a stationary road finger keeps the car driving")
	touch.pressed=false;game._input(touch)
	frame(game,0.25)
	check(is_equal_approx(game.player.x,one_drag_x),"Lifting the road finger stops touch steering")
	game.player=Vector2(130,480);game.pointer_down=true;game.pointer=Vector2(500,480)
	for i in range(100):
		game.on_drag(Vector2(500,480));frame(game,0.0025)
	check(absf(game.player.x-one_drag_x)<0.1,"Driving speed is independent of drag event frequency")
	game.free()
	game=fresh("sky_shield")
	game.waiting=true
	game.pointer_event(Vector2(640,300),true)
	check(game.stage==2 and not game.waiting and game.ammo==24 and game.shots.is_empty(),"A tap starts the next missile wave without wasting ammunition")
	game.free()
	game=fresh("rock_drift")
	game.waiting=true;game.rocks.clear()
	game.pointer_event(Vector2(640,300),true)
	check(game.stage==2 and not game.waiting and game.rocks.size()==4,"A tap starts the next debris field")
	game.free()
	game=fresh("soft_landing")
	game.lander_crash();game.pointer_event(Vector2(640,300),true)
	check(game.stage==1 and game.lives==2 and not game.waiting,"A tap retries the crashed landing pad and preserves the lost hull")
	game.free()
	game=fresh("crate_shift")
	game.on_action("left")
	check(game.awaiting and game.score==300,"A solved warehouse awards its clear once")
	game.on_action("secondary")
	check(not game.awaiting and game.score==0,"Undo rolls back the warehouse clear score")
	game.on_action("left")
	check(game.awaiting and game.score==300,"Undo and re-solving cannot farm extra clear points")
	game.pointer_event(Vector2(640,300),true)
	check(game.stage==2 and not game.awaiting,"A board tap advances the solved warehouse")
	game.free()
	game=fresh("stackfall")
	game.grid[Vector2i(4,0)]=0;game.spawn_piece()
	check(game.ended and not game.won and game.lives==0,"Stackfall top-out consumes its single run and reaches the result screen")
	game.free()
	game=fresh("brick_burst")
	game.on_action("primary")
	var opening_speed:float=game.ball_v.length()
	game.stage=3;game.make_bricks();game.on_action("primary")
	check(game.ball_v.length()>opening_speed,"Later Brick Burst waves launch at a higher ball speed")
	game.free()
func test_input_regressions() -> void:
	var game=load("res://scenes/adventure/iron_adventure.tscn").instantiate()
	add_child(game);game.set_physics_process(false)
	Input.action_press("action")
	check(game.down("secondary") and not game.down("primary"),"Holding blast does not also hold adventure jump")
	Input.action_press("jump")
	game.action_event("primary",false)
	check(game.down("primary"),"A still-held jump action survives another jump key release")
	Input.action_release("jump")
	check(not game.down("primary") and game.down("secondary"),"Releasing jump permits a short hop while blast stays held")
	Input.action_release("action")
	check(not game.down("primary") and not game.down("secondary"),"Adventure keyboard actions release independently")
	game.free()
	game=fresh("dino_dash")
	Input.action_press("arcade_primary")
	check(game.down("primary"),"Cabinets retain their shared primary action mapping")
	Input.action_release("arcade_primary")
	game.free()
	for id in ["byte_munch","dot_gobbler"]:
		game=fresh(id)
		var touch=InputEventScreenTouch.new();touch.index=7;touch.pressed=true;touch.position=Vector2(1000,420)
		game._input(touch)
		var drag=InputEventScreenDrag.new();drag.index=7;drag.position=Vector2(1000,380)
		game._input(drag)
		check((game.requested if id=="dot_gobbler" else game.turns.back())==Vector2i.UP,"Up swipe follows the finger even far right of the hero: "+id)
		drag.position=Vector2(1001,382);game._input(drag)
		check(game.gesture_origin==Vector2(1000,380),"Tiny finger jitter does not create another turn: "+id)
		drag.position=Vector2(950,380);game._input(drag)
		check((game.requested if id=="dot_gobbler" else game.turns.back())==Vector2i.LEFT,"A second swipe turns relative to the last gesture: "+id)
		touch.pressed=false;game._input(touch)
		drag.position=Vector2(950,450);game._input(drag)
		check(not game.gesture_active and not game.pointer_down and (game.requested if id=="dot_gobbler" else game.turns.back())==Vector2i.LEFT,"Lifting the finger ends swipe steering: "+id)
		touch.pressed=true;game._input(touch)
		game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
		check(not game.gesture_active and not game.pointer_down,"Focus cleanup cancels the swipe gesture: "+id)
		game.free()
	game=fresh("soft_landing")
	check(not game.FUEL_GAUGE.intersects(game.BOARD),"Lander fuel gauge stays outside the flight area")
	for pad in range(1,4):
		game.stage=pad;game.setup_lander()
		check(not game.FUEL_GAUGE.intersects(Rect2(game.ship-Vector2(25,20),Vector2(50,50))),"Fuel gauge leaves the initial lander visible on pad %d" % pad)
	game.free()

func paint_walk(game,seen: Dictionary) -> void:
	if game.awaiting or game.ended:return
	var origin:Vector2i=game.player
	seen[origin]=true
	for pair in [["left",Vector2i(1,0),"right"],["down",Vector2i(1,1),"up"],["up",Vector2i(-1,-1),"down"],["right",Vector2i(-1,0),"left"]]:
		var next:Vector2i=origin+pair[1]
		if game.grid.has(next) and not seen.has(next):
			game.on_action(pair[0]);paint_walk(game,seen)
			if game.awaiting or game.ended:return
			game.on_action(pair[2])
func test_adventure() -> void:
	Global.adventure_stage=0
	var game=load("res://scenes/adventure/iron_adventure.tscn").instantiate()
	add_child(game);game.set_physics_process(false)
	check(game.hero.hero_id=="ember" and game.stage_number==0,"The main adventure always stars Iron Mario")
	for level in range(4):
		game.load_stage(level)
		check(not game.platforms.is_empty() and game.checkpoint.y<510,"Authored stage %d has ground and a safe checkpoint" % (level+1))
	game.load_stage(0);game.motor.position=Vector2(80,450);game.motor.grounded=true
	var first:=InputEventScreenTouch.new();first.index=0;first.pressed=true;first.position=Vector2(280,660)
	var second:=InputEventScreenTouch.new();second.index=1;second.pressed=true;second.position=Vector2(1140,650)
	game._input(first);game._input(second);frame(game,0.016)
	check(game.motor.velocity.x>0 and game.motor.velocity.y<0,"Two actual touch fingers move Iron Mario and jump simultaneously")
	second.pressed=false;game._input(second)
	check(game.down("right") and not game.down("primary"),"Releasing jump keeps the movement finger held")
	game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.held.is_empty() and game.fingers.is_empty(),"Focus cleanup clears both adventure fingers")
	game.load_stage(0);game.motor.grounded=true;game.action_event("primary",true);frame(game,0.016)
	check(game.motor.velocity.y<0,"Iron Mario jump buffer produces immediate upward movement")
	game.action_event("primary",false);frame(game,0.016)
	check(game.motor.velocity.y>=-235,"Releasing jump gives a shorter hop")
	for level in range(3):
		game.load_stage(level)
		var hold_jump:=0
		for i in range(60*40):
			game.enemies.clear()
			var target:=Vector2(2220,450)
			for fuse in game.fuses:
				if not fuse["taken"]:target=fuse["at"];break
			var center:Vector2=game.motor.position+Vector2(20,30)
			var dx:float=target.x-center.x
			game.held["right"]=dx>14
			game.held["left"]=dx< -14
			var need_jump:=absf(dx)<155 and center.y-target.y>25
			for pit in game.pits:
				if pit.position.x-game.motor.position.x>0 and pit.position.x-game.motor.position.x<135:need_jump=true
			if level==2:
				for vent in [820,1680]:
					if vent-game.motor.position.x> -30 and vent-game.motor.position.x<135:need_jump=true
			if need_jump and game.motor.grounded:game.on_action("primary");hold_jump=28
			game.held["primary"]=hold_jump>0
			hold_jump-=1
			frame(game,1.0/60)
			if game.stage_number>level or game.ended:break
		check(game.stage_number==level+1 and not game.ended,"Authored stage %d: legal movement and jumps collect all fuses and reach exit" % (level+1))
		game.ended=false;game.lives=3
	game.held.clear();game.load_stage(3);game.motor.position=Vector2(1050,450);game.motor.grounded=true;game.held["secondary"]=true
	var jump_frames:=0
	for i in range(60*45):
		var incoming:=false
		for shot in game.shots:
			if not shot["friendly"] and shot["at"].x>game.motor.position.x and shot["at"].x-game.motor.position.x<135:incoming=true
		if incoming and game.motor.grounded:game.on_action("primary");jump_frames=25
		game.held["primary"]=jump_frames>0
		jump_frames-=1
		frame(game,1.0/60)
		if game.ended:break
	check(game.won and Global.adventure_complete,"Boss is beatable with legal shots, readable jumps and three hulls")
	game.free()
