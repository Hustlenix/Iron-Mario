extends Node2D

const Paint = preload("res://scripts/ui/Paint.gd")
var pose := "idle"
var facing := 1.0
var reactor_color := Color("b7faff")
var age := 0.0

func _ready() -> void:
	if reactor_color == Color("b7faff"):
		reactor_color = Global.REACTOR_COLORS[Global.reactor_style]

func _process(delta: float) -> void:
	age += delta
	queue_redraw()

func _plate(points: Array, color: Color) -> void:
	var vertices := PackedVector2Array(points)
	Paint.polygon(self, vertices, PackedColorArray([color]))
	vertices.append(vertices[0])
	Paint.polyline(self, vertices, Paint.INK, 1.25)

func _limb(start: Vector2, end: Vector2, width: float, color: Color) -> void:
	var side := (end - start).normalized().orthogonal() * width * 0.5
	_plate([start-side, start+side, end+side*0.8, end-side*0.8], color)

func _draw() -> void:
	var red := Color("bd302c") if pose != "damaged" else Color("784244")
	var bright := Color("eb4f3c") if pose != "damaged" else Color("996057")
	var gold := Color("eebd55") if pose != "damaged" else Color("9b8155")
	var dark := Color("622c35")
	var lift := -2.0 if pose == "jump" else 0.0
	# Art stays centered on the existing 44 x 64 collision body.
	# Separate limbs, faceplate, two eye slits, chest plates and repulsors.
	for direction in [-1.0, 1.0]:
		var hip := Vector2(direction*6, 13)
		var knee := Vector2(direction*7, 22 + (2 if pose == "damaged" else 0))
		var foot := Vector2(direction*9, 30)
		_limb(hip, knee, 9, gold)
		_limb(knee, foot, 9, red)
		_plate([foot+Vector2(-5,-2),foot+Vector2(4,-2),foot+Vector2(6,3),foot+Vector2(-6,3)], bright)
		Paint.line(self, knee+Vector2(-3,0), knee+Vector2(3,0), gold, 2)
		if pose == "jump":
			_plate([foot+Vector2(-3,4),foot+Vector2(3,4),foot+Vector2(1,11+sin(age*20)*2)], Paint.GOLD)
		var shoulder := Vector2(direction*15, -7+lift)
		var elbow := Vector2(direction*19, 3)
		var hand := Vector2(direction*20, 13)
		if pose == "victory":
			elbow = Vector2(direction*23,-16)
			hand = Vector2(direction*24,-26)
		elif pose == "jump":
			elbow = Vector2(direction*19, 5)
			hand = Vector2(direction*22, 14)
		_limb(shoulder, elbow, 8, gold)
		_limb(elbow, hand, 9, red)
		Paint.circle(self, shoulder, 5, bright)
		Paint.circle(self, hand, 4, dark)
		Paint.circle(self, hand, 2, reactor_color)
	_plate([Vector2(-13,-12),Vector2(13,-12),Vector2(15,-3),Vector2(10,11),Vector2(-10,11),Vector2(-15,-3)], red)
	_plate([Vector2(-13,-10),Vector2(-2,-8),Vector2(-3,-1),Vector2(-12,1)], bright)
	_plate([Vector2(2,-8),Vector2(13,-10),Vector2(12,1),Vector2(3,-1)], bright)
	_plate([Vector2(-9,8),Vector2(9,8),Vector2(8,17),Vector2(-8,17)], dark)
	for y in [8,12,16]:
		Paint.line(self, Vector2(-7,y),Vector2(7,y),gold,1.6)
	Paint.circle(self, Vector2(0,-3), 5.5, Paint.INK)
	Paint.circle(self, Vector2(0,-3), 4, reactor_color)
	Paint.circle(self, Vector2(0,-3), 2, Color.WHITE)
	# Red helmet shell and the full gold faceplate, rather than a visor stripe.
	_plate([Vector2(-10,-30),Vector2(-5,-33),Vector2(6,-33),Vector2(11,-28),Vector2(10,-16),Vector2(6,-11),Vector2(-6,-11),Vector2(-10,-17)], red)
	_plate([Vector2(-7,-29),Vector2(-2,-28),Vector2(2,-28),Vector2(7,-30),Vector2(8,-21),Vector2(5,-14),Vector2(-5,-14),Vector2(-8,-21)], gold)
	Paint.line(self, Vector2(-7,-24),Vector2(-2,-23),Paint.INK,3)
	Paint.line(self, Vector2(2,-23),Vector2(7,-24),Paint.INK,3)
	Paint.line(self, Vector2(-6,-24),Vector2(-2,-23),reactor_color,1.4)
	Paint.line(self, Vector2(2,-23),Vector2(6,-24),reactor_color,1.4)
	Paint.line(self, Vector2(-4,-17),Vector2(4,-17),dark,1.2)
	Paint.line(self, Vector2(-3,-15),Vector2(3,-15),Color("fff0ad"),1)
	if pose == "damaged":
		Paint.polyline(self,PackedVector2Array([Vector2(6,-9),Vector2(3,-5),Vector2(7,0),Vector2(4,4)]),Paint.INK,1.3)
