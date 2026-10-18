extends "res://scripts/arcade/ArcadeGameBase.gd"
var ball = Vector2(640,300)
var ball_v = Vector2.ZERO
var paddle_y = 300.0
var rival_y = 300.0
var player_points = 0
var rival_points = 0
var ready_ball = true
var cooldown = 0.0
var paddle_x = 640.0
var bricks: Array[Dictionary] = []
var chips: Array[Dictionary] = []
var wide_time = 0.0
var slow_time = 0.0
var broken = 0
var runner_y = 446.0
var runner_v = 0.0
var obstacles: Array[Dictionary] = []
var spawn_clock = 1.2
var obstacle_count = 0
var distance = 0.0
var player_x = 300.0
var rival_x = 970.0
var lob = false
var bounces = [0,0]
var last_hit = 0
var swing_clock = 0.0
var rival_swing = 0.0
var point_clock = 0.0

func setup() -> void:
	if game_id == "dino_dash":
		primary_label = "JUMP"
		secondary_label = "DUCK"
		use_secondary = true
		lives = 1
		hint = "JUMP THORNS. HOLD DOWN / Z TO DUCK LOW FLYERS."
	elif game_id == "brick_burst":
		primary_label = "LAUNCH"
		make_bricks()
		hint = "MOVE / DRAG. SPACE LAUNCHES. WIDE AND SLOW CHIPS LAST 8 SECONDS."
	elif game_id == "paddle_panic":
		primary_label = "SERVE"
		hint = "UP / DOWN OR DRAG YOUR PADDLE. FIRST TO FIVE!"
	else:
		primary_label = "SWING"
		secondary_label = "LOB"
		use_secondary = true
		hint = "MOVE. HOLD ACTION TO SERVE / SWING. UP: LOB. DOWN: DRIVE."
func on_action(action: String) -> void:
	if game_id == "dino_dash" and action in ["primary","up"] and runner_y>=445:
		runner_v = -570
	elif game_id in ["paddle_panic","brick_burst"] and action == "primary" and ready_ball:
		ready_ball = false
		ball_v = Vector2(355,125) if game_id=="paddle_panic" else Vector2(180,-345)
	elif game_id == "sidecourt":
		if action in ["up","secondary"]: lob = true
		elif action == "down": lob = false
func on_pointer(at: Vector2,active: bool) -> void:
	if not active:return
	if game_id == "dino_dash": on_action("primary")
	elif game_id in ["paddle_panic","brick_burst"]:
		on_drag(at)
		on_action("primary")
func on_drag(at: Vector2) -> void:
	if game_id == "paddle_panic": paddle_y = clampf(at.y,190,475)
	elif game_id == "brick_burst": paddle_x = clampf(at.x,150,1130)
	elif game_id == "sidecourt" and pointer_down: player_x = clampf(at.x,100,585)
func tick(delta: float) -> void:
	cooldown = maxf(0,cooldown-delta)
	if game_id=="dino_dash": runner_tick(delta)
	elif game_id=="paddle_panic": pong_tick(delta)
	elif game_id=="brick_burst": brick_tick(delta)
	else: tennis_tick(delta)
func runner_tick(delta: float) -> void:
	var duck = down("down") or down("secondary")
	runner_v += 1450*delta
	runner_y = minf(446,runner_y+runner_v*delta)
	if runner_y>=446: runner_v=0
	var speed = minf(590,245+elapsed*3.8)
	distance += speed*delta
	score = int(distance/10)
	spawn_clock -= delta
	if spawn_clock<=0:
		obstacle_count += 1
		var flyer = obstacle_count>3 and rng.randf()<0.38
		obstacles.append({"rect":Rect2(1260,421 if flyer else (480 if obstacle_count<=3 else 464),52 if flyer else 28,37 if flyer else (20 if obstacle_count<=3 else 36)),"flyer":flyer})
		spawn_clock = rng.randf_range(1.15,1.75)*maxf(0.75,320/speed)
	var player = Rect2(180,runner_y+(28 if duck and runner_y>=445 else 0),62,26 if duck and runner_y>=445 else 54).grow(-5)
	for obstacle in obstacles:
		obstacle["rect"].position.x -= speed*delta
		if player.intersects(obstacle["rect"].grow(-4)):
			complete(false,"DISTANCE %d! TAP PLAY AGAIN TO BEAT YOUR BEST." % score)
	obstacles = obstacles.filter(func(o):return o["rect"].end.x>0)
	status = "DISTANCE %d    SPEED %d" % [score,int(speed)]
func pong_tick(delta: float) -> void:
	paddle_y = clampf(paddle_y+axis_y()*390*delta,190,475)
	rival_y = move_toward(rival_y,ball.y if ball_v.x>0 else 320,225*delta)
	rival_y = clampf(rival_y,190,475)
	if ready_ball:
		ball = Vector2(640,310)
		if cooldown<=0 and (down("primary") or elapsed>1.5): on_action("primary")
		return
	var previous = ball
	ball += ball_v*delta
	if ball.y<155: ball.y=155;ball_v.y=absf(ball_v.y)
	if ball.y>525: ball.y=525;ball_v.y=-absf(ball_v.y)
	if ball_v.x<0 and previous.x>=126 and ball.x<=126 and absf(ball.y-paddle_y)<59:
		paddle_return(1,(ball.y-paddle_y)/50)
	elif ball_v.x>0 and previous.x<=1154 and ball.x>=1154 and absf(ball.y-rival_y)<59:
		paddle_return(-1,(ball.y-rival_y)/50)
	if ball.x<55: award_point(false)
	elif ball.x>1225: award_point(true)
	status = "%d : %d   /   FIRST TO FIVE" % [player_points,rival_points]
func paddle_return(side: float,offset: float) -> void:
	var speed = minf(760,ball_v.length()+24)
	var angle = clampf(offset,-1,1)*1.05
	ball_v = Vector2(side*cos(angle),sin(angle))*speed
	ball.x = 127 if side>0 else 1153
	SoundFX.play_click()
func award_point(player: bool) -> void:
	if player: player_points+=1;score+=100
	else: rival_points+=1
	SoundFX.play_collect() if player else SoundFX.play_failure()
	ready_ball = true
	cooldown = 0.8
	bounces=[0,0]
	ball_v=Vector2.ZERO
	if player_points>=5: complete(true,"MATCH WON %d TO %d!" % [player_points,rival_points])
	elif rival_points>=5: complete(false,"MATCH %d TO %d. TRY ANOTHER ANGLE!" % [player_points,rival_points])
func make_bricks() -> void:
	bricks.clear()
	for row in range(3+mini(stage,4)):
		for col in range(10):
			if stage>1 and (col+row+stage)%7==0:continue
			bricks.append({"rect":Rect2(100+col*108,155+row*32,100,25),"hp":1+(1 if stage>1 and row<2 else 0)})
	ready_ball=true
	ball_v=Vector2.ZERO
func brick_tick(delta: float) -> void:
	wide_time=maxf(0,wide_time-delta)
	slow_time=maxf(0,slow_time-delta)
	paddle_x=clampf(paddle_x+axis_x()*650*delta,155,1125)
	var width = 210.0 if wide_time>0 else 145.0
	if ready_ball:ball=Vector2(paddle_x,480)
	else:
		var count = maxi(1,ceili(ball_v.length()*delta/9))
		for sub in range(count): brick_ball_step(delta/count,width)
	for chip in chips:
		chip["at"].y += 115*delta
		if Rect2(paddle_x-width/2,490,width,22).grow(14).has_point(chip["at"]):
			if chip["wide"]:wide_time=8
			else:slow_time=8
			chip["at"].y=800
			SoundFX.play_collect()
	chips=chips.filter(func(c):return c["at"].y<550)
	if bricks.is_empty() and not ended:
		stage+=1
		score+=500
		make_bricks()
	status="WAVE %d    WIDE %.0f    SLOW %.0f" % [stage,wide_time,slow_time]
func brick_ball_step(delta: float,width: float) -> void:
	if ready_ball or ended:return
	var previous = ball
	ball+=ball_v*delta*(0.65 if slow_time>0 else 1.0)
	if ball.x<76:ball.x=76;ball_v.x=absf(ball_v.x)
	if ball.x>1204:ball.x=1204;ball_v.x=-absf(ball_v.x)
	if ball.y<141:ball.y=141;ball_v.y=absf(ball_v.y)
	if ball_v.y>0 and previous.y<=485 and ball.y>=485 and absf(ball.x-paddle_x)<width/2+9:
		var angle = clampf((ball.x-paddle_x)/(width/2),-0.95,0.95)*1.08
		ball_v=Vector2(sin(angle),-cos(angle))*minf(650,ball_v.length()+9)
		ball.y=484
		SoundFX.play_click()
	for brick in bricks:
		var r:Rect2=brick["rect"]
		if int(brick["hp"])>0 and r.grow(8).has_point(ball):
			brick["hp"]-=1
			if previous.x<r.position.x-8 or previous.x>r.end.x+8:ball_v.x=-ball_v.x
			else:ball_v.y=-ball_v.y
			score+=25
			SoundFX.play_collect()
			if int(brick["hp"])==0:
				broken+=1
				if broken%7==0:chips.append({"at":r.get_center(),"wide":broken%14==0})
			break
	bricks=bricks.filter(func(b):return b["hp"]>0)
	if ball.y>540:
		invulnerable=0
		damage("THREE BALLS LOST. WAVE %d / SCORE %d" % [stage,score])
		ready_ball=true
func tennis_tick(delta: float) -> void:
	player_x=clampf(player_x+axis_x()*325*delta,105,580)
	rival_x=move_toward(rival_x,clampf(ball.x,715,1170),245*delta)
	swing_clock=maxf(0,swing_clock-delta)
	rival_swing=maxf(0,rival_swing-delta)
	if down("up"):lob=true
	if down("down"):lob=false
	if ready_ball:
		ball=Vector2(player_x+30,390)
		if cooldown<=0 and down("primary"):
			ready_ball=false
			hit_tennis(true)
		return
	ball_v.y+=530*delta
	ball+=ball_v*delta
	if down("primary") and swing_clock<=0 and absf(ball.x-player_x)<105 and ball.y>315 and ball.y<510: hit_tennis(true)
	if rival_swing<=0 and absf(ball.x-rival_x)<90 and ball.y>325 and ball.y<490 and ball_v.x>0: hit_tennis(false)
	if absf(ball.x-640)<12 and ball.y>405 and ball.y<510:
		ball_v.x=-ball_v.x*0.6
		ball.x=626 if ball_v.x<0 else 654
	if ball.y>=505:
		var side=0 if ball.x<640 else 1
		bounces[side]+=1
		ball.y=504
		ball_v.y=-absf(ball_v.y)*0.72
		if bounces[side]>=2: award_point(side==1)
	if ball.x<65 or ball.x>1215: award_point(last_hit==1)
	status="%d : %d   %s   /   HOLD SWING WHEN BALL IS IN REACH" % [player_points,rival_points,"LOB" if lob else "DRIVE"]
func hit_tennis(player: bool) -> void:
	if player:
		ball_v=Vector2(355 if lob else 510,-530 if lob else -330)
		swing_clock=0.42
		last_hit=0
	else:
		ball_v=Vector2(-390,-410)
		rival_swing=0.65
		last_hit=1
	bounces=[0,0]
	SoundFX.play_click()
func draw_game() -> void:
	if game_id=="dino_dash":draw_runner()
	elif game_id=="paddle_panic":draw_pong()
	elif game_id=="brick_burst":draw_bricks()
	else:draw_tennis()
func draw_runner() -> void:
	Paint.rect(self,Rect2(0,0,1280,720),Color("d7e3bd"))
	for i in range(8):
		var x=i*220-fposmod(distance*0.2,220)
		Paint.polygon(self,PackedVector2Array([Vector2(x-90,500),Vector2(x+30,220),Vector2(x+170,500)]),PackedColorArray([Color("b2b89a")]))
	line(Vector2(0,502),Vector2(1280,500),Paint.INK,6)
	var duck=down("down") or down("secondary")
	var body=Rect2(180,runner_y+(28 if duck and runner_y>=445 else 0),62,26 if duck and runner_y>=445 else 54)
	panel(body,Color("6d9e6e"))
	panel(Rect2(body.position+Vector2(36,-14),Vector2(39,28)),Color("6d9e6e"))
	dot(body.position+Vector2(64,-5),3,Paint.INK)
	line(body.position+Vector2(-23,15),body.position+Vector2(12,25),Color("6d9e6e"),14)
	for leg in [12,42]:line(body.position+Vector2(leg,body.size.y),body.position+Vector2(leg+sin(elapsed*14+leg)*9,body.size.y+6),Paint.INK,6)
	for o in obstacles:
		var r:Rect2=o["rect"]
		if o["flyer"]:
			Paint.polygon(self,PackedVector2Array([r.position,r.get_center()+Vector2(0,sin(elapsed*12)*25),r.end]),PackedColorArray([Paint.RED]))
			dot(r.get_center(),9,Paint.GOLD)
		else:
			for x in range(int(r.position.x),int(r.end.x),12):Paint.polygon(self,PackedVector2Array([Vector2(x,r.end.y),Vector2(x+6,r.position.y),Vector2(x+13,r.end.y)]),PackedColorArray([Color("49775d")]))
func draw_pong() -> void:
	panel(BOARD,Color("99c3c9"))
	for y in range(150,530,35):line(Vector2(640,y),Vector2(640,y+18),Paint.PAPER,4)
	panel(Rect2(103,paddle_y-50,16,100),Paint.RED)
	panel(Rect2(1160,rival_y-50,16,100),Paint.BLUE)
	dot(ball,10,Paint.GOLD)
	text("%d       %d" % [player_points,rival_points],Vector2(535,190),38)
func draw_bricks() -> void:
	panel(BOARD,Color("d5d2e2"))
	for brick in bricks:panel(brick["rect"],Paint.RED if brick["hp"]>1 else [Paint.GOLD,Paint.CYAN,Color("9fca8e")][int(brick["rect"].position.x/108)%3])
	var width=210 if wide_time>0 else 145
	panel(Rect2(paddle_x-width/2,490,width,18),Paint.RED)
	dot(ball,9,Paint.GOLD)
	for chip in chips:
		panel(Rect2(chip["at"]-Vector2(28,12),Vector2(56,24)),Paint.CYAN)
		text("WIDE" if chip["wide"] else "SLOW",chip["at"]+Vector2(-22,5),12)
func draw_tennis() -> void:
	panel(BOARD,Color("d9b28c"))
	line(Vector2(75,511),Vector2(1205,511),Paint.PAPER,5)
	for x in range(640,650,5):line(Vector2(x,405),Vector2(x,512),Paint.INK,3)
	for at in [Vector2(player_x,467),Vector2(rival_x,467)]:
		dot(at-Vector2(0,35),13,Paint.GOLD)
		line(at-Vector2(0,20),at+Vector2(0,15),Paint.RED if at.x<640 else Paint.BLUE,15)
		line(at+Vector2(0,10),at+Vector2(-17,42),Paint.INK,5)
		line(at+Vector2(0,10),at+Vector2(18,42),Paint.INK,5)
		Paint.circle(self,at+Vector2(30,-10),20,Paint.PAPER,false,4)
	if not ready_ball and absf(ball.x-player_x)<105 and ball.y>315:Paint.circle(self,Vector2(player_x,440),95,Color("4b9c73"),false,4)
	dot(ball,8,Paint.CYAN)
