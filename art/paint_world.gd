class_name PaintWorld
extends Control
var clock: float = 0.0
var hero_id: String = 'dart'
var pose: String = 'idle'
var celebration: bool = false
var ink := Color('#242333')
var palettes := [Color('#ef6351'),Color('#4a8de0'),Color('#9180c7'),Color('#8bd3db'),Color('#f49e4c'),Color('#60b990'),Color('#ffc857'),Color('#ec85b3'),Color('#67acbe')]
const HEROES := ['dart','bolt','echo','frost','tether','snap','aegis','pulse','lance','flappy']
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
	clock += delta
	queue_redraw()
func polygon(points: Array, color: Color, width: float = 4) -> void:
	var pts := PackedVector2Array(points)
	draw_colored_polygon(pts,color)
	pts.append(pts[0])
	draw_polyline(pts,ink,width)
func _draw() -> void:
	var sx: float = size.x / 560.0
	var sy: float = size.y / 390.0
	var amount: float = minf(sx,sy)
	draw_set_transform(Vector2((size.x-560*amount)/2,(size.y-390*amount)/2),0,Vector2.ONE*amount)
	# Crooked rooftops and pencil clouds, composed from bucket-filled shapes.
	for i in 7:
		var x: float = 15+i*83
		var y: float = 235+sin(i*12.8)*46
		polygon([Vector2(x,367),Vector2(x+3,y),Vector2(x+64,y-4),Vector2(x+70,370)],Color('#bfd8d0'),3)
		for j in 3:
			draw_rect(Rect2(x+15,y+20+j*30,13,13),Color('#fff4d7'))
	draw_line(Vector2(12,373),Vector2(548,371),ink,4)
	for i in 5:
		var p := Vector2(40+i*111,40+sin(i*5.0)*27)
		draw_line(p-Vector2(8,0),p+Vector2(8,0),ink,3)
		draw_line(p-Vector2(0,8),p+Vector2(0,8),ink,3)
	var idx: int = maxi(0,HEROES.find(hero_id))
	var color: Color = palettes[idx%palettes.size()]
	if idx == 9:
		polygon([Vector2(75,200),Vector2(180,164),Vector2(230,230),Vector2(320,232),Vector2(382,163),Vector2(492,200),Vector2(381,270),Vector2(163,274)],Color('#ffc857'),5)
	var bob: float = sin(clock*3)*4
	if pose == 'victory': bob = absf(sin(clock*7))*-24
	draw_set_transform(Vector2(size.x/2,size.y*0.48+bob*amount),sin(clock*2)*0.02,Vector2.ONE*amount)
	match idx:
		2:
			draw_arc(Vector2(0,-38),66,PI,TAU,12,ink,14)
			draw_rect(Rect2(-69,-40,18,36),color)
			draw_rect(Rect2(51,-40,18,36),color)
		4:
			draw_polyline(PackedVector2Array([Vector2(35,30),Vector2(96,4),Vector2(110,55),Vector2(72,83)]),ink,8)
		5:
			polygon([Vector2(-47,-19),Vector2(-65,34),Vector2(-45,81),Vector2(54,79),Vector2(70,29),Vector2(46,-19)],color)
		6:
			polygon([Vector2(-68,-10),Vector2(-30,-1),Vector2(-23,58),Vector2(-48,85),Vector2(-80,50)],Color('#ffc857'))
		7:
			draw_arc(Vector2(0,-50),83,0,TAU,16,Color('#ec85b3'),7)
		8:
			draw_line(Vector2(73,-117),Vector2(77,120),ink,10)
			polygon([Vector2(63,-103),Vector2(73,-138),Vector2(88,-103)],Color('#67acbe'))
	# Broad silhouette changes: cape, antennae, wing, visor, ears and body shapes.
	polygon([Vector2(-33,-13),Vector2(-109,94),Vector2(-21,80),Vector2(20,13)],Color('#ef6351'))
	if idx in [1,4,6]:
		polygon([Vector2(-45,-58),Vector2(-12,-116),Vector2(7,-69),Vector2(47,-85),Vector2(27,-28)],Color('#ffc857'))
	if idx in [2,3,5]:
		polygon([Vector2(-40,-49),Vector2(-52,-108),Vector2(-16,-67)],color)
		polygon([Vector2(19,-59),Vector2(52,-106),Vector2(44,-36)],color)
	polygon([Vector2(-36,-1),Vector2(33,-4),Vector2(49,67),Vector2(-36,71)],color)
	polygon([Vector2(-38,-63),Vector2(29,-71),Vector2(53,-43),Vector2(45,-10),Vector2(-30,0),Vector2(-49,-31)],Color('#ffc857') if idx==0 else color)
	polygon([Vector2(-39,-47),Vector2(43,-49),Vector2(38,-26),Vector2(-34,-24)],ink,2)
	draw_rect(Rect2(-27,-42,17,10),Color('#fff4d7'))
	draw_rect(Rect2(10,-42,17,10),Color('#fff4d7'))
	draw_line(Vector2(-4,-9),Vector2(13,-12),ink,4)
	polygon([Vector2(-10,12),Vector2(17,9),Vector2(8,29),Vector2(19,31),Vector2(-8,51),Vector2(-2,31),Vector2(-18,32)],Color('#fff4d7'),2)
	var hands: float = -45 if pose == 'victory' else 35
	draw_line(Vector2(-34,14),Vector2(-67,hands),ink,18)
	draw_line(Vector2(33,13),Vector2(70,hands-7),ink,18)
	draw_circle(Vector2(-67,hands),13,color)
	draw_circle(Vector2(70,hands-7),13,color)
	var leg: float = sin(clock*9)*14 if pose == 'run' else 0
	draw_line(Vector2(-16,67),Vector2(-24-leg,111),ink,19)
	draw_line(Vector2(26,67),Vector2(37+leg,108),ink,19)
	polygon([Vector2(-40-leg,105),Vector2(-11-leg,104),Vector2(-9-leg,121),Vector2(-47-leg,121)],color)
	polygon([Vector2(24+leg,103),Vector2(48+leg,103),Vector2(60+leg,119),Vector2(22+leg,122)],color)
	if pose == 'defeat':
		draw_line(Vector2(-28,-44),Vector2(-10,-32),Color('#fff4d7'),4)
		draw_line(Vector2(-28,-32),Vector2(-10,-44),Color('#fff4d7'),4)
	draw_set_transform(Vector2.ZERO)
