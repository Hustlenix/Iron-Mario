extends SceneTree
var canvas: Image
func poly(points: Array, color: Color) -> void:
	var polygon := PackedVector2Array(points)
	for y in 128:
		for x in 128:
			if Geometry2D.is_point_in_polygon(Vector2(x,y),polygon): canvas.set_pixel(x,y,color)
func _initialize() -> void:
	canvas = Image.create(128,128,false,Image.FORMAT_RGBA8)
	canvas.fill(Color('#fff4d7'))
	var ink := Color('#242333')
	poly([Vector2(22,109),Vector2(33,78),Vector2(57,71),Vector2(86,75),Vector2(105,112)],ink)
	poly([Vector2(29,105),Vector2(38,84),Vector2(59,77),Vector2(84,81),Vector2(97,106)],Color('#ef6351'))
	poly([Vector2(31,35),Vector2(79,25),Vector2(96,45),Vector2(88,77),Vector2(47,82),Vector2(28,64)],ink)
	poly([Vector2(35,39),Vector2(77,31),Vector2(90,47),Vector2(83,71),Vector2(49,77),Vector2(34,61)],Color('#ffc857'))
	poly([Vector2(34,47),Vector2(91,43),Vector2(85,63),Vector2(38,66)],ink)
	poly([Vector2(45,51),Vector2(56,50),Vector2(56,58),Vector2(45,58)],Color('#fff4d7'))
	poly([Vector2(69,50),Vector2(79,49),Vector2(78,57),Vector2(68,57)],Color('#fff4d7'))
	poly([Vector2(58,86),Vector2(73,84),Vector2(68,94),Vector2(74,95),Vector2(59,106),Vector2(63,96),Vector2(55,96)],Color('#fff4d7'))
	for amount in [144,180,512]:
		var icon: Image = canvas.duplicate()
		icon.resize(amount,amount,Image.INTERPOLATE_NEAREST)
		icon.save_png('res://assets/icons/icon_%dx%d.png' % [amount,amount])
	quit()
