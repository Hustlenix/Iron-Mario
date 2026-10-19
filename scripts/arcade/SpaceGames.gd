extends "res://scripts/arcade/ArcadeGameBase.gd"
var ship = Vector2(260,330)
var velocity = Vector2.ZERO
var angle = -PI/2
var bullets: Array[Dictionary] = []
var rocks: Array[Dictionary] = []
var fire_clock = 0.0
var enemy_clock = 1.8
var rival = Vector2(940,310)
var rival_hp = 3
var waiting = false
var fuel = 100.0
var pad_x = 910.0
var landed = false
const SUN = Vector2(640,335)
func setup() -> void:
	use_secondary=true
	secondary_label="BRAKE"
	if game_id=="soft_landing":
		primary_label="THRUST";secondary_label="LEVEL"
		hint="PULSE THRUST. LAND VERTICAL <=28, SIDEWAYS <=20, ANGLE <=7 DEGREES."
		setup_lander()
	else:
		primary_label="FIRE"
		hint="LEFT/RIGHT TURN. UP THRUST. DOWN/Z BRAKE. HOLD ACTION TO FIRE."
		if game_id=="rock_drift":make_rocks()
func setup_lander() -> void:
	ship=Vector2(220 if stage%2 else 1060,180)
	velocity=Vector2.ZERO
	angle=0
	fuel=100
	waiting=false
	landed=false
	pad_x=[910.0,300.0,950.0][clampi(stage-1,0,2)]
func waiting_for_next() -> bool:
	return waiting
func next_button_label() -> String:
	if game_id=="soft_landing": return "NEXT PAD" if landed else "RETRY PAD"
	return "NEXT FIELD"
func on_action(action: String) -> void:
	if action=="primary" and waiting:
		if game_id=="soft_landing":
			if landed:stage+=1
			setup_lander()
		else:stage+=1;waiting=false;make_rocks()
func tick(delta: float) -> void:
	if waiting:return
	if game_id=="soft_landing":lander_tick(delta);return
	angle+=axis_x()*3.0*delta
	var forward=Vector2.from_angle(angle)
	if down("up"):velocity+=forward*235*delta
	if down("down") or down("secondary"):velocity=velocity.move_toward(Vector2.ZERO,255*delta)
	if game_id=="orbit_duel":
		var diff=SUN-ship
		velocity+=diff.normalized()*minf(165,620000/maxf(diff.length_squared(),2000))*delta
	velocity=velocity.limit_length(340)
	ship+=velocity*delta
	ship=wrap_point(ship)
	fire_clock-=delta
	if down("primary") and fire_clock<=0:
		fire_clock=0.19
		bullets.append({"at":ship+forward*21,"v":forward*500+velocity*0.5,"life":1.8,"enemy":false})
		SoundFX.play_click()
	for bullet in bullets:
		bullet["at"]=Vector2(bullet["at"])+Vector2(bullet["v"])*delta
		bullet["life"]-=delta
		var at:Vector2=bullet["at"]
		if bullet["enemy"]:
			if at.distance_to(ship)<22:space_damage();bullet["life"]=0
		elif game_id=="orbit_duel" and at.distance_to(rival)<28:
			rival_hp-=1;score+=75;bullet["life"]=0;SoundFX.play_collect()
		elif game_id=="rock_drift":
			for rock in rocks:
				if rock["alive"] and at.distance_to(rock["at"])<float(rock["size"])*13+5:
					split_rock(rock);bullet["life"]=0;break
		if game_id=="orbit_duel" and at.distance_to(SUN)<50:bullet["life"]=0
	bullets=bullets.filter(func(b):return b["life"]>0)
	if game_id=="orbit_duel":orbit_tick(delta)
	else:rocks_tick(delta)
	status="HULLS %d   SPEED %d   %s" % [lives,int(velocity.length()),"RIVAL %d / 3" % stage if game_id=="orbit_duel" else "FIELD %d / 3" % stage]
func wrap_point(at: Vector2) -> Vector2:
	return Vector2(wrapf(at.x,75,1205),wrapf(at.y,155,525))
func space_damage() -> void:
	if damage("YOUR THREE HULLS ARE GONE."):
		ship=Vector2(225,330);velocity=Vector2.ZERO
func orbit_tick(delta: float) -> void:
	rival=SUN+Vector2(cos(elapsed*(0.55+stage*0.12)+stage)*340,sin(elapsed*(0.55+stage*0.12)+stage)*145)
	enemy_clock-=delta
	if enemy_clock<=0:
		enemy_clock=maxf(0.85,1.8-stage*0.18)
		bullets.append({"at":rival,"v":(ship+velocity*0.3-rival).normalized()*245,"enemy":true,"life":4.2})
	if ship.distance_to(SUN)<66 or ship.distance_to(rival)<34:space_damage()
	if rival_hp<=0:
		score+=300
		if stage==3:complete(true,"ALL THREE RIVAL DRONES DEFEATED!")
		else:stage+=1;rival_hp=3;enemy_clock=2.0
func make_rocks() -> void:
	rocks.clear();bullets.clear();ship=Vector2(230,330);velocity=Vector2.ZERO
	for i in range(stage+2):
		rocks.append({"at":Vector2(760+i*85,185+(i*87)%300),"v":Vector2(-45-i*7,32 if i%2 else -27),"size":3,"alive":true,"seed":i})
func split_rock(rock: Dictionary) -> void:
	rock["alive"]=false;score+=50;SoundFX.play_collect()
	if rock["size"]>1:
		for sign_value in [-1,1]:
			rocks.append({"at":rock["at"],"v":Vector2(rock["v"]).rotated(sign_value*0.8)*1.25,"size":rock["size"]-1,"alive":true,"seed":randi()%20})
func rocks_tick(delta: float) -> void:
	for rock in rocks:
		if not rock["alive"]:continue
		rock["at"]=wrap_point(Vector2(rock["at"])+Vector2(rock["v"])*delta)
		if ship.distance_to(rock["at"])<float(rock["size"])*13+12:space_damage()
	rocks=rocks.filter(func(r):return r["alive"])
	if rocks.is_empty():
		if stage==3:complete(true,"THREE DEBRIS FIELDS CLEARED!")
		else:waiting=true;status="FIELD CLEAR! ACTION STARTS THE NEXT FIELD."
func lander_tick(delta: float) -> void:
	angle=clampf(angle+axis_x()*1.7*delta,-0.72,0.72)
	if down("down") or down("secondary"):angle=move_toward(angle,0,2.3*delta)
	velocity.y+=30*delta
	if (down("up") or down("primary")) and fuel>0:
		velocity+=Vector2(sin(angle),-cos(angle))*95*delta
		fuel=maxf(0,fuel-8*delta)
	velocity=velocity.limit_length(190)
	ship+=velocity*delta
	var pad_width=190-stage*15
	if ship.y+20>=510:
		var safe=absf(ship.x-pad_x)<pad_width/2-15 and velocity.y>=0 and velocity.y<=28 and absf(velocity.x)<=20 and absf(angle)<=0.13
		if safe:
			ship.y=490;waiting=true;landed=true;score+=300+int(fuel)*2;SoundFX.play_success()
			if stage==3:complete(true,"THREE SOFT LANDINGS. REACTOR STABLE!")
			else:status="SAFE LANDING! ACTION OPENS THE NEXT PAD."
		else:lander_crash()
	elif ship.x<80 or ship.x>1200 or ship.y<130:lander_crash()
	if not waiting:status="FUEL %d   DOWN %.1f / 28   SIDE %.1f / 20   ANGLE %.0f" % [int(fuel),velocity.y,absf(velocity.x),rad_to_deg(angle)]
func lander_crash() -> void:
	invulnerable=0
	damage("ALL THREE LANDER HULLS LOST.")
	waiting=true;landed=false
	status="CRASH. ACTION RETRIES THE CURRENT PAD."
func draw_ship(at: Vector2,rotation_value: float,color: Color,thrusting: bool) -> void:
	var points=PackedVector2Array()
	for p in [Vector2(22,0),Vector2(-17,-14),Vector2(-10,0),Vector2(-17,14)]:points.append(at+p.rotated(rotation_value))
	Paint.polygon(self,points,PackedColorArray([color]))
	dot(at,5,Paint.CYAN)
	if thrusting:
		Paint.polygon(self,PackedVector2Array([at+Vector2(-13,-7).rotated(rotation_value),at+Vector2(-32-sin(elapsed*30)*6,0).rotated(rotation_value),at+Vector2(-13,7).rotated(rotation_value)]),PackedColorArray([Paint.GOLD]))
func draw_game() -> void:
	Paint.rect(self,Rect2(0,0,1280,720),Color("b6c5d9"))
	panel(BOARD,Color("8796b0"))
	for i in range(70):
		var at=Vector2(80+(i*173)%1120,155+(i*89)%365)
		Paint.rect(self,Rect2(at,Vector2(3,3)),Paint.PAPER)
	if game_id=="soft_landing":draw_lander();return
	if game_id=="orbit_duel":
		Paint.burst(self,SUN,67,Paint.GOLD)
		dot(SUN,49,Color("e99657"))
		draw_ship(rival,atan2(ship.y-rival.y,ship.x-rival.x),Paint.BLUE,true)
		if enemy_clock<0.35:Paint.circle(self,rival,35,Paint.RED,false,4)
		text("HP %d" % rival_hp,rival+Vector2(-30,-35),17)
	else:
		for rock in rocks:
			var points=PackedVector2Array()
			for i in range(9):points.append(Vector2(rock["at"])+Vector2.from_angle(i*TAU/9)*float(rock["size"])*13*(0.8+float((i+int(rock["seed"]))%3)*0.1))
			Paint.polygon(self,points,PackedColorArray([Color("c2b8a5")]))
	if invulnerable<=0 or fmod(elapsed,0.2)>0.1:draw_ship(ship,angle,Paint.RED,down("up"))
	for bullet in bullets:dot(bullet["at"],4,Paint.RED if bullet["enemy"] else Paint.GOLD)
func draw_lander() -> void:
	var pad_width=190-stage*15
	for i in range(12):
		var x=80+i*105.0
		Paint.polygon(self,PackedVector2Array([Vector2(x,535),Vector2(x+45,475+(i%3)*12),Vector2(x+110,535)]),PackedColorArray([Color("a5a49f")]))
	panel(Rect2(pad_x-pad_width/2,510,pad_width,20),Paint.GOLD)
	text("PAD %d" % stage,Vector2(pad_x-40,547),17)
	var corners=PackedVector2Array()
	for p in [Vector2(-15,-15),Vector2(15,-15),Vector2(20,12),Vector2(-20,12)]:corners.append(ship+p.rotated(angle))
	Paint.polygon(self,corners,PackedColorArray([Paint.RED]))
	dot(ship-Vector2(0,6),8,Paint.CYAN)
	for side in [-1,1]:line(ship+Vector2(side*12,8).rotated(angle),ship+Vector2(side*23,20).rotated(angle),Paint.GOLD,5)
	if (down("up") or down("primary")) and fuel>0 and not waiting:Paint.burst(self,ship+Vector2(0,28).rotated(angle),13,Paint.GOLD)
	panel(Rect2(85,160,200,24),Paint.INK)
	Paint.rect(self,Rect2(90,165,190*fuel/100,14),Paint.GOLD)
