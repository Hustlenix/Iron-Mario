extends Node2D

func _ready() -> void:
	SceneFade.fade_in(self)
	$Bgm.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	$Bgm.play()
	$StreakLabel.text = "[center]BEST STREAK: %d[/center]" % Global.best_streak
	_build_hero()
	_pulse_logo()

func _build_hero() -> void:
	var hero := TextureRect.new()
	hero.texture = load("res://assets/hero.svg") as Texture2D
	hero.position = Vector2(300, 380)
	hero.custom_minimum_size = Vector2(150, 150)
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hero)
	var tween := create_tween()
	tween.set_loops(-1)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(hero, "position:y", 430.0, 1.1)
	tween.tween_property(hero, "position:y", 380.0, 1.1)

func _pulse_logo() -> void:
	var tween := create_tween()
	tween.set_loops(-1)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($TitleLabel, "scale", Vector2(1.06, 1.06), 0.9)
	tween.tween_property($TitleLabel, "scale", Vector2.ONE, 0.9)

func _on_start_button_pressed() -> void:
	Global.reset()
	await SceneFade.fade_out(self)
	get_tree().change_scene_to_file("res://scenes/level_scene.tscn")

func _on_settings_button_pressed() -> void:
	await SceneFade.fade_out(self)
	get_tree().change_scene_to_file("res://scenes/settings_scene.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
