extends SceneTree
## Drives production actions against real rule predicates. No direct win() calls.
const GAME = preload("res://microgames/pack_c.gd")
var checks: int = 0
var failed: int = 0
var actions: int = 0

func _initialize() -> void:
	call_deferred("run")

func expect(condition: bool, message: String) -> void:
	checks+=1
	if not condition: failed+=1; print("FAIL ",message)

func run() -> void:
	if "--capture" in OS.get_cmdline_user_args():
		await capture_pack()
		return
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://microgames/pack_c.json"))
	expect(entries.size()==25,"25 distinct registered puzzles")
	var ids: Array[String] = []
	for item in entries:
		expect(not ids.has(str(item.id)),"unique "+str(item.id)); ids.append(str(item.id))
		for level in [1.0,6.0]:
			for seed_value in [17,92]:
				var game = GAME.new()
				root.add_child(game)
				game.set_process(false)
				var result: Dictionary = {"won":false,"emitted":0,"score":0}
				game.completed.connect(func(won:bool,score:int): result.won=won; result.score=score; result.emitted=int(result.emitted)+1)
				game.start(item,level,seed_value)
				await process_frame
				expect(not game.finished and game.active,"initial playable "+str(item.id))
				game.advance(0.2)
				var before_pause: float = game.elapsed
				game.active=false; game.advance(2.0)
				expect(game.elapsed==before_pause,"pause freezes "+str(item.id))
				game.active=true
				var before: Dictionary = game.s.duplicate(true)
				game.handle_action("cancel",Vector2.ZERO,Vector2.ZERO)
				expect(not game.finished and int(game.s.selected)==-1,"cancel "+str(item.id))
				solve(game)
				expect(game.finished and result.won and int(result.score)>0,"WIN "+str(item.id)+" level "+str(level)+" seed "+str(seed_value))
				expect(int(result.emitted)==1,"single terminal event "+str(item.id))
				game.advance(100); game.handle_action("press",Vector2(480,240),Vector2.ZERO)
				expect(int(result.emitted)==1,"terminal input ignored "+str(item.id))
				game.start(item,level,seed_value)
				expect(not game.finished and game.s==before,"restart restores seeded board "+str(item.id))
				game.free()
			var idle = GAME.new()
			root.add_child(idle); idle.set_process(false)
			var result: Dictionary = {"won":true,"emitted":0}
			idle.completed.connect(func(won:bool,_score:int): result.won=won; result.emitted=int(result.emitted)+1)
			idle.start(item,level,17)
			idle.advance(idle.duration+0.1)
			expect(idle.finished and not result.won and int(result.emitted)==1,"IDLE LOSS "+str(item.id)+" level "+str(level))
			idle.free()
	await special_rules(entries)
	print("PACK C: ",checks," checks, ",actions," production input actions, 100 solved boards and 50 idle losses; failures=",failed)
	quit(1 if failed>0 else 0)

func tap(game,point: Vector2) -> void:
	actions+=1
	game.handle_action("press",point,Vector2.ZERO)
	game.handle_action("release",point,Vector2.ZERO)
	game.advance(0.035)

func cell(game,index: int) -> void:
	tap(game,game.cell_center(index))

func select(game,option: int) -> void:
	actions+=1
	game.handle_action("select",Vector2.ZERO,Vector2(option+1,0))
	game.advance(0.035)

func solve(game) -> void:
	match game.mode:
		"water_sort","ball_sort":
			var path: Array = solve_tubes(game.s.tubes,int(game.s.capacity),game.mode=="water_sort")
			expect(not path.is_empty(),"tube puzzle has legal solution")
			for move in path: select(game,int(move[0])); select(game,int(move[1]))
		"sliding_puzzle":
			var path: Array = solve_slide(game.s.board)
			expect(not path.is_empty(),"sliding board reachable by legal moves")
			for index in path: cell(game,int(index))
		"sokoban":
			for d in [Vector2.RIGHT,Vector2.UP,Vector2.LEFT,Vector2.UP,Vector2.RIGHT]:
				actions+=1; game.handle_action("direction",Vector2.ZERO,d); game.advance(0.04)
		"minesweeper":
			for i in 16:
				if not game.s.mines.has(i) and not game.s.revealed.has(i): cell(game,i)
		"tangram":
			for move in [[0,0],[1,1],[2,3]]: select(game,int(move[0])); cell(game,int(move[1]))
		"nonogram":
			# The visible clue runs are checked independently, including solution uniqueness.
			var solutions: Array = nonogram_solutions(game.s.goal)
			expect(solutions.size()==1,"nonogram uniquely solvable")
			if solutions.is_empty(): return
			for i in 25:
				if int(solutions[0][i])==1: cell(game,i)
		"domino":
			var path: Array = domino_path(game.s.tiles,0,[])
			expect(path.size()==6,"domino chain uses every tile")
			for i in path: tap(game,Vector2(270+(int(i)%3)*205,170+(int(i)/3)*115))
		"pipe_flow":
			for pair in [[4,10],[5,12],[9,3],[10,10],[11,10]]:
				for n in 4:
					if game.finished or int(game.s.board[pair[0]])==int(pair[1]): break
					cell(game,int(pair[0]))
		"laser_reflect":
			for pair in [[6,0],[1,0],[3,1],[13,0]]:
				if int(game.s.mirrors[pair[0]])!=int(pair[1]): cell(game,int(pair[0]))
		"tic_tac_toe":
			for turn in 5:
				if game.finished: break
				var choice: int = best_tic(game.s.board,1)
				if choice>=0: cell(game,choice)
		"connect_four":
			cell(game,3 if int(game.s.board[24])==1 else 2)
		"hex_rotation":
			var route: Array[Vector2i] = [Vector2i(-1,0),Vector2i(0,-1),Vector2i(1,-1),Vector2i(1,0),Vector2i(0,1),Vector2i(-1,1),Vector2i.ZERO]
			var directions: Array[Vector2i] = [Vector2i(1,0),Vector2i(0,1),Vector2i(-1,1),Vector2i(-1,0),Vector2i(0,-1),Vector2i(1,-1)]
			for i in 6:
				var previous: Vector2i = Vector2i(-2,0) if i==0 else route[i-1]
				var ports: int = (1<<directions.find(previous-route[i]))|(1<<directions.find(route[i+1]-route[i]))
				for n in 6:
					if game.finished or int(game.s.ports[i])==ports: break
					tap(game,game.hex_center(i))
		"word_ladder":
			for word in ["CORD","CARD","WARD","WARM"]:
				var choices: Array[String] = game.ladder_choices()
				var i: int = choices.find(word)
				expect(i>=0,"word differs by one letter "+word)
				if i>=0: select(game,i)
		"tower_hanoi":
			var moves: Array = []
			hanoi(int(game.s.disks),0,2,1,moves)
			for move in moves: select(game,int(move[0])); select(game,int(move[1]))
		"memory_pairs":
			for color in 4:
				for i in 8:
					if int(game.s.cards[i])==color: cell(game,i)
		"chess_fork": cell(game,7)
		"knight_tour":
			var path: Array = knight_path([0])
			expect(path.size()==12,"knight board has full tour")
			for i in range(1,path.size()): cell(game,int(path[i]))
		"river_ferry":
			for cargo in [2,-1,1,2,3,-1,2]:
				if cargo>=0: select(game,int(cargo)-1)
				select(game,3)
		"peg_solitaire":
			var forward: bool = int(game.s.board[0])==1
			for i in 3:
				cell(game,i*2 if forward else 6-i*2)
				cell(game,i*2+2 if forward else 4-i*2)
		"logic_grid":
			# Two visible clues determine the only bijection.
			var bolt: int = int(game.s.goal[1])
			var excluded_dart: int = int(game.s.goal[2])
			var dart: int = 3-bolt-excluded_dart
			for pair in [[0,dart],[1,bolt],[2,excluded_dart]]: tap(game,Vector2(335+int(pair[1])*110,167+int(pair[0])*75))
		"train_shunt":
			for move in [[0,1],[0,3],[0,3],[1,3]]: select(game,int(move[0])); select(game,int(move[1]))
		"circuit_logic":
			var answer: int = -1
			for mask in 16:
				var a: Array = [mask&1,(mask>>1)&1,(mask>>2)&1,(mask>>3)&1]
				if [a[0]^a[1],a[1]&a[2],a[2]^a[3],a[0]|a[3]]==game.s.target: answer=mask; break
			expect(answer>=0,"circuit truth table has solution")
			for i in 4:
				if (answer>>i)&1: select(game,i)
		"gear_link":
			select(game,0); tap(game,Vector2(300,285)); select(game,1); tap(game,Vector2(460,285))
		"code_breaker":
			for i in 4:
				for n in int(game.s.code[i]): select(game,i)
			tap(game,Vector2(810,180))

func tube_goal(tubes: Array,capacity: int) -> bool:
	for tube in tubes:
		if tube.is_empty(): continue
		if tube.size()!=capacity: return false
		for color in tube:
			if color!=tube[0]: return false
	return true

func solve_tubes(start: Array,capacity: int,pour: bool) -> Array:
	var queue: Array = [{"board":start.duplicate(true),"path":[]}]
	var seen: Dictionary = {str(start):true}
	var read: int = 0
	while read<queue.size():
		var node: Dictionary = queue[read]; read+=1
		if tube_goal(node.board,capacity): return node.path
		for source in 4:
			for destination in 4:
				var from: Array = node.board[source]
				var to: Array = node.board[destination]
				if source==destination or from.is_empty() or to.size()>=capacity: continue
				if not to.is_empty() and to.back()!=from.back(): continue
				var board: Array = node.board.duplicate(true)
				var color: int = int(board[source].back())
				board[destination].append(board[source].pop_back())
				if pour:
					while not board[source].is_empty() and int(board[source].back())==color and board[destination].size()<capacity: board[destination].append(board[source].pop_back())
				var key: String = str(board)
				if seen.has(key): continue
				seen[key]=true
				var path: Array = node.path.duplicate(); path.append([source,destination])
				queue.append({"board":board,"path":path})
	return []

func solve_slide(start: Array) -> Array:
	var queue: Array = [{"board":start.duplicate(),"path":[]}]
	var seen: Dictionary = {str(start):true}
	var read: int = 0
	while read<queue.size():
		var node: Dictionary = queue[read]; read+=1
		if node.board==[1,2,3,4,5,6,7,8,0]: return node.path
		var blank: int = node.board.find(0)
		for i in 9:
			if absi(i%3-blank%3)+absi(i/3-blank/3)!=1: continue
			var board: Array = node.board.duplicate(); board[blank]=board[i]; board[i]=0
			var key: String = str(board)
			if seen.has(key): continue
			seen[key]=true
			var path: Array = node.path.duplicate(); path.append(i)
			queue.append({"board":board,"path":path})
	return []

func row_groups(row: Array) -> Array:
	var answer: Array = []
	var count: int = 0
	for value in row:
		if value==1: count+=1
		elif count>0: answer.append(count); count=0
	if count>0: answer.append(count)
	return [0] if answer.is_empty() else answer

func nonogram_solutions(goal: Array) -> Array:
	var row_candidates: Array = []
	var col_clues: Array = []
	for row in 5:
		var clue: Array = row_groups(goal.slice(row*5,row*5+5))
		var candidates: Array = []
		for mask in 32:
			var values: Array = []
			for bit in 5: values.append((mask>>bit)&1)
			if row_groups(values)==clue: candidates.append(values)
		row_candidates.append(candidates)
		var column: Array = []
		for r in 5: column.append(goal[r*5+row])
		col_clues.append(row_groups(column))
	var result: Array = []
	nonogram_search(row_candidates,col_clues,[],result)
	return result

func nonogram_search(rows: Array,cols: Array,board: Array,result: Array) -> void:
	if board.size()==25:
		for col in 5:
			var values: Array = []
			for row in 5: values.append(board[row*5+col])
			if row_groups(values)!=cols[col]: return
		result.append(board.duplicate()); return
	for row in rows[board.size()/5]:
		var next: Array = board.duplicate(); next.append_array(row)
		nonogram_search(rows,cols,next,result)

func domino_path(tiles: Array,end: int,used: Array) -> Array:
	if used.size()==6: return used if end==3 else []
	for i in tiles.size():
		if used.has(i): continue
		var tile: Array = tiles[i]
		if tile[0]!=end and tile[1]!=end: continue
		var next: Array = used.duplicate(); next.append(i)
		var result: Array = domino_path(tiles,int(tile[1]) if tile[0]==end else int(tile[0]),next)
		if not result.is_empty(): return result
	return []

func tic_winner(board: Array) -> int:
	for row in [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]]:
		if board[row[0]]!=0 and board[row[0]]==board[row[1]] and board[row[1]]==board[row[2]]: return int(board[row[0]])
	return 0

func tic_eval(board: Array,turn: int) -> int:
	var winner: int = tic_winner(board)
	if winner!=0: return 1 if winner==1 else -1
	if not board.has(0): return 0
	var scores: Array[int] = []
	for i in 9:
		if board[i]!=0: continue
		board[i]=turn; scores.append(tic_eval(board,3-turn)); board[i]=0
	return scores.max() if turn==1 else scores.min()

func best_tic(board: Array,turn: int) -> int:
	var best: int = -2
	var choice: int = -1
	for i in 9:
		if board[i]!=0: continue
		board[i]=turn
		var score: int = tic_eval(board,3-turn)
		board[i]=0
		if score>best: best=score; choice=i
	return choice

func hanoi(count: int,source: int,destination: int,spare: int,moves: Array) -> void:
	if count==0: return
	hanoi(count-1,source,spare,destination,moves)
	moves.append([source,destination])
	hanoi(count-1,spare,destination,source,moves)

func knight_path(path: Array) -> Array:
	if path.size()==12: return path
	var a: int = int(path.back())
	for b in 12:
		if path.has(b): continue
		var x: int = absi(a%4-b%4)
		var y: int = absi(a/4-b/4)
		if not ((x==1 and y==2) or (x==2 and y==1)): continue
		var next: Array = path.duplicate(); next.append(b)
		var answer: Array = knight_path(next)
		if not answer.is_empty(): return answer
	return []

func special_rules(entries: Array) -> void:
	for mode in ["minesweeper","river_ferry","code_breaker","connect_four"]:
		var game = GAME.new(); root.add_child(game); game.set_process(false)
		var spec: Dictionary = {}
		for item in entries:
			if str(item.id)==mode: spec=item
		var result: Dictionary = {"won":true,"events":0}
		game.completed.connect(func(won:bool,_score:int): result.won=won; result.events=int(result.events)+1)
		game.start(spec,1,17)
		match mode:
			"minesweeper": cell(game,0)
			"river_ferry": select(game,3) # empty boat leaves an unsafe bank
			"code_breaker":
				# Ensure the repeated incorrect guess cannot accidentally match the generated code.
				if game.s.code==[0,0,0,0]: select(game,0)
				for n in 6: tap(game,Vector2(810,180))
			"connect_four":
				cell(game,0 if game.s.board[24]==1 else 5)
				expect(game.s.board[27]==2 if game.s.board[24]==1 else game.s.board[26]==2,"opponent blocks the red four-in-a-row threat")
				for turn in 20:
					if game.finished: break
					for column in [0,5,1,4,2,3]:
						if game.drop_index(game.s.board,column)>=0: cell(game,column); break
		expect(game.finished and not result.won,"rule-specific loss "+mode)
		expect(int(result.events)==1,"loss once "+mode)
		game.free()
	var water = GAME.new(); root.add_child(water); water.set_process(false)
	water.start(entries[0],1,17)
	var original: Dictionary = water.s.duplicate(true)
	var source: int = 0 if not water.s.tubes[0].is_empty() else 3
	var destination: int = 2 if water.s.tubes[2].is_empty() else 0
	select(water,source); select(water,destination)
	expect(int(water.s.moves)==1,"real contiguous pour")
	water.handle_action("undo",Vector2.ZERO,Vector2.ZERO)
	# Undo restores the source selection as it was at the moment of the move.
	water.handle_action("cancel",Vector2.ZERO,Vector2.ZERO)
	expect(water.s.tubes==original.tubes and int(water.s.moves)==0,"undo reverses a real move")
	select(water,source); select(water,destination)
	var clock: float = water.elapsed
	water.handle_action("reset",Vector2.ZERO,Vector2.ZERO)
	expect(water.s==original and water.elapsed==clock,"reset restores board without replenishing timer")
	water.free()
	var code = GAME.new(); root.add_child(code); code.set_process(false)
	expect(code.code_response([0,0,1,1],[0,1,0,1])==Vector2i(2,2),"Mastermind repeated-color accounting")
	expect(code.code_response([0,0,0,0],[0,1,2,3])==Vector2i(1,0),"Mastermind cannot overcount a color")
	code.free()
	await process_frame

func capture_pack() -> void:
	root.size=Vector2i(960,480)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	var folder: String = ProjectSettings.globalize_path("res://build/qa_pack_c")
	DirAccess.make_dir_recursive_absolute(folder)
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://microgames/pack_c.json"))
	for item in entries:
		var game = GAME.new()
		root.add_child(game); game.set_process(false); game.start(item,1,17)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder+"/"+str(item.id)+".png")
		game.free()
	print("PACK C VISUAL: captured ",entries.size()," actual rendered boards at 960x480")
	quit()
