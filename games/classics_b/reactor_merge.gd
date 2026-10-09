extends "res://microgames/microgame_base.gd"

const SIZE: int = 4
const GOAL: int = 128
var tiles: Array[int] = []
var undo_state: Dictionary = {}
var moves: int = 0
var invalid_moves: int = 0
var last_direction := Vector2.ZERO

func setup() -> void:
	tiles.clear()
	tiles.resize(16)
	tiles.fill(0)
	undo_state.clear()
	moves = 0
	invalid_moves = 0
	spawn_tile()
	spawn_tile()

func spawn_tile() -> void:
	var empty: Array[int] = []
	for i in 16:
		if tiles[i] == 0: empty.append(i)
	if not empty.is_empty(): tiles[empty[rng.randi_range(0,empty.size()-1)]] = 4 if rng.randf()<0.1 else 2

func preview(direction: Vector2, source: Array[int] = []) -> Dictionary:
	if source.is_empty(): source = tiles
	var out: Array[int] = source.duplicate()
	var earned: int = 0
	for line in SIZE:
		var indices: Array[int] = []
		for i in SIZE:
			if direction.x < 0: indices.append(line*SIZE+i)
			elif direction.x > 0: indices.append(line*SIZE+SIZE-1-i)
			elif direction.y < 0: indices.append(i*SIZE+line)
			else: indices.append((SIZE-1-i)*SIZE+line)
		var values: Array[int] = []
		for index in indices:
			if source[index] != 0: values.append(source[index])
		var merged: Array[int] = []
		var j: int = 0
		while j < values.size():
			if j+1<values.size() and values[j]==values[j+1]:
				merged.append(values[j]*2)
				earned += values[j]*2
				j += 2
			else:
				merged.append(values[j])
				j += 1
		while merged.size()<SIZE: merged.append(0)
		for i in SIZE: out[indices[i]] = merged[i]
	return {'tiles':out,'points':earned,'changed':out!=source}

func slide(direction: Vector2) -> void:
	var result: Dictionary = preview(direction)
	if not result.changed:
		invalid_moves += 1
		return
	undo_state = {'tiles':tiles.duplicate(),'points':points,'rng':rng.state,'moves':moves}
	tiles.assign(result.tiles)
	points += result.points
	moves += 1
	last_direction = direction
	feedback(Vector2(480,240))
	if tiles.max() >= GOAL:
		win(points+100)
		return
	spawn_tile()
	var can_move: bool = false
	for d in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		if preview(d).changed: can_move = true
	if not can_move: lose()

func undo() -> void:
	if undo_state.is_empty(): return
	tiles.assign(undo_state.tiles)
	points = undo_state.points
	rng.state = undo_state.rng
	moves = undo_state.moves
	undo_state.clear()

func handle_action(action: String, point: Vector2, value: Vector2) -> void:
	if finished: return
	if action in ['direction','swipe'] and value.length()>0:
		slide(Vector2(signf(value.x),0) if absf(value.x)>absf(value.y) else Vector2(0,signf(value.y)))
	elif action == 'undo': undo()
	elif action == 'reset':
		points = 0
		setup()
	elif action == 'press':
		if Rect2(125,345,145,84).has_point(point): undo()
		elif Rect2(725,375,150,84).has_point(point):
			points = 0
			setup()
		elif Rect2(125,185,145,84).has_point(point): slide(Vector2.LEFT)
		elif Rect2(725,182,150,84).has_point(point): slide(Vector2.RIGHT)
		elif Rect2(725,85,150,84).has_point(point): slide(Vector2.UP)
		elif Rect2(725,279,150,84).has_point(point): slide(Vector2.DOWN)

func paint() -> void:
	text_at(Vector2(20,35),'REACH '+str(GOAL),26)
	text_at(Vector2(20,66),'Swipe / arrows. U undo, R reset.',19)
	text_at(Vector2(700,35),'MOVES '+str(moves),22)
	for i in 16:
		var r := Rect2(310+(i%4)*86,73+floori(i/4.0)*86,80,80)
		box(r,PAPER if tiles[i]==0 else (GOLD if tiles[i]<16 else GREEN))
		if tiles[i]>0: text_at(r.position+Vector2(15,52),str(tiles[i]),30)
	box(Rect2(125,185,145,84),BLUE)
	text_at(Vector2(177,239),'<',34)
	box(Rect2(725,182,150,84),BLUE)
	text_at(Vector2(780,236),'>',34)
	box(Rect2(725,85,150,84),BLUE)
	text_at(Vector2(775,137),'UP',24)
	box(Rect2(725,279,150,84),BLUE)
	text_at(Vector2(757,331),'DOWN',24)
	box(Rect2(125,345,145,84),GREEN)
	text_at(Vector2(149,397),'UNDO',24)
	box(Rect2(725,375,150,84),RED)
	text_at(Vector2(755,427),'RESET',24)

