extends Control

func _ready() -> void:
	$CenterContainer/VBoxContainer/BestStreakLabel.text = "BEST STREAK: %d" % Global.best_streak

func _on_play_again_button_pressed() -> void:
	Global.reset()
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
