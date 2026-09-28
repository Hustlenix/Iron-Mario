extends SceneTree
## Deterministic black-box action driver: production scripts contain no auto-solve API.
const GAME = preload("res://microgames/pack_a.gd")
var failed: int = 0
var checked: int = 0
var waypoints: Array[Vector2] = [Vector2(170,125),Vector2(470,125),Vector2(470,365),Vector2(810,365),Vector2(810,180)]

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://microgames/pack_a.json"))
	for level in [1.0,6.0]:
		for item in entries:
			for seed_value in [17,92]:
				var game = GAME.new()
				root.add_child(game)
				game.set_process(false)
				var result: Dictionary={"won":false,"emitted":false}
				game.completed.connect(func(won:bool,_score:int): result.won=won; result.emitted=true)
				game.start(item,level,seed_value)
				await process_frame
				var driver: Dictionary={"idx":0}
				for step in range(1800):
					if game.finished: break
					solve_step(game,driver)
					game.advance(0.01)
				checked+=1
				if not result.won:
					failed+=1
					print("FAIL WIN ",item.id," difficulty ",level," seed ",seed_value," elapsed ",game.elapsed," state ",game.s)
				game.free()
			var idle = GAME.new()
			root.add_child(idle)
			idle.set_process(false)
			var idle_result: Dictionary={"won":false,"emitted":false}
			idle.completed.connect(func(won:bool,_score:int): idle_result.won=won; idle_result.emitted=true)
			idle.start(item,level,17)
			for step in range(1800):
				if idle.finished: break
				idle.advance(0.01)
			checked+=1
			if not idle_result.emitted or idle_result.won:
				failed+=1
				print("FAIL IDLE ",item.id," difficulty ",level)
			idle.free()
			if level==6.0:
				var bad = GAME.new()
				root.add_child(bad)
				bad.set_process(false)
				var bad_result: Dictionary={"won":false,"emitted":false}
				bad.completed.connect(func(won:bool,_score:int): bad_result.won=won; bad_result.emitted=true)
				bad.start(item,level,17)
				make_mistake(bad)
				for step in range(1800):
					if bad.finished: break
					bad.advance(0.01)
				checked+=1
				if not bad_result.emitted or bad_result.won:
					failed+=1
					print("FAIL MISTAKE ",item.id)
				bad.free()
	print("PACK A: ",checked," action-driven win and idle-failure cases; failures=",failed)
	quit(1 if failed>0 else 0)

func make_mistake(game) -> void:
	var s: Dictionary=game.s
	match game.mode:
		"target_lock": tap(game,Vector2.ZERO)
		"reactor_parry", "rhythm_knock", "hold_balance", "door_peek": tap(game,Vector2(480,240))
		"power_sequence":
			game.advance(float(s.goal)*0.52+0.41)
			tap(game,Vector2(180+((int(s.seq[0])+1)%4)*200,380))
		"stop_bar":
			while absf(float(s.value)-float(s.center))<0.2: game.advance(0.02)
			tap(game,Vector2(480,240))
		"odd_one":
			var i: int=(int(s.answer)+1)%12
			tap(game,Vector2(255+(i%4)*150,155+(i/4)*100))
		"whack_mole":
			var i: int=(int(s.answer)+1)%6
			tap(game,Vector2(290+(i%3)*180,175+(i/3)*145))
		"coin_catch": game.handle_action("drag",Vector2(840 if float(s.target.x)<480 else 120,390),Vector2.ZERO)
		"shield_turn", "mirror_match":
			var d: int=(int(s.seq[0])+1)%4
			game.handle_action("direction",Vector2.ZERO,[Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT][d])
		"trace_wire":
			game.handle_action("press",s.path[0],Vector2.ZERO)
			game.handle_action("release",s.path[0],Vector2.ZERO)
			game.handle_action("drag",s.path[1],Vector2.ZERO)
		"balloon_pump": tap(game,Vector2(480,240))
		"color_switch": tap(game,Vector2(180+((int(s.answer)+1)%4)*200,380))
		"number_order":
			var i: int=s.order.find(6)
			tap(game,Vector2(290+(i%3)*180,175+(i/3)*145))
		"orbit_snap":
			while absf(wrapf(float(s.angle),-PI,PI))<0.8: game.advance(0.02)
			tap(game,Vector2(480,240))
		"light_out": tap(game,Vector2(480,235))
		"safe_dial": game.handle_action("swipe",Vector2(480,240),Vector2(-int(s.seq[0])*100,0))
		"fuse_cut": tap(game,Vector2(480,141+((int(s.answer)+1)%4)*72))
		"pixel_repair": tap(game,Vector2(597,142))
		"maze_runner": game.handle_action("move",Vector2.ZERO,Vector2.RIGHT)
		"gravity_flip":
			tap(game,Vector2(480,240))
			tap(game,Vector2(480,240))
		"word_sort": game.handle_action("swipe",Vector2(480,240),Vector2.RIGHT)
		"echo_taps":
			game.advance(2.41)
			tap(game,Vector2(480,240))

func tap(game, point: Vector2) -> void:
	game.handle_action("press",point,Vector2.ZERO)
	game.handle_action("release",point,Vector2.ZERO)

func solve_step(game, driver: Dictionary) -> void:
	var s: Dictionary=game.s
	match game.mode:
		"target_lock": tap(game,s.target)
		"reactor_parry":
			if absf(float(s.value)-0.92)<0.02: tap(game,Vector2(700,240))
		"power_sequence":
			if int(s.phase)==1: tap(game,Vector2(180+int(s.seq[s.n])*200,380))
		"stop_bar":
			if absf(float(s.value)-float(s.center))<0.025: tap(game,Vector2(480,240))
		"odd_one": tap(game,Vector2(255+(int(s.answer)%4)*150,155+(int(s.answer)/4)*100))
		"rhythm_knock", "echo_taps":
			if absf(game.elapsed-float(s.beats[s.n]))<0.02: tap(game,Vector2(480,245))
		"whack_mole": tap(game,Vector2(290+(int(s.answer)%3)*180,175+(int(s.answer)/3)*145))
		"coin_catch": game.handle_action("drag",Vector2(s.target.x,390),Vector2.ZERO)
		"shield_turn", "mirror_match":
			var d: int=int(s.seq[s.n])
			if game.mode=="mirror_match": d=(d+2)%4
			game.handle_action("direction",Vector2.ZERO,[Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT][d])
		"trace_wire":
			if not s.held: game.handle_action("press",s.path[0],Vector2.ZERO)
			else: game.handle_action("drag",s.path[s.idx],Vector2.ZERO)
		"balloon_pump": tap(game,Vector2(480,240))
		"hold_balance":
			if not s.held: game.handle_action("press",Vector2(480,240),Vector2.ZERO)
			elif float(s.value)>=float(s.goal_value): game.handle_action("release",Vector2(480,240),Vector2.ZERO)
		"color_switch": tap(game,Vector2(180+int(s.answer)*200,380))
		"number_order":
			var i: int=s.order.find(int(s.n)+1)
			tap(game,Vector2(290+(i%3)*180,175+(i/3)*145))
		"orbit_snap":
			if absf(wrapf(float(s.angle),-PI,PI))<0.03: tap(game,Vector2(480,240))
		"light_out":
			var i: int=int(s.scramble[driver.idx])
			tap(game,Vector2(380+(i%3)*100,135+(i/3)*100))
			driver.idx=int(driver.idx)+1
		"safe_dial": game.handle_action("swipe",Vector2(480,240),Vector2(int(s.seq[s.n])*100,0))
		"fuse_cut": tap(game,Vector2(480,141+int(s.answer)*72))
		"pixel_repair":
			for i in range(9):
				if s.cells[i]!=s.answer[i]:
					tap(game,Vector2(597+(i%3)*95,142+(i/3)*95))
					break
		"maze_runner":
			if Vector2(s.target).distance_to(waypoints[driver.idx])<6:
				driver.idx=mini(int(driver.idx)+1,waypoints.size()-1)
			game.handle_action("move",Vector2.ZERO,(waypoints[driver.idx]-Vector2(s.target)).normalized())
		"gravity_flip":
			for obstacle in s.obstacles:
				if float(obstacle.x)>180 and float(obstacle.x)<345 and int(obstacle.lane)==int(s.lane):
					tap(game,Vector2(480,240))
					break
		"word_sort": game.handle_action("swipe",Vector2(480,240),Vector2.LEFT if int(s.n)%2==0 else Vector2.RIGHT)
		"door_peek":
			if game.elapsed>=float(s.open_at): tap(game,Vector2(480,240))
