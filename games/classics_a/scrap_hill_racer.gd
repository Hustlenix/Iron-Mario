extends ArcadeGame
var pos := Vector2(70,220)
var velocity := Vector2.ZERO
var angle: float = 0.0
var spin: float = 0.0
var gas: float = 0.0
var fuel: float = 100.0
var camera_x: float = 0.0
var grounded: bool = false
var crash_time: float = 0.0
var tanks: Array[float] = []
var travelled: float = 0.0

func terrain(x: float) -> float:
	return 300+sin(x/190)*35+sin(x/410)*22

func configure() -> void:
	pos=Vector2(70,terrain(70)-27); velocity=Vector2.ZERO; angle=0; spin=0; gas=0; fuel=100
	camera_x=0; grounded=false; crash_time=0; travelled=0; health=1; tanks=[580.0,1250.0,1920.0]

func handle_action(action: String, point: Vector2, value: Vector2) -> void:
	if action=='cancel': gas=0; return
	if action=='move': gas=value.x
	if action=='action': gas=1
	if action=='press': gas=-1 if point.x<480 else 1
	if action=='release': gas=0

func simulate(dt: float) -> void:
	var left_height: float = terrain(pos.x-31)
	var right_height: float = terrain(pos.x+31)
	var floor_y: float = (left_height+right_height)*0.5-26
	var slope: float = atan2(right_height-left_height,62)
	grounded=pos.y>=floor_y-3
	if grounded:
		pos.y=floor_y
		velocity.y=0
		velocity.x+=((gas*170 if fuel>0 else 0)+sin(slope)*110-velocity.x*0.38)*dt
		angle=lerp_angle(angle,slope,dt*10)
		spin=0
	else:
		velocity.y+=550*dt
		spin+=gas*1.8*dt
		angle+=spin*dt
	velocity.x=clampf(velocity.x,-75,240)
	pos+=velocity*dt; pos.x=maxf(40,pos.x)
	if pos.y>floor_y: pos.y=floor_y
	fuel=maxf(0,fuel-absf(gas)*dt*4)
	for i in range(tanks.size()-1,-1,-1):
		if absf(pos.x-tanks[i])<42:
			fuel=minf(100,fuel+45); tanks.remove_at(i); earn(15,pos)
	travelled=maxf(travelled,pos.x)
	camera_x=maxf(0,pos.x-250)
	if grounded and absf(wrapf(angle,-PI,PI))>1.7: crash_time+=dt
	else: crash_time=0
	if crash_time>0.35 or (fuel<=0 and absf(velocity.x)<2): lose()
	if pos.x>2350: win(150+int(fuel)+score)

func paint() -> void:
	hud('SCRAP HILL RACER / RIGHT GAS, LEFT BRAKE')
	text_at(Vector2(22,62),'FUEL %d / %dm TO FINISH' % [int(fuel),maxi(0,2350-int(pos.x))],23)
	var shape := PackedVector2Array([Vector2(0,400)])
	for x in range(0,981,20): shape.append(Vector2(x,terrain(x+camera_x)))
	shape.append(Vector2(980,400)); draw_colored_polygon(shape,Color('#b7d5bd'))
	for t in tanks:
		box(Rect2(t-camera_x-12,terrain(t)-40,24,30),RED)
		text_at(Vector2(t-camera_x-8,terrain(t)-15),'F',18)
	var screen := pos-Vector2(camera_x,0)
	draw_set_transform(screen,angle)
	box(Rect2(-38,-24,76,28),RED); box(Rect2(-20,-43,40,20),GOLD)
	disc(Vector2(-28,11),15,INK); disc(Vector2(28,11),15,INK)
	draw_set_transform(Vector2.ZERO)
	buttons(['BRAKE / TILT','GAS / TILT'])
