extends Control

func _ready() -> void:
	$CenterContainer/VBoxContainer/BestStreakLabel.text = "BEST STREAK: %d" % Global.best_streak

func _on_play_again_button_pressed() -> void:
	Global.reset()
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _on_continue_button_pressed() -> void:
	Global.loop += 1
	Global.minigames_done = 0
	Global.lives = 5
	get_tree().change_scene_to_file("res://scenes/level_scene.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
