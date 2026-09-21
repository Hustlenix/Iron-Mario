extends "res://scripts/MiniGameBase.gd"

var chips: Array[Dictionary] = []
var sockets: Array[Dictionary] = []
var dragging := -1
var placed_count := 0
var pieces_canvas: Node2D

func _init() -> void:
	game_title = "ARMOR REPAIR"
	instruction = "DRAG EACH CHIP ONTO ITS MATCHING SOCKET!"
	duration = 11.0

func setup_game() -> void:
	var colors := [Color("ff5058"), Color("63e7ff"), Color("ffd75e")]
	var chip_positions := [Vector2(185, 275), Vector2(185, 420), Vector2(185, 565)]
	var socket_positions := [Vector2(935, 395), Vector2(1030, 485), Vector2(900, 570)]
	for index in range(3):
		chips.append({
			"position": chip_positions[index],
			"home": chip_positions[index],
			"color": colors[index],
			"shape": index,
			"placed": false
		})
		sockets.append({"position": socket_positions[index], "color": colors[index], "shape": index})

	var suit := preload("res://scripts/ui/IronHero.gd").new()
	suit.position = Vector2(935,423)
	suit.scale = Vector2(4.4,6.2)
	add_child(suit)
	pieces_canvas = Node2D.new()
	pieces_canvas.name = "RepairParts"
	add_child(pieces_canvas)
	pieces_canvas.draw.connect(_draw_parts)

func update_game(_delta: float) -> void:
	queue_redraw()
	pieces_canvas.queue_redraw()

func handle_game_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_action("click"):
		if event.pressed:
			for index in range(chips.size() - 1, -1, -1):
				if not bool(chips[index]["placed"]) and event.position.distance_to(chips[index]["position"]) <= 42.0:
					dragging = index
					SoundFX.play_click()
					get_viewport().set_input_as_handled()
					break
		elif dragging >= 0:
			chips[dragging]["position"] = event.position
			_drop_chip()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and dragging >= 0:
		chips[dragging]["position"] = event.position
		get_viewport().set_input_as_handled()

func _drop_chip() -> void:
	var socket_position: Vector2 = sockets[dragging]["position"]
	var chip_position: Vector2 = chips[dragging]["position"]
	var snap_distance := maxf(48.0, 72.0 / Global.difficulty)
	if chip_position.distance_to(socket_position) <= snap_distance:
		chips[dragging]["position"] = socket_position
		chips[dragging]["placed"] = true
		placed_count += 1
		SoundFX.play_collect()
		if placed_count >= 3:
			finish(true)
	else:
		chips[dragging]["position"] = chips[dragging]["home"]
		penalize_time(0.3)
	dragging = -1
	pieces_canvas.queue_redraw()

func _draw() -> void:
	Paint.background(self, "workshop")
	draw_pixel_panel(Rect2(80, 190, 230, 455), Color("e6bf86"))
	pixel_text("REPAIR CHIPS", Vector2(92, 235), 21, Color("ffffff"), 205, HORIZONTAL_ALIGNMENT_CENTER)
	draw_pixel_panel(Rect2(690, 175, 490, 485), Color("eee5c4"))
	pixel_text("REPAIRS  %d / 3" % placed_count, Vector2(385, 178), 28, Color("7bd9df"), 300, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_parts() -> void:
	for index in range(sockets.size()):
		_draw_piece(sockets[index]["position"], int(sockets[index]["shape"]), Color(sockets[index]["color"], 0.3), true)
	for chip in chips:
		_draw_piece(chip["position"], int(chip["shape"]), chip["color"], false)

func _draw_piece(pos: Vector2, shape: int, color: Color, socket: bool) -> void:
	var outline := Color("202022")
	if shape == 0:
		Paint.rect(pieces_canvas, Rect2(pos - Vector2(31, 31), Vector2(62, 62)), color)
		Paint.rect(pieces_canvas, Rect2(pos - Vector2(31, 31), Vector2(62, 62)), outline, false, 5.0)
	elif shape == 1:
		Paint.circle(pieces_canvas, pos, 33, color)
		Paint.circle(pieces_canvas, pos, 33, outline, false, 5.0)
	else:
		var points := PackedVector2Array([pos + Vector2(0, -39), pos + Vector2(39, 0), pos + Vector2(0, 39), pos + Vector2(-39, 0)])
		Paint.polygon(pieces_canvas, points, PackedColorArray([color]))
		Paint.polyline(pieces_canvas, PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), outline, 5.0)
	if not socket:
		Paint.line(pieces_canvas, pos + Vector2(-12, 0), pos + Vector2(12, 0), Color("ffffff"), 4.0)
		Paint.line(pieces_canvas, pos + Vector2(0, -12), pos + Vector2(0, 12), Color("ffffff"), 4.0)

