extends Node2D

@onready var timer_label: RichTextLabel = $TimerLabel

func countdown(start_time: float) -> void:
	var time_left := start_time
	while time_left > 0.0:
		timer_label.text = "TIME: %.1f" % snapped(time_left, 0.10)
		await get_tree().create_timer(0.10).timeout
		time_left = maxf(time_left - 0.10, 0.0)
	timer_label.text = "TIME: 0.0"
	timer_label.visible = false
