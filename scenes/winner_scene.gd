extends Control

func _ready() -> void:
	SceneFade.fade_in(self)
	$CenterContainer/VBoxContainer/BestStreakLabel.text = "ROUNDS CLEARED: %d    BEST STREAK: %d" % [Global.minigames_done, Global.best_streak]
	_confetti()

func _confetti() -> void:
	for i in range(10):
		Juice.burst(
			self,
			Vector2(randf_range(100, 1180), randf_range(60, 300)),
			Color(randf_range(0.85, 1.0), randf_range(0.6, 1.0), randf_range(0.2, 0.6)),
			10,
			280.0
		)
		await get_tree().create_timer(0.12).timeout

func _on_play_again_button_pressed() -> void:
	Global.reset()
	await SceneFade.fade_out(self)
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _on_continue_button_pressed() -> void:
	Global.loop += 1
	Global.minigames_done = 0
	Global.lives = 5
	await SceneFade.fade_out(self)
	get_tree().change_scene_to_file("res://scenes/level_scene.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
