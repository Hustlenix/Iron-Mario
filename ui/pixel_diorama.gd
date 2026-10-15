extends Node2D
## A native-resolution, original platform-world presentation for the shared roster.
var host: Control
var npc: Texture2D = preload('res://assets/shared_foundation/town_cast/pip.png')
var workshop: Texture2D = preload('res://assets/rooms/reactor_workshop.png')
var town_room: Texture2D = preload('res://assets/shared_foundation/workshop/room.png')
var burst: Texture2D = preload('res://assets/shared_foundation/town_fx_ui/effects/success_burst.png')
var room_animation := [
	[preload('res://assets/shared_foundation/workshop/control_room_screens.png'),Vector2(64,48),11,5,Vector2(172,10)],
	[preload('res://assets/shared_foundation/workshop/control_room_server.png'),Vector2(16,48),3,4,Vector2(283,20)],
	[preload('res://assets/shared_foundation/workshop/amplifier.png'),Vector2(16,32),3,4,Vector2(20,53)],
	[preload('res://assets/shared_foundation/workshop/cat.png'),Vector2(48,16),12,6,Vector2(30,150)]
]
const INK := Color('#252844')
func box(x: float, y: float, w: float, h: float, c: String) -> void:
	draw_rect(Rect2(roundf(x),roundf(y),w,h),Color(c))
func _process(_delta: float) -> void:
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(host): return
	var t: float = 0.0 if host.reduced_motion else host.clock
	if host.entry.power=='town':
		draw_texture(town_room,Vector2.ZERO)
		for item: Array in room_animation:
			var frame: int=0 if host.reduced_motion else int(t*item[3])%int(item[2])
			draw_texture_rect_region(item[0],Rect2(item[4],item[1]),Rect2(Vector2(frame*item[1].x,0),item[1]))
		for i in HeroRoster.HEROES.size():
			var person: Dictionary=HeroRoster.hero(i)
			var feet := Vector2(102+(i%3)*56,126+(i/3)*35)
			var selected: bool=person.id==host.entry.id
			if selected:
				box(feet.x-9,feet.y,18,2,'#ffdb85')
				if host.demo_time>=0 and not host.reduced_motion: feet.y-=roundf(sin(host.demo_time/2.2*PI)*14)
			CharacterVisual.draw(self,String(person.id),feet,1.0,t,selected and host.demo_time>=0,3,host.reduced_motion)
			if selected and host.demo_time>=0:
				var frame: int=3 if host.reduced_motion else mini(7,int(host.demo_time*8))
				draw_texture_rect_region(burst,Rect2(feet-Vector2(16,30),Vector2(32,32)),Rect2(frame*32,0,32,32))
		return
	var night: bool = host.entry.power in ['stealth','rift']
	box(0,0,320,180,'#34395d' if night else '#8bcbd4')
	box(0,86,320,70,'#555a79' if night else '#b3dcd3')
	# Stepped cloud silhouettes: every edge lands on the native pixel grid.
	for i in 4:
		var x: int = int(fposmod(i*94-t*2,380))-30
		var y: int = 20+(i%3)*12
		box(x+8,y,24,5,'#fff0ce'); box(x,y+5,44,7,'#fff0ce')
		box(x+4,y+12,36,3,'#d5e9dc')
	for i in 7:
		var x: int = i*56-12
		box(x,108-(i%3)*10,52,52,'#608e99')
		box(x+8,96-(i%3)*10,36,20,'#608e99')
		box(x+16,89-(i%3)*10,20,12,'#608e99')
		box(x+17,100-(i%3)*10,3,20,'#87b8ad')
	# Tiny foundry workshop with tiled roof, windows, and licensed interior prop.
	box(16,89,78,63,'#353750'); box(20,91,70,61,'#bc795d')
	for row in 6:
		for col in 5:
			box(20+col*14+(row%2)*3,94+row*9,11,1,'#d99a71')
	box(12,85,86,7,'#354054'); box(18,78,74,7,'#487d83')
	for x in range(18,92,8): box(x,79,5,2,'#80b7ad')
	box(30,100,22,22,'#34354a'); box(32,102,18,18,'#ffcf75')
	box(40,102,2,18,'#82524f'); box(32,110,18,2,'#82524f')
	draw_texture_rect_region(workshop,Rect2(65,112,16,36),Rect2(26,140,78,160))
	box(28,62,9,17,'#51516b'); box(26,61,13,3,'#e6b786')
	for i in 3:
		var rise: int = int(fposmod(t*8+i*9,28))
		box(29+int(sin(t+i)*3),56-rise,5+i*2,4,'#d9e4d4')
	# Original brass platforms and collectibles, composed on a 16px tile grid.
	for platform in [Vector2(112,112),Vector2(208,96),Vector2(256,120)]:
		for j in 3:
			var x: float = platform.x+j*16
			box(x,platform.y,16,12,'#34354b'); box(x+1,platform.y+1,14,3,'#ffe3a0')
			box(x+1,platform.y+4,14,6,'#c78653'); box(x+3,platform.y+6,2,2,'#805449')
		var cy: float = platform.y-14+(0 if host.reduced_motion else int(sin(t*3+platform.x)*2))
		box(platform.x+22,cy,5,8,'#a5613c'); box(platform.x+23,cy,3,7,'#ffd66f'); box(platform.x+24,cy+1,1,4,'#fff0ce')
	# Ground tiles: lit grassy lip, dark underside and offset masonry joints.
	box(0,152,320,28,'#79514e'); box(0,150,320,3,'#cfe89b'); box(0,153,320,4,'#5d986a')
	for row in 2:
		for col in 21:
			var x: int = col*16-(row%2)*8
			box(x,159+row*12,15,10,'#aa7256'); box(x+1,160+row*12,13,1,'#cb986b')
	# Character Generator export: 16x32 cells, first walk strip at y=32.
	var frame: int = 0 if host.reduced_motion else int(t*7)%6
	var nx: float = 42 if host.reduced_motion else 38+int(sin(t*0.5)*14)
	draw_texture_rect_region(npc,Rect2(nx,120,16,32),Rect2(frame*16,32,16,32))
	# Keep the original hero identity at a character-sized scale in the world.
	if is_instance_valid(host.art) and host.art.texture:
		var jump: float = 0
		if host.demo_time>=0 and not host.reduced_motion: jump=sin(host.demo_time/2.2*PI)*44
		var pos := Vector2(166,120-roundf(jump))
		CharacterVisual.draw(self,String(host.entry.id),pos+Vector2(16,32),1.0,t,false,3,host.reduced_motion)
		if host.demo_time>=0:
			for i in 10:
				var a: float = i*TAU/10+t*2
				var p: Vector2 = pos+Vector2(16,16)+Vector2(cos(a),sin(a))*23
				box(p.x,p.y,2,2,'#ffe5a1')
