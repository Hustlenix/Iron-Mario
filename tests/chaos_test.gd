extends SceneTree
var checks: int = 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred('run_tests')
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func run_tests() -> void:
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string('res://games/chaos.json'))
	for entry in entries:
		for difficulty in [1.0,3.0,6.0]:
			var g: Node = load(entry.script).new()
			root.add_child(g); g.set_process(false); g.start(entry,difficulty,123)
			var results: Array = []
			g.completed.connect(func(won:bool,score:int)->void:results.append([won,score]))
			play(g)
			check(g.finished and not results.is_empty() and results[0][0],entry.id+' win '+str(difficulty)+' t '+str(g.elapsed)+' state '+str(g.s))
			check(results.size()==1,entry.id+' completion once')
			check(g.points>=0,entry.id+' valid score')
			g.start(entry,difficulty,123); g.active=false; g.advance(0.5)
			check(g.elapsed==0 and not g.finished,entry.id+' pause and restart')
			g.active=true
			for i in 8000:
				if g.finished: break
				g.advance(0.01)
			check(g.finished and not results.back()[0],entry.id+' idle failure')
			g.free()
	print('CHAOS: ',checks,' checks, ',failures.size(),' failures')
	for failure in failures: print(failure)
	quit(0 if failures.is_empty() else 1)

func play(g: Node) -> void:
	var parking_phase: int = 0
	var route: Array[Vector2] = [Vector2.RIGHT,Vector2.RIGHT,Vector2.RIGHT,Vector2.RIGHT,Vector2.DOWN,Vector2.DOWN,Vector2.LEFT,Vector2.LEFT,Vector2.LEFT,Vector2.LEFT,Vector2.UP]
	var route_index: int = 0
	var frontier_waypoints: Array[Vector2i] = [Vector2i(7,3),Vector2i(7,5),Vector2i(3,5),Vector2i(3,3)]
	var last_n: int = -1
	for frame in 7500:
		if g.finished: break
		match g.game:
			'brainrot_button_panic':
				var answer: int = (g.s.answer+2)%4 if g.s.reverse else g.s.answer
				g.handle_action('press',g.pad(answer),Vector2.ZERO)
			'meme_dodge_arena':
				var danger: bool = false
				for item in g.s.items:
					if item.t<0.25 and item.pos.distance_to(g.s.p)<90: danger=true
				if danger:
					for candidate in [Vector2(140,140),Vector2(480,330),Vector2(820,140)]:
						var safe: bool = true
						for item in g.s.items:
							if item.pos.distance_to(candidate)<100: safe=false
						if safe: g.handle_action('drag',candidate,Vector2.ZERO); break
			'one_pixel_survival':
				var nearest: Dictionary = {}
				for item in g.s.items:
					if not item.hit and item.y<337 and (nearest.is_empty() or item.y>nearest.y): nearest=item
				if not nearest.is_empty(): g.handle_action('drag',Vector2(nearest.gap,330),Vector2.ZERO)
			'impossible_parking':
				var target: Vector2 = Vector2(435,345) if parking_phase==0 else Vector2(805,340)
				if g.s.p.distance_to(target)<28: parking_phase+=1
				if parking_phase>=2:
					g.handle_action('move',Vector2.ZERO,Vector2.ZERO); g.handle_action('action',Vector2.ZERO,Vector2.ZERO)
				else:
					var angle: float = (target-g.s.p).angle()
					var steer: float = clampf(wrapf(angle-g.s.angle,-PI,PI)*3,-1,1)
					g.handle_action('move',Vector2.ZERO,Vector2(steer,-0.7))
			'reaction_relay':
				if g.s.go: g.handle_action('action',Vector2.ZERO,Vector2.ZERO)
			'chaos_elevator':
				var target: int = 0
				if g.s.onboard>=0: target=g.s.guests[g.s.onboard].dest
				else:
					for guest in g.s.guests:
						if guest.floor>=0: target=guest.floor; break
				g.handle_action('select',Vector2.ZERO,Vector2(target+1,0))
			'dont_press_red':
				if g.s.green and not g.s.tapped: g.handle_action('action',Vector2.ZERO,Vector2.ZERO)
			'fall_forever':
				for item in g.s.items:
					if not item.passed:
						g.handle_action('drag',Vector2(item.gap,190),Vector2.ZERO); break
			'physics_disaster':
				if not g.s.cut: g.handle_action('select',Vector2.ZERO,Vector2(2,0))
			'paint_frontier':
				if route_index<frontier_waypoints.size():
					if g.s.cell==frontier_waypoints[route_index]: route_index+=1
					if route_index<frontier_waypoints.size():
						var d: Vector2i = frontier_waypoints[route_index]-g.s.cell
						g.handle_action('direction',Vector2.ZERO,Vector2(signi(d.x),0) if d.x!=0 else Vector2(0,signi(d.y)))
			'notebook_platformer':
				g.handle_action('move',Vector2.ZERO,Vector2.RIGHT)
				if g.s.grounded and ((g.s.p.x>170 and g.s.p.x<250) or (g.s.p.x>380 and g.s.p.x<460) or (g.s.p.x>580 and g.s.p.x<680)):
					g.handle_action('action',Vector2.ZERO,Vector2.ZERO)
		g.advance(0.01)
