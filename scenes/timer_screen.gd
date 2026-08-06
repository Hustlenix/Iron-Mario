extends Node2D

const INTERMISSION_TIME := 5.0

@onready var lives_container: HBoxContainer = $LivesContainer
@onready var level_label: RichTextLabel = $LevelLabel
@onready var timer_label: RichTextLabel = $TimerLabel

var time_left: float = INTERMISSION_TIME

func _ready() -> void:
	await countdown()

func _process(_delta: float) -> void:
	for i in range(lives_container.get_child_count()):
		lives_container.get_child(i).visible = i < Global.lives
	level_label.text = "LEVEL %d" % (Global.minigames_done + 1)
	timer_label.text = "TIME: %.1f" % snapped(time_left, 0.1)

func countdown() -> void:
	time_left = INTERMISSION_TIME
	while time_left > 0.0:
		await get_tree().create_timer(0.1).timeout
		time_left = maxf(time_left - 0.1, 0.0)
	if Global.lives <= 0:
		$SfxFail.play()
		await get_tree().create_timer(0.45).timeout
		get_tree().change_scene_to_file("res://scenes/death_scene.tscn")
	elif Global.minigames_done < 4:
		Global.minigames_done += 1
		get_tree().change_scene_to_file("res://scenes/minigame_%d.tscn" % Global.minigames_done)
	else:
		$SfxWin.play()
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/winner_scene.tscn")
