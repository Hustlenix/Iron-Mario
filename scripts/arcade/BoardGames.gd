extends "res://scripts/arcade/ArcadeGameBase.gd"
var grid: Dictionary = {}
var walls: Dictionary = {}
var cells: Array = []
var cursor = 4
var awaiting = false
var room = 0
var tunnel = 0
var aiming = false
var bolts = 3
var creature_alive = true
var caches = [2,10]
var found: Array = []
var snake: Array[Vector2i] = []
var direction = Vector2i.RIGHT
var turns: Array[Vector2i] = []
var food = Vector2i(12,6)
var step_clock = 0.0
var meals = 0
var post_warning = -1.0
var pending_post = Vector2i(-1,-1)
var player = Vector2i(1,1)
var requested = Vector2i.ZERO
var robots: Array[Dictionary] = []
var robot_clock = 0.0
var power = 0.0
var crystals: Dictionary = {}
var lanes: Array[Dictionary] = []
var frog = Vector2(220,357)
var homes: Array = []
var crossing_time = 25.0
var hop_clock = 0.0
var pyramid_size = 4
var coats = 1
var bug = Vector2i(3,1)
var recall = true
var bug_clock = 2.5
var crates: Array[Vector2i] = []
var docks: Array[Vector2i] = []
var history: Array = []
var room_rows: Array = []
var piece: Array[Vector2i] = []
var piece_at = Vector2i(4,0)
var piece_kind = 0
var next_kind = 0
var bag: Array = []
var lines_cleared = 0
var repeat_clock = 0.0
const MAZE_ORIGIN = Vector2(318,155)
const HOP_ORIGIN = Vector2(419,150)
const ROOMS = [
	["#######","#     #","# .$@ #","#     #","#######"],
	["########","#      #","# . $@ #","# . $  #","#      #","########"],
	["########","#   .  #","#   $  #","# #    #","# .$ @ #","#      #","########"],
	["#########","# .   . #","# $ # $ #","#   #   #","#   @   #","#       #","#########"],
	["#########","# . . . #","# $ $ $ #","#   #   #","#       #","#   @   #","#########"]
]
const SHAPES = [
	[Vector2i(-1,0),Vector2i(0,0),Vector2i(1,0),Vector2i(2,0)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)],
	[Vector2i(-1,0),Vector2i(0,0),Vector2i(1,0),Vector2i(0,1)],
	[Vector2i(-1,0),Vector2i(0,0),Vector2i(0,1),Vector2i(1,1)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(-1,1),Vector2i(0,1)],
	[Vector2i(-1,0),Vector2i(0,0),Vector2i(1,0),Vector2i(-1,1)],
	[Vector2i(-1,0),Vector2i(0,0),Vector2i(1,0),Vector2i(1,1)]
]
func setup() -> void:
	match game_id:
		"grid_x":
			primary_label="PLACE"
			reset_x()
		"dark_cavern":
			primary_label="ENTER"
			secondary_label="AIM"
			use_secondary=true
		"byte_munch":
			lives=1
			snake.assign([Vector2i(6,6),Vector2i(5,6),Vector2i(4,6)])
			place_food()
		"dot_gobbler":make_maze()
		"hopway":
			lives=4
			primary_label="HOP"
			make_lanes()
		"color_steps":
			primary_label="RECALL"
			make_pyramid()
		"crate_shift":
			primary_label="NEXT"
			secondary_label="UNDO"
			use_secondary=true
			make_room()
		"stackfall":
			primary_label="DROP"
			secondary_label="ROTATE <"
			use_secondary=true
			hint="LEFT/RIGHT MOVE. UP ROTATES. SPACE DROPS. Z REVERSES. CLEAR 24 ROWS."
			next_kind=take_bag()
			spawn_piece()
func tick(delta: float) -> void:
	hop_clock=maxf(0,hop_clock-delta)
	repeat_clock=maxf(0,repeat_clock-delta)
	match game_id:
		"byte_munch":snake_tick(delta)
		"dot_gobbler":maze_tick(delta)
		"hopway":hop_tick(delta)
		"color_steps":pyramid_tick(delta)
		"stackfall":stack_tick(delta)
func on_action(action: String) -> void:
	var dir=Vector2i.ZERO
	if action in ["left","up","down","right"]:dir=DIRECTIONS[["left","up","down","right"].find(action)]
	match game_id:
		"grid_x":
			if dir!=Vector2i.ZERO:cursor=clampi(cursor+dir.x+dir.y*3,0,8)
			if action=="primary":
				if awaiting:reset_x()
				else:place_x(cursor)
		"dark_cavern":
			if action=="left":tunnel=posmod(tunnel-1,3)
			elif action=="right":tunnel=(tunnel+1)%3
			elif action=="secondary":aiming=not aiming;primary_label="FIRE" if aiming else "ENTER"
			elif action=="primary":enter_cavern()
		"byte_munch":
			if dir!=Vector2i.ZERO:queue_turn(dir)
		"dot_gobbler":
			if dir!=Vector2i.ZERO:requested=dir
			if action=="primary" and awaiting:stage+=1;awaiting=false;make_maze()
		"hopway":
			if action=="primary":dir=Vector2i.UP
			if dir!=Vector2i.ZERO:hop(dir)
		"color_steps":pyramid_action(action)
		"crate_shift":
			if dir!=Vector2i.ZERO:push_crate(dir)
			if action=="secondary" and not history.is_empty():
				var snapshot=history.pop_back()
				player=snapshot[0];crates.assign(snapshot[1]);awaiting=false
			if action=="primary" and awaiting:stage+=1;make_room()
		"stackfall":
			if action=="left":move_piece(Vector2i.LEFT);repeat_clock=0.18
			elif action=="right":move_piece(Vector2i.RIGHT);repeat_clock=0.18
			elif action in ["up","secondary"]:rotate_piece(1 if action=="up" else -1)
			elif action=="primary":
				while piece_valid(piece,piece_at+Vector2i.DOWN):piece_at.y+=1;score+=2
				lock_piece()
func on_pointer(at: Vector2,active: bool) -> void:
	if not active:return
	match game_id:
		"grid_x":
			var local=at-Vector2(370,160)
			if local.x>=0 and local.x<540 and local.y>=0 and local.y<360:cursor=int(local.y/120)*3+int(local.x/180);place_x(cursor)
		"dark_cavern":
			for i in range(3):
				if Rect2(210+i*300,355,260,125).has_point(at):tunnel=i;enter_cavern()
		"hopway":
			var diff=at-(HOP_ORIGIN+frog)
			hop(Vector2i(signf(diff.x),0) if absf(diff.x)>absf(diff.y) else Vector2i(0,signf(diff.y)))
func on_drag(at: Vector2) -> void:
	if game_id in ["dot_gobbler","byte_munch"] and pointer_down:
		var center=MAZE_ORIGIN+Vector2(player)*28 if game_id=="dot_gobbler" else Vector2(280,155)+Vector2(snake[0])*30
		var diff=at-center
		if diff.length()>18:
			var dir=Vector2i(signf(diff.x),0) if absf(diff.x)>absf(diff.y) else Vector2i(0,signf(diff.y))
			if game_id=="dot_gobbler":requested=dir
			else:queue_turn(dir)
func reset_x() -> void:
	cells=[0,0,0,0,0,0,0,0,0]
	awaiting=false
	status="TERMINAL %d / 3. YOU ARE X." % stage
func x_winner(board: Array) -> int:
	for ids in [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]]:
		if board[ids[0]]!=0 and board[ids[0]]==board[ids[1]] and board[ids[1]]==board[ids[2]]:return board[ids[0]]
	return 0 if board.has(0) else 3
func place_x(index: int) -> void:
	if awaiting or ended or cells[index]!=0:return
	cells[index]=1
	SoundFX.play_click()
	if finish_x():return
	var open:Array=[]
	for i in range(9):
		if cells[i]==0:open.append(i)
	var choice:int=open[rng.randi_range(0,open.size()-1)]
	if stage==2:
		for mark in [1,2]:
			for i in open:
				var copy=cells.duplicate();copy[i]=mark
				if x_winner(copy)==mark:choice=i
	elif stage>=3:
		var value=-100
		for i in open:
			var copy=cells.duplicate();copy[i]=2
			var result=minimax(copy,false)
			if result>value:value=result;choice=i
	cells[choice]=2
	finish_x()
func minimax(board: Array,ai: bool) -> int:
	var result=x_winner(board)
	if result!=0:return 10 if result==2 else (-10 if result==1 else 0)
	var best=-100 if ai else 100
	for i in range(9):
		if board[i]!=0:continue
		var copy=board.duplicate();copy[i]=2 if ai else 1
		var value=minimax(copy,not ai)
		best=maxi(best,value) if ai else mini(best,value)
	return best
func finish_x() -> bool:
	var result=x_winner(cells)
	if result==0:return false
	awaiting=true
	if result==2:
		status="COMPUTER WINS. ACTION RETRIES TERMINAL %d." % stage
	else:
		score+=100 if result==1 else 50
		if stage==3:complete(true,"ALL THREE TERMINALS CLEARED!")
		else:
			stage+=1
			status="WIN / DRAW! ACTION OPENS TERMINAL %d." % stage
	return true
func neighbors(id: int) -> Array:
	return [(id+1)%12,(id+11)%12,(id+6)%12]
func enter_cavern() -> void:
	var target:int=neighbors(room)[tunnel]
	if aiming:
		if bolts<=0:status="NO BOLTS LEFT. RETRY TO PLAN A NEW ROUTE.";return
		bolts-=1
		if target==7 and creature_alive:creature_alive=false;score+=250;SoundFX.play_collect()
		else:SoundFX.play_click()
		if bolts==0 and creature_alive:complete(false,"OUT OF BOLTS. FOLLOW THE SCRAPING NEXT TIME.")
	else:
		if target in [4,9] or (target==7 and creature_alive):
			invulnerable=0
			damage("LOST IN THE CAVERN. YOUR CLUES WERE NEARBY.")
			room=0
		else:
			room=target
			if caches.has(room) and not found.has(room):found.append(room);score+=200;SoundFX.play_collect()
			if room==0 and found.size()==2 and not creature_alive:complete(true,"BOTH CACHES RECOVERED. CREATURE DEFEATED. HOME SAFE!")
	tunnel=0
func queue_turn(dir: Vector2i) -> void:
	var previous:Vector2i=turns.back() if not turns.is_empty() else direction
	if dir!=previous and dir!=-previous and turns.size()<2:turns.append(dir)
func place_food() -> void:
	var free:Array[Vector2i]=[]
	for y in range(12):
		for x in range(24):
			var cell=Vector2i(x,y)
			if not snake.has(cell) and not walls.has(cell):free.append(cell)
	if free.is_empty():complete(true,"THE WHOLE GRID IS YOUR BYTE TRAIN!")
	else:food=free[rng.randi_range(0,free.size()-1)]
func snake_tick(delta: float) -> void:
	if post_warning>=0:
		post_warning-=delta
		if post_warning<0:
			if not snake.has(pending_post) and food!=pending_post:walls[pending_post]=true
			pending_post=Vector2i(-1,-1)
	step_clock+=delta
	var interval=maxf(0.075,0.19-meals*0.004)
	while step_clock>=interval and not ended:
		step_clock-=interval
		if not turns.is_empty():direction=turns.pop_front()
		var head:Vector2i=snake[0]+direction
		var grows=head==food
		var body=snake.duplicate()
		if not grows:body.pop_back()
		if head.x<0 or head.y<0 or head.x>=24 or head.y>=12 or walls.has(head) or body.has(head):complete(false,"BYTE TRAIN LENGTH %d / FOOD %d" % [snake.size(),meals]);return
		snake.push_front(head)
		if grows:
			meals+=1;score+=100;SoundFX.play_collect();place_food()
			if meals%4==0:
				var choices:Array=[]
				for y in range(1,11):
					for x in range(1,23):
						var c=Vector2i(x,y)
						if not snake.has(c) and not walls.has(c) and food!=c:choices.append(c)
				if not choices.is_empty():pending_post=choices[rng.randi_range(0,choices.size()-1)];post_warning=1.4
		else:snake.pop_back()
	status="FOOD %d / LENGTH %d%s" % [meals,snake.size()," / NEW POST WARNING!" if post_warning>=0 else ""]
func make_maze() -> void:
	awaiting=false
	walls.clear();grid.clear();crystals.clear();robots.clear()
	player=Vector2i(1,1);direction=Vector2i.ZERO;requested=Vector2i.ZERO;step_clock=0;power=0
	for y in range(13):
		for x in range(23):
			var cell=Vector2i(x,y)
			var border=x==0 or y==0 or x==22 or y==12
			var pillar=x in ([4,8,12,16,20] if stage==1 else [3,7,11,15,19]) and y>1 and y<11 and y not in ([3,9] if stage==1 else [4,8])
			if border or pillar:walls[cell]=true
			elif cell!=player:grid[cell]=true
	for at in [Vector2i(1,11),Vector2i(21,1),Vector2i(21,11),Vector2i(10,6)]:
		if not walls.has(at):crystals[at]=true
	for at in [Vector2i(21,11),Vector2i(21,1),Vector2i(11,11)]:robots.append({"cell":at,"home":at,"sleep":1.5})
func maze_tick(delta: float) -> void:
	if awaiting:return
	power=maxf(0,power-delta)
	step_clock+=delta;robot_clock+=delta
	if step_clock>=0.13:
		step_clock=0
		if requested!=Vector2i.ZERO and not walls.has(player+requested):direction=requested
		if direction!=Vector2i.ZERO and not walls.has(player+direction):player+=direction
		if grid.has(player):grid.erase(player);score+=10
		if crystals.has(player):crystals.erase(player);power=7;score+=50;SoundFX.play_collect()
	if robot_clock>=0.28:
		robot_clock=0
		for robot in robots:
			if robot["sleep"]>0:robot["sleep"]-=0.28;continue
			var options:Array=[]
			for dir in DIRECTIONS:
				var at:Vector2i=robot["cell"]+dir
				if not walls.has(at):options.append(at)
			if not options.is_empty():
				options.sort_custom(func(a,b):return a.distance_squared_to(player)<b.distance_squared_to(player))
				robot["cell"]=options.back() if power>0 else options.front()
	for robot in robots:
		if robot["sleep"]<=0 and robot["cell"]==player:
			if power>0:score+=100;robot["cell"]=robot["home"];robot["sleep"]=2
			elif damage("THE ROBOTS CAUGHT YOU. YOUR DOTS STAY COLLECTED."):
				player=Vector2i(1,1);direction=Vector2i.ZERO
				for other in robots:other["cell"]=other["home"];other["sleep"]=1.5
	if grid.is_empty():
		if stage>=2:complete(true,"BOTH ORIGINAL MAZES CLEARED!")
		else:awaiting=true;status="MAZE CLEAR! ACTION OPENS MAZE TWO."
	else:status="DOTS %d   POWER %.1f" % [grid.size(),power]
func make_lanes() -> void:
	lanes.clear();homes.clear();frog=Vector2(221,357);crossing_time=25
	for row in [1,2,3,5,6,8,9]:
		lanes.append({"row":row,"offset":float(row*53),"speed":(45+row*5+stage*10)*(1 if row%2 else -1),"water":row<=3})
func hop(dir: Vector2i) -> void:
	if hop_clock>0:return
	frog+=Vector2(dir)*34
	frog.x=clampf(frog.x,17,425)
	frog.y=clampf(frog.y,17,357)
	hop_clock=0.13
	SoundFX.play_click()
func hop_tick(delta: float) -> void:
	crossing_time-=delta
	for lane in lanes:lane["offset"]=fposmod(float(lane["offset"])+float(lane["speed"])*delta,680)
	var row=int(frog.y/34)
	for lane in lanes:
		if lane["row"]!=row:continue
		var on_log=false
		for i in range(-3,5):
			var x=i*170+float(lane["offset"])-340
			var r=Rect2(x,row*34+3,130 if lane["water"] else 75,28)
			if r.grow(-3).has_point(frog):on_log=true
		if lane["water"]:
			if on_log:frog.x+=float(lane["speed"])*delta
			else:hop_fail();return
		elif on_log:hop_fail();return
	if frog.x<0 or frog.x>442 or crossing_time<=0:hop_fail();return
	if row==0:
		var col=int(frog.x/34)
		var home_index=-1
		for i in range(4):
			if abs(col-[1,4,8,11][i])<=0:home_index=i
		if home_index<0 or homes.has(home_index):hop_fail();return
		homes.append(home_index);score+=200;frog=Vector2(221,357);crossing_time=25;SoundFX.play_collect()
		if homes.size()==4:
			if stage==3:complete(true,"TWELVE HOMES REACHED. THREE ROUNDS CLEAR!")
			else:stage+=1;make_lanes()
	status="HOMES %d / 4   CROSSING %.0f" % [homes.size(),crossing_time]
func hop_fail() -> void:
	invulnerable=0
	damage("TRAFFIC AND WATER TOOK YOUR FOUR LIVES.")
	frog=Vector2(221,357);crossing_time=25;hop_clock=0.4
func make_pyramid() -> void:
	pyramid_size=stage+3;coats=2 if stage==3 else 1
	grid.clear();player=Vector2i(0,0);bug=Vector2i(pyramid_size-1,1);recall=true;bug_clock=2.5;awaiting=false
	for row in range(pyramid_size):
		for col in range(row+1):grid[Vector2i(row,col)]=0
	paint_tile()
func paint_tile() -> void:
	if grid[player]<coats:grid[player]+=1;score+=20;SoundFX.play_collect()
	var done=true
	for value in grid.values():
		if value<coats:done=false
	if done:
		if stage==3:complete(true,"THREE PYRAMIDS PAINTED, INCLUDING TWO COATS!")
		else:awaiting=true;status="PYRAMID PAINTED! ACTION CONTINUES."
func pyramid_action(action: String) -> void:
	if action=="primary":
		if awaiting:stage+=1;make_pyramid()
		elif recall:recall=false;player=Vector2i.ZERO;paint_tile()
		return
	if awaiting:return
	var dir=Vector2i.ZERO
	match action:
		"left":dir=Vector2i(1,0)
		"down":dir=Vector2i(1,1)
		"up":dir=Vector2i(-1,-1)
		"right":dir=Vector2i(-1,0)
	if dir==Vector2i.ZERO:return
	var next=player+dir
	if not grid.has(next):
		invulnerable=0;damage("A HOP LEFT THE PYRAMID.");player=Vector2i.ZERO
	else:player=next;paint_tile()
func pyramid_tick(delta: float) -> void:
	if awaiting:return
	bug_clock-=delta
	if bug_clock<=0:
		bug_clock=maxf(0.55,1.25-stage*0.12)
		var options:Array=[]
		for dir in [Vector2i(1,0),Vector2i(1,1),Vector2i(-1,-1),Vector2i(-1,0)]:
			if grid.has(bug+dir):options.append(bug+dir)
		if not options.is_empty():
			options.sort_custom(func(a,b):return pyramid_pos(a).distance_squared_to(pyramid_pos(player))<pyramid_pos(b).distance_squared_to(pyramid_pos(player)))
			bug=options.front()
	if bug==player and damage("THE SCRAP BUG CAUGHT YOUR PAINT TRAIL."):player=Vector2i.ZERO;bug=Vector2i(pyramid_size-1,1);bug_clock=2.0
	if not awaiting:status="COATS %d / RECALL %s   LEFT: DOWN-LEFT, DOWN: DOWN-RIGHT" % [coats,"READY" if recall else "USED"]
func pyramid_pos(cell: Vector2i) -> Vector2:
	return Vector2(640+(cell.y*2-cell.x)*42,183+cell.x*52)
func make_room() -> void:
	walls.clear();crates.clear();docks.clear();history.clear();awaiting=false
	room_rows=ROOMS[clampi(stage-1,0,4)]
	for y in range(room_rows.size()):
		for x in range(room_rows[y].length()):
			var ch:String=room_rows[y][x]
			var cell=Vector2i(x,y)
			if ch=="#":walls[cell]=true
			elif ch=="$":crates.append(cell)
			elif ch==".":docks.append(cell)
			elif ch=="@":player=cell
	status="ROOM %d / 5   Z: UNDO   CRATES CANNOT BE PULLED" % stage
func push_crate(dir: Vector2i) -> void:
	if awaiting:return
	var next=player+dir
	if walls.has(next):return
	var index=crates.find(next)
	if index>=0 and (walls.has(next+dir) or crates.has(next+dir)):return
	history.append([player,crates.duplicate()])
	if index>=0:crates[index]=next+dir
	player=next
	var done=true
	for dock in docks:
		if not crates.has(dock):done=false
	if done:
		score+=300
		if stage==5:complete(true,"ALL FIVE WAREHOUSES SORTED!")
		else:awaiting=true;status="ROOM CLEAR! ACTION OPENS THE NEXT ROOM."
func take_bag() -> int:
	if bag.is_empty():
		bag=[0,1,2,3,4,5,6]
		for i in range(6,0,-1):
			var swap=rng.randi_range(0,i);var temp=bag[i];bag[i]=bag[swap];bag[swap]=temp
	return bag.pop_back()
func spawn_piece() -> void:
	piece_kind=next_kind;next_kind=take_bag();piece.assign(SHAPES[piece_kind]);piece_at=Vector2i(4,0);step_clock=0
	if not piece_valid(piece,piece_at):complete(false,"THE SPAWN AREA FILLED. ROWS %d / 24." % lines_cleared)
func piece_valid(shape: Array,at: Vector2i) -> bool:
	for local in shape:
		var cell:Vector2i=at+local
		if cell.x<0 or cell.x>=10 or cell.y>=18 or grid.has(cell):return false
	return true
func move_piece(dir: Vector2i) -> void:
	if piece_valid(piece,piece_at+dir):piece_at+=dir
func rotate_piece(sign_value: int) -> void:
	if piece_kind==1:return
	var rotated:Array[Vector2i]=[]
	for at in piece:rotated.append(Vector2i(-at.y,at.x) if sign_value>0 else Vector2i(at.y,-at.x))
	for kick in [Vector2i.ZERO,Vector2i.LEFT,Vector2i.RIGHT,Vector2i(-2,0),Vector2i(2,0),Vector2i.UP]:
		if piece_valid(rotated,piece_at+kick):piece=rotated;piece_at+=kick;return
func stack_tick(delta: float) -> void:
	if repeat_clock<=0 and axis_x()!=0:
		move_piece(Vector2i(int(axis_x()),0));repeat_clock=0.12
	step_clock+=delta
	if step_clock>=(0.045 if down("down") else maxf(0.12,0.72-lines_cleared*0.022)):
		step_clock=0
		if piece_valid(piece,piece_at+Vector2i.DOWN):piece_at.y+=1
		else:lock_piece()
	status="ROWS %d / 24   LEVEL %d   UP: ROTATE" % [lines_cleared,stage]
func lock_piece() -> void:
	for at in piece:
		var cell:Vector2i=piece_at+at
		if cell.y<0:complete(false,"BLOCKS REACHED THE SPAWN AREA.");return
		grid[cell]=piece_kind
	var removed=0
	var row=17
	while row>=0:
		var full=true
		for x in range(10):
			if not grid.has(Vector2i(x,row)):full=false
		if full:
			removed+=1
			for x in range(10):grid.erase(Vector2i(x,row))
			var shifted:Dictionary={}
			for cell in grid:shifted[cell+Vector2i(0,1) if cell.y<row else cell]=grid[cell]
			grid=shifted
		else:row-=1
	lines_cleared+=removed;score+=removed*removed*100;stage=1+lines_cleared/5
	if lines_cleared>=24:complete(true,"TWENTY-FOUR ROWS CLEARED!")
	else:spawn_piece()
func draw_game() -> void:
	match game_id:
		"grid_x":draw_x()
		"dark_cavern":draw_cavern()
		"byte_munch":draw_snake()
		"dot_gobbler":draw_maze()
		"hopway":draw_hop()
		"color_steps":draw_pyramid()
		"crate_shift":draw_crates()
		"stackfall":draw_stack()
func draw_x() -> void:
	panel(Rect2(345,140,590,390),Color("b8c8bb"))
	for y in range(3):
		for x in range(3):
			var i=y*3+x
			var r=Rect2(370+x*180,160+y*120,173,113)
			panel(r,Paint.GOLD if cursor==i else Paint.PAPER)
			if cells[i]==1:
				line(r.position+Vector2(45,25),r.position+Vector2(125,90),Paint.RED,8)
				line(r.position+Vector2(125,25),r.position+Vector2(45,90),Paint.RED,8)
			elif cells[i]==2:Paint.circle(self,r.get_center(),35,Paint.BLUE,false,7)
func draw_cavern() -> void:
	Paint.rect(self,Rect2(0,0,1280,720),Color("b9bdce"))
	panel(Rect2(275,145,730,180),Color("d1c1a6"))
	text("ENTRANCE" if room==0 else "ROOM %02d" % room,Vector2(325,193),32)
	var clues:Array[String]=[]
	for next in neighbors(room):
		if next in [4,9] and not clues.has("COLD AIR / A PIT IS NEAR"):clues.append("COLD AIR / A PIT IS NEAR")
		if next==7 and creature_alive:clues.append("SCRAPING / CREATURE NEAR")
		if caches.has(next) and not found.has(next):clues.append("A GLIMMER / CACHE NEAR")
	if clues.is_empty():clues.append("QUIET TUNNELS")
	for i in range(clues.size()):text(clues[i],Vector2(325,235+i*30),19)
	for i in range(3):
		panel(Rect2(210+i*300,355,260,125),Paint.GOLD if tunnel==i else Paint.PAPER)
		text("TUNNEL %02d" % neighbors(room)[i],Vector2(230+i*300,408),24)
		text("FIRE" if aiming else "WALK",Vector2(230+i*300,450),20)
	status="BOLTS %d / CACHES %d OF 2 / CREATURE %s" % [bolts,found.size(),"ALIVE" if creature_alive else "DEFEATED"]
func draw_snake() -> void:
	panel(Rect2(272,147,736,376),Color("c9d9b7"))
	for y in range(12):
		for x in range(24):Paint.rect(self,Rect2(280+x*30,155+y*30,28,28),Color("dae4c9"))
	for cell in walls:panel(Rect2(Vector2(280,155)+Vector2(cell)*30,Vector2(28,28)),Color("8b8296"))
	for i in range(snake.size()):panel(Rect2(Vector2(280,155)+Vector2(snake[i])*30,Vector2(28,28)),Paint.GOLD if i==0 else Paint.CYAN)
	dot(Vector2(295,170)+Vector2(food)*30,11,Paint.RED)
	if post_warning>=0:Paint.rect(self,Rect2(Vector2(280,155)+Vector2(pending_post)*30,Vector2(29,29)),Paint.RED,false,4)
func draw_maze() -> void:
	panel(Rect2(MAZE_ORIGIN-Vector2(5,5),Vector2(654,374)),Color("c9d0df"))
	for cell in walls:panel(Rect2(MAZE_ORIGIN+Vector2(cell)*28,Vector2(27,27)),Color("7d8eae"))
	for cell in grid:dot(MAZE_ORIGIN+Vector2(cell)*28+Vector2(14,14),2.5,Paint.GOLD)
	for cell in crystals:dot(MAZE_ORIGIN+Vector2(cell)*28+Vector2(14,14),8,Paint.CYAN)
	dot(MAZE_ORIGIN+Vector2(player)*28+Vector2(14,14),11,Paint.GOLD)
	for i in range(robots.size()):
		var robot=robots[i]
		panel(Rect2(MAZE_ORIGIN+Vector2(robot["cell"])*28+Vector2(3,3),Vector2(22,22)),Paint.CYAN if power>0 else [Paint.RED,Color("b987b8"),Paint.BLUE][i])
func draw_hop() -> void:
	panel(Rect2(HOP_ORIGIN,Vector2(442,374)),Color("b4c79c"))
	for lane in lanes:
		var row:int=lane["row"]
		panel(Rect2(HOP_ORIGIN+Vector2(0,row*34),Vector2(442,34)),Color("8db9d0") if lane["water"] else Color("a3a5a7"))
		for i in range(-3,5):
			var x=i*170+float(lane["offset"])-340
			var width=130 if lane["water"] else 75
			var left=maxf(0,x);var right=minf(442,x+width)
			if right>left:panel(Rect2(HOP_ORIGIN+Vector2(left,row*34+4),Vector2(right-left,26)),Color("b88555") if lane["water"] else Paint.RED)
	for i in range(4):
		var at=HOP_ORIGIN+Vector2([1,4,8,11][i]*34+17,17)
		dot(at,14,Paint.GOLD if homes.has(i) else Paint.PAPER)
	dot(HOP_ORIGIN+frog,12,Color("6eaa70"))
func draw_pyramid() -> void:
	for cell in grid:
		var at=pyramid_pos(cell)
		var colors: Array=[Paint.PAPER,Paint.GOLD,Paint.CYAN]
		Paint.polygon(self,PackedVector2Array([at+Vector2(0,-23),at+Vector2(41,0),at+Vector2(0,23),at+Vector2(-41,0)]),PackedColorArray([colors[grid[cell]]]))
		line(at+Vector2(-41,0),at+Vector2(0,42),Color("ae8a69"),4)
		line(at+Vector2(41,0),at+Vector2(0,42),Color("ae8a69"),4)
	dot(pyramid_pos(player)-Vector2(0,14),15,Paint.RED)
	dot(pyramid_pos(bug)-Vector2(0,14),14,Paint.BLUE)
func draw_crates() -> void:
	var origin=Vector2(640-room_rows[0].length()*22,155)
	for y in range(room_rows.size()):
		for x in range(room_rows[y].length()):
			var cell=Vector2i(x,y)
			panel(Rect2(origin+Vector2(cell)*44,Vector2(43,43)),Color("9da4af") if walls.has(cell) else Color("dfccb1"))
	for at in docks:dot(origin+Vector2(at)*44+Vector2(22,22),12,Paint.CYAN)
	for at in crates:
		var p=origin+Vector2(at)*44+Vector2(3,3)
		panel(Rect2(p,Vector2(37,37)),Paint.GOLD if docks.has(at) else Color("bb8965"))
		line(p+Vector2(6,6),p+Vector2(31,31),Paint.INK,2)
		line(p+Vector2(31,6),p+Vector2(6,31),Paint.INK,2)
	dot(origin+Vector2(player)*44+Vector2(22,22),15,Paint.RED)
func draw_stack() -> void:
	var origin=Vector2(535,145)
	panel(Rect2(origin-Vector2(5,5),Vector2(220,388)),Color("bac9d7"))
	for y in range(18):
		for x in range(10):Paint.rect(self,Rect2(origin+Vector2(x,y)*21,Vector2(20,20)),Color("d9dfe0"))
	var colors: Array=[Paint.CYAN,Paint.GOLD,Color("bd8cc3"),Paint.RED,Color("94c681"),Paint.BLUE,Color("e9aa6a")]
	for at in grid:panel(Rect2(origin+Vector2(at)*21,Vector2(20,20)),colors[grid[at]])
	var ghost=piece_at
	while piece_valid(piece,ghost+Vector2i.DOWN):ghost.y+=1
	for at in piece:
		Paint.rect(self,Rect2(origin+Vector2(ghost+at)*21,Vector2(20,20)),Paint.INK,false,2)
		if (piece_at+at).y>=0:panel(Rect2(origin+Vector2(piece_at+at)*21,Vector2(20,20)),colors[piece_kind])
	text("NEXT",Vector2(850,190),24)
	for at in SHAPES[next_kind]:panel(Rect2(Vector2(895,245)+Vector2(at)*26,Vector2(24,24)),colors[next_kind])
	text("24 ROWS",Vector2(300,230),26)
	text("TO WIN",Vector2(300,275),26)
