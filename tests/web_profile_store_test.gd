extends SceneTree

const WebStoreScript = preload("res://core/web_profile_store.gd")
const SaveStoreScript = preload("res://core/save_store.gd")
var checks: int = 0
var failures: int = 0
var folder: String

class FakeBrowser:
	extends RefCounted
	var values: Dictionary = {}
	var blocked: bool = false
	var fail_key: String = ""
	var writes: int = 0
	func request(op: Dictionary) -> Dictionary:
		if blocked:
			return {"ok": false, "error": "Browser profile storage unavailable: SecurityError."}
		if op.action == "read":
			return {"ok": true, "primary": values.get(WebStoreScript.PRIMARY_KEY), "backup": values.get(WebStoreScript.BACKUP_KEY), "hero": values.get(WebStoreScript.HERO_KEY), "motion": values.get(WebStoreScript.MOTION_KEY)}
		if op.key == fail_key:
			return {"ok": false, "error": "Browser profile storage unavailable: QuotaExceededError."}
		writes += 1
		values[op.key] = op.value
		return {"ok": true}

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)

func store(fake: FakeBrowser) -> RefCounted:
	var result = WebStoreScript.new()
	result.bridge = fake.request
	return result

func profile(fake: FakeBrowser) -> Node:
	var result = SaveStoreScript.new()
	result.profile_path = folder + "/profile.json"
	result.legacy_path = folder + "/absent.dat"
	result.legacy_config_path = folder + "/absent.cfg"
	result.browser_store = store(fake)
	return result

func write_file(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()

func _run() -> void:
	folder = "user://web_profile_test_%s" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var fake := FakeBrowser.new()
	fake.values["unrelated-app"] = "never touched"
	var web = store(fake)
	var loaded: Dictionary = web.load_profile()
	check(loaded.migration_allowed and loaded.raw.is_empty(), "Absent browser slots permit one migration")
	check(web.save_profile({"schema_version": 2, "hero": "bolt", "xp": 30}), "First synchronous browser save succeeds")
	check(fake.values.has(WebStoreScript.PRIMARY_KEY) and fake.values.has(WebStoreScript.BACKUP_KEY), "First save creates both app copies")
	check(web.load_profile().raw.hero == "bolt", "Immediate fresh load reads primary")
	check(web.save_profile({"schema_version": 2, "hero": "echo", "xp": 60}), "Updated save succeeds")
	check(JSON.parse_string(fake.values[WebStoreScript.BACKUP_KEY]).hero == "bolt", "Backup holds previous valid primary")
	fake.values[WebStoreScript.PRIMARY_KEY] = "{broken"
	loaded = web.load_profile()
	check(web.recovered_from_backup and loaded.raw.hero == "bolt", "Corrupt primary falls back to backup")
	check(web.save_profile({"schema_version": 2, "hero": "frost"}), "Recovery repairs primary")
	check(JSON.parse_string(fake.values[WebStoreScript.BACKUP_KEY]).hero == "bolt", "Repair never rotates corrupted primary over backup")
	fake.values[WebStoreScript.PRIMARY_KEY] = "[]"
	fake.values[WebStoreScript.BACKUP_KEY] = "null"
	loaded = web.load_profile()
	check(not loaded.migration_allowed and loaded.raw.is_empty(), "Existing corrupt slots cannot reimport stale file profile")
	check(not web.save_profile({"schema_version": 2.5}), "Fractional versions rejected")
	check(not web.save_profile({"schema_version": "2"}), "String versions rejected")
	check(not web.save_profile({"schema_version": 2, "oversized": "x".repeat(WebStoreScript.MAX_CHARACTERS)}), "Oversized saves rejected before writes")
	fake.values[WebStoreScript.PRIMARY_KEY] = JSON.stringify({"schema_version": 99, "hero": "future-hero", "unknown": "preserve"})
	var preserved: String = fake.values[WebStoreScript.PRIMARY_KEY]
	loaded = web.load_profile()
	check(web.future_version and loaded.raw.unknown == "preserve", "Future primary remains authoritative")
	check(not web.save_profile({"schema_version": 2}) and fake.values[WebStoreScript.PRIMARY_KEY] == preserved, "Future schema is never overwritten")
	fake.values[WebStoreScript.PRIMARY_KEY] = JSON.stringify({"schema_version": 2, "hero": "dart"})
	fake.values.erase(WebStoreScript.BACKUP_KEY)
	web = store(fake)
	web.load_profile()
	fake.values[WebStoreScript.PRIMARY_KEY] = preserved
	check(not web.save_profile({"schema_version": 2}), "Another tab's future schema blocks an already loaded writer")
	fake.values[WebStoreScript.PRIMARY_KEY] = "broken"
	fake.values[WebStoreScript.BACKUP_KEY] = preserved
	web = store(fake)
	check(web.load_profile().raw.unknown == "preserve" and web.recovered_from_backup and web.future_version, "Future backup recovery is read only")
	fake.values[WebStoreScript.PRIMARY_KEY] = JSON.stringify({"schema_version": 2})
	web = store(fake)
	web.load_profile()
	check(not web.save_profile({"schema_version": 2}), "Future backup cannot be downgraded by a current primary")
	fake.values.clear()
	fake.blocked = true
	web = store(fake)
	check(web.load_profile().blocked and web.last_error.contains("SecurityError"), "Blocked reads expose meaningful error")
	check(not web.save_profile({"schema_version": 2}) and fake.writes > 0, "Blocked writes return false")
	fake.blocked = false
	fake.fail_key = WebStoreScript.PRIMARY_KEY
	web = store(fake)
	check(not web.save_profile({"schema_version": 2, "hero": "echo"}) and web.last_error.contains("QuotaExceededError"), "Quota failure returns false")
	check(web.load_profile().raw.hero == "echo" and web.recovered_from_backup, "Interrupted first primary write retains recoverable backup")
	fake.fail_key = ""
	fake.values.clear()
	write_file(folder + "/profile.json", {"schema_version": 2, "hero": "frost", "xp": 87, "favorites": ["old_game"], "settings": {"volume": 37}})
	fake.values[WebStoreScript.HERO_KEY] = "bolt"
	fake.values[WebStoreScript.MOTION_KEY] = "true"
	var user_profile = profile(fake)
	user_profile.load_profile()
	check(user_profile.uses_browser_profile(), "Injected browser store is isolated from native path")
	check(user_profile.data.hero == "bolt" and user_profile.data.settings.reduced_motion, "One-time roster migration preserves last equipped hero and motion")
	check(user_profile.data.xp == 87 and user_profile.data.settings.volume == 37 and user_profile.data.favorites == ["old_game"], "Existing file profile migrates all other progress")
	user_profile.equip_hero("echo")
	user_profile.data.settings.volume = 24.0
	user_profile.data.settings.shake = false
	user_profile.data.settings.reduced_motion = false
	user_profile.toggle_favorite("target_lock")
	user_profile.record_game("target_lock", true, 321, "Aim")
	var expected: Dictionary = user_profile.data.duplicate(true)
	user_profile.free()
	# A fresh helper/profile simulates full runtime destruction, with stale old keys.
	user_profile = profile(fake)
	user_profile.load_profile()
	check(user_profile.data.hero == "echo" and not user_profile.data.settings.reduced_motion, "Stale roster keys never override full browser profile")
	check(user_profile.data.records.target_lock.best == 321 and user_profile.data.records.target_lock.plays == 1 and user_profile.data.xp == 117, "Fresh load restores completed-game records and earned XP")
	check(user_profile.data.favorites == expected.favorites and user_profile.data.settings == expected.settings, "Fresh load restores favorites and every setting")
	write_file(folder + "/profile.json", {"schema_version": 2, "hero": "dart", "xp": 0})
	user_profile.load_profile()
	check(user_profile.data.xp == 117 and user_profile.data.hero == "echo", "Browser primary remains authoritative over older virtual file")
	fake.values[WebStoreScript.PRIMARY_KEY] = JSON.stringify({"schema_version": 2, "xp": [], "hero": {}, "settings": {"volume": -12, "shake": "yes"}, "favorites": [true, "target_lock", "target_lock"], "records": {"bad": [], "target_lock": {"stars": 99, "wins": "bad"}}})
	user_profile.load_profile()
	check(user_profile.data.hero == "dart" and user_profile.data.xp == 0 and user_profile.data.settings.volume == 0 and user_profile.data.settings.shake, "Browser path shares Profile numeric/settings sanitation")
	check(user_profile.data.favorites == ["target_lock"] and user_profile.data.records.target_lock.stars == 3 and not user_profile.data.records.has("bad"), "Browser path sanitizes nested records and duplicate arrays")
	fake.blocked = true
	check(not user_profile.equip_hero("bolt") and user_profile.data.hero == "dart" and user_profile.last_error.contains("SecurityError"), "Blocked equip fails and restores previously equipped hero")
	user_profile.free()
	fake.blocked = false
	fake.values.clear()
	write_file(folder + "/profile.json", {"schema_version": 99, "xp": 888})
	user_profile = profile(fake)
	user_profile.load_profile()
	check(not user_profile.save_profile() and not fake.values.has(WebStoreScript.PRIMARY_KEY) and user_profile.data.xp == 888, "Future virtual profile migration remains read only")
	user_profile.free()
	var native = SaveStoreScript.new()
	native.profile_path = folder + "/native.json"
	native.legacy_path = folder + "/absent.dat"
	native.legacy_config_path = folder + "/absent.cfg"
	check(not native.uses_browser_profile(), "Native and --test instances retain isolated atomic file saves")
	native.load_profile()
	check(native.save_profile() and FileAccess.file_exists(native.profile_path), "Native file save still succeeds")
	native.free()
	for filename: String in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(folder.path_join(filename)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(folder))
	print("WEB PROFILE: %s checks, %s failures" % [checks, failures])
	quit(1 if failures else 0)
