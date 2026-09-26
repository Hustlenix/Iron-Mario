extends Node2D

## When the clock gets this close to zero the score swaps to the danger loop, so
## the pressure arrives before the buzzer rather than after it.
const DANGER_LEAD := 3.0

@onready var timer_label: RichTextLabel = $TimerLabel
@onready var tick_player: AudioStreamPlayer = $TickPlayer

var _danger_played := false

func countdown(start_time: float) -> void:
	# Reset rather than rely on one call per instance: a reused timer would
	# otherwise keep the latch set and never escalate to the danger loop.
	_danger_played = false
	Music.play("gauntlet", 1.2)
	var time_left := start_time
	var last_whole := int(ceil(start_time)) + 1
	while time_left > 0.0:
		if not _danger_played and time_left <= DANGER_LEAD:
			_danger_played = true
			Music.play("danger", 1.5)
		timer_label.text = "TIME: %.1f" % snapped(time_left, 0.10)
		var whole := int(ceil(time_left))
		if whole < last_whole:
			last_whole = whole
			tick_player.play()
		await get_tree().create_timer(0.10).timeout
		if not is_instance_valid(self) or not is_inside_tree():
			return
		time_left = maxf(time_left - 0.10, 0.0)
	timer_label.text = "TIME: 0.0"
	timer_label.visible = false
