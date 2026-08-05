extends Node2D

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_scene.tscn")

func _on_settings_button_pressed() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
