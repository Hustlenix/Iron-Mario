extends "res://microgames/microgame_base.gd"

var fuel: float = 35.0
var hygiene: float = 35.0
var joy: float = 35.0
var heat: float = 10.0
var selected: int = 0
var cooldown: float = 0.0
var cared: int = 0
var actions: Array[int] = [0,0,0,0]
var misses: int = 0
var toy := Vector2.ZERO
var phase: float = 0.0

func setup() -> void:
	cared = 0
	selected = 0
	actions = [0,0,0,0]
	misses = 0
	new_visit()

func new_visit() -> void:
	fuel = 34+rng.randf_range(0,7)
	hygiene = 34+rng.randf_range(0,7)
	joy = 34+rng.randf_range(0,7)
	heat = 10
	cooldown = 0
	phase = 0
	toy = Vector2(595,235)

func perform() -> void:
	if cooldown>0: return
	match selected:
		0:
			fuel = minf(100,fuel+32)
			hygiene = maxf(0,hygiene-8)
			joy = minf(100,joy+4)
			heat += 24
		1:
			hygiene = minf(100,hygiene+40)
			fuel = maxf(0,fuel-2)
			joy = maxf(0,joy-6)
		2:
			if absf(wrapf(phase,-PI,PI))>0.55:
				misses += 1
				feedback(toy,false)
				cooldown = 0.25
				return
			joy = minf(100,joy+35)
			fuel = maxf(0,fuel-8)
			heat = maxf(0,heat-8)
		3:
			heat = maxf(0,heat-30)
			fuel = maxf(0,fuel-3)
	actions[selected] += 1
	cooldown = 0.6
	feedback(Vector2(480,240))
	if heat>=100: lose()

func handle_action(action: String, point: Vector2, value: Vector2) -> void:
	if finished: return
	if action == 'select': selected = clampi(int(value.x)-1,0,3)
	elif action == 'secondary': selected = (selected+1)%4
	elif action == 'action': perform()
	elif action == 'press':
		if point.y>=390:
			selected = clampi(int((point.x-45)/220),0,3)
			if selected!=2: perform()
		elif selected==2 and point.distance_to(Vector2(595,235))<68: perform()

func tick(delta: float) -> void:
	cooldown = maxf(0,cooldown-delta)
	fuel = maxf(0,fuel-0.15*delta)
	hygiene = maxf(0,hygiene-0.12*delta)
	joy = maxf(0,joy-0.1*delta)
	heat = maxf(0,heat-3*delta)
	phase += delta*1.65
	toy = Vector2(480,235)+Vector2(cos(phase),sin(phase))*115
	if fuel>=75 and hygiene>=75 and joy>=75 and heat<70:
		cared += 1
		points += 100
		feedback(Vector2(480,235))
		if cared==3:
			win(points+int(duration-elapsed))
			return
		new_visit()
	if fuel<=0 or hygiene<=0 or joy<=0: lose()

func paint() -> void:
	text_at(Vector2(24,35),'CARE SHIFT  '+str(cared)+'/3  KEEP ALL NEEDS ABOVE 75',24)
	text_at(Vector2(24,66),'1-4 select + Space. Play: catch the orb inside the green ring.',18)
	var values: Array[float] = [fuel,hygiene,joy,heat]
	var labels: Array[String] = ['FUEL','CLEAN','JOY','HEAT']
	for i in 4:
		var x: float = 40+i*230
		text_at(Vector2(x,104),labels[i]+' '+str(int(values[i])),19)
		box(Rect2(x,115,200,15),PAPER)
		draw_rect(Rect2(x+2,117,values[i]*1.96,11),RED if i==3 else GREEN)
	disc(Vector2(480,245),65,GOLD)
	draw_line(Vector2(449,230),Vector2(459,230),INK,7)
	draw_line(Vector2(501,230),Vector2(511,230),INK,7)
	draw_arc(Vector2(480,238),28,0.15,PI-0.15,18,INK,5)
	text_at(Vector2(460,293),'+',32)
	if selected==2:
		draw_arc(Vector2(480,235),115,-0.55,0.55,18,GREEN,12)
		disc(toy,16,BLUE)
		text_at(Vector2(610,240),'CATCH',22,GREEN)
	else: text_at(Vector2(346,365),'A tiny reactor with big feelings.',20)
	for i in 4:
		box(Rect2(45+i*220,390,207,86),GOLD if selected==i else PAPER)
		text_at(Vector2(56+i*220,425),str(i+1)+' '+['FEED','POLISH','PLAY','COOL'][i],22)
		text_at(Vector2(58+i*220,450),['Fuel+, heat+','Clean+, joy-','Timed joy+','Heat-, fuel-'][i],17)
	if cooldown>0: text_at(Vector2(763,360),'...'+str(snappedf(cooldown,0.1))+'s',22)
