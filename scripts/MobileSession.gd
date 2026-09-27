extends Node
## Pause while a phone is upright or the app loses focus. Timers resume in place.
var inactive := false
var owns_pause := false
var paused_for_portrait := false
var _portrait_started_ms := 0
var _focus_started_ms := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	var dimensions := DisplayServer.window_get_size()
	var portrait_now := Global.uses_touch() and dimensions.x < dimensions.y
	if portrait_now != paused_for_portrait:
		paused_for_portrait = portrait_now
		if portrait_now:
			_portrait_started_ms = Time.get_ticks_msec()
			Analytics.track("orientation_warning", {"orientation": "portrait"})
			Analytics.track("game_paused", {"reason": "portrait"})
		else:
			var duration_ms := maxi(0, Time.get_ticks_msec() - _portrait_started_ms)
			Analytics.track("orientation_fixed", {"duration_ms": duration_ms})
			Analytics.track("game_resumed", {"reason": "portrait", "pause_duration_ms": duration_ms})
			_portrait_started_ms = 0
	var should_pause := paused_for_portrait or inactive
	if should_pause and not get_tree().paused:
		get_tree().paused = true
		owns_pause = true
	elif not should_pause and owns_pause:
		get_tree().paused = false
		owns_pause = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not inactive:
		inactive = true
		_focus_started_ms = Time.get_ticks_msec()
		Analytics.track("game_paused", {"reason": "focus"})
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN and inactive:
		inactive = false
		var duration_ms := maxi(0, Time.get_ticks_msec() - _focus_started_ms)
		Analytics.track("game_resumed", {"reason": "focus", "pause_duration_ms": duration_ms})
		_focus_started_ms = 0
