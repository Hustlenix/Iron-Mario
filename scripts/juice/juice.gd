class_name Juice
extends Object

static func shake(root: Node, amount: float) -> void:
	var cam := root.get_tree().get_first_node_in_group("shake_cam")
	if cam is ScreenShake:
		cam.add_trauma(amount)

static func burst(parent: Node, pos: Vector2, color: Color, count := 14, speed := 260.0, lifetime := 0.7) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.z_index = 50
	p.one_shot = true
	p.emitting = true
	p.amount = count
	p.lifetime = lifetime
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.3
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 520.0)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.6
	p.self_modulate = color
	parent.add_child(p)
	p.finished.connect(p.queue_free)

static func text(parent: Node, text: String, pos: Vector2, color := Color.WHITE, font_size := 30) -> void:
	var ft := FloatingText.new()
	ft.position = pos
	parent.add_child(ft)
	ft.setup(text, color, font_size)

static func hit_stop(root: Node, seconds := 0.08) -> void:
	Engine.time_scale = 0.05
	root.get_tree().create_timer(seconds, true, false, true).timeout.connect(
		func() -> void: Engine.time_scale = 1.0
	)
