extends Control

func _ready() -> void:
	SceneFade.fade_in(self)
	$CenterContainer/VBoxContainer/BestStreakLabel.text = "BEST STREAK: %d" % Global.best_streak
	_pulse_vignette()

func _pulse_vignette() -> void:
	var vignette := ColorRect.new()
	vignette.color = Color(0.6, 0, 0, 0.0)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vignette)
	var tween := create_tween()
	tween.set_loops(3)
	tween.tween_property(vignette, "color:a", 0.3, 0.4)
	tween.tween_property(vignette, "color:a", 0.0, 0.6)

func _on_play_again_button_pressed() -> void:
	Global.reset()
	await SceneFade.fade_out(self)
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
