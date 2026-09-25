extends Node
## Pause while a phone is upright or the app loses focus. Timers resume in place.
var inactive := false
var owns_pause := false
var paused_for_portrait := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	var dimensions := DisplayServer.window_get_size()
	paused_for_portrait = Global.uses_touch() and dimensions.x < dimensions.y
	var should_pause := paused_for_portrait or inactive
	if should_pause and not get_tree().paused:
		get_tree().paused = true
		owns_pause = true
	elif not should_pause and owns_pause:
		get_tree().paused = false
		owns_pause = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		inactive = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		inactive = false
