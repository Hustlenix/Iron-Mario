extends Node2D

func _ready() -> void:
	$Bgm.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	$Bgm.play()

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_scene.tscn")

func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings_scene.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
