extends Node2D

const TIME_LIMIT := 10.0
const SWEEP_MIN_X := -100.0
const SWEEP_MAX_X := 1400.0
const SWEEP_DURATION_MIN := 1.8
const SWEEP_DURATION_MAX := 2.6

var finished := false
var _laser_frozen := false
# Each laser owns a looping tween, kept so a reveal can pause the sweeps and a
# blast can kill one without leaving a dead laser sweeping the screen.
var _sweeps: Dictionary = {}
var _freeze_token := 0

@onready var player_area: Area2D = $Player/PlayerArea

func _ready() -> void:
	SceneFade.fade_in(self)
	PowerBus.register_handler(self)
	player_area.area_entered.connect(_on_hazard_hit)
	_setup_laser_sweeps()
	await $ThemedTimer.countdown(_time_limit())
	_finish(true)

func _exit_tree() -> void:
	PowerBus.unregister_handler(self)

func _physics_process(_delta: float) -> void:
	if not finished and Input.is_action_just_pressed("power"):
		PowerBus.try_activate()

func _time_limit() -> float:
	return maxf(5.0, TIME_LIMIT - Global.loop)

func _setup_laser_sweeps() -> void:
	# Stagger each laser's start so the beams never align.
	var index := 0
	for laser: Area2D in $Hazards.get_children():
		var delay := index * 0.45
		get_tree().create_timer(delay).timeout.connect(_arm_sweep.bind(laser))
		index += 1

func _arm_sweep(laser: Area2D) -> void:
	laser.modulate = Color(1, 0.4, 0.4)
	var warn := create_tween()
	warn.tween_property(laser, "modulate", Color(1, 0.15, 0.15), 0.35)
	await warn.finished
	laser.modulate = Color.WHITE
	_start_sweep(laser)

func _start_sweep(laser: Area2D) -> void:
	var speed_factor := 1.0 + 0.15 * Global.loop
	var duration := randf_range(SWEEP_DURATION_MIN, SWEEP_DURATION_MAX) / speed_factor
	var tween := create_tween()
	tween.set_loops(-1)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(laser, "position:x", SWEEP_MAX_X, duration)
	tween.tween_property(laser, "position:x", SWEEP_MIN_X, duration)
	_sweeps[laser] = tween
	# A laser that arms while the field is frozen must start frozen too.
	if _laser_frozen:
		tween.pause()

func _on_hazard_hit(area: Area2D) -> void:
	if finished or not area.is_in_group("hazard"):
		return
	# A ward soaks the contact outright, and a dash makes the player untouchable
	# for its duration. Either way the run continues.
	if $Player.consume_shield():
		Juice.text(self, "BLOCKED", $Player.global_position + Vector2(0, -60), Color(1, 0.85, 0.35), 32)
		Juice.burst(self, $Player.global_position, Color(1, 0.85, 0.35), 12, 200.0)
		return
	if $Player.is_invincible():
		return
	Juice.text(self, "REACTOR DOWN", $Player.global_position + Vector2(0, -60), Color(1, 0.35, 0.35), 34)
	_finish(false)

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

## Lunge: cross the laser lane too fast for a beam to land.
func _power_dash() -> bool:
	_power_text("LUNGE!", Color(0.45, 0.85, 1.0))
	var lane_y: float = $Player.global_position.y
	$Player.burst_toward(Vector2(get_viewport_rect().size.x * 0.5, lane_y), 1050.0, 0.3, true)
	return true

## Sonar / freeze: hold every sweep still for a second, and light the
## next laser so it is unmistakable.
func _power_reveal() -> bool:
	_power_text("SONAR", Color(0.75, 0.6, 1.0))
	_freeze_lasers(1.0)
	var laser := _nearest_laser()
	if laser != null:
		var tween := create_tween()
		tween.set_loops(3)
		tween.tween_property(laser, "modulate", Color(0.75, 0.6, 1.0, 0.35), 0.15)
		tween.tween_property(laser, "modulate", Color.WHITE, 0.15)
	return true

## Tether / snap / aegis: a ward that eats the next hit, plus a short hop
## so the escape reads on screen.
func _power_reach() -> bool:
	_power_text("TETHER!", Color(1.0, 0.75, 0.35))
	$Player.grant_shield()
	$Player.burst(Vector2(0, -340), 0.28, true)
	return true

## Pulse / lance: delete the nearest laser outright.
func _power_blast() -> bool:
	var laser := _nearest_laser()
	if laser == null:
		return false
	_power_text("PULSE!", Color(1.0, 0.5, 0.35))
	Juice.burst(self, laser.global_position, Color(1, 0.5, 0.35), 20, 300.0)
	var sweep: Tween = _sweeps.get(laser)
	if sweep != null:
		sweep.kill()
	_sweeps.erase(laser)
	laser.queue_free()
	return true

func _power_text(text: String, color: Color) -> void:
	Juice.text(self, text, $Player.global_position + Vector2(0, -60), color, 32)

func _freeze_lasers(seconds: float) -> void:
	_freeze_token += 1
	var token := _freeze_token
	_laser_frozen = true
	for laser: Area2D in _sweeps:
		var sweep: Tween = _sweeps[laser]
		if sweep != null:
			sweep.pause()
	get_tree().create_timer(seconds).timeout.connect(_unfreeze_lasers.bind(token))

func _unfreeze_lasers(token: int) -> void:
	# Ignore a stale timer so a second reveal cannot be cut short by the first.
	if token != _freeze_token:
		return
	_laser_frozen = false
	for laser: Area2D in _sweeps:
		if not is_instance_valid(laser):
			_sweeps.erase(laser)
			continue
		var sweep: Tween = _sweeps[laser]
		if sweep != null:
			sweep.play()

func _nearest_laser() -> Area2D:
	var best: Area2D = null
	var best_dist := INF
	for child in $Hazards.get_children():
		var laser := child as Area2D
		if laser == null:
			continue
		var dist := global_position.distance_squared_to(laser.global_position)
		if dist < best_dist:
			best_dist = dist
			best = laser
	return best

func _finish(win: bool) -> void:
	if finished:
		return
	finished = true
	if win:
		$SfxWin.play()
		Juice.shake(self, 0.5)
		Juice.burst(self, $Player.global_position, Color(1, 0.85, 0.25), 26, 320.0)
		await get_tree().create_timer(0.5).timeout
		Global.win()
		await SceneFade.fade_out(self)
		get_tree().change_scene_to_file("res://scenes/level_scene.tscn")
	else:
		$SfxFail.play()
		Juice.hit_stop(self)
		Juice.shake(self, 0.9)
		Juice.burst(self, $Player.global_position, Color(1, 0.3, 0.3), 24, 320.0)
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
