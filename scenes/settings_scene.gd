extends Control

@onready var volume_slider: HSlider = $CenterContainer/VBoxContainer/VolumeRow/VolumeSlider
@onready var status_label: RichTextLabel = $CenterContainer/VBoxContainer/StatusLabel

func _ready() -> void:
	volume_slider.value = Global.volume
	_apply_volume(Global.volume)
	SceneFade.fade_in(self)

func _apply_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value, 0.001) / 100.0))

func _on_volume_changed(value: float) -> void:
	Global.volume = value
	_apply_volume(value)

func _on_reset_button_pressed() -> void:
	Global.best_streak = 0
	Global.streak = 0
	Global.loop = 0
	Global.save()
	status_label.text = "PROGRESS RESET (SAVED)"
	status_label.visible = true

func _on_back_button_pressed() -> void:
	Global.save()
	await SceneFade.fade_out(self)
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _exit_tree() -> void:
	Global.save()
