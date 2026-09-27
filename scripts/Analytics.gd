extends Node
## Privacy-first game telemetry. Browser providers are loaded by web/mobile_shell.html
## only after the player explicitly opts in. Never send callsigns or typed text.

const TRACKED_ACTIONS := [
	"left", "right", "move_left", "move_right", "move_down",
	"jump", "action", "restart", "click", "ui_cancel"
]

var current_mission_id := ""
var current_mission_title := ""
var current_mission_mode := ""
var mission_started_ms := 0
var run_active := false
var run_mode := ""
var run_started_ms := 0

var _control_counts: Dictionary = {}
var _control_seen: Dictionary = {}
var _last_input_type := "unknown"
var _fps_total := 0.0
var _fps_samples := 0
var _min_fps := 9999.0
var _last_fps_sample_ms := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	set_process_input(true)
	track("godot_ready", {
		"engine": "godot",
		"engine_version": str(Engine.get_version_info().get("string", "unknown")),
		"os": OS.get_name()
	})

func _process(_delta: float) -> void:
	if current_mission_id.is_empty():
		return
	var now := Time.get_ticks_msec()
	if now - _last_fps_sample_ms < 1000:
		return
	_last_fps_sample_ms = now
	var fps := float(Engine.get_frames_per_second())
	if fps <= 0.0:
		return
	_fps_total += fps
	_fps_samples += 1
	_min_fps = minf(_min_fps, fps)

func _input(event: InputEvent) -> void:
	if current_mission_id.is_empty():
		return
	if event is InputEventKey:
		if not event.pressed or event.echo:
			return
		for action in TRACKED_ACTIONS:
			if event.is_action_pressed(action):
				record_control(action, "keyboard")
				return
	elif event is InputEventMouseButton:
		if event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION:
			record_control("pointer", "mouse")
	elif event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			record_control("pointer", "touch")

func track(event_name: String, params: Dictionary = {}) -> void:
	var payload := _safe_params(params)
	payload["source"] = "godot"
	var scene := get_tree().current_scene
	if is_instance_valid(scene) and not scene.scene_file_path.is_empty():
		payload["scene"] = scene.scene_file_path.get_file().get_basename()
	if OS.has_feature("web"):
		var script := "window.GameAnalytics&&window.GameAnalytics.track(%s,%s);" % [
			JSON.stringify(event_name),
			JSON.stringify(payload)
		]
		JavaScriptBridge.eval(script, true)
	else:
		print("[analytics] %s %s" % [event_name, JSON.stringify(payload)])

func report_error(code: String, params: Dictionary = {}) -> void:
	var payload := _safe_params(params)
	track("game_error", payload.merged({"error_code": code}, true))
	if OS.has_feature("web"):
		var script := "window.GameAnalytics&&window.GameAnalytics.reportError(%s,%s);" % [
			JSON.stringify(code),
			JSON.stringify(payload)
		]
		JavaScriptBridge.eval(script, true)

func start_run(mode: String, params: Dictionary = {}) -> void:
	if run_active:
		end_run("replaced")
	run_active = true
	run_mode = mode
	run_started_ms = Time.get_ticks_msec()
	var payload := _safe_params(params)
	payload["mode"] = mode
	track("game_session_start", payload)

func end_run(reason: String, params: Dictionary = {}) -> void:
	if not run_active:
		return
	var payload := _safe_params(params)
	payload["mode"] = run_mode
	payload["reason"] = reason
	payload["duration_seconds"] = _seconds_since(run_started_ms)
	track("game_session_end", payload)
	run_active = false
	run_mode = ""
	run_started_ms = 0

func start_mission(mission_id: String, title: String, max_duration: float, mode: String) -> void:
	if not current_mission_id.is_empty():
		abandon_mission("replaced")
	current_mission_id = mission_id
	current_mission_title = title
	current_mission_mode = mode
	mission_started_ms = Time.get_ticks_msec()
	_control_counts.clear()
	_control_seen.clear()
	_last_input_type = "unknown"
	_fps_total = 0.0
	_fps_samples = 0
	_min_fps = 9999.0
	_last_fps_sample_ms = 0
	track("mission_started", {
		"mission_id": mission_id,
		"mission_title": title,
		"mode": mode,
		"max_duration_seconds": max_duration
	})

func finish_mission(won: bool, time_left: float) -> void:
	if current_mission_id.is_empty():
		return
	var payload := _mission_payload()
	payload["time_left_seconds"] = snappedf(maxf(time_left, 0.0), 0.1)
	payload["outcome"] = "win" if won else "loss"
	track("mission_completed" if won else "mission_failed", payload)
	_clear_mission()

func restart_mission() -> void:
	if current_mission_id.is_empty():
		return
	var payload := _mission_payload()
	payload["reason"] = "restart"
	track("mission_restarted", payload)
	_clear_mission()

func abandon_mission(reason: String) -> void:
	if current_mission_id.is_empty():
		return
	var payload := _mission_payload()
	payload["reason"] = reason
	track("mission_abandoned", payload)
	_clear_mission()

func record_control(action: String, input_type: String) -> void:
	if current_mission_id.is_empty() or action.is_empty():
		return
	_last_input_type = input_type
	_control_counts[action] = int(_control_counts.get(action, 0)) + 1
	var key := "%s:%s" % [action, input_type]
	if not _control_seen.has(key):
		_control_seen[key] = true
		track("control_used", {
			"mission_id": current_mission_id,
			"control": action,
			"input_type": input_type
		})

func _mission_payload() -> Dictionary:
	var payload := {
		"mission_id": current_mission_id,
		"mission_title": current_mission_title,
		"mode": current_mission_mode,
		"duration_seconds": _seconds_since(mission_started_ms),
		"input_type": _last_input_type
	}
	if _fps_samples > 0:
		payload["avg_fps"] = snappedf(_fps_total / float(_fps_samples), 0.1)
		payload["min_fps"] = snappedf(_min_fps, 0.1)
	for action in _control_counts:
		payload["controls_" + String(action)] = int(_control_counts[action])
	return payload

func _clear_mission() -> void:
	current_mission_id = ""
	current_mission_title = ""
	current_mission_mode = ""
	mission_started_ms = 0
	_control_counts.clear()
	_control_seen.clear()
	_last_input_type = "unknown"
	_fps_total = 0.0
	_fps_samples = 0
	_min_fps = 9999.0
	_last_fps_sample_ms = 0

func _seconds_since(start_ms: int) -> float:
	if start_ms <= 0:
		return 0.0
	return snappedf(float(Time.get_ticks_msec() - start_ms) / 1000.0, 0.1)

func _safe_params(params: Dictionary) -> Dictionary:
	var safe := {}
	for key in params:
		var name := String(key)
		var lower := name.to_lower()
		if "name" in lower or "email" in lower or "callsign" in lower or "text" in lower:
			continue
		var value = params[key]
		if value is String:
			safe[name] = String(value).substr(0, 100)
		elif value is int or value is float or value is bool:
			safe[name] = value
	return safe
