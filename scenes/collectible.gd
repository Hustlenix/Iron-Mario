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
	Juice.burst(get_parent(), global_position, Color(1, 0.85, 0.25), 10, 220.0)
	Juice.text(get_parent(), "+1", global_position + Vector2(0, -30), Color(1, 0.9, 0.3), 34)
	collectible_collected.emit()
