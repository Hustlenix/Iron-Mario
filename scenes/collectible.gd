extends Node2D

signal collectible_collected

@onready var area: Area2D = $Area2D
@onready var anim: AnimationPlayer = $AnimationPlayer

var collected := false

func _physics_process(_delta: float) -> void:
	if collected:
		return
	var player_area := get_tree().get_first_node_in_group("player_area")
	if player_area and player_area.overlaps_area(area):
		collect()

func collect() -> void:
	if collected:
		return
	collected = true
	anim.stop()
	hide()
	collectible_collected.emit()
