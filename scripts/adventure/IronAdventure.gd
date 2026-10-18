extends "res://scripts/arcade/ArcadeGameBase.gd"
const Motor = preload("res://scripts/adventure/AdventureMotor.gd")
const NAMES = ["WORKSHOP ESCAPE","SKYLINE RELAY","THE MOLTEN WORKS","THE SCRAP KING"]
var motor = Motor.new()
var hero: Node2D
var platforms: Array[Rect2] = []
var pits: Array[Rect2] = []
var enemies: Array[Dictionary] = []
var fuses: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var sparks: Array[Dictionary] = []
var checkpoint = Vector2(80,430)
var camera_x = 0.0
var world_width = 2300.0
var fire_clock = 0.0
var boss_hp = 12
var boss_clock = 2.8
var boss_open = 0.0
var boss_warning = 0.0
var boss_attacks = 0
var title_clock = 3.0
var gate_clock = 0.0
var stage_number = 0
var fuses_found = 0
var victory_clock = 0.0

func _init() -> void: game_id = "adventure"
func setup() -> void:
	primary_label = "JUMP"
	use_secondary = true
	secondary_label = "BLAST"
	lives = 3
	hero = preload("res://scripts/ui/IronHero.gd").new()
	hero.hero_id = "ember"
	hero.scale = Vector2(1.05,1.05)
	add_child(hero)
	load_stage(Global.adventure_stage)
	hint = "A/D MOVE  SPACE JUMP  E BLAST  /  FIND 3 FUSES, REACH THE EXIT"
func load_stage(index: int) -> void:
	stage_number = index
	stage = index+1
	world_width = 2300 if index<3 else 1700
	motor.position = Vector2(80,430)
	motor.velocity = Vector2.ZERO
	motor.grounded = false
	motor.buffer = 0
	motor.coyote = 0
	motor.facing = 1
	checkpoint = motor.position
	enemies.clear(); fuses.clear(); shots.clear(); pits.clear(); platforms.clear()
	fuses_found = 0
	fire_clock = 0
	title_clock = 3
	boss_hp = 12
	boss_clock = 2.8
	boss_open = 0
	boss_warning = 0
	boss_attacks = 0
	if index == 0:
		platforms.assign([Rect2(0,510,2300,80),Rect2(360,440,220,18),Rect2(920,395,240,18),Rect2(1460,440,220,18)])
	elif index == 1:
		platforms.assign([Rect2(0,510,600,80),Rect2(770,510,630,80),Rect2(1570,510,730,80),Rect2(555,435,270,18),Rect2(1330,420,300,18),Rect2(1800,400,220,18)])
		pits.assign([Rect2(600,510,170,100),Rect2(1400,510,170,100)])
	elif index == 2:
		platforms.assign([Rect2(0,510,480,80),Rect2(620,510,660,80),Rect2(1430,510,870,80),Rect2(415,425,270,18),Rect2(1200,415,300,18),Rect2(1770,380,220,18)])
		pits.assign([Rect2(480,510,140,100),Rect2(1280,510,150,100)])
	else:
		platforms.assign([Rect2(0,510,1700,80),Rect2(430,410,180,18),Rect2(830,410,180,18)])
		checkpoint = Vector2(720,440)
	if index<3:
		var locations = [Vector2(470,402),Vector2(1035,355 if index==0 else 464),Vector2(1880,355 if index==2 else (360 if index==1 else 464))]
		for at in locations: fuses.append({"at":at,"taken":false})
		for i in range(3+index):
			var x = 620+i*270.0
			enemies.append({"at":Vector2(x,477),"home":x,"dir":-1.0,"hp":1 if i%2==0 else 2,"clock":2.0+i*0.4,"kind":"walker" if i%2==0 else "turret","alive":true})
	camera_x = 0
	hero.position = motor.position+Vector2(20,30)
	invulnerable = 1.0
	Music.play_theme("ember","boss" if index==3 else "mission")
	Global.adventure_stage = index
	Global.save_data()
func on_action(action: String) -> void:
	if action == "primary": motor.jump()
func tick(delta: float) -> void:
	title_clock = maxf(0,title_clock-delta)
	fire_clock = maxf(0,fire_clock-delta)
	gate_clock = maxf(0,gate_clock-delta)
	if stage_number==1:
		platforms[3].position.y=435+sin(elapsed*1.1)*10
		platforms[4].position.y=420+sin(elapsed*1.1+1)*10
	var before: Vector2 = motor.position
	motor.step(delta,axis_x(),down("primary"),platforms,world_width)
	if down("secondary") and fire_clock<=0:
		fire_clock = 0.23
		shots.append({"at":motor.position+Vector2(20+motor.facing*25,22),"v":Vector2(motor.facing*720,0),"friendly":true,"life":1.4})
		SoundFX.play_click()
	if motor.position.y>570:
		take_hit(true)
	if motor.position.x>1080 and stage_number<3 and checkpoint.x<1000:
		checkpoint = Vector2(1060,440)
		score += 100
		status = "CHECKPOINT LIT!"
		SoundFX.play_collect()
	if stage_number==2:
		for i in range(2):
			var cycle=fposmod(elapsed+i*0.8,4.0)
			if cycle>2.1 and cycle<2.9 and motor.rect().grow(-4).intersects(Rect2(794+i*860,465,52,45)):
				take_hit(false)
	for fuse in fuses:
		if not fuse["taken"] and (motor.position+Vector2(20,30)).distance_to(fuse["at"])<45:
			fuse["taken"] = true
			fuses_found += 1
			score += 150
			SoundFX.play_collect()
	for enemy in enemies:
		if not enemy["alive"]: continue
		var at: Vector2 = enemy["at"]
		if enemy["kind"] == "walker":
			at.x += float(enemy["dir"])*(65+stage_number*15)*delta
			if absf(at.x-float(enemy["home"]))>75: enemy["dir"] = -float(enemy["dir"])
		else:
			enemy["clock"] = float(enemy["clock"])-delta
			if enemy["clock"]<=0:
				enemy["clock"] = 2.6
				var toward = (motor.position+Vector2(20,25)-at).normalized()
				shots.append({"at":at,"v":toward*225,"friendly":false,"life":5.0})
		enemy["at"] = at
		if motor.rect().grow(-4).intersects(Rect2(at-Vector2(23,25),Vector2(46,50))):
			if motor.velocity.y>100 and before.y+motor.size.y<at.y:
				enemy["alive"] = false
				motor.velocity.y = -430
				score += 75
				burst(at,Paint.GOLD)
			else: take_hit(false)
	for shot in shots:
		shot["at"] = Vector2(shot["at"])+Vector2(shot["v"])*delta
		shot["life"] = float(shot["life"])-delta
		var at: Vector2 = shot["at"]
		if shot["friendly"]:
			for enemy in enemies:
				if enemy["alive"] and at.distance_to(enemy["at"])<30:
					shot["life"] = 0
					enemy["hp"] -= 1
					if enemy["hp"]<=0:
						enemy["alive"] = false
						score += 75
						burst(enemy["at"],Paint.GOLD)
					break
			if stage_number==3 and Rect2(1270,315,170,195).has_point(at):
				shot["life"] = 0
				if boss_open>0:
					boss_hp -= 1
					score += 100
					burst(at,Paint.CYAN)
					SoundFX.play_collect()
		elif motor.rect().grow(-3).has_point(at):
			take_hit(false)
			shot["life"] = 0
	shots = shots.filter(func(s):return float(s["life"])>0)
	if stage_number==3: boss_tick(delta)
	elif motor.position.x>2180:
		if fuses_found>=3:
			score += lives*100
			load_stage(stage_number+1)
		elif gate_clock<=0:
			status = "EXIT LOCKED: FIND ALL 3 GLOWING FUSES"
			gate_clock = 2
	for spark in sparks:
		spark["at"] = Vector2(spark["at"])+Vector2(spark["v"])*delta
		spark["life"] -= delta
	sparks = sparks.filter(func(s):return s["life"]>0)
	camera_x = clampf(motor.position.x-430,0,world_width-1280)
	hero.position = motor.position+Vector2(20,30)-Vector2(camera_x,0)
	hero.scale.x = motor.facing*1.05
	hero.pose = "damaged" if invulnerable>0.5 else ("jump" if not motor.grounded else ("blast" if down("secondary") else ("run" if absf(motor.velocity.x)>20 else "idle")))
	hero.modulate.a = 0.45 if invulnerable>0 and fmod(elapsed,0.15)<0.07 else 1.0
	if stage_number<3 and gate_clock<=0: status = "FUSES %d / 3     %s" % [fuses_found,NAMES[stage_number]]
func take_hit(fell: bool) -> void:
	if damage("SUIT POWERED DOWN. RETRY THIS STAGE."):
		burst(motor.position+Vector2(20,30),Paint.RED)
		if fell:
			motor.position = checkpoint
			motor.velocity = Vector2.ZERO
		else:
			motor.velocity = Vector2(-motor.facing*180,-300)
func burst(at: Vector2,color: Color) -> void:
	for i in range(10): sparks.append({"at":at,"v":Vector2.from_angle(float(i)*TAU/10)*145,"life":0.5,"color":color})
func boss_tick(delta: float) -> void:
	if motor.rect().intersects(Rect2(1270,340,170,170)):
		take_hit(false)
		motor.position.x=1220
	boss_clock -= delta
	boss_open = maxf(0,boss_open-delta)
	boss_warning = maxf(0,boss_warning-delta)
	if boss_clock<0.8 and boss_clock>0: boss_warning = boss_clock
	if boss_clock<=0:
		boss_attacks += 1
		boss_open = 1.9
		boss_clock = 4.0 if boss_hp>6 else 3.5
		shots.append({"at":Vector2(1250,488),"v":Vector2(-260,0),"friendly":false,"life":6.0})
		if boss_hp<=8: shots.append({"at":Vector2(1390,330),"v":Vector2(-210,105),"friendly":false,"life":6.0})
		if boss_hp<=4: shots.append({"at":Vector2(1320,488),"v":Vector2(-360,0),"friendly":false,"life":5.0})
		if boss_attacks%3==0:
			enemies.append({"at":Vector2(1120,477),"home":1120.0,"dir":-1.0,"hp":1,"clock":2.0,"kind":"walker","alive":true})
	status = "CORE OPEN: BLAST!" if boss_open>0 else ("JUMP! SHOCKWAVE INCOMING!" if boss_warning>0 else "SCRAP KING / WATCH THE WARNING LIGHTS")
	if boss_hp<=0:
		if not Global.adventure_complete:Global.adventure_wins+=1
		Global.adventure_complete = true
		Global.save_data()
		hero.pose = "victory"
		complete(true,"REACTOR STABLE! IRON MARIO SAVED THE CITY!")
		Music.play_theme("ember","victory")
func restart_game() -> void:
	GameManager.open_menu(scene_file_path)
func draw_game() -> void:
	var sky = [Color("c6dee0"),Color("d6d8ee"),Color("f1c9a5"),Color("aebbd3")][stage_number]
	Paint.rect(self,Rect2(0,0,1280,720),sky)
	for i in range(16):
		var x = i*150-fposmod(camera_x*0.3,150)
		var h = 100+(i*47)%160
		panel(Rect2(x,530-h,120,h),Color("8fa9b3"))
		for y in range(int(550-h),520,35): Paint.rect(self,Rect2(x+22,y,12,15),Paint.PAPER)
	for pit in pits:
		var r = pit
		r.position.x -= camera_x
		panel(r,Paint.RED if stage_number==2 else Color("547792"))
	if stage_number==2:
		for i in range(2):
			var cycle=fposmod(elapsed+i*0.8,4.0)
			var x=820+i*860-camera_x
			panel(Rect2(x-27,502,54,12),Paint.INK)
			if cycle>1.4 and cycle<=2.1:
				Paint.burst(self,Vector2(x,480),24,Paint.GOLD)
			elif cycle>2.1 and cycle<2.9:
				for j in range(4): Paint.line(self,Vector2(x-18+j*12,500),Vector2(x-14+j*12,462),Paint.RED,7)
	for surface in platforms:
		var r = surface
		r.position.x -= camera_x
		if r.end.x<0 or r.position.x>1280: continue
		panel(r,Color("c18c68"))
		line(r.position+Vector2(3,3),r.position+Vector2(r.size.x-3,3),Paint.GOLD,6)
	for fuse in fuses:
		if fuse["taken"]: continue
		var at: Vector2 = fuse["at"]-Vector2(camera_x,0)
		Paint.burst(self,at,24+sin(elapsed*4)*3,Paint.GOLD)
		dot(at,14,Paint.CYAN)
		line(at+Vector2(-7,0),at+Vector2(7,0),Color.WHITE)
	for enemy in enemies:
		if not enemy["alive"]:continue
		var at: Vector2 = enemy["at"]-Vector2(camera_x,0)
		panel(Rect2(at-Vector2(22,24),Vector2(44,48)),Paint.BLUE if enemy["kind"]=="walker" else Paint.RED)
		line(at+Vector2(-12,-8),at+Vector2(12,-8),Paint.GOLD,6)
		if enemy["kind"]=="turret" and enemy["clock"]<0.55: Paint.burst(self,at,34,Paint.RED)
	for shot in shots:
		dot(shot["at"]-Vector2(camera_x,0),7 if shot["friendly"] else 12,Paint.CYAN if shot["friendly"] else Paint.RED)
	for spark in sparks: Paint.rect(self,Rect2(spark["at"]-Vector2(camera_x,0),Vector2(5,5)),spark["color"])
	var cp = checkpoint-Vector2(camera_x,0)
	line(Vector2(cp.x,510),Vector2(cp.x,422),Paint.INK,4)
	Paint.polygon(self,PackedVector2Array([Vector2(cp.x,422),Vector2(cp.x+45,437),Vector2(cp.x,452)]),PackedColorArray([Paint.CYAN]))
	if stage_number<3:
		var exit_x = 2210-camera_x
		panel(Rect2(exit_x,398,62,112),Paint.CYAN if fuses_found==3 else Paint.RED)
		text("EXIT",Vector2(exit_x-2,386),18)
	else:
		var at = Vector2(1350-camera_x,430)
		panel(Rect2(at-Vector2(80,110),Vector2(160,190)),Color("666a83"))
		panel(Rect2(at-Vector2(55,135),Vector2(110,55)),Paint.RED)
		line(at+Vector2(-35,-112),at+Vector2(35,-112),Paint.GOLD,10)
		dot(at-Vector2(0,30),32,Paint.CYAN if boss_open>0 else Paint.RED)
		for side in [-1,1]: panel(Rect2(at+Vector2(side*90-20,-40),Vector2(40,140)),Paint.GOLD)
		panel(Rect2(435,120,410,20),Paint.INK)
		Paint.rect(self,Rect2(440,124,400*maxf(0,boss_hp)/12.0,12),Paint.RED)
		if boss_warning>0: Paint.burst(self,at-Vector2(0,145),40,Paint.GOLD)
	if ended and won:
		for i in range(36):
			Paint.rect(self,Rect2(40+(i*89)%1200,fposmod(i*57+victory_clock*(40+i%5*12),600),6,10),[Paint.GOLD,Paint.CYAN,Paint.RED][i%3])
	if title_clock>0:
		panel(Rect2(350,165,650,85))
		text("%d. %s" % [stage,NAMES[stage_number]],Vector2(380,220),30)

func _process(delta: float) -> void:
	if ended:
		victory_clock += delta
		hero.position = Vector2(155,365+sin(victory_clock*2)*6)
		hero.scale = Vector2(3,3)
		hero.pose = "victory" if won else "damaged"
		hero.modulate.a = 1.0
		queue_redraw()
