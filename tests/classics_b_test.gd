extends SceneTree

var checks: int = 0
var failures: Array[String] = []
var signals_seen: Dictionary = {}

func _initialize() -> void:
	call_deferred('run')

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label)

func make_game(entry: Dictionary, level: float = 1, seed_value: int = 1204) -> Node:
	var g: Node = load(entry.script).new()
	root.add_child(g)
	g.set_process(false)
	var seen := {'count':0,'won':false,'score':-1}
	g.completed.connect(func(won:bool,score:int)->void:
		seen.count += 1
		seen.won = won
		seen.score = score)
	signals_seen[g.get_instance_id()] = seen
	g.start(entry,level,seed_value)
	return g

func act(g: Node, action: String, point: Vector2 = Vector2.ZERO, value: Vector2 = Vector2.ZERO) -> void:
	g.handle_action(action,point,value)

func result(g: Node) -> Dictionary:
	return signals_seen[g.get_instance_id()]

func run() -> void:
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string('res://games/classics_b.json'))
	check(entries.size()==8,'eight distinct classics B entries')
	for e in entries:
		for level in [1.0,6.0]:
			var g: Node = make_game(e,level)
			play(g,e.id)
			print('CLASSIC_LOOP ',e.id,' level=',level,' controls=keyboard-equivalent won=',result(g).won,' score=',result(g).score,' seconds=',snappedf(g.elapsed,0.01))
			check(g.finished and result(g).won,'WIN '+e.id+' level '+str(level)+' elapsed '+str(g.elapsed))
			check(result(g).count==1 and result(g).score>0,'one scored completion '+e.id)
			var frozen_time: float = g.elapsed
			g.advance(1)
			check(g.elapsed==frozen_time and result(g).count==1,'terminal freeze '+e.id)
			g.free()
		var touch: Node = make_game(e,3,902)
		play(touch,e.id,'touch',1.0/30)
		check(touch.finished and result(touch).won,'touch gestures at30Hz '+e.id)
		check(result(touch).count==1 and result(touch).score>0,'touch scored completion '+e.id)
		print('CLASSIC_LOOP ',e.id,' level=3 controls=touch-handlers@30Hz won=',result(touch).won,' score=',result(touch).score,' seconds=',snappedf(touch.elapsed,0.01))
		touch.free()
		var failed: Node = make_game(e)
		var before: float = failed.elapsed
		failed.active = false
		failed.advance(5)
		check(failed.elapsed==before,'paused game time '+e.id)
		failed.active = true
		for frame in 10000:
			if failed.finished: break
			failed.advance(0.01)
		check(failed.finished and not result(failed).won and result(failed).count==1,'unattended fail '+e.id)
		failed.start(e,1,1204)
		check(not failed.finished and failed.elapsed==0 and failed.points==0,'restart reset '+e.id)
		failed.free()
	rule_fixtures(entries)
	print('CLASSICS_B_CHECKS=',checks,' FAILURES=',failures.size())
	for f in failures: print(f)
	quit(0 if failures.is_empty() else 1)

func play(g: Node, id: String, controls: String = 'keyboard', frame_step: float = 0.01) -> void:
	var last_y: float = 400
	var last_landings: int = 0
	for frame in 10000:
		if g.finished: break
		match id:
			'feed_reactor':
				if g.brace_attached:
					if controls=='touch': act(g,'press',g.brace_anchor.lerp(g.battery,0.5))
					else: act(g,'select',Vector2.ZERO,Vector2(2,0))
				var ready: bool = (g.angle>-0.16 and g.angle<0.03 and g.angular_velocity>0) if g.receiver.get_center().x>g.anchor.x else (g.angle<0.16 and g.angle>-0.03 and g.angular_velocity<0)
				if g.attached and ready:
					if controls=='touch':
						var midpoint: Vector2 = g.anchor.lerp(g.battery,0.5)
						var normal: Vector2 = (g.battery-g.anchor).orthogonal().normalized()*80
						act(g,'swipe',midpoint+normal,normal*2)
					else: act(g,'action')
			'neon_rhythm_escape':
				if g.grounded:
					for o in g.obstacles:
						var x: float = o.x-g.travel
						if not o.passed and x>g.runner.x-30 and x<g.runner.x+90:
							act(g,'press' if controls=='touch' else 'action',Vector2(480,440))
							break
			'skyline_jumper':
				if g.landings!=last_landings:
					last_landings = g.landings
					last_y = g.jumper.y+14
				var target: Dictionary = {}
				for p in g.platforms:
					if not p.gone and p.y<last_y-1 and (target.is_empty() or p.y>target.y): target = p
				if not target.is_empty():
					var move: float = signf(target.x-g.jumper.x) if absf(target.x-g.jumper.x)>5 else 0
					if controls=='touch':
						if move==0: act(g,'release')
						else: act(g,'press',Vector2(200 if move<0 else 700,440))
					else: act(g,'move',Vector2.ZERO,Vector2(move,0))
			'turbo_flapper':
				var center: float = 235
				for gate in g.gates:
					if gate.x>g.flyer.x-45:
						center = gate.y
						break
				if g.flyer.y>center+7 and g.vertical_speed>0: act(g,'press' if controls=='touch' else 'action',Vector2(480,240))
			'bridge_builder':
				if g.phase=='ready': act(g,'press' if controls=='touch' else 'action',Vector2(480,240))
				if g.phase=='growing' and g.plank_length>=g.destination.get_center().x-g.island.end.x: act(g,'release')
			'reactor_merge':
				if frame%3==0: act(g,'swipe' if controls=='touch' else 'direction',Vector2(480,240),choose_merge(g)*(160 if controls=='touch' else 1))
			'rooftop_defense':
				if g.units.is_empty():
					if controls=='touch': act(g,'press',Vector2(260,435))
					else: act(g,'select',Vector2.ZERO,Vector2(1,0))
					act(g,'press',g.cell_point(Vector2i(0,0)))
				if g.currency>=60:
					for row in 3:
						var exists: bool = false
						for u in g.units:
							if u.cell==Vector2i(1,row): exists = true
						if not exists:
							if controls=='touch': act(g,'press',Vector2(490,435))
							else: act(g,'select',Vector2.ZERO,Vector2(2,0))
							act(g,'press',g.cell_point(Vector2i(1,row)))
							break
			'mini_reactor_buddy':
				if g.cooldown<=0:
					var choice: int = -1
					if g.heat>65: choice = 3
					elif g.fuel<83: choice = 0
					elif g.hygiene<83: choice = 1
					elif g.joy<83 and absf(wrapf(g.phase,-PI,PI))<0.5: choice = 2
					if choice>=0:
						if controls=='touch':
							act(g,'press',Vector2(140+choice*220,430))
							if choice==2: act(g,'press',Vector2(595,235))
						else:
							act(g,'select',Vector2.ZERO,Vector2(choice+1,0))
							act(g,'action')
		g.advance(frame_step)

func merge_quality(board: Array) -> float:
	var quality: float = 0
	var maximum: int = 0
	var weights: Array[float] = [16,8,4,2,1,0.8,0.6,0.4,0.3,0.25,0.2,0.15,0.1,0.08,0.06,0.04]
	for i in 16:
		if board[i]==0: quality += 110
		quality += board[i]*weights[i]
		maximum = maxi(maximum,board[i])
	if board[0]==maximum: quality += maximum*5
	return quality

func choose_merge(g: Node) -> Vector2:
	var selected := Vector2.LEFT
	var best: float = -INF
	for d in [Vector2.LEFT,Vector2.UP,Vector2.RIGHT,Vector2.DOWN]:
		var preview: Dictionary = g.preview(d)
		if not preview.changed: continue
		var quality: float = merge_quality(preview.tiles)+preview.points*2
		var follow: float = -INF
		for next in [Vector2.LEFT,Vector2.UP,Vector2.RIGHT,Vector2.DOWN]:
			var second: Dictionary = g.preview(next,preview.tiles)
			if second.changed: follow = maxf(follow,merge_quality(second.tiles))
		if follow>-INF: quality += follow*0.35
		if quality>best:
			best = quality
			selected = d
	return selected

func rule_fixtures(entries: Array) -> void:
	var merge: Node = make_game(entries[5])
	# Isolated algorithm fixture, distinct from the input-driven seeded win runs.
	merge.tiles.assign([2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0])
	var predicted: Dictionary = merge.preview(Vector2.LEFT)
	check(predicted.tiles.slice(0,4)==[4,4,0,0],'one merge per tile')
	act(merge,'direction',Vector2.ZERO,Vector2.LEFT)
	var after: Array = merge.tiles.duplicate()
	act(merge,'undo')
	check(merge.tiles.slice(0,4)==[2,2,2,2] and merge.moves==0,'undo restores board and moves')
	act(merge,'direction',Vector2.ZERO,Vector2.LEFT)
	check(merge.tiles==after,'undo also restores seeded spawn sequence')
	merge.tiles.assign([2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0])
	var rng_before: int = merge.rng.state
	act(merge,'direction',Vector2.ZERO,Vector2.LEFT)
	check(merge.tiles.count(0)==15 and merge.rng.state==rng_before,'invalid slide does not spawn')
	merge.free()
	var defense: Node = make_game(entries[6])
	act(defense,'press',defense.cell_point(Vector2i(1,0)))
	var spent: int = defense.currency
	act(defense,'press',defense.cell_point(Vector2i(1,0)))
	check(defense.currency==spent and defense.units.size()==1,'occupied defense cell does not spend')
	act(defense,'select',Vector2.ZERO,Vector2(1,0))
	act(defense,'press',defense.cell_point(Vector2i(0,0)))
	act(defense,'press',defense.cell_point(Vector2i(0,1)))
	check(defense.currency>=0 and defense.rejected>=2,'insufficient energy rejected')
	defense.free()
	var care: Node = make_game(entries[7])
	var before_clean: float = care.hygiene
	act(care,'action')
	check(care.hygiene<before_clean and care.heat>10 and care.fuel>60,'feeding has actual care tradeoffs')
	var fuel_after: float = care.fuel
	act(care,'action')
	check(care.fuel==fuel_after,'care cooldown prevents spam')
	care.free()
	var bridge: Node = make_game(entries[4])
	act(bridge,'action')
	bridge.advance(0.3)
	act(bridge,'cancel')
	var length_before: float = bridge.plank_length
	bridge.advance(0.2)
	act(bridge,'release')
	check(bridge.plank_length==length_before and bridge.phase=='growing','cancel clears held growth without lowering')
	act(bridge,'action')
	act(bridge,'release')
	for i in 300:
		if bridge.finished: break
		bridge.advance(0.01)
	check(bridge.finished and not result(bridge).won,'short bridge falls and loses')
	bridge.free()
