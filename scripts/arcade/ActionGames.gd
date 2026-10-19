extends "res://scripts/arcade/ArcadeGameBase.gd"
var player = Vector2(640,500)
var facing = Vector2.UP
var enemies: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var walls: Array[Rect2] = []
var barriers: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var blasts: Array[Dictionary] = []
var mushrooms: Dictionary = {}
var fire_clock = 0.0
var enemy_clock = 1.0
var waiting = false
var formation_dir = 1.0
var fuel = 100.0
var flags = 0
var smoke_time = 0.0
var aim = Vector2(640,320)
var ammo = 20
var spawned = 0
var outposts = [true,true,true]
func setup() -> void:
	primary_label="FIRE"
	if game_id=="armored_arena":make_tanks()
	elif game_id=="invader_patrol":make_invaders()
	elif game_id=="flag_run":
		primary_label="SMOKE"
		hint="COLLECT SIX FLAGS, THEN RETURN TO EXIT. SMOKE COSTS 12 FUEL."
		make_district()
	elif game_id=="sky_shield":
		hint="AIM AHEAD. TAP TO INTERCEPT. BLASTS CHAIN. AMMO IS LIMITED."
		primary_label="LAUNCH"
	else:make_bugs()
func waiting_for_next() -> bool:
	return waiting
func on_action(action: String) -> void:
	if action!="primary":return
	if waiting:
		stage+=1;waiting=false
		if game_id=="armored_arena":make_tanks()
		elif game_id=="invader_patrol":make_invaders()
		elif game_id=="bug_blaster":make_bugs()
		elif game_id=="sky_shield":spawned=0;enemy_clock=1;ammo=20+stage*2
	elif game_id=="flag_run" and fuel>=12:
		fuel-=12;smoke_time=1.2
		for enemy in enemies:
			if Vector2(enemy["at"]).distance_to(player)<175:enemy["stun"]=2.8
	elif game_id=="sky_shield":intercept()
func on_pointer(at: Vector2,active: bool) -> void:
	if not active:return
	if game_id=="sky_shield":aim=Vector2(clampf(at.x,80,1200),clampf(at.y,150,500));intercept()
	else:on_drag(at)
func on_drag(at: Vector2) -> void:
	if game_id=="sky_shield":aim=Vector2(clampf(at.x,80,1200),clampf(at.y,150,500))
	elif pointer_down:
		if game_id=="invader_patrol":player.x=clampf(at.x,90,1190)
		elif game_id=="bug_blaster":player=Vector2(clampf(at.x,90,1190),clampf(at.y,425,515))
		elif game_id=="flag_run":
			# Steering is integrated in flag_tick so a stationary finger keeps
			# driving and the speed does not depend on touch event frequency.
			pointer=at
func tick(delta: float) -> void:
	if waiting:return
	fire_clock=maxf(0,fire_clock-delta)
	if game_id=="armored_arena":tank_tick(delta)
	elif game_id=="invader_patrol":invader_tick(delta)
	elif game_id=="flag_run":flag_tick(delta)
	elif game_id=="sky_shield":shield_tick(delta)
	else:bug_tick(delta)
func move_blocked(at: Vector2,change: Vector2,radius = 17.0) -> Vector2:
	var result=at
	for axis in [0,1]:
		var candidate=result
		candidate[axis]+=change[axis]
		var blocked=false
		for wall in walls:
			if wall.grow(radius).has_point(candidate):blocked=true;break
		if not blocked:result=candidate
	return Vector2(clampf(result.x,85,1195),clampf(result.y,165,515))
func fire(at: Vector2,dir: Vector2,enemy = false,speed = 470.0) -> void:
	shots.append({"at":at+dir*24,"v":dir*speed,"enemy":enemy,"life":3.0})
func progress_wave(reason: String) -> void:
	if stage>=3:complete(true,reason)
	else:waiting=true;status="WAVE CLEAR! ACTION CONTINUES.";shots.clear()
func hit_player() -> void:
	if damage("YOUR THREE ARMOR HULLS ARE GONE."):player=Vector2(150,490) if game_id=="armored_arena" else Vector2(640,500)
func make_tanks() -> void:
	enemies.clear();shots.clear();walls.clear();player=Vector2(150,490)
	walls.assign([Rect2(350,225,40,215),Rect2(620,350,220,30),Rect2(925,175,35,170)])
	if stage==2:walls.append(Rect2(480,165,30,145))
	if stage==3:walls.append(Rect2(1050,410,140,25))
	for i in range(stage+2):enemies.append({"at":[Vector2(1050,195),Vector2(1100,475),Vector2(735,210),Vector2(500,470),Vector2(190,190)][i],"clock":1.6+i*0.45,"face":Vector2.DOWN,"alive":true})
func tank_tick(delta: float) -> void:
	var input=Vector2(axis_x(),axis_y())
	if input!=Vector2.ZERO:
		facing=Vector2(signf(input.x),0) if absf(input.x)>=absf(input.y) else Vector2(0,signf(input.y))
		player=move_blocked(player,input.normalized()*185*delta)
	if down("primary") and fire_clock<=0:fire_clock=0.3;fire(player,facing);SoundFX.play_click()
	for enemy in enemies:
		if not enemy["alive"]:continue
		var at:Vector2=enemy["at"]
		var diff=player-at
		if enemy["clock"]>0.65:
			var toward=Vector2(signf(diff.x),0) if absf(diff.x)>absf(diff.y) else Vector2(0,signf(diff.y))
			var next=move_blocked(at,toward*(62+stage*10)*delta)
			if next.distance_to(at)<0.1:next=move_blocked(at,Vector2(toward.y,toward.x)*(62+stage*10)*delta)
			enemy["at"]=next
			enemy["face"]=toward
		enemy["clock"]-=delta
		if enemy["clock"]<=0:
			enemy["clock"]=2.5-stage*0.2
			fire(enemy["at"],enemy["face"],true,240)
		if Vector2(enemy["at"]).distance_to(player)<33:hit_player()
	for shot in shots:
		shot["at"]+=Vector2(shot["v"])*delta;shot["life"]-=delta
		for wall in walls:
			if wall.grow(5).has_point(shot["at"]):shot["life"]=0
		if shot["life"]<=0:continue
		if shot["enemy"]:
			if Vector2(shot["at"]).distance_to(player)<22:hit_player();shot["life"]=0
		else:
			for enemy in enemies:
				if enemy["alive"] and Vector2(shot["at"]).distance_to(enemy["at"])<24:enemy["alive"]=false;shot["life"]=0;score+=150;SoundFX.play_collect();break
	shots=shots.filter(func(s):return s["life"]>0)
	enemies=enemies.filter(func(e):return e["alive"])
	if enemies.is_empty():progress_wave("THREE ARMORED ARENAS CLEARED!")
	if not waiting:status="ARENA %d / 3    TANKS %d    WALLS BLOCK SHELLS" % [stage,enemies.size()]
func make_invaders() -> void:
	enemies.clear();shots.clear();barriers.clear();player=Vector2(640,505);formation_dir=1;enemy_clock=1
	for row in range(3):
		for col in range(8):enemies.append({"at":Vector2(160+col*118,165+row*45),"alive":true})
	for x in [225,500,775,1050]:
		for row in range(3):
			for col in range(5):barriers.append({"rect":Rect2(x-40+col*16,425+row*12,15,11),"hp":2})
func invader_tick(delta: float) -> void:
	player.x=clampf(player.x+axis_x()*410*delta,90,1190)
	if down("primary") and fire_clock<=0:fire_clock=0.19;fire(player,Vector2.UP)
	var reverse=false
	var speed=35+stage*10+(24-enemies.size())*1.7
	for enemy in enemies:
		enemy["at"].x+=formation_dir*speed*delta
		if enemy["at"].x>1170 or enemy["at"].x<110:reverse=true
		if enemy["at"].y>460:complete(false,"THE FORMATION CROSSED THE DEFENSE LINE.")
	if reverse:
		formation_dir=-formation_dir
		for enemy in enemies:enemy["at"].y+=16
	enemy_clock-=delta
	if enemy_clock<=0 and not enemies.is_empty():
		enemy_clock=maxf(0.4,0.95-stage*0.12)
		var shooter:Dictionary=enemies[rng.randi_range(0,enemies.size()-1)]
		for enemy in enemies:
			if absf(enemy["at"].x-shooter["at"].x)<20 and enemy["at"].y>shooter["at"].y:shooter=enemy
		fire(shooter["at"],Vector2.DOWN,true,210+stage*15)
	for shot in shots:
		shot["at"]+=Vector2(shot["v"])*delta;shot["life"]-=delta
		if shot["enemy"]:
			for block in barriers:
				if block["hp"]>0 and block["rect"].grow(4).has_point(shot["at"]):block["hp"]-=1;shot["life"]=0;break
			if shot["life"]>0 and Vector2(shot["at"]).distance_to(player)<22:hit_player();shot["life"]=0
		else:
			for enemy in enemies:
				if enemy["alive"] and Rect2(enemy["at"]-Vector2(22,16),Vector2(44,32)).grow(5).has_point(shot["at"]):enemy["alive"]=false;shot["life"]=0;score+=50;break
	shots=shots.filter(func(s):return s["life"]>0 and s["at"].y>125 and s["at"].y<540)
	enemies=enemies.filter(func(e):return e["alive"])
	if enemies.is_empty():progress_wave("THREE ROBOT FORMATIONS STOPPED!")
	if not waiting:status="WAVE %d / 3    ROBOTS %d    BARRIERS REPAIR BETWEEN WAVES" % [stage,enemies.size()]
func make_district() -> void:
	walls.assign([Rect2(360,265,130,125),Rect2(680,285,150,120),Rect2(960,315,110,90)])
	if stage>1:walls.append(Rect2(530,170,90,70))
	pickups.clear();enemies.clear();flags=0;player=Vector2(130,480);fuel=minf(100,fuel+35)
	for at in [Vector2(200,200),Vector2(460,190),Vector2(745,200),Vector2(1080,210),Vector2(350,470),Vector2(1060,475)]:pickups.append({"at":at,"flag":true,"taken":false})
	for at in [Vector2(610,475),Vector2(880,210),Vector2(250,350)]:pickups.append({"at":at,"flag":false,"taken":false})
	for i in range(1+stage):enemies.append({"at":Vector2(1120,175+i*105),"stun":1.5})
func flag_tick(delta: float) -> void:
	fuel=maxf(0,fuel-3.4*delta);smoke_time=maxf(0,smoke_time-delta)
	var input=Vector2(axis_x(),axis_y())
	if pointer_down:
		var toward=pointer-player
		input=toward.normalized() if toward.length()>15 else Vector2.ZERO
	if input!=Vector2.ZERO:player=move_blocked(player,input.normalized()*275*delta)
	for pickup in pickups:
		if not pickup["taken"] and player.distance_to(pickup["at"])<30:
			pickup["taken"]=true
			if pickup["flag"]:flags+=1;score+=100
			else:fuel=minf(100,fuel+28)
			SoundFX.play_collect()
	for enemy in enemies:
		enemy["stun"]=maxf(0,enemy["stun"]-delta)
		if enemy["stun"]>0:continue
		var at:Vector2=enemy["at"]
		var diff=player-at
		var next=move_blocked(at,diff.normalized()*(120+stage*12)*delta)
		if next.distance_to(at)<0.1:next=move_blocked(at,Vector2(-diff.y,diff.x).normalized()*(120+stage*12)*delta)
		enemy["at"]=next
		if next.distance_to(player)<32:
			if damage("PURSUERS USED UP YOUR THREE LIVES."):player=Vector2(130,480)
	if fuel<=0:complete(false,"OUT OF FUEL. SMOKE COSTS 12: SAVE IT FOR TROUBLE.")
	if flags==6 and player.distance_to(Vector2(130,480))<45:
		if stage==3:complete(true,"SIX FLAGS IN EACH OF THREE DISTRICTS. HOME SAFE!")
		else:stage+=1;make_district()
	status="FLAGS %d / 6    FUEL %d    SMOKE COST 12" % [flags,int(fuel)]
func intercept() -> void:
	if ammo<=0:return
	ammo-=1
	shots.append({"at":Vector2(640,515),"v":(aim-Vector2(640,515)).normalized()*460,"target":aim,"life":2.0,"enemy":false})
	SoundFX.play_click()
func shield_tick(delta: float) -> void:
	aim+=Vector2(axis_x(),axis_y())*345*delta
	aim=Vector2(clampf(aim.x,80,1200),clampf(aim.y,150,500))
	enemy_clock-=delta
	var total=8+stage*3
	if enemy_clock<=0 and spawned<total:
		spawned+=1;enemy_clock=maxf(0.45,0.95-stage*0.1)
		var index=rng.randi_range(0,2)
		var at=Vector2(rng.randf_range(85,1195),145)
		var target=Vector2([230,640,1050][index],515)
		enemies.append({"at":at,"v":(target-at).normalized()*(48+stage*11),"target":index,"alive":true})
	for shot in shots:
		shot["at"]+=Vector2(shot["v"])*delta;shot["life"]-=delta
		if Vector2(shot["at"]).distance_to(shot["target"])<16 or shot["life"]<=0:
			blasts.append({"at":shot["target"],"age":0.0})
			shot["life"]=0
	shots=shots.filter(func(s):return s["life"]>0)
	for blast in blasts:blast["age"]+=delta
	var chain:Array[Vector2]=[]
	for enemy in enemies:
		enemy["at"]+=Vector2(enemy["v"])*delta
		for blast in blasts:
			var radius=minf(70,blast["age"]*135) if blast["age"]<0.65 else maxf(0,70-(blast["age"]-0.65)*120)
			if Vector2(enemy["at"]).distance_to(blast["at"])<radius:
				enemy["alive"]=false;chain.append(enemy["at"]);score+=100;break
		if enemy["alive"] and enemy["at"].y>507:
			outposts[enemy["target"]]=false;enemy["alive"]=false;SoundFX.play_failure()
	for at in chain:blasts.append({"at":at,"age":0.0})
	blasts=blasts.filter(func(b):return b["age"]<1.24)
	enemies=enemies.filter(func(e):return e["alive"])
	lives=outposts.count(true)
	if lives==0:complete(false,"ALL THREE OUTPOSTS WERE LOST.")
	elif spawned>=total and enemies.is_empty() and blasts.is_empty():progress_wave("THREE WAVES INTERCEPTED. OUTPOSTS PROTECTED!")
	if not waiting:status="MISSILES %d / %d    AMMO %d    OUTPOSTS %d" % [spawned,total,ammo,lives]
func make_bugs() -> void:
	enemies.clear();shots.clear();player=Vector2(640,500)
	if mushrooms.is_empty():
		for i in range(30):mushrooms[Vector2i(rng.randi_range(1,19),rng.randi_range(1,7))]=2
	for i in range(8+stage*3):enemies.append({"at":Vector2(350+i*47,169),"dir":1.0,"alive":true,"down":true})
func bug_tick(delta: float) -> void:
	player+=Vector2(axis_x(),axis_y()).normalized()*335*delta
	player=Vector2(clampf(player.x,90,1190),clampf(player.y,425,515))
	if (down("primary") or pointer_down) and fire_clock<=0:fire_clock=0.15;fire(player,Vector2.UP,false,530)
	for enemy in enemies:
		var at:Vector2=enemy["at"]
		var next=at+Vector2(enemy["dir"]*(82+stage*17)*delta,0)
		var cell=Vector2i(int((next.x-90)/52),int((next.y-150)/37))
		if next.x<100 or next.x>1180 or mushrooms.has(cell):
			enemy["dir"]=-float(enemy["dir"])
			next=at+Vector2(0,30 if enemy["down"] else -30)
			if next.y>510:next.y=510;enemy["down"]=false
			if next.y<425 and not enemy["down"]:enemy["down"]=true
		enemy["at"]=next
		if next.distance_to(player)<26:hit_player()
	for shot in shots:
		shot["at"]+=Vector2(shot["v"])*delta;shot["life"]-=delta
		var cell=Vector2i(int((shot["at"].x-90)/52),int((shot["at"].y-150)/37))
		if mushrooms.has(cell):
			mushrooms[cell]-=1;shot["life"]=0
			if mushrooms[cell]<=0:mushrooms.erase(cell);score+=5
		else:
			for enemy in enemies:
				if enemy["alive"] and Vector2(shot["at"]).distance_to(enemy["at"])<21:
					enemy["alive"]=false;shot["life"]=0;score+=80
					var seed=Vector2i(int((enemy["at"].x-90)/52),int((enemy["at"].y-150)/37))
					if seed.y<9:mushrooms[seed]=2
					SoundFX.play_collect();break
	shots=shots.filter(func(s):return s["life"]>0 and s["at"].y>140)
	enemies=enemies.filter(func(e):return e["alive"])
	if enemies.is_empty():progress_wave("THREE GARDEN WAVES CLEARED!")
	if not waiting:status="WAVE %d / 3    BUGS %d    MUSHROOMS %d" % [stage,enemies.size(),mushrooms.size()]
func draw_tank(at: Vector2,dir: Vector2,color: Color) -> void:
	panel(Rect2(at-Vector2(20,19),Vector2(40,38)),color)
	for side in [-1,1]:panel(Rect2(at+Vector2(side*19-4,-24),Vector2(8,48)),Color("706e6a"))
	dot(at,10,Paint.GOLD)
	line(at,at+dir*32,Paint.INK,8)
func draw_game() -> void:
	panel(BOARD,Color("c5c6b3") if game_id in ["armored_arena","flag_run"] else Color("c3d1dc"))
	match game_id:
		"armored_arena":
			for wall in walls:panel(wall,Color("a6998a"))
			for enemy in enemies:
				draw_tank(enemy["at"],enemy["face"],Paint.BLUE)
				if enemy["clock"]<0.65:Paint.burst(self,enemy["at"],34,Paint.RED)
			if invulnerable<=0 or fmod(elapsed,0.2)>0.1:draw_tank(player,facing,Paint.RED)
		"invader_patrol":
			for block in barriers:
				if block["hp"]>0:panel(block["rect"],Paint.GOLD if block["hp"]==2 else Color("d1b789"))
			for enemy in enemies:
				var at:Vector2=enemy["at"]
				panel(Rect2(at-Vector2(21,14),Vector2(42,28)),Paint.BLUE)
				dot(at-Vector2(8,0),3,Paint.PAPER);dot(at+Vector2(8,0),3,Paint.PAPER)
				for side in [-1,1]:line(at+Vector2(side*15,10),at+Vector2(side*23,21),Paint.INK,3)
			Paint.polygon(self,PackedVector2Array([player+Vector2(0,-20),player+Vector2(27,15),player+Vector2(-27,15)]),PackedColorArray([Paint.RED]))
			line(Vector2(75,473),Vector2(1200,473),Paint.RED,2)
		"flag_run":draw_district()
		"sky_shield":draw_shield()
		"bug_blaster":
			for cell in mushrooms:
				var at=Vector2(116,168)+Vector2(cell)*Vector2(52,37)
				panel(Rect2(at+Vector2(-4,0),Vector2(8,14)),Paint.PAPER)
				dot(at,12,Paint.RED if mushrooms[cell]==2 else Color("ca9b8e"))
			for enemy in enemies:
				dot(enemy["at"],17,Color("80ab72"))
				line(enemy["at"]+Vector2(-10,9),enemy["at"]+Vector2(-17,17),Paint.INK,3)
				dot(enemy["at"]+Vector2(6,-5),3,Paint.PAPER)
			panel(Rect2(player-Vector2(20,9),Vector2(40,18)),Paint.RED)
			line(player,player-Vector2(0,22),Paint.INK,6)
	for shot in shots:
		line(shot["at"],shot["at"]-Vector2(shot["v"]).normalized()*13,Paint.RED if shot["enemy"] else Paint.GOLD,5)
func draw_district() -> void:
	for wall in walls:
		panel(wall,Color("a49385"))
		for x in range(int(wall.position.x+12),int(wall.end.x-10),28):Paint.rect(self,Rect2(x,wall.position.y+18,10,15),Paint.PAPER)
	panel(Rect2(90,445,80,75),Paint.CYAN if flags==6 else Paint.PAPER)
	text("EXIT",Vector2(98,478),17)
	for pickup in pickups:
		if pickup["taken"]:continue
		var at:Vector2=pickup["at"]
		if pickup["flag"]:
			line(at-Vector2(0,15),at+Vector2(0,15),Paint.INK,3)
			Paint.polygon(self,PackedVector2Array([at-Vector2(0,15),at+Vector2(22,-6),at]),PackedColorArray([Paint.GOLD]))
		else:
			panel(Rect2(at-Vector2(12,15),Vector2(24,30)),Paint.CYAN)
			text("F",at+Vector2(-7,6),16)
	for enemy in enemies:
		panel(Rect2(enemy["at"]-Vector2(17,12),Vector2(34,24)),Paint.BLUE)
		if enemy["stun"]>0:Paint.circle(self,enemy["at"],26,Paint.PAPER,false,3)
	if smoke_time>0:Paint.circle(self,player,70,Color("dde0d3ad"))
	panel(Rect2(player-Vector2(17,12),Vector2(34,24)),Paint.RED)
func draw_shield() -> void:
	for i in range(3):
		var at=Vector2([230,640,1050][i],510)
		panel(Rect2(at-Vector2(35,30),Vector2(70,45)),Paint.GOLD if outposts[i] else Color("92928c"))
	for enemy in enemies:
		line(enemy["at"],enemy["at"]-Vector2(enemy["v"]).normalized()*35,Paint.RED,4)
		dot(enemy["at"],4,Paint.GOLD)
	for blast in blasts:
		var radius=minf(70,blast["age"]*135) if blast["age"]<0.65 else maxf(0,70-(blast["age"]-0.65)*120)
		if radius>1:dot(blast["at"],radius,Color("f6c66ac9"))
	line(aim-Vector2(12,0),aim+Vector2(12,0),Paint.INK,3)
	line(aim-Vector2(0,12),aim+Vector2(0,12),Paint.INK,3)
