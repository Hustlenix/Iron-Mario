extends "res://microgames/microgame_base.gd"
## Reaction laboratory. All state belongs to this round; no scene reloads or timers.
var s: Dictionary = {}
var mode: String = ""
var pad_colors: Array[Color] = [RED, BLUE, GREEN, GOLD]
var arrows: Array[String] = ["UP", "RIGHT", "DOWN", "LEFT"]

func cancel_input() -> void:
	s.held=false
	s.axis=Vector2.ZERO

func setup() -> void:
	mode = str(spec.get("id", "target_lock"))
	s = {"n": 0, "goal": 3, "held": false, "axis": Vector2.ZERO, "t": 0.0, "idx": 0, "phase": 0, "x": 480.0, "y": 240.0, "target": Vector2(480,240), "value": 0.0, "gesture_swiped": false}
	match mode:
		"target_lock":
			s.goal = 3 + int(difficulty / 3.0)
			new_target()
		"reactor_parry": s.goal = 3
		"power_sequence", "mirror_match", "shield_turn":
			s.seq = []
			for i in range(3 + int(difficulty / 3.0)): s.seq.append(rng.randi_range(0,3))
			s.goal = s.seq.size()
		"stop_bar": s.center = rng.randf_range(0.35,0.7)
		"odd_one":
			s.answer = rng.randi_range(0,11)
			s.goal = 2 + int(difficulty / 3.0)
		"rhythm_knock": s.beats = [1.0, 2.1, 3.2, 4.3]
		"whack_mole":
			s.answer = rng.randi_range(0,5)
			s.goal = 4 + int(difficulty / 3.0)
		"coin_catch":
			s.x = 480.0
			s.target = Vector2(rng.randf_range(220,740),-20)
			s.goal = 3
		"trace_wire": s.path = [Vector2(170,330), Vector2(310,145), Vector2(470,330), Vector2(640,145), Vector2(790,330)]
		"balloon_pump": s.goal = 10 + int(difficulty)
		"hold_balance": s.goal_value = 0.62
		"color_switch":
			s.answer = rng.randi_range(0,3)
			s.word = (int(s.answer) + rng.randi_range(1,3)) % 4
		"number_order":
			s.order = [1,2,3,4,5,6]
			shuffle_values(s.order)
			s.goal = 6
		"orbit_snap": s.angle = rng.randf_range(1.5,4.5)
		"light_out":
			s.cells = [false,false,false,false,false,false,false,false,false]
			s.scramble = []
			var candidates: Array=[0,1,2,3,4,5,6,7,8]
			shuffle_values(candidates)
			for i in range(2+int(difficulty/2.0)): s.scramble.append(candidates[i])
			for index in s.scramble: toggle_cross(int(index))
		"safe_dial":
			s.seq = []
			s.goal = 3+int(difficulty/3.0)
			for i in range(s.goal): s.seq.append(1 if rng.randf()>0.5 else -1)
		"fuse_cut": s.answer = rng.randi_range(0,3)
		"pixel_repair":
			s.answer = []
			for i in range(9): s.answer.append(rng.randf()>0.45)
			s.cells = s.answer.duplicate()
			var candidates: Array=[0,1,2,3,4,5,6,7,8]
			shuffle_values(candidates)
			for i in range(2+int(difficulty/2.0)): s.cells[candidates[i]]=not s.cells[candidates[i]]
		"maze_runner": s.target = Vector2(170,310)
		"gravity_flip":
			s.y = 325.0
			s.lane = 1
			s.obstacles = [{"x": 920.0, "lane": 1}, {"x": 1260.0, "lane": 0}, {"x": 1600.0, "lane": 1}]
		"word_sort":
			s.words = ["APPLE", "HAMMER", "PEAR", "WRENCH", "BANANA", "SAW"]
			s.goal = 6
		"echo_taps": s.beats = [2.7, 2.7+rng.randf_range(0.45,0.75), 2.7+rng.randf_range(1.35,1.8)]
		"door_peek": s.open_at = rng.randf_range(1.5,3.5)
	queue_redraw()

func shuffle_values(values: Array) -> void:
	for i in range(values.size()-1,0,-1):
		var j: int = rng.randi_range(0,i)
		var old: Variant = values[i]
		values[i] = values[j]
		values[j] = old

func new_target() -> void:
	s.target = Vector2(rng.randf_range(150,810),rng.randf_range(130,360))

func tick(delta: float) -> void:
	if finished: return
	s.t = float(s.t) + delta
	match mode:
		"target_lock":
			s.target.x = clampf(float(s.target.x) + sin(elapsed*3.0) * delta * (8.0+difficulty*5.0),100,860)
		"reactor_parry":
			s.value = float(s.value) + delta * (0.7+difficulty*0.055)
			if float(s.value) > 1.13: lose()
		"power_sequence":
			if elapsed > float(s.goal)*0.52+0.4: s.phase = 1
		"stop_bar": s.value = (sin(elapsed*(2.1+difficulty*0.13))+1.0)*0.5
		"rhythm_knock", "echo_taps":
			if int(s.n) < s.beats.size() and elapsed > float(s.beats[s.n]) + 0.29: lose()
		"whack_mole":
			if float(s.t) > 1.1-difficulty*0.045:
				s.answer = (int(s.answer)+rng.randi_range(1,5))%6
				s.t = 0.0
		"coin_catch":
			s.x = clampf(float(s.x)+float(s.axis.x)*delta*560,120,840)
			s.target.y += delta*(180+difficulty*15)
			if float(s.target.y) >= 366:
				if absf(float(s.target.x)-float(s.x)) < 70:
					progress(Vector2(s.x,385))
					s.target = Vector2(rng.randf_range(180,780),-20)
				else: lose()
		"shield_turn":
			if float(s.t) > 1.65-difficulty*0.09: lose()
		"balloon_pump":
			s.value = maxf(0,float(s.value)-delta*(0.55+difficulty*0.09))
		"hold_balance":
			if s.held:
				s.value = float(s.value)+delta*(0.30+difficulty*0.035)
				if float(s.value)>0.91: lose()
		"orbit_snap": s.angle = fmod(float(s.angle)+delta*(1.8+difficulty*0.17),TAU)
		"maze_runner":
			var next: Vector2 = s.target + Vector2(s.axis)*delta*(195+difficulty*4)
			next = next.clamp(Vector2(100,115),Vector2(860,385))
			var wall1: Rect2 = Rect2(315,175,75,250)
			var wall2: Rect2 = Rect2(570,70,75,245)
			if wall1.grow(18).has_point(next) or wall2.grow(18).has_point(next):
				feedback(next,false)
			else: s.target = next
			if Vector2(s.target).distance_to(Vector2(810,180)) < 36: win()
		"gravity_flip":
			s.y = move_toward(float(s.y),155.0 if int(s.lane)==0 else 325.0,delta*820)
			for obstacle in s.obstacles:
				obstacle.x = float(obstacle.x)-delta*(245+difficulty*17)
				var oy: float = 155.0 if int(obstacle.lane)==0 else 325.0
				if absf(float(obstacle.x)-190)<43 and absf(float(s.y)-oy)<46: lose()
			if float(s.obstacles[-1].x) < 100: win()
	queue_redraw()

func handle_action(action: String, point: Vector2, value: Vector2) -> void:
	if action=='cancel': cancel_input(); return
	if finished: return
	var tap: bool = action == "press" or action == "action"
	# Swipe choices commit on release, so a swipe start cannot select a wrong box.
	if mode in ["safe_dial","fuse_cut","word_sort"]:
		if action=="press": s.gesture_swiped=false
		tap=action=="action" or (action=="release" and not s.gesture_swiped)
		if action=="swipe": s.gesture_swiped=true
	if action == "move": s.axis = value
	match mode:
		"target_lock":
			if tap and point.distance_to(s.target)<maxf(35,59-difficulty*3):
				progress(point)
				new_target()
		"reactor_parry":
			if tap:
				if absf(float(s.value)-0.92) < 0.16-difficulty*0.009:
					progress(Vector2(700,240))
					s.value = 0.0
				else: lose()
		"power_sequence":
			if tap and int(s.phase)==1:
				var selected: int = pad_at(point)
				if selected >= 0:
					if selected == int(s.seq[s.n]): progress(point)
					else: lose()
		"stop_bar":
			if tap:
				if absf(float(s.value)-float(s.center))<0.115-difficulty*0.008: win()
				else: lose()
		"odd_one":
			if tap:
				var selected: int = grid_at(point,4,3,Vector2(180,105),Vector2(150,100))
				if selected >= 0:
					if selected == int(s.answer):
						progress(point)
						s.answer = (int(s.answer)+rng.randi_range(1,11))%12
					else: lose()
		"rhythm_knock", "echo_taps":
			if tap:
				if absf(elapsed-float(s.beats[s.n])) < 0.27-difficulty*0.012:
					s.n = int(s.n)+1
					feedback(point)
					if int(s.n)==s.beats.size(): win()
				elif mode=="rhythm_knock" or elapsed>2.3: lose()
		"whack_mole":
			if tap:
				var selected: int = grid_at(point,3,2,Vector2(210,110),Vector2(180,145))
				if selected>=0:
					if selected==int(s.answer):
						progress(point)
						s.answer=(int(s.answer)+rng.randi_range(1,5))%6
						s.t=0.0
					else: lose()
		"coin_catch":
			if action=="drag" or tap: s.x=clampf(point.x,120,840)
		"shield_turn", "mirror_match":
			var direction: int = -1
			if action=="direction" or action=="swipe": direction=direction_index(value)
			elif tap: direction=pad_at(point)
			if direction>=0:
				var expected: int = int(s.seq[s.n])
				if mode=="mirror_match": expected=(expected+2)%4
				if direction==expected:
					progress(Vector2(480,240))
					s.t=0.0
				else: lose()
		"trace_wire":
			if action=="press" and point.distance_to(s.path[0])<60:
				s.held=true
				s.idx=1
			if (action=="drag" or action=="action") and (s.held or action=="action"):
				if point.distance_to(s.path[s.idx])<58:
					s.idx=int(s.idx)+1
					feedback(point)
					if int(s.idx)==s.path.size(): win()
			if action=="release": s.held=false
		"balloon_pump":
			if tap:
				s.value=float(s.value)+1.0
				feedback(Vector2(480,240))
				if float(s.value)>=float(s.goal): win()
		"hold_balance":
			if tap: s.held=true
			if action=="release" and s.held:
				s.held=false
				if absf(float(s.value)-float(s.goal_value))<0.13-difficulty*0.009: win()
				else: lose()
		"color_switch":
			if tap:
				var selected: int=pad_at(point)
				if selected>=0:
					if selected==int(s.answer):
						progress(point)
						s.answer=(int(s.answer)+rng.randi_range(1,3))%4
						s.word=(int(s.answer)+rng.randi_range(1,3))%4
					else: lose()
		"number_order":
			if tap:
				var selected: int=grid_at(point,3,2,Vector2(210,110),Vector2(180,145))
				if selected>=0:
					if int(s.order[selected])==int(s.n)+1: progress(point)
					elif int(s.order[selected])>int(s.n): lose()
		"orbit_snap":
			if tap:
				if absf(wrapf(float(s.angle),-PI,PI))<0.30-difficulty*0.021: win()
				else: lose()
		"light_out":
			if tap:
				var selected: int=grid_at(point,3,3,Vector2(330,85),Vector2(100,100))
				if selected>=0:
					toggle_cross(selected)
					feedback(point)
					if not s.cells.has(true): win()
		"safe_dial":
			if action=="swipe" or action=="direction":
				if absf(value.x)>absf(value.y):
					var sign_x: int=1 if value.x>0 else -1
					if sign_x==int(s.seq[s.n]): progress(Vector2(480,240))
					else: lose()
			elif tap:
				var sign_x: int=1 if point.x>480 else -1
				if sign_x==int(s.seq[s.n]): progress(point)
				else: lose()
		"fuse_cut":
			if tap or action=="swipe":
				var selected: int=int((point.y-105)/72)
				if point.x>220 and point.x<760 and point.y>105 and point.y<393:
					if selected==int(s.answer): win()
					else: lose()
		"pixel_repair":
			if tap:
				var selected: int=grid_at(point,3,3,Vector2(550,95),Vector2(95,95))
				if selected>=0:
					s.cells[selected]=not s.cells[selected]
					if s.cells==s.answer: win()
		"maze_runner":
			if action=="drag": s.axis=(point-Vector2(s.target)).normalized() if point.distance_to(s.target)>12 else Vector2.ZERO
			if action=="release": s.axis=Vector2.ZERO
		"gravity_flip":
			if tap: s.lane=1-int(s.lane)
		"word_sort":
			if tap or action=="swipe" or action=="direction":
				var right: bool=point.x>=480 if tap else value.x>0
				if right==(int(s.n)%2==1): progress(Vector2(480,220))
				else: lose()
		"door_peek":
			if tap:
				if elapsed>=float(s.open_at) and elapsed<float(s.open_at)+0.75-difficulty*0.06: win()
				else: lose()
	queue_redraw()

func progress(point: Vector2) -> void:
	s.n=int(s.n)+1
	feedback(point)
	if int(s.n)>=int(s.goal): win(100+int(maxf(0,duration-elapsed)*5))

func direction_index(value: Vector2) -> int:
	if value.length()<0.2: return -1
	if absf(value.x)>absf(value.y): return 1 if value.x>0 else 3
	return 2 if value.y>0 else 0

func pad_at(point: Vector2) -> int:
	for i in range(4):
		if Rect2(90+i*200,330,180,100).has_point(point): return i
	return -1

func grid_at(point: Vector2, cols: int, rows: int, origin: Vector2, step: Vector2) -> int:
	var local: Vector2=point-origin
	if local.x<0 or local.y<0 or local.x>=cols*step.x or local.y>=rows*step.y: return -1
	return int(local.y/step.y)*cols+int(local.x/step.x)

func toggle_cross(index: int) -> void:
	for i in range(9):
		if absi(i%3-index%3)+absi(i/3-index/3)<=1: s.cells[i]=not s.cells[i]

func label(pos: Vector2, message: String, size: int=26, color: Color=INK) -> void:
	text_at(pos,message,size,color)

func panel(rect: Rect2, color: Color) -> void:
	box(Rect2(rect.position+Vector2(5,6),rect.size),INK)
	box(rect,color)
	draw_rect(rect,INK,false,3)

func pads(words: Array) -> void:
	for i in range(4):
		panel(Rect2(90+i*200,330,180,100),pad_colors[i])
		label(Vector2(110+i*200,389),str(words[i]),24)

func paint() -> void:
	if s.is_empty(): return
	label(Vector2(36,40),str(spec.get("objective","")),25)
	match mode:
		"target_lock":
			label(Vector2(36,84),"LOCKS  %d / %d"%[s.n,s.goal],22)
			var p: Vector2=s.target
			disc(p,62-difficulty*3,GOLD)
			draw_arc(p,65,0,TAU,32,INK,4)
			draw_line(p-Vector2(80,0),p+Vector2(80,0),INK,3)
			draw_line(p-Vector2(0,80),p+Vector2(0,80),INK,3)
			disc(p,12,RED)
		"reactor_parry":
			label(Vector2(90,110),"PARRY %d / %d - TAP IN THE GREEN RING"%[s.n,s.goal],24)
			draw_line(Vector2(110,240),Vector2(760,240),INK,5)
			draw_arc(Vector2(700,240),58,0,TAU,32,GREEN,14)
			disc(Vector2(100+float(s.value)*650,240),27,RED)
			hero(Vector2(795,250),1.4)
		"power_sequence":
			var active: int=-1
			if int(s.phase)==0:
				var step: int=int(elapsed/0.52)
				if step<s.seq.size() and fmod(elapsed,0.52)<0.37: active=int(s.seq[step])
				label(Vector2(290,145),"WATCH THE POWER CODE",30)
			else: label(Vector2(270,145),"REPEAT IT!  %d / %d"%[s.n,s.goal],30)
			pads(["1","2","3","4"])
			if active>=0:
				draw_rect(Rect2(84+active*200,324,192,112),PAPER,false,9)
				disc(Vector2(480,235),48,pad_colors[active])
		"stop_bar", "hold_balance":
			var center: float=float(s.center) if mode=="stop_bar" else float(s.goal_value)
			panel(Rect2(120,205,720,75),PAPER)
			box(Rect2(120+(center-0.095)*720,205,137,75),GREEN)
			box(Rect2(115+float(s.value)*720,186,10,113),RED)
			label(Vector2(200,365),"TAP TO STOP" if mode=="stop_bar" else "HOLD TO FILL - RELEASE IN GREEN",29)
		"odd_one":
			for i in range(12):
				var p: Vector2=Vector2(180+(i%4)*150,105+(i/4)*100)
				panel(Rect2(p+Vector2(5,5),Vector2(130,85)),PAPER)
				label(p+Vector2(48,61),"Q" if i==int(s.answer) else "O",48)
		"rhythm_knock":
			label(Vector2(220,110),"TAP AS THE DOTS HIT THE LINE",28)
			draw_line(Vector2(480,145),Vector2(480,350),RED,5)
			draw_line(Vector2(100,245),Vector2(860,245),INK,3)
			for i in range(s.beats.size()):
				var timing: float=float(s.beats[i])
				var bx: float=480+(timing-elapsed)*190
				if bx>85 and bx<875 and i>=int(s.n): disc(Vector2(bx,245),27,GOLD)
			label(Vector2(300,395),"%d / %d"%[s.n,s.beats.size()],32)
		"echo_taps":
			var preview: bool=elapsed<2.4
			var pulse: bool=false
			for beat in s.beats:
				if preview and absf(elapsed-(float(beat)-2.4))<0.11: pulse=true
			disc(Vector2(480,240),93 if pulse else 77,GOLD if pulse else BLUE)
			draw_arc(Vector2(480,240),112,0,TAU,36,INK,4)
			label(Vector2(335,110),"WATCH THE THREE FLASHES" if preview else "YOUR TURN - COPY THE RHYTHM",27)
			label(Vector2(437,257),"!" if pulse else str(s.n)+" / 3",37)
			label(Vector2(245,408),"REMEMBER THE GAPS" if preview else "THE FLASHES ARE NOW HIDDEN",27)
		"whack_mole", "number_order":
			for i in range(6):
				var p: Vector2=Vector2(210+(i%3)*180,110+(i/3)*145)
				panel(Rect2(p,Vector2(160,125)),BLUE if mode=="whack_mole" else PAPER)
				if mode=="whack_mole":
					disc(p+Vector2(80,80),45,INK)
					if i==int(s.answer):
						disc(p+Vector2(80,57),38,GOLD)
						label(p+Vector2(61,65),"!!",29)
				elif int(s.order[i])>int(s.n): label(p+Vector2(62,80),str(s.order[i]),48)
		"coin_catch":
			draw_line(Vector2(80,420),Vector2(880,420),INK,4)
			panel(Rect2(float(s.x)-65,370,130,42),BLUE)
			disc(s.target,25,GOLD)
			label(Vector2(s.target)-Vector2(9,-9),"$",27)
			label(Vector2(100,90),"CAUGHT %d / 3   DRAG THE BASKET"%s.n,25)
		"shield_turn", "mirror_match":
			label(Vector2(245,120),"BLOCK THE ARROW" if mode=="shield_turn" else "CHOOSE THE OPPOSITE",30)
			label(Vector2(395,240),arrows[int(s.seq[mini(int(s.n),s.seq.size()-1)])],48,RED)
			pads(arrows)
			if mode=="shield_turn": box(Rect2(280,280,maxf(0,400*(1-float(s.t)/(1.65-difficulty*0.09))),8),GOLD)
		"trace_wire":
			for i in range(s.path.size()-1): draw_line(s.path[i],s.path[i+1],INK,8)
			for i in range(s.path.size()):
				disc(s.path[i],39,GREEN if i<int(s.idx) else GOLD)
				label(Vector2(s.path[i])+Vector2(-10,10),str(i+1),30)
			label(Vector2(275,430),"DRAG FROM 1 THROUGH 5",25)
		"balloon_pump":
			var radius: float=40+float(s.value)*6
			draw_line(Vector2(480,270+radius),Vector2(480,440),INK,3)
			disc(Vector2(480,225),radius,RED)
			draw_arc(Vector2(480,225),40+float(s.goal)*6,0,TAU,40,INK,3)
			label(Vector2(370,425),"TAP TAP TAP!",31)
		"color_switch":
			var names: Array[String]=["RED","BLUE","GREEN","YELLOW"]
			label(Vector2(310,218),names[int(s.word)],68,pad_colors[int(s.answer)])
			label(Vector2(295,290),"MATCH THE INK COLOR",27)
			pads(names)
		"orbit_snap":
			var center: Vector2=Vector2(480,250)
			draw_arc(center,135,0,TAU,60,INK,5)
			draw_arc(center,135,-0.25,0.25,12,GREEN,27)
			disc(center+Vector2.from_angle(float(s.angle))*135,23,RED)
			label(Vector2(354,255),"TAP AT GREEN",28)
		"light_out":
			for i in range(9):
				panel(Rect2(335+(i%3)*100,90+(i/3)*100,90,90),GOLD if s.cells[i] else INK)
			label(Vector2(238,430),"TAP FLIPS A CROSS. TURN ALL OFF.",25)
		"safe_dial":
			draw_arc(Vector2(480,250),115,0,TAU,50,INK,8)
			label(Vector2(391,263),"%d / %d"%[s.n,s.goal],45)
			var code: String="CODE:  "
			for turn in s.seq: code += " >  " if int(turn)==1 else " <  "
			label(Vector2(240,110),code,35)
			panel(Rect2(120,190,170,110),BLUE)
			panel(Rect2(670,190,170,110),RED)
			label(Vector2(149,255),"< LEFT",27)
			label(Vector2(682,255),"RIGHT >",27)
		"fuse_cut":
			label(Vector2(140,85),"CUT WIRE %d - KEEP THE REACTOR ALIVE"%(int(s.answer)+1),26)
			for i in range(4):
				var y: float=141+i*72
				draw_line(Vector2(235,y),Vector2(745,y),INK,26)
				draw_line(Vector2(240,y),Vector2(740,y+3),pad_colors[i],17)
				label(Vector2(180,y+10),str(i+1),30)
		"pixel_repair":
			label(Vector2(140,85),"BLUEPRINT",25)
			label(Vector2(570,85),"REPAIR HERE",25)
			for i in range(9):
				panel(Rect2(145+(i%3)*75,125+(i/3)*75,68,68),BLUE if s.answer[i] else PAPER)
				panel(Rect2(555+(i%3)*95,100+(i/3)*95,85,85),BLUE if s.cells[i] else PAPER)
		"maze_runner":
			panel(Rect2(315,175,75,250),RED)
			panel(Rect2(570,70,75,245),RED)
			disc(Vector2(810,180),38,GREEN)
			label(Vector2(782,190),"GO",25)
			hero(s.target,0.75)
			label(Vector2(105,460),"MOVE / DRAG AROUND THE TWO WALLS",23)
		"gravity_flip":
			draw_line(Vector2(90,115),Vector2(900,115),INK,5)
			draw_line(Vector2(90,365),Vector2(900,365),INK,5)
			for obstacle in s.obstacles:
				var oy: float=155 if int(obstacle.lane)==0 else 325
				panel(Rect2(float(obstacle.x)-25,oy-35,50,70),RED)
			hero(Vector2(190,float(s.y)),0.8)
			label(Vector2(265,425),"TAP TO FLIP GRAVITY",30)
		"word_sort":
			label(Vector2(335,222),str(s.words[mini(int(s.n),5)]),49)
			panel(Rect2(120,305,310,120),GREEN)
			panel(Rect2(530,305,310,120),GOLD)
			label(Vector2(175,377),"< FRUIT",32)
			label(Vector2(580,377),"TOOLS >",32)
		"door_peek":
			var opened: bool=elapsed>=float(s.open_at) and elapsed<float(s.open_at)+0.75-difficulty*0.06
			panel(Rect2(360,105,240,300),GREEN if opened else RED)
			if opened:
				hero(Vector2(480,285),1.9)
				label(Vector2(390,165),"NOW!",40)
			else:
				disc(Vector2(565,267),13,GOLD)
				label(Vector2(390,185),"WAIT...",35)
