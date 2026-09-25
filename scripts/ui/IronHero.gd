extends Node2D

const Paint = preload("res://scripts/ui/Paint.gd")
var pose := "idle"
var facing := 1.0
var reactor_color := Color("b7faff")
var age := 0.0
var hero_id := ""
const Catalog = preload("res://scripts/HeroCatalog.gd")

func _ready() -> void:
	if hero_id.is_empty():
		hero_id = Global.hero_id
	if reactor_color == Color("b7faff"):
		reactor_color = Color(Catalog.get_hero(hero_id)["light"])

func set_hero(value: String) -> void:
	hero_id = Catalog.valid_id(value)
	reactor_color = Color(Catalog.get_hero(hero_id)["light"])
	queue_redraw()

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
	if hero_id != "ember" and not hero_id.is_empty():
		_draw_roster()
		return
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

func _draw_roster() -> void:
	var data := Catalog.get_hero(hero_id)
	var body := Color(data["body"])
	var trim := Color(data["trim"])
	if pose == "damaged":
		body = body.darkened(0.25)
		trim = trim.darkened(0.2)
	var skin := Color("d7a27a")
	var bob := sin(age * 3) * 0.6 if pose == "idle" else 0.0
	# Accessories behind the same small collision body; all cast members share physics.
	if hero_id in ["moon", "prism"]:
		_plate([Vector2(-12,-15),Vector2(12,-15),Vector2(20,26),Vector2(0,20),Vector2(-20,28)], body.darkened(0.22))
	if hero_id == "sun":
		_plate([Vector2(-10,-13),Vector2(-30,-7+sin(age*6)*3),Vector2(-20,0),Vector2(2,-10)], trim)
	if hero_id == "comet":
		_plate([Vector2(-17,-9),Vector2(17,-9),Vector2(18,18),Vector2(-18,18)], trim.darkened(0.15))
		if pose == "jump":
			for x in [-14,14]:
				_plate([Vector2(x-3,18),Vector2(x+3,18),Vector2(x,29+sin(age*18)*3)], reactor_color)
	for side in [-1.0,1.0]:
		var foot := Vector2(side*8,30)
		if pose == "jump":
			foot.y -= 5 if side < 0 else 0
		if pose == "damaged":
			foot.x += side*3
		_limb(Vector2(side*6,9),Vector2(side*7,21),8,body)
		_limb(Vector2(side*7,21),foot,8,trim)
		_plate([foot+Vector2(-5,-2),foot+Vector2(4,-2),foot+Vector2(5,3),foot+Vector2(-5,3)], body.darkened(0.2))
		var hand := Vector2(side*20,13)
		var elbow := Vector2(side*19,0)
		if pose == "victory":
			hand = Vector2(side*24,-27)
			elbow = Vector2(side*23,-15)
		elif pose == "jump":
			hand = Vector2(side*24,-6)
		_limb(Vector2(side*13,-10),elbow,8,body)
		_limb(elbow,hand,7,trim)
		Paint.circle(self,hand,3.5,body)
		if hero_id == "prism":
			Paint.circle(self,hand,6,reactor_color,false,1.2)
			Paint.line(self,hand+Vector2(0,-9),hand+Vector2(0,-5),trim,1)
	_plate([Vector2(-12,-13+bob),Vector2(12,-13+bob),Vector2(10,16),Vector2(-10,16)],body)
	Paint.line(self,Vector2(-10,10),Vector2(10,10),trim,3)
	# Each costume has its own emblem and equipment, rather than a colour swap.
	match hero_id:
		"moon":
			Paint.circle(self,Vector2(0,-4),5,trim)
			Paint.circle(self,Vector2(2,-6),4,body)
		"sun":
			Paint.line(self,Vector2(-10,-12),Vector2(9,9),trim,4)
			_plate([Vector2(4,0),Vector2(13,0),Vector2(13,12),Vector2(4,12)],Color("b66539"))
		"tide":
			for y in [-7,-2,3]:
				Paint.polyline(self,PackedVector2Array([Vector2(-7,y),Vector2(-2,y-2),Vector2(3,y+1),Vector2(8,y-1)]),trim,1.8)
			Paint.circle(self,Vector2(-20,7),9,trim)
			Paint.circle(self,Vector2(-20,7),6,body)
			Paint.line(self,Vector2(-24,7),Vector2(-16,7),reactor_color,2)
		"comet":
			_plate([Vector2(0,-10),Vector2(6,-3),Vector2(0,5),Vector2(-6,-3)],trim)
			Paint.line(self,Vector2(-6,3),Vector2(-10,8),reactor_color,2)
		"thread":
			Paint.line(self,Vector2(-11,-11),Vector2(10,10),trim,3)
			Paint.line(self,Vector2(11,-11),Vector2(-10,10),trim,3)
			Paint.circle(self,Vector2(-12,9),5,trim)
		"cipher":
			Paint.line(self,Vector2(0,-12),Vector2(0,15),trim,1.5)
			Paint.rect(self,Rect2(-10,0,6,7),trim)
			Paint.rect(self,Rect2(4,0,6,7),trim)
		"prism":
			_plate([Vector2(0,-12),Vector2(5,-4),Vector2(0,4),Vector2(-5,-4)],reactor_color)
		"copper":
			Paint.rect(self,Rect2(-9,-9,18,13),trim)
			_plate([Vector2(-26,-6),Vector2(-15,-11),Vector2(-7,-4),Vector2(-10,15),Vector2(-21,21),Vector2(-29,12)],body)
			Paint.line(self,Vector2(-22,-3),Vector2(-17,13),reactor_color,2)
	# Head silhouettes: hoods, goggles, a wrapped mask, a braid, or a square helmet.
	_plate([Vector2(-9,-30),Vector2(-5,-34),Vector2(6,-33),Vector2(10,-28),Vector2(8,-15),Vector2(-7,-15)],skin)
	if hero_id in ["moon","prism"]:
		_plate([Vector2(-12,-28),Vector2(0,-38),Vector2(12,-28),Vector2(10,-12),Vector2(6,-16),Vector2(7,-28),Vector2(-6,-28),Vector2(-7,-15),Vector2(-12,-13)],body)
	elif hero_id == "thread":
		_plate([Vector2(-10,-31),Vector2(6,-34),Vector2(11,-25),Vector2(7,-14),Vector2(-8,-15)],body)
		Paint.line(self,Vector2(-9,-20),Vector2(8,-18),trim,3)
	elif hero_id in ["sun","comet"]:
		_plate([Vector2(-11,-27),Vector2(-8,-33),Vector2(6,-35),Vector2(12,-27),Vector2(6,-27),Vector2(-5,-29)],body)
		Paint.rect(self,Rect2(-11,-28,22,9),trim)
	elif hero_id == "copper":
		_plate([Vector2(-12,-32),Vector2(9,-34),Vector2(12,-17),Vector2(-11,-16)],body)
		Paint.rect(self,Rect2(-9,-27,17,7),trim)
	elif hero_id == "tide":
		_plate([Vector2(-12,-28),Vector2(-5,-35),Vector2(7,-33),Vector2(11,-22),Vector2(4,-28),Vector2(-6,-27),Vector2(-10,-14)],Color("384b54"))
		Paint.line(self,Vector2(-10,-29),Vector2(9,-29),trim,3)
	elif hero_id == "cipher":
		_plate([Vector2(-11,-27),Vector2(-6,-35),Vector2(7,-34),Vector2(11,-27),Vector2(2,-29),Vector2(-7,-24)],Color("ad6244"))
		for y in [-23,-16,-9]:
			Paint.circle(self,Vector2(11,y),4,Color("ad6244"))
	for x in [-5,4]:
		Paint.line(self,Vector2(x-2,-24),Vector2(x+1,-24),Paint.INK,2)
		if hero_id in ["moon","comet","thread","copper"]:
			Paint.line(self,Vector2(x-2,-24),Vector2(x+1,-24),reactor_color,1)
	if hero_id not in ["thread","copper"]:
		Paint.line(self,Vector2(-3,-18),Vector2(3,-18),Paint.INK,1)
