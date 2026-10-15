extends RefCounted
## Synchronous, app-scoped browser persistence. No virtual filesystem/IDB access.
## Inject a Callable accepting an operation Dictionary for isolated native tests.

const PRIMARY_KEY: String = "iron-mario-profile-v2"
const BACKUP_KEY: String = "iron-mario-profile-v2-backup"
const HERO_KEY: String = "iron-mario-roster-hero-v1"
const MOTION_KEY: String = "iron-mario-roster-motion-v1"
const VERSION: int = 2
const MAX_CHARACTERS: int = 1048576
var bridge: Callable
var last_error: String = ""
var recovered_from_backup: bool = false
var future_version: bool = false

func _request(operation: Dictionary) -> Dictionary:
	if bridge.is_valid():
		var result: Variant = bridge.call(operation)
		return result if result is Dictionary else {"ok": false, "error": "Invalid browser storage response."}
	if not OS.has_feature("web"):
		return {"ok": false, "error": "Browser storage is unavailable on this platform."}
	# Only four known keys in this app's namespace are reachable through this bridge.
	var script: String = "(()=>{try{const op=" + JSON.stringify(operation) + ";"
	script += "const p='iron-mario-profile-v2',b='iron-mario-profile-v2-backup';"
	script += "if(op.action==='read')return JSON.stringify({ok:true,primary:localStorage.getItem(p),backup:localStorage.getItem(b),hero:localStorage.getItem('iron-mario-roster-hero-v1'),motion:localStorage.getItem('iron-mario-roster-motion-v1')});"
	script += "if(op.action==='write'&&(op.key===p||op.key===b)){localStorage.setItem(op.key,op.value);if(localStorage.getItem(op.key)!==op.value)throw new Error('Write verification failed');return JSON.stringify({ok:true});}"
	script += "return JSON.stringify({ok:false,error:'Invalid profile storage operation.'});}catch(e){return JSON.stringify({ok:false,error:'Browser profile storage unavailable: '+(e.name||'Error')+'.'});}})()"
	var response: Variant = JavaScriptBridge.eval(script, true)
	if response is String:
		var parsed: Variant = JSON.parse_string(response)
		if parsed is Dictionary:
			return parsed
	return {"ok": false, "error": "Browser profile storage did not respond."}

func _decode(value: Variant) -> Dictionary:
	if value == null:
		return {"state": "missing", "raw": {}}
	if not value is String or value.is_empty() or value.length() > MAX_CHARACTERS:
		return {"state": "invalid", "raw": {}}
	var parser := JSON.new()
	if parser.parse(value) != OK or not parser.data is Dictionary:
		return {"state": "invalid", "raw": {}}
	var raw: Dictionary = parser.data
	var version: Variant = raw.get("schema_version")
	if not (version is int or version is float) or not is_finite(float(version)) or float(version) != floorf(float(version)) or float(version) < VERSION:
		return {"state": "invalid", "raw": {}}
	return {"state": "future" if float(version) > VERSION else "current", "raw": raw}

func load_profile() -> Dictionary:
	last_error = ""
	recovered_from_backup = false
	future_version = false
	var slots: Dictionary = _request({"action": "read"})
	if slots.get("ok") != true:
		last_error = str(slots.get("error", "Could not read browser profile storage."))
		return {"raw": {}, "migration_allowed": false, "preferences": {}, "blocked": true}
	var primary: Dictionary = _decode(slots.get("primary"))
	var backup: Dictionary = _decode(slots.get("backup"))
	var selected: Dictionary = primary
	if primary.state not in ["current", "future"] and backup.state in ["current", "future"]:
		selected = backup
		recovered_from_backup = true
	future_version = selected.state == "future"
	if future_version:
		last_error = "This profile was saved by a newer version; saving is disabled."
	elif selected.state == "invalid":
		last_error = "Browser profile and backup were unreadable; using a new profile."
	var migration_allowed: bool = primary.state == "missing" and backup.state == "missing"
	var preferences: Dictionary = {}
	if migration_allowed:
		if slots.get("hero") is String:
			preferences.hero = slots.hero
		if slots.get("motion") in ["true", "false"]:
			preferences.reduced_motion = slots.motion == "true"
	return {"raw": selected.raw, "migration_allowed": migration_allowed, "preferences": preferences, "blocked": false}

func _write(key: String, value: String) -> bool:
	var result: Dictionary = _request({"action": "write", "key": key, "value": value})
	if result.get("ok") != true:
		last_error = str(result.get("error", "Could not write browser profile."))
		return false
	return true

func save_profile(profile: Dictionary) -> bool:
	last_error = ""
	if future_version:
		last_error = "This profile was saved by a newer version; saving is disabled."
		return false
	var serialized: String = JSON.stringify(profile)
	if serialized.length() > MAX_CHARACTERS or _decode(serialized).state != "current":
		last_error = "Profile is invalid or exceeds the browser save limit."
		return false
	var slots: Dictionary = _request({"action": "read"})
	if slots.get("ok") != true:
		last_error = str(slots.get("error", "Could not read browser profile storage."))
		return false
	var primary: Dictionary = _decode(slots.get("primary"))
	var backup: Dictionary = _decode(slots.get("backup"))
	# Recheck on every save, including a profile upgraded in another browser tab.
	if primary.state == "future" or backup.state == "future":
		future_version = true
		last_error = "This profile was saved by a newer version; saving is disabled."
		return false
	if primary.state == "current":
		if not _write(BACKUP_KEY, slots.primary):
			return false
	elif backup.state != "current":
		# First write creates both copies; failed primary writes remain recoverable.
		if not _write(BACKUP_KEY, serialized):
			return false
	if not _write(PRIMARY_KEY, serialized):
		return false
	return true
