extends Node

const TITLE_SCENE := "res://scenes/title_screen.tscn"
const INTERMISSION_SCENE := "res://scenes/intermission.tscn"
const WINNER_SCENE := "res://scenes/winner_scene.tscn"
const DEATH_SCENE := "res://scenes/death_scene.tscn"

const MINIGAMES := [
	{
		"name": "ARC REACTOR DASH",
		"instruction": "MOVE, JUMP, AND GRAB 3 REACTOR SHARDS!",
		"scene": "res://scenes/minigames/arc_reactor_dash.tscn"
	},
	{
		"name": "TARGET LOCK",
		"instruction": "TAP OR CLICK THE FLYING TARGETS!",
		"scene": "res://scenes/minigames/target_lock.tscn"
	},
	{
		"name": "LASER TUNNEL",
		"instruction": "JUMP OVER THE LASERS UNTIL TIME RUNS OUT!",
		"scene": "res://scenes/minigames/laser_tunnel.tscn"
	},
	{
		"name": "REACTOR PARRY",
		"instruction": "PRESS JUMP INSIDE THE GREEN ZONE 3 TIMES!",
		"scene": "res://scenes/minigames/reactor_parry.tscn"
	},
	{
		"name": "ARMOR REPAIR",
		"instruction": "DRAG EACH CHIP ONTO ITS MATCHING SOCKET!",
		"scene": "res://scenes/minigames/armor_repair.tscn"
	},
	{
		"name": "ROCKET RESCUE",
		"instruction": "MOVE LEFT AND RIGHT TO CATCH 5 PODS!",
		"scene": "res://scenes/minigames/rocket_rescue.tscn"
	},
	{
		"name": "POWER CORE SEQUENCE",
		"instruction": "WATCH, THEN REPEAT WITH ARROWS OR TAPS!",
		"scene": "res://scenes/minigames/power_core_sequence.tscn"
	}
]

var round_order: Array[int] = []
var round_index: int = 0
var transition_locked := false
var rng := RandomNumberGenerator.new()
var scene_path := TITLE_SCENE
var run_generation := 0
var single_game := false
var single_won := false

func _ready() -> void:
	rng.randomize()

func start_run(harder: bool = false) -> void:
	if transition_locked:
		return
	single_game = false
	Global.reset_run(harder)
	run_generation += 1
	round_order.clear()
	for index in range(MINIGAMES.size()):
		round_order.append(index)
	_shuffle_rounds()
	round_index = 0
	transition_locked = true
	SoundFX.play_start()
	_change_scene(INTERMISSION_SCENE)

func start_single(index: int) -> void:
	if transition_locked or index < 0 or index >= MINIGAMES.size():
		return
	single_game = true
	single_won = false
	Global.reset_run()
	run_generation += 1
	round_order.assign([index])
	round_index = 0
	transition_locked = true
	_change_scene(INTERMISSION_SCENE)

func replay_single() -> void:
	start_single(round_order[0] if not round_order.is_empty() else 0)

func get_upcoming_game() -> Dictionary:
	if round_order.is_empty():
		return MINIGAMES[0]
	return MINIGAMES[round_order[clampi(round_index, 0, round_order.size() - 1)]]

func launch_current_minigame(prepared: PackedScene = null) -> void:
	if round_order.is_empty():
		start_run(false)
		return
	Global.current_minigame = round_index + 1
	transition_locked = true
	_change_scene(String(get_upcoming_game()["scene"]), prepared)

func resolve_round(won: bool) -> void:
	if transition_locked:
		return
	transition_locked = true
	var generation := run_generation
	if single_game:
		single_won = won
		Global.score = 100 if won else 0
		Global.completed_minigames = 1 if won else 0
	elif won:
		Global.record_success()
	else:
		Global.record_failure()
	await get_tree().create_timer(0.8).timeout
	if generation != run_generation:
		return
	if single_game:
		_change_scene("res://scenes/single_result.tscn")
		return
	if Global.lives <= 0:
		_change_scene(DEATH_SCENE)
		return
	# A failed game stays in the queue until cleared or all lives run out.
	if won:
		round_index += 1
	if Global.completed_minigames >= MINIGAMES.size():
		Global.total_wins += 1
		Global.save_data()
		_change_scene(WINNER_SCENE)
	else:
		_change_scene(INTERMISSION_SCENE)

func restart_current_minigame() -> void:
	if transition_locked:
		return
	transition_locked = true
	_change_scene(scene_path)

func return_to_title() -> void:
	if transition_locked:
		return
	transition_locked = true
	_change_scene(TITLE_SCENE)

func open_menu(path: String) -> void:
	if transition_locked:
		return
	transition_locked = true
	_change_scene(path)

func _change_scene(path: String, prepared: PackedScene = null) -> void:
	scene_path = path
	# A pressed button must finish its GUI event before its scene is removed.
	_perform_scene_change.call_deferred(path, prepared)

func _perform_scene_change(path: String, prepared: PackedScene = null) -> void:
	var error := get_tree().change_scene_to_packed(prepared) if prepared != null else get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Iron-Mario could not open scene: %s (error %s)" % [path, error])
		transition_locked = false
	else:
		call_deferred("_unlock_transition")

func _unlock_transition() -> void:
	transition_locked = false
	if OS.has_feature("web"):
		print("SCENE_READY " + scene_path)

func register_preview(path: String) -> void:
	# F6 must restart the scene being previewed, not always the first mission.
	if not round_order.is_empty():
		return
	Global.reset_run()
	for index in range(MINIGAMES.size()):
		if MINIGAMES[index]["scene"] == path:
			round_order.append(index)
	for index in range(MINIGAMES.size()):
		if not round_order.has(index):
			round_order.append(index)
	round_index = 0
	Global.current_minigame = 1
	scene_path = path

func _shuffle_rounds() -> void:
	for index in range(round_order.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value := round_order[index]
		round_order[index] = round_order[swap_index]
		round_order[swap_index] = value
