extends Node2D

const COLLECTIBLES_REQUIRED := 3
const TIME_LIMIT := 10.0

var collectible_count := 0
var finished := false

@onready var collectibles: Node2D = $Collectibles

func _ready() -> void:
	for child in collectibles.get_children():
		child.collectible_collected.connect(_on_collectible_collected)
	await $ThemedTimer.countdown(TIME_LIMIT)
	_finish(false)

func _on_collectible_collected() -> void:
	collectible_count += 1
	if collectible_count >= COLLECTIBLES_REQUIRED:
		_finish(true)

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
