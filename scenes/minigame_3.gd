extends Node2D

const TIME_LIMIT := 10.0
const SWEEP_MIN_X := -100.0
const SWEEP_MAX_X := 1400.0
const SWEEP_DURATION_MIN := 1.8
const SWEEP_DURATION_MAX := 2.6

var finished := false

@onready var player_area: Area2D = $Player/PlayerArea

func _ready() -> void:
	SceneFade.fade_in(self)
	player_area.area_entered.connect(_on_hazard_hit)
	_setup_laser_sweeps()
	await $ThemedTimer.countdown(_time_limit())
	_finish(true)

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

func _on_hazard_hit(area: Area2D) -> void:
	if area.is_in_group("hazard"):
		Juice.text(self, "REACTOR DOWN", $Player.global_position + Vector2(0, -60), Color(1, 0.35, 0.35), 34)
		_finish(false)

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
