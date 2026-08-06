extends Node2D

const TIME_LIMIT := 10.0
const SWEEP_MIN_X := -100.0
const SWEEP_MAX_X := 1400.0
const SWEEP_DURATION_MIN := 1.8
const SWEEP_DURATION_MAX := 2.6

var finished := false

@onready var player_area: Area2D = $Player/PlayerArea

func _ready() -> void:
	player_area.area_entered.connect(_on_hazard_hit)
	_setup_laser_sweeps()
	await $ThemedTimer.countdown(TIME_LIMIT)
	_finish(true)

func _setup_laser_sweeps() -> void:
	# Stagger each laser's start so the beams never align.
	var index := 0
	for laser: Area2D in $Hazards.get_children():
		var delay := index * 0.45
		get_tree().create_timer(delay).timeout.connect(_start_sweep.bind(laser))
		index += 1

func _start_sweep(laser: Area2D) -> void:
	var duration := randf_range(SWEEP_DURATION_MIN, SWEEP_DURATION_MAX)
	var tween := create_tween()
	tween.set_loops(-1)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(laser, "position:x", SWEEP_MAX_X, duration)
	tween.tween_property(laser, "position:x", SWEEP_MIN_X, duration)

func _on_hazard_hit(area: Area2D) -> void:
	if area.is_in_group("hazard"):
		_finish(false)

func _finish(win: bool) -> void:
	if finished:
		return
	finished = true
	if win:
		get_tree().change_scene_to_file("res://scenes/level_scene.tscn")
	else:
		Global.minigames_done -= 1
		Global.lives -= 1
		if Global.lives <= 0:
			get_tree().change_scene_to_file("res://scenes/death_scene.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/level_scene.tscn")
