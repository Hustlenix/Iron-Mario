extends Node2D

## Arc Break is the first authored world slice: repulsor energy charges the
## Modern Interiors resonance rig, follows original bioluminescent fungus
## filaments into a cave, then exposes the creature feeding on the breach.

enum Stage { LAB, CAVE, BOSS, WON, LOST }

const PLAYER_SPEED := 260.0
const PLAYER_RADIUS := 18.0
const WORLD_BOUNDS := Rect2(66, 112, 1148, 552)
const REPULSOR_SPEED := 760.0
const REPULSOR_COST := 16.0
const REPULSOR_COOLDOWN := 0.28
const ENERGY_REGEN := 18.0
const RELAY_RADIUS := 26.0
const HIT_INVULNERABLE := 0.85

const LAB_RELAYS := [Vector2(442, 238), Vector2(836, 234), Vector2(850, 512)]
const CAVE_RELAYS := [Vector2(340, 244), Vector2(920, 256), Vector2(650, 534)]

const NAVY := Color(0.035, 0.055, 0.105)
const LAB_TILE_A := Color(0.11, 0.16, 0.22)
const LAB_TILE_B := Color(0.13, 0.19, 0.25)
const INK := Color(0.025, 0.035, 0.07)
const GOLD := Color(1.0, 0.79, 0.27)
const CYAN := Color(0.4, 0.9, 1.0)
const FUNGUS := Color(0.66, 1.0, 0.47)
const CAVE := Color(0.075, 0.07, 0.13)
const CAVE_TILE := Color(0.12, 0.1, 0.18)

var stage: Stage = Stage.LAB
var player_facing := Vector2.RIGHT
var energy := 84.0
var health := 3
var score := 0
var relay_nodes: Array[Dictionary] = []
var bolts: Array[Dictionary] = []
var world_obstacles: Array[Rect2] = []
var boss_position := Vector2(640, 370)
var boss_health := 3
var boss_clock := 0.0
var elapsed := 0.0
var fire_cooldown := 0.0
var invulnerable := 0.0
var _lab_machine: Texture2D
var _lab_screen: Texture2D
var _scientist: Texture2D
var _status_flash := 0.0

@onready var player: CharacterBody2D = $Player
@onready var hero_sprite: Sprite2D = $Player/Sprite
@onready var stage_label: Label = $HUD/StageLabel
@onready var objective_label: Label = $HUD/ObjectiveLabel
@onready var energy_label: Label = $HUD/EnergyLabel
@onready var health_label: Label = $HUD/HealthLabel
@onready var message_label: Label = $HUD/MessageLabel
@onready var controls_hint: Label = $HUD/ControlsHint

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_lab_machine = load("res://assets/arc_break/modern_interiors/resonance_machine.png") as Texture2D
	_lab_screen = load("res://assets/arc_break/modern_interiors/lab_screen.png") as Texture2D
	_scientist = load("res://assets/arc_break/character_generator/scientist_premade_20.png") as Texture2D
	_begin_lab()
	SceneFade.fade_in(self)
	Music.play("gauntlet", 1.0, -9.0)
	_update_hud()

func _process(delta: float) -> void:
	elapsed += delta
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	invulnerable = maxf(0.0, invulnerable - delta)
	_status_flash = maxf(0.0, _status_flash - delta)
	energy = minf(100.0, energy + ENERGY_REGEN * delta)
	if stage == Stage.BOSS:
		boss_clock += delta
		boss_position.x = 640.0 + sin(boss_clock * 1.4) * 270.0
		boss_position.y = 335.0 + sin(boss_clock * 2.1) * 95.0
		if int(boss_clock * 2.0) % 5 == 0:
			controls_hint.text = "THE CORE IS OPEN — HIT IT WITH REPULSOR"
	elif stage == Stage.LAB and player.global_position.distance_to(Vector2(164, 250)) < 78.0:
		controls_hint.text = "TECH: CHARGE ALL THREE RELAYS. THE CAVE IS UNDER US."
	else:
		controls_hint.text = _controls_text()

func _physics_process(delta: float) -> void:
	if stage == Stage.WON or stage == Stage.LOST:
		if Input.is_action_just_pressed("power"):
			_restart()
		elif Input.is_action_just_pressed("ui_cancel"):
			_return_to_library()
		return

	var movement := _movement_input()
	if movement.length_squared() > 0.01:
		player_facing = movement.normalized()
	player.velocity = movement.normalized() * PLAYER_SPEED
	player.move_and_slide()
	player.global_position.x = clampf(player.global_position.x, WORLD_BOUNDS.position.x + PLAYER_RADIUS, WORLD_BOUNDS.end.x - PLAYER_RADIUS)
	player.global_position.y = clampf(player.global_position.y, WORLD_BOUNDS.position.y + PLAYER_RADIUS, WORLD_BOUNDS.end.y - PLAYER_RADIUS)
	if Input.is_action_just_pressed("power"):
		_fire_repulsor()
	if Input.is_action_just_pressed("jump") and stage == Stage.LAB and player.global_position.distance_to(Vector2(164, 250)) < 78.0:
		message_label.text = "THE TECH: THE MYCELIUM CARRIES REACTOR CURRENT. WAKE IT UP."
		_status_flash = 2.5

	_update_bolts(delta)
	_update_contacts()
	_check_stage_transitions()
	_update_hud()
	queue_redraw()

func _movement_input() -> Vector2:
	return Input.get_vector("left", "right", "arc_up", "arc_down")

func _begin_lab() -> void:
	stage = Stage.LAB
	player.global_position = Vector2(144, 374)
	player_facing = Vector2.RIGHT
	health = 3
	energy = 84.0
	score = 0
	bonus_stage_reset()
	relay_nodes = _make_nodes(LAB_RELAYS)
	world_obstacles = [
		Rect2(300, 170, 110, 90),
		Rect2(560, 170, 150, 74),
		Rect2(1020, 165, 90, 140),
		Rect2(1030, 460, 80, 130),
	]
	_rebuild_walls(true)
	message_label.text = "THE REACTOR IS LEAKING. CHARGE THE LINKED RELAYS."
	controls_hint.text = _controls_text()

func _make_nodes(points: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for point in points:
		result.append({"position": point, "charged": false, "pulse": 0.0})
	return result

func bonus_stage_reset() -> void:
	bolts.clear()
	boss_health = 3
	boss_clock = 0.0
	invulnerable = 0.0

func _rebuild_walls(allow_exit: bool) -> void:
	for child in $WorldColliders.get_children():
		child.queue_free()
	var walls: Array[Rect2] = [
		Rect2(40, 94, 1200, 20), Rect2(40, 94, 20, 590), Rect2(40, 664, 1200, 20),
	]
	if allow_exit:
		walls.append(Rect2(1220, 94, 20, 205))
		walls.append(Rect2(1220, 440, 20, 244))
	else:
		walls.append(Rect2(1220, 94, 20, 590))
	for obstacle in world_obstacles:
		walls.append(obstacle)
	for rect in walls:
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = rect.size
		shape.shape = rectangle
		body.position = rect.get_center()
		body.add_child(shape)
		$WorldColliders.add_child(body)

func _fire_repulsor() -> void:
	if fire_cooldown > 0.0 or energy < REPULSOR_COST:
		if energy < REPULSOR_COST:
			message_label.text = "ARC CORE LOW — WAIT FOR RECHARGE"
			_status_flash = 0.45
		return
	energy -= REPULSOR_COST
	fire_cooldown = REPULSOR_COOLDOWN
	var origin := player.global_position + player_facing * 25.0
	bolts.append({"position": origin, "velocity": player_facing * REPULSOR_SPEED, "life": 1.25})
	Juice.burst(self, origin, CYAN, 5, 140.0)

func _update_bolts(delta: float) -> void:
	for i in range(bolts.size() - 1, -1, -1):
		var bolt: Dictionary = bolts[i]
		bolt.position += bolt.velocity * delta
		bolt.life -= delta
		var remove: bool = bolt.life <= 0.0 or not WORLD_BOUNDS.has_point(bolt.position)
		if not remove and stage in [Stage.LAB, Stage.CAVE]:
			for relay_index in relay_nodes.size():
				var relay: Dictionary = relay_nodes[relay_index]
				if not relay.charged and bolt.position.distance_to(relay.position) <= RELAY_RADIUS:
					_charge_relay(relay_index)
					remove = true
					break
		if not remove and stage == Stage.BOSS and bolt.position.distance_to(boss_position) < 36.0:
			_hit_boss()
			remove = true
		if remove:
			bolts.remove_at(i)
		else:
			bolts[i] = bolt

func _charge_relay(index: int) -> void:
	if index < 0 or index >= relay_nodes.size() or relay_nodes[index].charged:
		return
	relay_nodes[index].charged = true
	score += 100
	energy = minf(100.0, energy + 24.0)
	message_label.text = "MYCELIUM LINK %d / 3 — ENERGY IS FLOWING" % _charged_count()
	_status_flash = 1.8
	Juice.shake(self, 0.16)
	Juice.burst(self, relay_nodes[index].position, FUNGUS, 18, 230.0)
	Juice.text(self, "LINKED!", relay_nodes[index].position + Vector2(-46, -30), FUNGUS, 28)
	if _all_relays_charged():
		if stage == Stage.LAB:
			message_label.text = "HATCH OPEN — HEAD RIGHT INTO THE CAVE"
		else:
			stage = Stage.BOSS
			message_label.text = "THE SOURCE OF THE BREACH IS HERE."
			boss_clock = 0.0
	_update_hud()
	queue_redraw()

func _charged_count() -> int:
	var count := 0
	for relay in relay_nodes:
		if relay.charged:
			count += 1
	return count

func _all_relays_charged() -> bool:
	return _charged_count() == relay_nodes.size()

func _check_stage_transitions() -> void:
	if stage == Stage.LAB and _all_relays_charged() and player.global_position.x >= 1184.0 and absf(player.global_position.y - 370.0) < 105.0:
		_enter_cave()

func _enter_cave() -> void:
	stage = Stage.CAVE
	player.global_position = Vector2(112, 370)
	player_facing = Vector2.RIGHT
	world_obstacles = [Rect2(334, 300, 112, 64), Rect2(834, 300, 112, 64)]
	relay_nodes = _make_nodes(CAVE_RELAYS)
	_rebuild_walls(false)
	message_label.text = "THE CAVE IS ALIVE. FOLLOW THE GLOWING ROOTS."
	controls_hint.text = "REPULSOR CHARGES FUNGUS — WATCH FOR THE SPORE STALKER"
	Juice.shake(self, 0.45)
	Juice.burst(self, player.global_position, CYAN, 26, 320.0)

func _update_contacts() -> void:
	if stage == Stage.CAVE:
		var stalker := Vector2(640.0 + sin(elapsed * 1.65) * 240.0, 366.0 + cos(elapsed * 1.1) * 86.0)
		if invulnerable <= 0.0 and player.global_position.distance_to(stalker) < 34.0:
			_damage_player(stalker)
	elif stage == Stage.BOSS:
		if invulnerable <= 0.0 and player.global_position.distance_to(boss_position) < 46.0:
			_damage_player(boss_position)

func _damage_player(source: Vector2) -> void:
	health -= 1
	invulnerable = HIT_INVULNERABLE
	var push := (player.global_position - source).normalized()
	if push == Vector2.ZERO:
		push = Vector2.LEFT
	player.velocity = push * 210.0
	player.move_and_slide()
	message_label.text = "SUIT HIT — %d CORE%s LEFT" % [health, "" if health == 1 else "S"]
	_status_flash = 1.0
	Juice.shake(self, 0.35)
	Juice.burst(self, player.global_position, Color(1.0, 0.34, 0.34), 13, 230.0)
	if health <= 0:
		_finish(false)
	_update_hud()

func _hit_boss() -> void:
	boss_health -= 1
	score += 250
	energy = minf(100.0, energy + 20.0)
	message_label.text = "THE CORE CRACKS — %d STRIKE%s LEFT" % [boss_health, "" if boss_health == 1 else "S"]
	_status_flash = 1.2
	Juice.shake(self, 0.34)
	Juice.burst(self, boss_position, Color(1.0, 0.48, 0.34), 22, 300.0)
	Juice.text(self, "CORE HIT!", boss_position + Vector2(-52, -36), GOLD, 30)
	if boss_health <= 0:
		_finish(true)

func _finish(won: bool) -> void:
	if stage == Stage.WON or stage == Stage.LOST:
		return
	stage = Stage.WON if won else Stage.LOST
	if won:
		message_label.text = "CONTAINMENT RESTORED — YOU BROUGHT THE LIGHT BACK."
		Global.unlock_achievement("arc_break_clear")
	else:
		message_label.text = "SUIT DOWN — PRESS REPULSOR TO RETRY"
	Global.arc_break_best = maxi(Global.arc_break_best, score)
	if GameLauncher.has_return_scene():
		GameLauncher.record_result("arc_break", score, won)
	Global.save()
	Juice.shake(self, 0.65 if won else 0.4)
	Juice.burst(self, player.global_position, FUNGUS if won else Color(1.0, 0.34, 0.34), 28, 350.0)
	_update_hud()
	queue_redraw()

func _restart() -> void:
	_begin_lab()
	_update_hud()
	queue_redraw()

func _update_hud() -> void:
	match stage:
		Stage.LAB:
			stage_label.text = "ARC BREAK   /   01 — CONTAINMENT LAB"
			objective_label.text = "CHARGE RELAYS  %d / 3" % _charged_count()
		Stage.CAVE:
			stage_label.text = "ARC BREAK   /   02 — THE MYCELIUM"
			objective_label.text = "WAKE THE ROOTS  %d / 3" % _charged_count()
		Stage.BOSS:
			stage_label.text = "ARC BREAK   /   03 — BREACH CORE"
			objective_label.text = "CORE INTEGRITY  %d / 3" % boss_health
		Stage.WON:
			stage_label.text = "ARC BREAK   /   CONTAINMENT RESTORED"
			objective_label.text = "SCORE  %04d   /   BEST  %04d" % [score, Global.arc_break_best]
		Stage.LOST:
			stage_label.text = "ARC BREAK   /   SUIT DOWN"
			objective_label.text = "SCORE  %04d   /   BEST  %04d" % [score, Global.arc_break_best]
	energy_label.text = "ARC  %03d%%" % int(energy)
	health_label.text = "CORE  %d / 3" % maxi(0, health)

func _controls_text() -> String:
	return "WASD / ARROWS MOVE   •   E REPULSOR   •   SPACE TALK / RESTART   •   ESC ARCADE"

func _return_to_library() -> void:
	await SceneFade.fade_out(self)
	if GameLauncher.has_return_scene():
		GameLauncher.return_to_library()
	else:
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _draw() -> void:
	_draw_room_floor()
	if stage == Stage.LAB:
		_draw_lab()
	else:
		_draw_cave()
	_draw_relays()
	_draw_bolts()
	if stage == Stage.CAVE:
		_draw_spore_stalker()
	if stage == Stage.BOSS:
		_draw_breach_core()
	_draw_exit()
	if invulnerable > 0.0 and int(invulnerable * 18.0) % 2 == 0:
		draw_arc(player.global_position, 27.0, 0.0, TAU, 64, Color(1.0, 0.35, 0.3, 0.8), 3.0)

func _draw_room_floor() -> void:
	var cave := stage != Stage.LAB
	draw_rect(Rect2(0, 0, 1280, 720), CAVE if cave else NAVY)
	var base := CAVE_TILE if cave else LAB_TILE_A
	for y in range(110, 664, 32):
		for x in range(66, 1214, 32):
			var alt := int(x / 32 + y / 32) % 2 == 0
			var color := base.lightened(0.06) if alt else base
			draw_rect(Rect2(x, y, 32, 32), color)
			draw_rect(Rect2(x + 1, y + 1, 30, 30), color.darkened(0.08))
			if alt and int(x + y) % 7 == 0:
				draw_rect(Rect2(x + 8, y + 8, 2, 2), Color(0.42, 0.53, 0.64, 0.24))
	draw_rect(Rect2(46, 94, 1188, 18), INK)
	draw_rect(Rect2(46, 94, 1188, 7), Color(0.32, 0.42, 0.56))
	draw_rect(Rect2(46, 664, 1188, 20), INK)
	draw_rect(Rect2(46, 657, 1188, 7), Color(0.32, 0.42, 0.56))
	draw_rect(Rect2(46, 94, 20, 590), INK)
	draw_rect(Rect2(66, 94, 7, 590), Color(0.32, 0.42, 0.56))
	if stage != Stage.LAB or not _all_relays_charged():
		draw_rect(Rect2(1214, 94, 20, 590), INK)
		draw_rect(Rect2(1207, 94, 7, 590), Color(0.32, 0.42, 0.56))
	else:
		draw_rect(Rect2(1214, 94, 20, 170), INK)
		draw_rect(Rect2(1214, 464, 20, 220), INK)

func _draw_lab() -> void:
	# Modern Interiors resonance equipment, licensed with the owner's Full pack.
	if _lab_machine:
		var frame := int(elapsed * 4.0) % 14
		draw_texture_rect_region(_lab_machine, Rect2(590, 171, 64, 128), Rect2(frame * 32, 0, 32, 64))
	if _lab_screen:
		var frame := int(elapsed * 2.0) % 5
		draw_texture_rect_region(_lab_screen, Rect2(930, 182, 64, 64), Rect2(frame * 32, 0, 32, 32))
	# Lab work benches and danger-strip panels are original in-engine art.
	_draw_console(Rect2(276, 405, 116, 56), Color(0.18, 0.27, 0.37), Color(0.46, 0.88, 1.0))
	_draw_console(Rect2(1035, 354, 70, 76), Color(0.16, 0.23, 0.31), GOLD)
	for x in range(92, 1190, 24):
		draw_rect(Rect2(x, 117, 14, 3), Color(0.47, 0.62, 0.74, 0.65))
	# Character Generator premade sprite sheet: first 16px frame is a lab tech.
	if _scientist:
		var npc_frame := 0
		if player.global_position.x > 164.0:
			npc_frame = 3
		draw_texture_rect_region(_scientist, Rect2(112, 206, 48, 96), Rect2(npc_frame * 16, 0, 16, 32))
	draw_string(ThemeDB.fallback_font, Vector2(114, 201), "TECH", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.9, 0.91, 0.92))
	# Reactor ring and radiating floor markings make the energy source the visual anchor.
	draw_arc(Vector2(640, 360), 58.0, 0.0, TAU, 48, Color(0.4, 0.88, 1.0, 0.44), 3.0)
	draw_arc(Vector2(640, 360), 72.0, 0.0, TAU, 48, Color(1.0, 0.79, 0.27, 0.22), 2.0)
	draw_line(Vector2(480, 360), Vector2(800, 360), Color(0.3, 0.62, 0.81, 0.18), 1.0)

func _draw_console(rect: Rect2, trim: Color, screen: Color) -> void:
	draw_rect(rect, INK)
	draw_rect(Rect2(rect.position + Vector2(4, 4), rect.size - Vector2(8, 8)), trim)
	draw_rect(Rect2(rect.position + Vector2(12, 10), Vector2(rect.size.x - 24, 12)), screen)
	for i in 4:
		draw_rect(Rect2(rect.position + Vector2(12 + i * 20, rect.size.y - 15), Vector2(10, 4)), GOLD.darkened(0.1))

func _draw_cave() -> void:
	# All cave growth is original; the unlicensed Fungus Cave pack is not shipped.
	for i in 8:
		var x := float(92 + i * 154)
		var y := 148.0 + float((i * 53) % 420)
		_draw_mushroom(Vector2(x, y), 0.7 + float(i % 3) * 0.16, FUNGUS if i % 2 == 0 else Color(0.47, 0.79, 1.0))
	for i in 18:
		var x := float(110 + (i * 131) % 1040)
		var y := float(156 + (i * 71) % 444)
		var flicker := 0.35 + 0.18 * sin(elapsed * 2.2 + i)
		draw_circle(Vector2(x, y), 2.2, Color(0.68, 1.0, 0.58, flicker))
	# Jagged cave shelves frame the traversal space without obscuring collisions.
	for i in 10:
		var x := float(95 + i * 112)
		var wobble := float((i * 37) % 24)
		draw_colored_polygon(PackedVector2Array([Vector2(x, 113), Vector2(x + 56, 113), Vector2(x + 42, 139 + wobble), Vector2(x + 18, 132 + wobble)]), Color(0.14, 0.11, 0.21))

func _draw_mushroom(center: Vector2, scale: float, cap: Color) -> void:
	var stem_h := 20.0 * scale
	draw_rect(Rect2(center.x - 5.0 * scale, center.y, 10.0 * scale, stem_h), Color(0.6, 0.72, 0.57))
	draw_rect(Rect2(center.x - 12.0 * scale, center.y - 8.0 * scale, 24.0 * scale, 12.0 * scale), INK)
	draw_rect(Rect2(center.x - 10.0 * scale, center.y - 7.0 * scale, 20.0 * scale, 8.0 * scale), cap)
	draw_rect(Rect2(center.x - 5.0 * scale, center.y - 4.0 * scale, 3.0 * scale, 3.0 * scale), Color(0.93, 1.0, 0.8))

func _draw_relays() -> void:
	var points: Array[Vector2] = []
	for relay in relay_nodes:
		points.append(relay.position)
	var source := Vector2(640, 340) if stage == Stage.LAB else points[0]
	for i in range(points.size() - 1):
		var a := source if stage == Stage.LAB and i == 0 else points[i]
		var b := points[i]
		if stage == Stage.LAB and i == 0:
			b = points[0]
		elif stage == Stage.LAB:
			a = points[i - 1]
			b = points[i]
		else:
			a = points[i]
			b = points[(i + 1) % points.size()]
		var energized: bool = relay_nodes[i].charged
		draw_line(a, b, Color(0.02, 0.03, 0.08), 9.0)
		draw_line(a, b, FUNGUS if energized else Color(0.39, 0.46, 0.51, 0.72), 4.0)
	for i in relay_nodes.size():
		var point: Vector2 = relay_nodes[i].position
		var energized: bool = relay_nodes[i].charged
		var glow := FUNGUS if energized else CYAN
		draw_circle(point, 31.0 if energized else 25.0, Color(glow.r, glow.g, glow.b, 0.12 + 0.05 * sin(elapsed * 4.0)))
		draw_circle(point, 17.0, INK)
		draw_circle(point, 12.0, glow if energized else Color(0.2, 0.3, 0.36))
		draw_circle(point, 5.0, Color(0.95, 1.0, 0.86) if energized else Color(0.47, 0.62, 0.68))
		draw_string(ThemeDB.fallback_font, point + Vector2(-6, 45), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, GOLD)

func _draw_bolts() -> void:
	for bolt in bolts:
		var point: Vector2 = bolt.position
		var trail: Vector2 = point - bolt.velocity.normalized() * 24.0
		draw_line(trail, point, Color(0.42, 0.88, 1.0, 0.6), 7.0)
		draw_circle(point, 8.0, Color(0.72, 0.96, 1.0, 0.33))
		draw_circle(point, 4.0, Color(0.95, 1.0, 1.0))

func _draw_spore_stalker() -> void:
	var stalker := Vector2(640.0 + sin(elapsed * 1.65) * 240.0, 366.0 + cos(elapsed * 1.1) * 86.0)
	_draw_spore_creature(stalker, 1.0, Color(0.67, 0.42, 1.0))
	if sin(elapsed * 2.4) > 0.65:
		draw_arc(stalker, 38.0, 0.0, TAU, 40, Color(1.0, 0.4, 0.42, 0.65), 3.0)

func _draw_breach_core() -> void:
	_draw_spore_creature(boss_position, 1.7, Color(0.95, 0.33, 0.42))
	draw_arc(boss_position, 48.0 + 3.0 * sin(elapsed * 7.0), 0.0, TAU, 48, GOLD, 3.0)
	for i in boss_health:
		draw_circle(boss_position + Vector2(-22 + i * 22, -58), 6.0, Color(1.0, 0.48, 0.43))

func _draw_spore_creature(center: Vector2, scale: float, cap: Color) -> void:
	var wobble := sin(elapsed * 7.0) * 3.0
	draw_circle(center + Vector2(0, 7), 26.0 * scale, Color(0.02, 0.025, 0.07, 0.5))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-19, 5) * scale,
		center + Vector2(-15, -15 + wobble) * scale,
		center + Vector2(0, -25 - wobble) * scale,
		center + Vector2(15, -15 + wobble) * scale,
		center + Vector2(20, 7) * scale,
		center + Vector2(10, 23) * scale,
		center + Vector2(-13, 22) * scale,
		]), INK)
	draw_rect(Rect2(center + Vector2(-14, -12 + wobble) * scale, Vector2(28, 25) * scale), cap)
	draw_rect(Rect2(center + Vector2(-10, -1) * scale, Vector2(6, 7) * scale), Color(0.98, 1.0, 0.72))
	draw_rect(Rect2(center + Vector2(5, -1) * scale, Vector2(6, 7) * scale), Color(0.98, 1.0, 0.72))
	draw_rect(Rect2(center + Vector2(-4, 11) * scale, Vector2(8, 4) * scale), INK)

func _draw_exit() -> void:
	if stage == Stage.LAB:
		var open := _all_relays_charged()
		draw_rect(Rect2(1180, 296, 38, 148), INK)
		draw_rect(Rect2(1185, 302, 25, 136), Color(0.24, 0.38, 0.48) if open else Color(0.36, 0.17, 0.2))
		draw_rect(Rect2(1189, 326, 17, 84), Color(0.3, 0.9, 0.72, 0.8) if open else Color(0.95, 0.34, 0.34, 0.75))
	elif stage in [Stage.WON, Stage.LOST]:
		draw_rect(Rect2(1182, 296, 34, 148), Color(0.2, 0.8, 0.63, 0.26))
