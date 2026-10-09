extends "res://microgames/microgame_base.gd"

const COSTS: Array[int] = [70,60,35]
const UNIT_NAMES: Array[String] = ['GENERATOR','TURRET','WALL']
var units: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var bolts: Array[Dictionary] = []
var currency: int = 150
var selected: int = 1
var cursor_cell := Vector2i(1,0)
var spawned: int = 0
var destroyed: int = 0
var spawn_clock: float = 1.8
var rejected: int = 0
var breaches: int = 0

func setup() -> void:
	units.clear()
	enemies.clear()
	bolts.clear()
	currency = 150
	selected = 1
	cursor_cell = Vector2i(1,0)
	spawned = 0
	destroyed = 0
	spawn_clock = 1.8
	rejected = 0
	breaches = 0

func cell_point(cell: Vector2i) -> Vector2:
	return Vector2(240+cell.x*95,145+cell.y*95)

func build(cell: Vector2i) -> void:
	if cell.x<0 or cell.x>5 or cell.y<0 or cell.y>2: return
	for u in units:
		if u.cell == cell:
			rejected += 1
			return
	if currency<COSTS[selected]:
		rejected += 1
		feedback(cell_point(cell),false)
		return
	currency -= COSTS[selected]
	units.append({'cell':cell,'kind':selected,'hp':180.0 if selected==2 else 95.0,'clock':0.0})
	feedback(cell_point(cell))

func handle_action(action: String, point: Vector2, value: Vector2) -> void:
	if finished: return
	if action == 'select': selected = clampi(int(value.x)-1,0,2)
	elif action == 'secondary': selected = (selected+1)%3
	elif action == 'direction':
		cursor_cell += Vector2i(int(value.x),int(value.y))
		cursor_cell = cursor_cell.clamp(Vector2i.ZERO,Vector2i(5,2))
	elif action == 'action': build(cursor_cell)
	elif action == 'press':
		if point.y>=388:
			selected = clampi(int((point.x-150)/230),0,2)
		elif point.x>=195 and point.x<765 and point.y>=98 and point.y<385:
			cursor_cell = Vector2i(int((point.x-195)/95),int((point.y-98)/95))
			build(cursor_cell)

func tick(delta: float) -> void:
	spawn_clock -= delta
	if spawn_clock<=0 and spawned<12:
		var lane: int = spawned%3
		enemies.append({'x':925.0,'lane':lane,'hp':65.0+(20 if spawned>5 else 0),'speed':26.0+difficulty*2,'attack':0.0})
		spawned += 1
		spawn_clock += 1.75
	for u in units:
		u.clock += delta
		if u.kind==0 and u.clock>=2.2:
			u.clock -= 2.2
			currency += 25
			feedback(cell_point(u.cell))
		elif u.kind==1 and u.clock>=0.8:
			var sees: bool = false
			for e in enemies:
				if e.lane==u.cell.y and e.x>cell_point(u.cell).x and e.hp>0: sees = true
			if sees:
				u.clock = 0
				bolts.append({'x':cell_point(u.cell).x+24,'lane':u.cell.y,'spent':false})
	for e in enemies:
		if e.hp<=0: continue
		var blocked: bool = false
		for u in units:
			if u.cell.y==e.lane and absf(e.x-cell_point(u.cell).x)<43 and u.hp>0:
				blocked = true
				u.hp -= (35+difficulty*2)*delta
				break
		if not blocked: e.x -= e.speed*delta
		if e.x<165:
			breaches += 1
			lose()
			return
	for b in bolts:
		var previous_x: float = b.x
		b.x += 440*delta
		for e in enemies:
			if not b.spent and e.hp>0 and e.lane==b.lane and e.x>=previous_x-22 and e.x<=b.x+22:
				b.spent = true
				e.hp -= 30
				feedback(Vector2(e.x,145+e.lane*95))
				if e.hp<=0:
					destroyed += 1
					currency += 15
					points += 35
	units = units.filter(func(u:Dictionary)->bool:return u.hp>0)
	enemies = enemies.filter(func(e:Dictionary)->bool:return e.hp>0)
	bolts = bolts.filter(func(b:Dictionary)->bool:return not b.spent and b.x<960)
	if destroyed==12:
		win(points+100)

func paint() -> void:
	text_at(Vector2(18,34),'DEFEND THREE ROOFTOPS  '+str(destroyed)+'/12',25)
	text_at(Vector2(18,65),'1/2/3 select, arrows + Space build. Tap a card, then a tile.',18)
	text_at(Vector2(777,35),'ENERGY '+str(currency),21)
	for row in 3:
		box(Rect2(195,100+row*95,615,90),Color('#dbe6d6'))
		for col in 6:
			var p := cell_point(Vector2i(col,row))
			draw_rect(Rect2(p-Vector2(45,42),Vector2(90,84)),Color(INK,0.18),false,1)
		box(Rect2(105,120+row*95,50,50),GOLD)
	for u in units:
		var p := cell_point(u.cell)
		box(Rect2(p-Vector2(30,27),Vector2(60,54)),[GOLD,BLUE,GREEN][u.kind])
		text_at(p+Vector2(-9,8),['+','>','#'][u.kind],26)
		draw_line(p+Vector2(-25,34),p+Vector2(-25+50*u.hp/(180 if u.kind==2 else 95),34),RED,4)
	for e in enemies:
		var p := Vector2(e.x,145+e.lane*95)
		box(Rect2(p-Vector2(20,25),Vector2(40,50)),RED)
		text_at(p+Vector2(-9,8),'!',26)
	for b in bolts: disc(Vector2(b.x,145+b.lane*95),6,GOLD)
	draw_rect(Rect2(cell_point(cursor_cell)-Vector2(43,40),Vector2(86,80)),INK,false,4)
	for i in 3:
		box(Rect2(150+i*230,388,220,88),GOLD if selected==i else PAPER)
		text_at(Vector2(163+i*230,431),str(i+1)+' '+UNIT_NAMES[i],18)
		text_at(Vector2(165+i*230,456),str(COSTS[i])+' ENERGY',17)

