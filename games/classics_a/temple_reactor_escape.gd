extends ArcadeGame
var commands: Array[Vector2] = []
var index: int = 0
var clock: float = 0.0
var window: float = 1.5
var response: bool = false
var path: Array[Vector2] = []
var position_index: int = 0

func configure() -> void:
	commands.clear(); path=[Vector2(450,280)]; index=0; clock=0; response=false; health=3; score=0
	window=maxf(0.8,1.5-difficulty*0.06)
	for i in 18: commands.append([Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN][rng.randi_range(0,3)])

func handle_action(action: String, point: Vector2, value: Vector2) -> void:
	var d := Vector2.ZERO
	if action in ['direction','swipe']:
		d=Vector2(signf(value.x),0) if absf(value.x)>absf(value.y) else Vector2(0,signf(value.y))
	elif action=='action': d=Vector2.UP
	elif action=='press':
		var b: int = pressed_button(point)
		if b>=0: d=[Vector2.LEFT,Vector2.RIGHT,Vector2.DOWN,Vector2.UP][b]
	if d==Vector2.ZERO or response or finished: return
	# The painted gate is the timing marker; early moves do not consume the turn.
	if clock<window*0.35: feedback(Vector2(480,210),false); return
	response=true
	if d==commands[index]: earn(15,Vector2(480,230))
	else: damage(Vector2(480,280))

func simulate(dt: float) -> void:
	clock+=dt
	if clock>=window:
		if not response: damage(Vector2(480,280))
		index+=1; clock=0; response=false
		window=maxf(0.62,window-0.025)
		if index>=commands.size() and not finished: win(score+100)

func paint() -> void:
	hud('TEMPLE REACTOR ESCAPE / READ THE NEXT TURN')
	text_at(Vector2(22,62),'GATE %d / 18 / WAIT FOR GREEN, THEN SWIPE' % (index+1),21)
	box(Rect2(180,85,600,310),Color('#dbc5a4'))
	for i in 7:
		var inset: float = i*28+clock/window*25
		draw_rect(Rect2(180+inset,85+inset*0.25,600-inset*2,310-inset*0.7),INK,false,3)
	var d: Vector2 = commands[mini(index,17)]
	var names := {Vector2.LEFT:'TURN LEFT',Vector2.RIGHT:'TURN RIGHT',Vector2.UP:'JUMP GAP',Vector2.DOWN:'SLIDE ARCH'}
	text_at(Vector2(340,175),names[d],30)
	draw_line(Vector2(480,220),Vector2(480,220)+d*70,GREEN if clock>=window*0.35 else RED,12)
	hero(Vector2(480,310),0.85)
	buttons(['LEFT','RIGHT','SLIDE','JUMP'])
