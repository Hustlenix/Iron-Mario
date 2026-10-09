extends ArcadeGame
var player_x: float = 360.0
var enemy_x: float = 620.0
var enemy_hp: int = 8
var state: String = 'approach'
var state_time: float = 0.0
var recovery: float = 0.0
var blocking: float = 0.0
var combo: int = 0
var combo_time: float = 0.0
var attack_flash: float = 0.0

func configure() -> void:
	player_x=360; enemy_x=620; enemy_hp=8; health=5; state='approach'; state_time=0
	recovery=0; blocking=0; combo=0; combo_time=0; attack_flash=0

func handle_action(action: String, point: Vector2, value: Vector2) -> void:
	if action=='move': axis=value
	if action=='direction':
		if value.y>0: blocking=0.65
		if value.y<0: attack(true)
	if action=='action': attack(false)
	if action=='secondary': blocking=0.9
	if action=='press':
		match pressed_button(point):
			0: axis=Vector2.LEFT
			1: axis=Vector2.RIGHT
			2: blocking=0.9
			3: attack(false)
	if action=='release': axis=Vector2.ZERO

func attack(heavy: bool) -> void:
	if recovery>0 or finished: return
	recovery=0.7 if heavy else 0.34
	attack_flash=0.2
	if absf(enemy_x-player_x)<135:
		combo=combo+1 if combo_time>0 else 1
		combo_time=0.9
		var hits: int = 2 if heavy or combo%3==0 else 1
		# Telegraph is armored; recovery and approach are punishable.
		if state=='windup': hits=1
		enemy_hp-=hits; enemy_x=minf(875,enemy_x+18*hits)
		earn(20*hits,Vector2(enemy_x,260))
		if enemy_hp<=0: win(score+100)

func simulate(dt: float) -> void:
	recovery=maxf(0,recovery-dt); blocking=maxf(0,blocking-dt); combo_time=maxf(0,combo_time-dt); attack_flash=maxf(0,attack_flash-dt)
	player_x=clampf(player_x+axis.x*180*dt,90,850)
	state_time+=dt
	match state:
		'approach':
			enemy_x=move_toward(enemy_x,player_x+95,110*dt)
			if state_time>1.0 and absf(enemy_x-player_x)<130: state='windup'; state_time=0
		'windup':
			if state_time>0.65:
				if absf(enemy_x-player_x)<135:
					if blocking>0: earn(5,Vector2(player_x,250))
					else: damage(Vector2(player_x,250)); player_x=maxf(85,player_x-35)
				state='recovery'; state_time=0
		'recovery':
			if state_time>0.8: state='approach'; state_time=0

func paint() -> void:
	hud('SHADOW ARMOR DUEL / SPACE PUNCH, UP HEAVY, DOWN BLOCK')
	box(Rect2(60,75,health*65,20),GREEN); box(Rect2(570,75,enemy_hp*38,20),RED)
	text_at(Vector2(580,120),'WINDUP!' if state=='windup' else state.to_upper(),24,RED if state=='windup' else INK)
	draw_line(Vector2(40,355),Vector2(920,355),INK,5)
	hero(Vector2(player_x,290),1.05)
	disc(Vector2(enemy_x,270),30,INK); box(Rect2(enemy_x-28,302,56,50),INK)
	if blocking>0: box(Rect2(player_x+35,245,12,70),BLUE)
	if attack_flash>0: draw_line(Vector2(player_x+20,285),Vector2(player_x+125,280),GOLD,12)
	text_at(Vector2(45,388),'COMBO %d / STEP IN, READ THE WINDUP, COUNTER' % combo,20)
	buttons(['LEFT','RIGHT','BLOCK','PUNCH'])
