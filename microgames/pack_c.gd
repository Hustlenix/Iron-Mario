extends "res://microgames/microgame_base.gd"
## Spatial and strategy puzzles. Each mode owns its rules and terminal predicate.
## All boards are constructed from known valid states, never arbitrary shuffles.
var mode: String = ""
var s: Dictionary = {}
var initial: Dictionary = {}
var history: Array[Dictionary] = []
const COLORS: Array[Color] = [RED, BLUE, GOLD, GREEN, Color('#a78ad7')]
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const HEX_DIRS: Array[Vector2i] = [Vector2i(1,0),Vector2i(0,1),Vector2i(-1,1),Vector2i(-1,0),Vector2i(0,-1),Vector2i(1,-1)]
const LADDER: Array[String] = ["COLD","CORD","CARD","WARD","WARM","SOLD","TOLD","BOLD","WORD","WORE","WORM"]

func setup() -> void:
	mode = str(spec.id)
	history.clear()
	s = {"moves":0,"selected":-1,"message":"","cols":3,"rows":3,"cell":90.0,"origin":Vector2(345,90)}
	match mode:
		"water_sort":
			s.tubes = [[0,1,1],[1,0,0],[],[]]
			s.capacity = 3
			var swap: bool = rng.randf()<0.5
			if swap: s.tubes.reverse()
		"ball_sort":
			s.tubes = [[0,1,0],[1,0,1],[],[]]
			s.capacity = 3
			if rng.randf()<0.5: s.tubes.reverse()
		"sliding_puzzle":
			s.board = [1,2,3,4,5,6,7,8,0]
			var blank: int = 8
			var previous: int = -1
			for n in range(8 + mini(int(difficulty),4)):
				var candidates: Array[int] = []
				for i in 9:
					if manhattan(i,blank,3)==1 and i!=previous: candidates.append(i)
				var next: int = candidates[rng.randi_range(0,candidates.size()-1)]
				s.board[blank] = s.board[next]
				s.board[next] = 0
				previous = blank
				blank = next
			if s.board==[1,2,3,4,5,6,7,8,0]: s.board[7]=0; s.board[8]=8
		"sokoban":
			grid(5,5,66,Vector2(315,70))
			s.player = 16
			s.crate = 12
			s.goal = 8
		"minesweeper":
			grid(4,4,76,Vector2(328,65))
			s.mines = [0,3,12,15]
			s.revealed = [5,6,9,10]
			s.flags = []
			s.flag_mode = false
		"tangram":
			grid(3,3,85,Vector2(280,95))
			s.board = [-1,-1,-1,-1,-1,-1,-1,-1,-1]
			s.shapes = [[Vector2i(0,0),Vector2i(0,1),Vector2i(1,1)],[Vector2i(0,0),Vector2i(1,0)],[Vector2i(2,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)]]
			s.placed = [false,false,false]
			s.rotation = 0
		"nonogram":
			grid(5,5,57,Vector2(345,110))
			s.board = filled(25,0)
			s.goal = [0,0,1,0,0,0,1,1,1,0,1,1,1,1,1,0,1,1,1,0,0,0,1,0,0]
			if rng.randf()<0.5:
				s.goal = [1,1,1,1,1,1,0,0,0,1,1,0,1,0,1,1,0,0,0,1,1,1,1,1,1]
		"domino":
			s.tiles = [[0,2],[2,1],[1,3],[3,2],[2,4],[4,3]]
			shuffle(s.tiles)
			s.used = []
			s.end = 0
			s.chain = []
		"pipe_flow":
			grid(4,4,77,Vector2(320,63))
			s.board = filled(16,0)
			for pair in [[4,10],[5,12],[9,3],[10,10],[11,10]]:
				s.board[pair[0]] = rotate_mask(pair[1],rng.randi_range(1,3),4)
		"laser_reflect":
			grid(5,3,75,Vector2(292,110))
			s.mirrors = {6:rng.randi_range(0,1),1:rng.randi_range(0,1),3:rng.randi_range(0,1),13:rng.randi_range(0,1)}
			if laser_reaches(): s.mirrors[6] = 1-int(s.mirrors[6])
		"tic_tac_toe":
			s.board = [1,0,0,0,2,0,0,2,1]
			if rng.randf()<0.5: s.board.reverse()
		"connect_four":
			grid(6,5,61,Vector2(295,60))
			s.board = filled(30,0)
			for col in 3:
				s.board[24+col] = 1
				s.board[18+col] = 2
			if rng.randf()<0.5:
				for row in 5:
					for col in 3:
						var old: int = int(s.board[row*6+col])
						s.board[row*6+col] = s.board[row*6+5-col]
						s.board[row*6+5-col] = old
		"hex_rotation":
			s.coords = [Vector2i(-1,0),Vector2i(0,-1),Vector2i(1,-1),Vector2i(1,0),Vector2i(0,1),Vector2i(-1,1),Vector2i(0,0)]
			s.ports = []
			for i in 6:
				var previous: Vector2i = Vector2i(-2,0) if i==0 else s.coords[i-1]
				var next: Vector2i = s.coords[i+1]
				var mask: int = (1<<HEX_DIRS.find(previous-s.coords[i])) | (1<<HEX_DIRS.find(next-s.coords[i]))
				s.ports.append(rotate_mask(mask,rng.randi_range(1,5),6))
		"word_ladder":
			s.word = "COLD"
			s.goal = "WARM"
			s.trail = ["COLD"]
		"tower_hanoi":
			s.disks = 3 if difficulty<4 else 4
			s.pegs = [[],[],[]]
			for n in range(int(s.disks),0,-1): s.pegs[0].append(n)
		"memory_pairs":
			grid(4,2,95,Vector2(290,125))
			s.cards = [0,0,1,1,2,2,3,3]
			shuffle(s.cards)
			s.open = []
			s.matched = []
			s.hide_at = -1.0
		"chess_fork":
			grid(5,5,62,Vector2(325,65))
			s.knight = 10
			s.enemies = [0,4]
			if rng.randf()<0.5: s.knight=14
		"knight_tour":
			grid(4,3,85,Vector2(310,95))
			s.knight = 0
			s.visited = [0]
		"river_ferry":
			s.bank = [0,0,0,0] # farmer, wolf, goat, cabbage
			s.cargo = -1
		"peg_solitaire":
			grid(7,1,78,Vector2(207,186))
			s.board = [1,1,0,1,0,1,0]
			if rng.randf()<0.5: s.board.reverse()
		"logic_grid":
			s.goal = [0,1,2]
			shuffle(s.goal)
			s.board = [-1,-1,-1]
		"train_shunt":
			s.tracks = [[2,0,1],[],[]]
			s.delivered = []
		"circuit_logic":
			s.switches = [0,0,0,0]
			var goal: Array = [1,0,1,1]
			for i in 4: goal[i]=rng.randi_range(0,1)
			if goal==[0,0,0,0]: goal[0]=1
			s.target = circuit_output(goal)
		"gear_link":
			s.gears = [70,90,50]
			s.slots = [50,0,0,90]
		"code_breaker":
			s.code = []
			for i in 4: s.code.append(rng.randi_range(0,3))
			s.guess = [0,0,0,0]
			s.guesses = []
	initial = s.duplicate(true)
	queue_redraw()

func grid(cols: int, rows: int, cell: float, origin: Vector2) -> void:
	s.cols=cols; s.rows=rows; s.cell=cell; s.origin=origin

func filled(count: int, value: int) -> Array:
	var out: Array = []
	for i in count: out.append(value)
	return out

func shuffle(items: Array) -> void:
	for i in range(items.size()-1,0,-1):
		var j: int = rng.randi_range(0,i)
		var old = items[i]
		items[i]=items[j]; items[j]=old

func cell_center(index: int) -> Vector2:
	return Vector2(s.origin)+Vector2(index%int(s.cols)+0.5,float(index/int(s.cols))+0.5)*float(s.cell)

func cell_at(point: Vector2) -> int:
	var v: Vector2 = (point-Vector2(s.origin))/float(s.cell)
	if v.x<0 or v.y<0 or v.x>=int(s.cols) or v.y>=int(s.rows): return -1
	return int(v.y)*int(s.cols)+int(v.x)

func snapshot() -> void:
	history.append(s.duplicate(true))
	if history.size()>80: history.pop_front()
	s.moves=int(s.moves)+1
	s.message=""

func invalid(point: Vector2, message: String="Try another move") -> void:
	s.message=message
	feedback(point,false)

func solved() -> void:
	feedback(Vector2(480,240))
	win(clampi(100+int((duration-elapsed)*2)-int(s.moves),50,200))

func manhattan(a: int,b: int,cols: int) -> int:
	return absi(a%cols-b%cols)+absi(a/cols-b/cols)

func handle_action(action: String,point: Vector2,value: Vector2) -> void:
	if finished or not active: return
	if action=="cancel":
		s.selected=-1
		if mode=="river_ferry": s.cargo=-1
		queue_redraw(); return
	if action=="reset": handle_action("press",Vector2(850,444),Vector2.ZERO); return
	if action=="undo": handle_action("press",Vector2(650,444),Vector2.ZERO); return
	if action=="secondary":
		match mode:
			"minesweeper": handle_action("press",Vector2(780,180),Vector2.ZERO)
			"tangram": handle_action("press",Vector2(160,240),Vector2.ZERO)
			"river_ferry": handle_action("press",Vector2(810,210),Vector2.ZERO)
			"train_shunt": handle_action("press",Vector2(760,210),Vector2.ZERO)
			"code_breaker": handle_action("press",Vector2(810,180),Vector2.ZERO)
		return
	if action=="select":
		var option: int = int(value.x)-1
		if option<0 or option>3: return
		var destination: Vector2 = cell_center(option)
		match mode:
			"water_sort","ball_sort": destination=Vector2(240+option*150,240)
			"tower_hanoi":
				if option>=3: return
				destination=Vector2(240+option*240,240)
			"tangram":
				if option>=3: return
				destination=Vector2(720,130+option*87)
			"word_ladder":
				var choices: Array[String] = ladder_choices()
				if option>=choices.size(): return
				destination=option_rect(option,choices.size()).get_center()
			"river_ferry":
				if option==3: destination=Vector2(810,210)
				else: destination=Vector2(215+option*190,200)
			"train_shunt": destination=Vector2(760,210) if option==3 else Vector2(360,145+option*87)
			"circuit_logic": destination=Vector2(250+option*150,250)
			"gear_link":
				if option>=3: return
				destination=Vector2(300+option*145,125)
			"code_breaker": destination=Vector2(280+option*105,180)
		handle_action("press",destination,Vector2.ZERO); return
	if mode=="sokoban" and action in ["direction","swipe"]:
		var d := Vector2i(signi(int(value.x)),signi(int(value.y)))
		if absi(d.x)+absi(d.y)==1: push_crate(d)
		queue_redraw(); return
	if action not in ["press","action"]: return
	if Rect2(765,416,175,55).has_point(point):
		s=initial.duplicate(true); history.clear(); queue_redraw(); return
	if Rect2(570,416,175,55).has_point(point):
		if not history.is_empty(): s=history.pop_back()
		queue_redraw(); return
	var index: int = cell_at(point)
	match mode:
		"water_sort","ball_sort": tube_action(point)
		"sliding_puzzle":
			if index>=0:
				var blank: int = s.board.find(0)
				if manhattan(index,blank,3)==1:
					snapshot(); s.board[blank]=s.board[index]; s.board[index]=0
					if s.board==[1,2,3,4,5,6,7,8,0]: solved()
				else: invalid(point,"Move a tile beside the gap")
		"sokoban":
			if index>=0 and manhattan(index,int(s.player),5)==1:
				push_crate(Vector2i(index%5-int(s.player)%5,index/5-int(s.player)/5))
		"minesweeper":
			if Rect2(675,150,220,64).has_point(point): s.flag_mode=not s.flag_mode
			elif index>=0 and not s.revealed.has(index):
				if s.flag_mode:
					snapshot()
					if s.flags.has(index): s.flags.erase(index)
					else: s.flags.append(index)
				elif not s.flags.has(index):
					snapshot()
					if s.mines.has(index): lose()
					else:
						s.revealed.append(index)
						if s.revealed.size()==12: solved()
		"tangram": tangram_action(index,point)
		"nonogram":
			if index>=0:
				snapshot(); s.board[index]=1-int(s.board[index])
				if nonogram_matches(): solved()
		"domino": domino_action(point)
		"pipe_flow":
			if index>=0 and int(s.board[index])!=0:
				snapshot(); s.board[index]=rotate_mask(int(s.board[index]),1,4)
				if pipe_reaches(): solved()
		"laser_reflect":
			if s.mirrors.has(index):
				snapshot(); s.mirrors[index]=1-int(s.mirrors[index])
				if laser_reaches(): solved()
		"tic_tac_toe":
			if index>=0 and int(s.board[index])==0:
				snapshot(); s.board[index]=1
				if line_winner(s.board,3,3,3)==1: solved()
				elif not s.board.has(0): solved()
				else:
					var cpu: int = tic_choice(s.board,2)
					if cpu>=0: s.board[cpu]=2
					if line_winner(s.board,3,3,3)==2: lose()
					elif not s.board.has(0): solved()
		"connect_four":
			if index>=0: drop_turn(index%6)
		"hex_rotation":
			for i in 6:
				if hex_center(i).distance_to(point)<48:
					snapshot(); s.ports[i]=rotate_mask(int(s.ports[i]),1,6)
					if hex_reaches(): solved()
					break
		"word_ladder":
			var words: Array[String] = ladder_choices()
			for i in words.size():
				if option_rect(i,words.size()).has_point(point):
					snapshot(); s.word=words[i]; s.trail.append(words[i])
					if s.word==s.goal: solved()
					elif int(s.moves)>=8: lose()
					break
		"tower_hanoi": hanoi_action(point)
		"memory_pairs":
			if index>=0 and s.open.size()<2 and not s.open.has(index) and not s.matched.has(index):
				snapshot(); s.open.append(index)
				if s.open.size()==2:
					if s.cards[s.open[0]]==s.cards[s.open[1]]:
						s.matched.append_array(s.open); s.open=[]
						if s.matched.size()==8: solved()
					else: s.hide_at=elapsed+0.7
		"chess_fork","knight_tour":
			if index>=0 and knight_step(int(s.knight),index,int(s.cols)):
				if mode=="knight_tour" and s.visited.has(index): invalid(point,"Visit a fresh square"); return
				snapshot(); s.knight=index
				if mode=="chess_fork":
					if knight_step(index,int(s.enemies[0]),5) and knight_step(index,int(s.enemies[1]),5): solved()
				else:
					s.visited.append(index)
					if s.visited.size()==12: solved()
					else:
						var available: bool = false
						for cell in 12:
							if not s.visited.has(cell) and knight_step(index,cell,4): available=true
						if not available: lose()
			elif index>=0: invalid(point,"Knight moves two, then one")
		"river_ferry": ferry_action(point)
		"peg_solitaire":
			if index>=0:
				if int(s.board[index])==1: s.selected=index
				elif int(s.selected)>=0 and absi(index-int(s.selected))==2 and int(s.board[(index+int(s.selected))/2])==1:
					var source: int = int(s.selected)
					snapshot(); s.board[source]=0; s.board[(index+source)/2]=0; s.board[index]=1; s.selected=-1
					if s.board.count(1)==1: solved()
					elif peg_moves().is_empty(): lose()
				else: invalid(point,"Jump one peg into an empty hole")
		"logic_grid":
			for row in 3:
				for col in 3:
					if Rect2(285+col*110,135+row*75,100,65).has_point(point):
						snapshot(); s.board[row]=col
						if s.board==s.goal: solved()
		"train_shunt": train_action(point)
		"circuit_logic":
			for i in 4:
				if Rect2(200+i*150,215,115,80).has_point(point):
					snapshot(); s.switches[i]=1-int(s.switches[i])
					if circuit_output(s.switches)==s.target: solved()
		"gear_link": gear_action(point)
		"code_breaker":
			for i in 4:
				if Vector2(280+i*105,180).distance_to(point)<38:
					snapshot(); s.guess[i]=(int(s.guess[i])+1)%4
			if Rect2(740,145,160,70).has_point(point):
				snapshot()
				var response: Vector2i = code_response(s.guess,s.code)
				s.guesses.append({"colors":s.guess.duplicate(),"exact":response.x,"near":response.y})
				if response.x==4: solved()
				elif s.guesses.size()>=6: lose()
	queue_redraw()

func tick(_delta: float) -> void:
	if mode=="memory_pairs" and float(s.hide_at)>=0 and elapsed>=float(s.hide_at):
		s.open=[]; s.hide_at=-1.0

func tube_action(point: Vector2) -> void:
	var tube: int = -1
	for i in 4:
		if Rect2(185+i*150,100,110,280).has_point(point): tube=i
	if tube<0: return
	if int(s.selected)<0:
		if not s.tubes[tube].is_empty(): s.selected=tube
		return
	var source: int = int(s.selected)
	if tube==source: s.selected=-1; return
	var from: Array = s.tubes[source]
	var to: Array = s.tubes[tube]
	if from.is_empty() or to.size()>=int(s.capacity) or (not to.is_empty() and to.back()!=from.back()):
		invalid(point,"Pour onto the same color or an empty tube"); s.selected=-1; return
	snapshot()
	var color: int = int(from.back())
	to.append(from.pop_back())
	if mode=="water_sort":
		while not from.is_empty() and int(from.back())==color and to.size()<int(s.capacity): to.append(from.pop_back())
	s.selected=-1
	var done: bool = true
	for stack in s.tubes:
		if stack.is_empty(): continue
		if stack.size()!=int(s.capacity): done=false
		for item in stack:
			if item!=stack[0]: done=false
	if done: solved()

func push_crate(direction: Vector2i) -> void:
	var p: Vector2i = Vector2i(int(s.player)%5,int(s.player)/5)+direction
	if p.x<=0 or p.y<=0 or p.x>=4 or p.y>=4: return
	var next: int = p.y*5+p.x
	if next==int(s.crate):
		var c: Vector2i = p+direction
		if c.x<=0 or c.y<=0 or c.x>=4 or c.y>=4: return
		snapshot(); s.crate=c.y*5+c.x
	else: snapshot()
	s.player=next
	if int(s.crate)==int(s.goal): solved()

func tangram_cells(piece: int, rotation: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var min_x: int = 999
	var min_y: int = 999
	for source in s.shapes[piece]:
		var v: Vector2i = source
		for n in rotation: v=Vector2i(-v.y,v.x)
		min_x=mini(min_x,v.x); min_y=mini(min_y,v.y); cells.append(v)
	for i in cells.size(): cells[i]-=Vector2i(min_x,min_y)
	return cells

func tangram_action(index: int, point: Vector2) -> void:
	for i in 3:
		if Rect2(630,100+i*87,235,70).has_point(point) and not s.placed[i]: s.selected=i; s.rotation=0; return
	if Rect2(75,205,170,70).has_point(point): s.rotation=(int(s.rotation)+1)%4; return
	if index<0 or int(s.selected)<0: return
	var piece: int = int(s.selected)
	var cells: Array[Vector2i] = tangram_cells(piece,int(s.rotation))
	var targets: Array[int] = []
	for cell in cells:
		var p: Vector2i = Vector2i(index%3,index/3)+cell
		if p.x>=3 or p.y>=3 or int(s.board[p.y*3+p.x])>=0: invalid(point,"Piece overlaps or leaves the square"); return
		targets.append(p.y*3+p.x)
	snapshot()
	for target in targets: s.board[target]=piece
	s.placed[piece]=true; s.selected=-1
	if not s.board.has(-1): solved()

func runs(values: Array) -> Array:
	var result: Array = []
	var count: int = 0
	for v in values:
		if int(v)==1: count+=1
		elif count>0: result.append(count); count=0
	if count>0: result.append(count)
	if result.is_empty(): result.append(0)
	return result

func nonogram_line(board: Array, line: int, column: bool) -> Array:
	var values: Array = []
	for i in 5: values.append(board[i*5+line] if column else board[line*5+i])
	return runs(values)

func nonogram_matches() -> bool:
	for i in 5:
		if nonogram_line(s.board,i,false)!=nonogram_line(s.goal,i,false): return false
		if nonogram_line(s.board,i,true)!=nonogram_line(s.goal,i,true): return false
	return true

func domino_action(point: Vector2) -> void:
	for i in 6:
		var rect := Rect2(185+(i%3)*205,130+(i/3)*115,175,80)
		if rect.has_point(point) and not s.used.has(i):
			var tile: Array = s.tiles[i]
			if int(tile[0])!=int(s.end) and int(tile[1])!=int(s.end): invalid(point,"Match the open number"); return
			snapshot()
			var next: int = int(tile[1]) if int(tile[0])==int(s.end) else int(tile[0])
			s.chain.append([s.end,next]); s.end=next; s.used.append(i)
			if s.used.size()==6:
				if int(s.end)==3: solved()
				else: lose()
			return

func rotate_mask(mask: int, turns: int, sides: int) -> int:
	var result: int = mask
	for n in turns: result=((result<<1)|(result>>(sides-1)))&((1<<sides)-1)
	return result

func pipe_route() -> Array[int]:
	var path: Array[int] = []
	var index: int = 4
	var incoming: int = 3
	for step in 20:
		if path.has(index) or not (int(s.board[index])&(1<<incoming)): return path
		path.append(index)
		var outgoing: int = -1
		for d in 4:
			if d!=incoming and int(s.board[index])&(1<<d): outgoing=d
		if outgoing<0: return path
		if index==11 and outgoing==1: path.append(16); return path
		var p := Vector2i(index%4,index/4)+DIRS[outgoing]
		if p.x<0 or p.y<0 or p.x>=4 or p.y>=4: return path
		index=p.y*4+p.x; incoming=(outgoing+2)%4
	return path

func pipe_reaches() -> bool:
	return pipe_route().has(16)

func laser_path() -> Array[Vector2]:
	var path: Array[Vector2] = [Vector2(-1,1)]
	var position := Vector2i(-1,1)
	var direction := Vector2i.RIGHT
	var visited: Array = []
	for i in 40:
		position+=direction
		path.append(Vector2(position))
		if position.x<0 or position.y<0 or position.x>=5 or position.y>=3: return path
		var state_key: String = str(position)+str(direction)
		if visited.has(state_key): return path
		visited.append(state_key)
		var index: int = position.y*5+position.x
		if s.mirrors.has(index):
			direction=Vector2i(-direction.y,-direction.x) if int(s.mirrors[index])==0 else Vector2i(direction.y,direction.x)
	return path

func laser_reaches() -> bool:
	return laser_path().back()==Vector2(-1,2)

func line_winner(board: Array, cols: int, rows: int, count: int) -> int:
	for index in board.size():
		if int(board[index])==0: continue
		for direction in [Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(1,-1)]:
			var ok: bool = true
			for n in range(1,count):
				var p: Vector2i = Vector2i(index%cols,index/cols)+direction*n
				if p.x<0 or p.y<0 or p.x>=cols or p.y>=rows or board[p.y*cols+p.x]!=board[index]: ok=false; break
			if ok: return int(board[index])
	return 0

func tic_value(board: Array, turn: int) -> int:
	var winner: int = line_winner(board,3,3,3)
	if winner!=0: return 1 if winner==1 else -1
	if not board.has(0): return 0
	var best: int = -2 if turn==1 else 2
	for i in 9:
		if board[i]!=0: continue
		board[i]=turn
		var score: int = tic_value(board,3-turn)
		board[i]=0
		best=maxi(best,score) if turn==1 else mini(best,score)
	return best

func tic_choice(board: Array, turn: int) -> int:
	var choice: int = -1
	var best: int = -2 if turn==1 else 2
	for i in 9:
		if board[i]!=0: continue
		board[i]=turn
		var score: int = tic_value(board,3-turn)
		board[i]=0
		if choice<0 or (score>best if turn==1 else score<best): choice=i; best=score
	return choice

func drop_index(board: Array,col: int) -> int:
	for row in range(4,-1,-1):
		if int(board[row*6+col])==0: return row*6+col
	return -1

func drop_turn(col: int) -> void:
	var index: int = drop_index(s.board,col)
	if index<0: invalid(cell_center(col),"That column is full"); return
	snapshot(); s.board[index]=1
	if line_winner(s.board,6,5,4)==1: solved(); return
	if not s.board.has(0): lose(); return
	var choice: int = -1
	for player in [2,1]:
		for c in 6:
			var candidate: int = drop_index(s.board,c)
			if candidate<0: continue
			s.board[candidate]=player
			var winner: int = line_winner(s.board,6,5,4)
			s.board[candidate]=0
			if winner==player: choice=c; break
		if choice>=0: break
	if choice<0:
		for c in [2,3,1,4,0,5]:
			if drop_index(s.board,c)>=0: choice=c; break
	if choice>=0: s.board[drop_index(s.board,choice)]=2
	if line_winner(s.board,6,5,4)==2: lose()

func hex_center(index: int) -> Vector2:
	var v: Vector2i = s.coords[index]
	return Vector2(480+v.x*105+v.y*52.5,240+v.y*91)

func hex_route() -> Array[int]:
	var path: Array[int] = []
	var index: int = 0
	var incoming: int = 3
	for step in 8:
		if index==6: path.append(6); return path
		if path.has(index) or not (int(s.ports[index])&(1<<incoming)): return path
		path.append(index)
		var outgoing: int = -1
		for d in 6:
			if d!=incoming and int(s.ports[index])&(1<<d): outgoing=d
		if outgoing<0: return path
		var next: int = s.coords.find(Vector2i(s.coords[index])+HEX_DIRS[outgoing])
		if next<0: return path
		index=next; incoming=(outgoing+3)%6
	return path

func hex_reaches() -> bool:
	var path: Array[int] = hex_route()
	return path.size()==7 and path.back()==6

func ladder_choices() -> Array[String]:
	var result: Array[String] = []
	for word in LADDER:
		var differences: int = 0
		for i in 4:
			if word[i]!=str(s.word)[i]: differences+=1
		if differences==1: result.append(word)
	return result

func option_rect(index: int,count: int) -> Rect2:
	var width: float = minf(185,680.0/maxi(1,count))
	return Rect2(480-count*width*0.5+index*width,200,width-10,90)

func hanoi_action(point: Vector2) -> void:
	var peg: int = -1
	for i in 3:
		if Rect2(130+i*240,90,220,285).has_point(point): peg=i
	if peg<0: return
	if int(s.selected)<0:
		if not s.pegs[peg].is_empty(): s.selected=peg
		return
	var source: int = int(s.selected)
	if source==peg: s.selected=-1; return
	if not s.pegs[peg].is_empty() and int(s.pegs[peg].back())<int(s.pegs[source].back()): invalid(point,"A bigger disk cannot cover a smaller one"); s.selected=-1; return
	snapshot(); s.pegs[peg].append(s.pegs[source].pop_back()); s.selected=-1
	if s.pegs[2].size()==int(s.disks): solved()

func knight_step(a: int,b: int,cols: int) -> bool:
	var x: int = absi(a%cols-b%cols)
	var y: int = absi(a/cols-b/cols)
	return (x==1 and y==2) or (x==2 and y==1)

func ferry_action(point: Vector2) -> void:
	for item in range(1,4):
		if Rect2(145+(item-1)*190,130,150,145).has_point(point) and int(s.bank[item])==int(s.bank[0]): s.cargo=-1 if int(s.cargo)==item else item
	if Rect2(730,165,170,90).has_point(point):
		snapshot()
		s.bank[0]=1-int(s.bank[0])
		if int(s.cargo)>=0: s.bank[s.cargo]=int(s.bank[0])
		s.cargo=-1
		if s.bank[1]==s.bank[2] and s.bank[1]!=s.bank[0]: lose(); return
		if s.bank[2]==s.bank[3] and s.bank[2]!=s.bank[0]: lose(); return
		if s.bank==[1,1,1,1]: solved()

func peg_moves() -> Array:
	var moves: Array = []
	for i in 7:
		for d in [-2,2]:
			var target: int = i+d
			if target>=0 and target<7 and s.board[i]==1 and s.board[i+d/2]==1 and s.board[target]==0: moves.append([i,target])
	return moves

func train_action(point: Vector2) -> void:
	for track in 3:
		if Rect2(145,110+track*87,430,70).has_point(point):
			if int(s.selected)<0:
				if not s.tracks[track].is_empty(): s.selected=track
				return
			var source: int = int(s.selected)
			if track==0 or track==source or s.tracks[track].size()>=3: s.selected=-1; return
			snapshot()
			var car: int = int(s.tracks[source].pop_front()) if source==0 else int(s.tracks[source].pop_back())
			s.tracks[track].append(car); s.selected=-1; return
	if Rect2(640,140,240,150).has_point(point) and int(s.selected)>=0:
		var source: int = int(s.selected)
		var car: int = int(s.tracks[source].front()) if source==0 else int(s.tracks[source].back())
		if car!=s.delivered.size(): invalid(point,"Dispatch A, then B, then C"); s.selected=-1; return
		snapshot()
		if source==0: s.tracks[source].pop_front()
		else: s.tracks[source].pop_back()
		s.delivered.append(car); s.selected=-1
		if s.delivered.size()==3: solved()

func circuit_output(values: Array) -> Array:
	return [int(values[0])^int(values[1]),int(values[1])&int(values[2]),int(values[2])^int(values[3]),int(values[0])|int(values[3])]

func gear_action(point: Vector2) -> void:
	for i in 3:
		if Vector2(300+i*145,125).distance_to(point)<48: s.selected=i; return
	for slot in [1,2]:
		if Vector2([180,300,460,640][slot],285).distance_to(point)<75 and int(s.selected)>=0:
			snapshot(); s.slots[slot]=s.gears[s.selected]; s.selected=-1
			if s.slots[0]+s.slots[1]==120 and s.slots[1]+s.slots[2]==160 and s.slots[2]+s.slots[3]==180: solved()

func code_response(guess: Array,code: Array) -> Vector2i:
	var exact: int = 0
	var hits: int = 0
	for i in 4:
		if guess[i]==code[i]: exact+=1
	for color in 4: hits+=mini(guess.count(color),code.count(color))
	return Vector2i(exact,hits-exact)

func paint() -> void:
	text_at(Vector2(32,451),"Moves: "+str(s.moves),23)
	if str(s.message)!="": text_at(Vector2(32,397),str(s.message),20,RED)
	box(Rect2(570,416,175,55),BLUE); text_at(Vector2(610,450),"UNDO",23,PAPER)
	box(Rect2(765,416,175,55),GOLD); text_at(Vector2(800,450),"RESET",23)
	match mode:
		"water_sort","ball_sort":
			for i in 4:
				box(Rect2(185+i*150,100,110,280),GOLD if int(s.selected)==i else Color('#e7eceb'))
				for j in s.tubes[i].size():
					var p := Vector2(240+i*150,340-j*74)
					if mode=="ball_sort": disc(p,30,COLORS[int(s.tubes[i][j])])
					else: box(Rect2(p-Vector2(45,35),Vector2(90,70)),COLORS[int(s.tubes[i][j])])
			text_at(Vector2(190,70),"One color per full tube. Select source, then destination.",21)
		"sliding_puzzle","sokoban","minesweeper","nonogram","pipe_flow","laser_reflect","tic_tac_toe","connect_four","memory_pairs","chess_fork","knight_tour","peg_solitaire","tangram": paint_grid()
		"domino":
			text_at(Vector2(210,85),"Open end: "+str(s.end)+"   Finish with 3. Use every tile.",25)
			for i in 6:
				box(Rect2(185+(i%3)*205,130+(i/3)*115,175,80),GREEN if s.used.has(i) else GOLD)
				text_at(Vector2(217+(i%3)*205,180+(i/3)*115),str(s.tiles[i][0])+" | "+str(s.tiles[i][1]),30)
		"hex_rotation":
			var path: Array[int] = hex_route()
			for i in 7:
				var p: Vector2 = hex_center(i)
				var polygon := PackedVector2Array()
				for n in 6: polygon.append(p+Vector2.from_angle((n+0.5)*TAU/6)*53)
				draw_colored_polygon(polygon,GREEN if path.has(i) else Color('#e7dbbf'))
				polygon.append(polygon[0]); draw_polyline(polygon,INK,4)
				if i==6: disc(p,19,BLUE); continue
				for d in 6:
					if int(s.ports[i])&(1<<d): draw_line(p,p+Vector2.from_angle(d*TAU/6)*46,INK,9)
			text_at(Vector2(155,90),"Turn hex pipes. Visit all six before the blue hub.",24)
			draw_line(Vector2(295,240),hex_center(0),BLUE,9)
		"word_ladder":
			text_at(Vector2(275,110),str(s.word)+"  ->  "+str(s.goal),40)
			text_at(Vector2(175,160),"Change one letter per move. Eight moves maximum.",23)
			var words: Array[String] = ladder_choices()
			for i in words.size():
				var r: Rect2 = option_rect(i,words.size()); box(r,GOLD); text_at(r.position+Vector2(12,52),words[i],28)
			text_at(Vector2(110,345)," -> ".join(s.trail),22)
		"tower_hanoi":
			text_at(Vector2(165,75),"Move every disk to RIGHT. Small disks stay on top.",25)
			for i in 3:
				draw_line(Vector2(240+i*240,115),Vector2(240+i*240,355),INK,8)
				box(Rect2(140+i*240,350,200,18),GOLD)
				for j in s.pegs[i].size():
					var disk: int = int(s.pegs[i][j])
					var width: float = 40+disk*34
					box(Rect2(240+i*240-width/2,310-j*46,width,40),COLORS[disk%4])
				if int(s.selected)==i: text_at(Vector2(215+i*240,103),"^",26,RED)
		"river_ferry":
			text_at(Vector2(115,80),"Wolf eats goat. Goat eats cabbage. Keep them supervised.",24)
			for i in range(1,4):
				box(Rect2(145+(i-1)*190,130,150,145),GOLD if int(s.cargo)==i else Color('#d9e9df'))
				text_at(Vector2(158+(i-1)*190,175),["WOLF","GOAT","LEAF"][i-1],24)
				text_at(Vector2(160+(i-1)*190,235),"LEFT" if int(s.bank[i])==0 else "RIGHT",22)
			box(Rect2(730,165,170,90),BLUE); text_at(Vector2(755,218),"SAIL",30,PAPER)
			text_at(Vector2(215,335),"Boat on "+("LEFT" if int(s.bank[0])==0 else "RIGHT")+". Pick one passenger, or sail empty.",23)
		"logic_grid":
			text_at(Vector2(100,75),"Dart does NOT have "+["WRENCH","BROOM","KEY"][int(s.goal[2])]+".  Bolt has "+["WRENCH","BROOM","KEY"][int(s.goal[1])]+".",24)
			for row in 3:
				text_at(Vector2(140,177+row*75),["DART","BOLT","ECHO"][row],25)
				for col in 3:
					var r := Rect2(285+col*110,135+row*75,100,65)
					box(r,GREEN if int(s.board[row])==col else GOLD); text_at(r.position+Vector2(5,38),["FIX","SWEEP","OPEN"][col],18)
			text_at(Vector2(180,385),"Each hero owns a different tool.",22)
		"train_shunt":
			text_at(Vector2(130,75),"Dispatch A, B, C. Sidings are stacks; last car leaves first.",24)
			for row in 3:
				box(Rect2(145,110+row*87,430,70),GOLD if int(s.selected)==row else Color('#d4e5e2'))
				text_at(Vector2(45,153+row*87),["IN","S1","S2"][row],24)
				for col in s.tracks[row].size():
					box(Rect2(165+col*115,122+row*87,90,46),COLORS[int(s.tracks[row][col])]); text_at(Vector2(195+col*115,156+row*87),["A","B","C"][int(s.tracks[row][col])],27)
			box(Rect2(640,140,240,150),BLUE); text_at(Vector2(675,200),"DISPATCH",27,PAPER)
			text_at(Vector2(710,255),str(s.delivered.size())+" / 3",30,PAPER)
		"circuit_logic":
			text_at(Vector2(160,100),"XOR A/B   AND B/C   XOR C/D   OR A/D",26)
			var outputs: Array = circuit_output(s.switches)
			for i in 4:
				disc(Vector2(255+i*150,153),25,GREEN if outputs[i]==s.target[i] else RED)
				text_at(Vector2(231+i*150,164),str(outputs[i])+"/"+str(s.target[i]),20)
				box(Rect2(200+i*150,215,115,80),GREEN if int(s.switches[i]) else GOLD)
				text_at(Vector2(230+i*150,265),["A","B","C","D"][i]+str(s.switches[i]),28)
			text_at(Vector2(180,360),"Left number is current. Right number is required.",22)
		"gear_link":
			text_at(Vector2(150,60),"Fit gears between motor and load. Radius sums equal gaps.",23)
			for i in 3:
				disc(Vector2(300+i*145,125),36,GOLD if int(s.selected)==i else BLUE); text_at(Vector2(282+i*145,135),str(s.gears[i]),23)
			for i in 4:
				var p := Vector2([180,300,460,640][i],285)
				disc(p,maxf(15,float(s.slots[i])),GREEN if int(s.slots[i])>0 else Color('#e7dbbf'))
				if int(s.slots[i])>0:
					var angle: float = elapsed*3*(1 if i%2==0 else -1)
					draw_line(p,p+Vector2.from_angle(angle)*float(s.slots[i])*0.75,INK,5)
			text_at(Vector2(225,400),"Gaps: 120, 160, 180. Choose gear, then empty hub.",22)
		"code_breaker":
			text_at(Vector2(155,75),"Crack four colors in six guesses. Tap to cycle a peg.",25)
			for i in 4: disc(Vector2(280+i*105,180),36,COLORS[int(s.guess[i])])
			box(Rect2(740,145,160,70),BLUE); text_at(Vector2(758,187),"CHECK",27,PAPER)
			for i in s.guesses.size():
				var guess: Dictionary = s.guesses[i]
				for col in 4: disc(Vector2(220+col*35,255+i*24),9,COLORS[int(guess.colors[col])])
				text_at(Vector2(395,264+i*24),str(guess.exact)+" exact, "+str(guess.near)+" wrong spot",20)

func paint_grid() -> void:
	for i in int(s.cols)*int(s.rows):
		var p: Vector2 = cell_center(i)
		var color: Color = Color('#e7dbbf')
		var label: String = ""
		match mode:
			"sliding_puzzle": color=GOLD if int(s.board[i]) else Color('#d2c9b1'); label=str(s.board[i]) if int(s.board[i]) else ""
			"sokoban":
				if i%5==0 or i%5==4 or i/5==0 or i/5==4: color=INK
				if i==int(s.goal): color=GREEN; label="GO"
				if i==int(s.crate): color=GOLD; label="BOX"
				if i==int(s.player): color=BLUE; label="YOU"
			"minesweeper":
				if s.revealed.has(i): color=PAPER; label=str(adjacent_mines(i))
				elif s.flags.has(i): color=RED; label="!"
				else: color=BLUE; label="?"
			"nonogram": color=BLUE if int(s.board[i]) else Color('#eee7ce')
			"tangram": color=COLORS[int(s.board[i])] if int(s.board[i])>=0 else Color('#e7dbbf')
			"tic_tac_toe": label=["","X","O"][int(s.board[i])]; color=GOLD
			"connect_four": color=COLORS[int(s.board[i])-1] if int(s.board[i]) else Color('#e7dbbf')
			"memory_pairs": color=GREEN if s.matched.has(i) else (GOLD if s.open.has(i) else BLUE); label=["SUN","MOON","STAR","RAIN"][int(s.cards[i])] if s.matched.has(i) or s.open.has(i) else "?"
			"chess_fork","knight_tour":
				color=Color('#d4e5e2') if (i%int(s.cols)+i/int(s.cols))%2==0 else GOLD
				if i==int(s.knight): color=BLUE; label="N"
				elif mode=="chess_fork" and s.enemies.has(i): color=RED; label="K" if i==int(s.enemies[0]) else "R"
				elif mode=="knight_tour" and s.visited.has(i): color=GREEN; label=str(s.visited.find(i)+1)
			"peg_solitaire": color=GOLD if int(s.selected)==i else Color('#e7dbbf')
		var size: float = float(s.cell)-6
		box(Rect2(p-Vector2.ONE*size/2,Vector2.ONE*size),color)
		if label!="": text_at(p+Vector2(-float(label.length())*7,10),label,21, PAPER if color==BLUE or color==RED else INK)
		if mode=="pipe_flow":
			for d in 4:
				if int(s.board[i])&(1<<d): draw_line(p,p+Vector2(DIRS[d])*float(s.cell)*0.49,BLUE if pipe_route().has(i) else INK,10)
		if mode=="laser_reflect" and s.mirrors.has(i): draw_line(p+Vector2(-22,22 if int(s.mirrors[i])==0 else -22),p+Vector2(22,-22 if int(s.mirrors[i])==0 else 22),INK,7)
		if mode=="peg_solitaire" and int(s.board[i])==1: disc(p,24,BLUE)
	match mode:
		"sliding_puzzle": text_at(Vector2(140,50),"Slide beside the gap. Restore 1 to 8 in reading order.",24)
		"sokoban": text_at(Vector2(135,50),"Push the crate onto GO. Arrows or adjacent tiles.",24)
		"minesweeper":
			text_at(Vector2(170,50),"Four mines. Reveal every safe tile.",24)
			box(Rect2(675,150,220,64),GOLD if s.flag_mode else BLUE); text_at(Vector2(693,190),"FLAG" if s.flag_mode else "REVEAL",26,INK if s.flag_mode else PAPER)
			text_at(Vector2(38,78),"Row mines",21)
			for row in 4: text_at(Vector2(80,cell_center(row*4).y+9),str([2,0,0,2][row]),25)
			text_at(Vector2(670,280),"Column mines:",20)
			text_at(Vector2(705,320),"2  0  0  2",23)
		"nonogram":
			for i in 5:
				text_at(Vector2(245,cell_center(i*5).y+8)," ".join(nonogram_line(s.goal,i,false)),22)
				var clues: Array = nonogram_line(s.goal,i,true)
				for n in clues.size(): text_at(Vector2(cell_center(i).x-6,98-(clues.size()-n-1)*20),str(clues[n]),19)
			text_at(Vector2(90,35),"Fill groups matching row and column counts.",23)
		"tangram":
			for i in 3:
				box(Rect2(630,100+i*87,235,70),GREEN if s.placed[i] else (GOLD if int(s.selected)==i else BLUE))
				text_at(Vector2(650,140+i*87),"PIECE "+str(i+1),22)
				for v in tangram_cells(i,0): box(Rect2(777+v.x*15,115+i*87+v.y*15,13,13),COLORS[i])
			box(Rect2(75,205,170,70),GOLD); text_at(Vector2(95,247),"ROTATE",24)
			text_at(Vector2(100,50),"Pack all three pieces into the square. Tap a top-left origin.",23)
		"pipe_flow":
			text_at(Vector2(100,50),"Rotate pipes to carry water from IN to OUT.",24)
			text_at(Vector2(220,185),"IN",25,BLUE); text_at(Vector2(650,265),"OUT",25,GREEN)
		"laser_reflect":
			text_at(Vector2(95,60),"Flip mirrors to send the red beam to lower-left GO.",23)
			var path: Array[Vector2] = laser_path()
			for i in range(1,path.size()): draw_line(Vector2(s.origin)+(path[i-1]+Vector2.ONE*0.5)*float(s.cell),Vector2(s.origin)+(path[i]+Vector2.ONE*0.5)*float(s.cell),RED,5)
			text_at(Vector2(185,310),"GO",25,GREEN)
		"tic_tac_toe": text_at(Vector2(175,60),"Make three Xs in a row, or earn a draw.",24)
		"connect_four": text_at(Vector2(180,40),"You are red. Drop a disk; connect four.",24)
		"memory_pairs": text_at(Vector2(205,85),"Find all four pairs. Mismatches flip back.",26)
		"chess_fork": text_at(Vector2(105,50),"Move the knight to attack BOTH red pieces at once.",24)
		"knight_tour": text_at(Vector2(125,60),"Visit all twelve squares using knight moves. Never revisit.",23)
		"peg_solitaire": text_at(Vector2(150,125),"Jump a peg over its neighbor. Leave exactly one.",25)

func adjacent_mines(index: int) -> int:
	var count: int = 0
	for mine in s.mines:
		if absi(index%4-int(mine)%4)<=1 and absi(index/4-int(mine)/4)<=1: count+=1
	return count
