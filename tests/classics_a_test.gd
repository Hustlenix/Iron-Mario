extends SceneTree
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void: call_deferred('run_tests')
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message)

func run_tests() -> void:
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string('res://games/classics_a.json'))
	for entry in entries:
		for level in [1.0,3.0,6.0]:
			var game: Node = load(entry.script).new()
			root.add_child(game); game.set_process(false); game.start(entry,level,1204)
			var outcomes: Array = []
			game.completed.connect(func(won:bool,score:int)->void:outcomes.append([won,score]))
			play(game,entry.id)
			check(game.finished and not outcomes.is_empty() and outcomes[0][0],'%s level %.0f win / t %.1f score %d' % [entry.id,level,game.elapsed,game.points])
			check(outcomes.size()==1,entry.id+' one completion')
			check(game.points>=0,entry.id+' valid score')
			game.start(entry,level,1204)
			check(not game.finished and game.elapsed==0,entry.id+' restart resets')
			game.active=false; game.advance(1)
			check(game.elapsed==0,entry.id+' paused simulation')
			game.active=true
			for frame in range(12000):
				if game.finished: break
				game.advance(0.01)
			check(game.finished and not outcomes.back()[0],entry.id+' unattended failure')
			game.free()
	print('CLASSICS_A: ',checks,' checks, ',failures.size(),' failures')
	for failure in failures: print(failure)
	quit(0 if failures.is_empty() else 1)

func play(g: Node, id: String) -> void:
	var last_input: float = -1
	for frame in range(11000):
		if g.finished: break
		match id:
			'metro_armor_rush':
				for coin in g.coins:
					if coin.y<180 or coin.y>300: continue
					var safe: bool = true
					for obstacle in g.obstacles:
						if obstacle.lane==coin.lane and obstacle.y>160 and obstacle.y<365: safe=false
					if safe and coin.lane!=g.lane:
						g.handle_action('direction',Vector2.ZERO,Vector2.LEFT if coin.lane<g.lane else Vector2.RIGHT)
				for obstacle in g.obstacles:
					if obstacle.y>220 and obstacle.y<350 and obstacle.lane==g.lane:
						g.handle_action('direction',Vector2.ZERO,Vector2.LEFT if g.lane>0 else Vector2.RIGHT)
			'shadow_armor_duel':
				g.handle_action('move',Vector2.ZERO,Vector2.RIGHT if absf(g.enemy_x-g.player_x)>105 else Vector2.ZERO)
				if g.state=='windup': g.handle_action('direction',Vector2.ZERO,Vector2.DOWN)
				else: g.handle_action('action',Vector2.ZERO,Vector2.ZERO)
			'scrap_hill_racer': g.handle_action('move',Vector2.ZERO,Vector2.RIGHT)
			'temple_reactor_escape':
				if g.clock>=g.window*0.45 and not g.response: g.handle_action('direction',Vector2.ZERO,g.commands[g.index])
			'reactor_slice':
				for fruit in g.fruit:
					if fruit.bomb or fruit.cut or fruit.pos.y>365: continue
					var safe: bool = true
					for other in g.fruit:
						if other.bomb and other.pos.distance_to(fruit.pos)<80: safe=false
					if safe:
						g.handle_action('press',fruit.pos-Vector2(15,0),Vector2.ZERO)
						g.handle_action('drag',fruit.pos+Vector2(15,0),Vector2.ZERO)
						g.handle_action('release',fruit.pos,Vector2.ZERO)
			'jetpack_test_lab':
				var target: float = 100
				var closest: float = 2000
				for hazard in g.hazards:
					if hazard.x>130 and hazard.x<closest:
						closest=hazard.x; target=355 if hazard.y<235 else 100
				g.handle_action('action' if g.y>target else 'release',Vector2.ZERO,Vector2.ZERO)
			'chaos_crossing':
				if g.cooldown<=0:
					var safe: bool = true
					for lane in g.hazards:
						if lane.row!=g.row+1: continue
						var aboard: bool = false
						for center in g.lane_centers(lane):
							if absf(g.x-center)<(65 if lane.water else 60): aboard=true
						if lane.water: safe=aboard
						else: safe=not aboard
					if safe: g.handle_action('direction',Vector2.ZERO,Vector2.UP)
					elif g.row in [4,5] and (g.x<130 or g.x>830): g.handle_action('direction',Vector2.ZERO,Vector2.DOWN)
			'catapult_chaos':
				if g.elapsed>0.5 and g.balls.is_empty() and g.ammo>0:
					for target in g.targets:
						if not target.alive: continue
						var time: float = (target.pos.x-g.anchor.x)/600.0
						var vy: float = (target.pos.y-g.anchor.y-250*time*time)/time
						var pull: Vector2 = g.anchor-Vector2(600,vy)/7.5
						g.handle_action('press',g.anchor,Vector2.ZERO)
						g.handle_action('drag',pull,Vector2.ZERO)
						g.handle_action('release',pull,Vector2.ZERO)
						break
		g.advance(0.01)
