extends Node2D

const CLICKS_REQUIRED := 5
const TIME_LIMIT := 10.0
const MARGIN := 48.0

var clicks := 0
var finished := false
var _dashing := false

@onready var target: TextureRect = $Target
@onready var score_label: RichTextLabel = $HUD/ScoreLabel
@onready var reposition_timer: Timer = $RepositionTimer

func _ready() -> void:
	SceneFade.fade_in(self)
	PowerBus.register_handler(self)
	_reposition_target()
	reposition_timer.timeout.connect(_reposition_target)
	reposition_timer.wait_time = maxf(0.35, 0.6 - 0.05 * Global.loop)
	reposition_timer.start()
	await $ThemedTimer.countdown(_time_limit())
	_finish(false)

func _exit_tree() -> void:
	PowerBus.unregister_handler(self)

func _physics_process(_delta: float) -> void:
	if finished:
		return
	if Input.is_action_just_pressed("power"):
		PowerBus.try_activate()
	# A dash only resolves when the player physically reaches the target, so
	# the pass-through is checked while the scripted motion is still live.
	if _dashing:
		# Untyped on purpose: this scene ships no Player node, and a statically
		# typed Node cannot call the player's own methods.
		var player = get_node_or_null("Player")
		if player == null:
			# No player body on screen, so the lunge resolves on the target itself.
			_dashing = false
			_register_hit()
		elif player.motion_active() and target.get_global_rect().has_point(player.global_position):
			_dashing = false
			_register_hit()

func _time_limit() -> float:
	return maxf(5.0, TIME_LIMIT - Global.loop)

func _unhandled_input(event: InputEvent) -> void:
	if finished:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if target.get_global_rect().has_point(event.position):
			_register_hit()
		else:
			Juice.text(self, "MISS", event.position, Color(1, 0.35, 0.35), 30)

## The single point where a tap counts, shared by the mouse, a dash landing, and
## the reach/blast auto-hits so the score and feedback stay in step.
func _register_hit() -> void:
	clicks += 1
	score_label.text = "HITS: %d / %d" % [clicks, CLICKS_REQUIRED]
	Juice.shake(self, 0.2)
	Juice.burst(self, target.get_global_rect().get_center(), Color(1, 0.85, 0.25), 10, 220.0)
	Juice.text(self, "HIT x%d" % clicks, target.get_global_rect().get_center() + Vector2(0, -50), Color(1, 0.9, 0.3), 36)
	_reposition_target()
	if clicks >= CLICKS_REQUIRED:
		_finish(true)

# --- Power handlers: one per family. ---

func on_power(family: int) -> bool:
	if finished:
		return false
	match family:
		HeroData.Family.DASH:
			return _power_dash()
		HeroData.Family.REVEAL:
			return _power_reveal()
		HeroData.Family.REACH:
			return _power_reach()
		HeroData.Family.BLAST:
			return _power_blast()
	return false

## Lunge: dive through the target. The hit lands in _physics_process when
## the player crosses the target rect, which is the same place a mouse hit is
## counted.
func _power_dash() -> bool:
	_power_text("LUNGE!", Color(0.45, 0.85, 1.0))
	_dashing = true
	var player = get_node_or_null("Player")
	if player == null:
		Juice.burst(self, target.get_global_rect().get_center(), Color(0.45, 0.85, 1.0), 14, 300.0)
		return true
	player.burst_toward(target.get_global_rect().get_center(), 1000.0, 0.5, true)
	return true

## Sonar / freeze: hold the target still and light it up for a beat.
func _power_reveal() -> bool:
	_power_text("SONAR", Color(0.75, 0.6, 1.0))
	reposition_timer.stop()
	var tween := create_tween()
	tween.set_loops(3)
	tween.tween_property(target, "modulate", Color(0.75, 0.6, 1.0, 0.4), 0.15)
	tween.tween_property(target, "modulate", Color(1, 1, 1, 1), 0.15)
	get_tree().create_timer(1.2).timeout.connect(_resume_reposition)
	return true

func _resume_reposition() -> void:
	if is_instance_valid(reposition_timer) and not finished:
		reposition_timer.start()

## Tether / snap / aegis: the long-range auto-hit, no movement needed.
func _power_reach() -> bool:
	_power_text("TETHER!", Color(1.0, 0.75, 0.35))
	_hit_flash()
	_register_hit()
	return true

## Pulse / lance: vaporise the target outright.
func _power_blast() -> bool:
	_power_text("PULSE!", Color(1.0, 0.5, 0.35))
	target.hide()
	_hit_flash()
	_register_hit()
	return true

func _hit_flash() -> void:
	var center := target.get_global_rect().get_center()
	Juice.shake(self, 0.3)
	Juice.burst(self, center, Color(1, 0.6, 0.25), 16, 280.0)

func _power_text(text: String, color: Color) -> void:
	# Anchored to the player when one exists, otherwise over the target: this
	# scene has no Player node, so $Player would be null here.
	var player = get_node_or_null("Player")
	var anchor: Vector2 = target.get_global_rect().get_center()
	if player != null:
		anchor = player.global_position
	Juice.text(self, text, anchor + Vector2(0, -70), color, 32)

func _reposition_target() -> void:
	if finished:
		return
	var vp_size: Vector2 = get_viewport_rect().size
	var max_pos := vp_size - target.size - Vector2(MARGIN, MARGIN)
	target.position = Vector2(
		randf_range(MARGIN, max_pos.x),
		randf_range(MARGIN, max_pos.y)
	)

func _finish(win: bool) -> void:
	if finished:
		return
	finished = true
	if win:
		$SfxWin.play()
		Juice.hit_stop(self)
		Juice.shake(self, 0.5)
		Juice.burst(self, target.get_global_rect().get_center(), Color(1, 0.85, 0.25), 26, 320.0)
		await get_tree().create_timer(0.5).timeout
		Global.win()
		await SceneFade.fade_out(self)
		get_tree().change_scene_to_file("res://scenes/level_scene.tscn")
	else:
		$SfxFail.play()
		Juice.shake(self, 0.6)
		Juice.burst(self, target.get_global_rect().get_center(), Color(1, 0.3, 0.3), 18, 280.0)
		await get_tree().create_timer(0.45).timeout
		Global.lose()
		Global.minigames_done -= 1
		Global.lives -= 1
		if Global.lives <= 0:
			await SceneFade.fade_out(self)
			get_tree().change_scene_to_file("res://scenes/death_scene.tscn")
		else:
			await SceneFade.fade_out(self)
			get_tree().change_scene_to_file("res://scenes/level_scene.tscn")
