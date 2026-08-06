extends Node2D

@onready var timer_label: RichTextLabel = $TimerLabel
@onready var tick_player: AudioStreamPlayer = $TickPlayer

func countdown(start_time: float) -> void:
	var time_left := start_time
	var last_whole := int(ceil(start_time)) + 1
	while time_left > 0.0:
		timer_label.text = "TIME: %.1f" % snapped(time_left, 0.10)
		var whole := int(ceil(time_left))
		if whole < last_whole:
			last_whole = whole
			tick_player.play()
		await get_tree().create_timer(0.10).timeout
		time_left = maxf(time_left - 0.10, 0.0)
	timer_label.text = "TIME: 0.0"
	timer_label.visible = false
