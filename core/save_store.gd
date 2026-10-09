extends Node
## Versioned local profile. Legacy save.dat is read only and never replaced.

signal profile_changed
const VERSION: int = 2
const HERO_IDS: Array[String] = ["dart", "bolt", "echo", "frost", "tether", "snap", "aegis", "pulse", "lance", "flappy"]
const COSMETICS: Dictionary = {"confetti": 100, "midnight": 180, "sunshine": 180}
var profile_path: String = "user://profile_v2.json"
var legacy_path: String = "user://save.dat"
var legacy_config_path: String = ""
var data: Dictionary = {}
var last_error: String = ""
var recovered_from_backup: bool = false
var _future_version: bool = false

func _ready() -> void:
	if '--test' in OS.get_cmdline_user_args():
		data = _defaults()
		_refresh_daily()
		return
	load_profile()

func _defaults() -> Dictionary:
	return {"schema_version": VERSION, "xp": 0, "coins": 0, "hero": "dart", "mastery": {}, "records": {}, "favorites": [], "recent": [], "settings": {"volume": 80.0, "music_volume": 70.0, "shake": true, "haptics": true, "touch_controls_enabled": true, "low_quality": false}, "achievements": [], "daily": {}, "tournament_best": 0, "best_streak": 0, "total_wins": 0, "total_plays": 0, "owned": ["classic"], "equipped_cosmetic": "classic", "onboarded": false, "heroes_used": [], "flappy_best": 0}

func _number(value: Variant, fallback: float = 0.0) -> float:
	if (value is int or value is float) and is_finite(float(value)):
		return clampf(float(value), 0.0, 1000000000.0)
	return fallback

func _strings(value: Variant, maximum: int = 200) -> Array:
	var result: Array = []
	if value is Array:
		for item: Variant in value:
			if item is String and not item.is_empty() and item.length() <= 100 and item not in result:
				result.append(item)
				if result.size() >= maximum:
					break
	return result

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser: JSON = JSON.new()
	var parse_error: Error = parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		return {}
	var parsed: Variant = parser.data
	return parsed if parsed is Dictionary else {}

func _is_profile(raw: Dictionary) -> bool:
	return int(_number(raw.get("schema_version"))) >= VERSION

func load_profile() -> void:
	last_error = ""
	recovered_from_backup = false
	_future_version = false
	var raw: Dictionary = _read(profile_path)
	if not _is_profile(raw):
		raw = _read(profile_path + ".bak")
		recovered_from_backup = _is_profile(raw)
	data = _defaults()
	if _is_profile(raw):
		_future_version = int(_number(raw.get("schema_version"))) > VERSION
		_sanitize(raw)
	else:
		_migrate(_read(legacy_path))
		_migrate_config()
	_refresh_daily()
	if _future_version:
		last_error = "This profile was saved by a newer version; saving is disabled."
	elif not FileAccess.file_exists(profile_path) or recovered_from_backup:
		save_profile()
	profile_changed.emit()

func _sanitize(raw: Dictionary) -> void:
	if raw.get('legacy_profile') is Dictionary: data['legacy_profile'] = raw.legacy_profile.duplicate(true)
	for key: String in ["xp", "coins", "tournament_best", "best_streak", "total_wins", "total_plays", "flappy_best"]:
		data[key] = int(_number(raw.get(key)))
	var saved_hero: Variant = raw.get("hero", "dart")
	data.hero = saved_hero if saved_hero is String and saved_hero in HERO_IDS else "dart"
	data.onboarded = raw.get("onboarded", false) if raw.get("onboarded") is bool else false
	for key: String in ["favorites", "recent", "achievements", "owned", "heroes_used"]:
		data[key] = _strings(raw.get(key), 20 if key == "recent" else 200)
	if "classic" not in data.owned:
		data.owned.append("classic")
	var equipped: Variant = raw.get("equipped_cosmetic", "classic")
	data.equipped_cosmetic = equipped if equipped is String and equipped in data.owned else "classic"
	var settings: Variant = raw.get("settings")
	if settings is Dictionary:
		for key: String in ["volume", "music_volume"]:
			data.settings[key] = clampf(_number(settings.get(key), data.settings[key]), 0.0, 100.0)
		for key: String in ["shake", "haptics", "touch_controls_enabled", "low_quality", "reduced_motion"]:
			if settings.get(key) is bool:
				data.settings[key] = settings[key]
	var mastery: Variant = raw.get("mastery")
	if mastery is Dictionary:
		for id: String in HERO_IDS:
			data.mastery[id] = int(_number(mastery.get(id)))
	var records: Variant = raw.get("records")
	if records is Dictionary:
		for id: Variant in records:
			if id is String and records[id] is Dictionary:
				var source: Dictionary = records[id]
				data.records[id] = {"best": int(_number(source.get("best"))), "plays": int(_number(source.get("plays"))), "wins": int(_number(source.get("wins"))), "stars": mini(3, int(_number(source.get("stars")))), "category": source.get("category", "") if source.get("category", "") is String else ""}
	var daily: Variant = raw.get("daily")
	if daily is Dictionary and daily.get("date") is String:
		data.daily = {"date": daily.date, "wins": int(_number(daily.get("wins"))), "plays": int(_number(daily.get("plays"))), "heroes": _strings(daily.get("heroes")), "claimed": _strings(daily.get("claimed")), "best": int(_number(daily.get("best"))), "completed": int(_number(daily.get("completed")))}

func _migrate(legacy: Dictionary) -> void:
	if legacy.is_empty():
		return
	data.best_streak = int(_number(legacy.get("best_streak")))
	data.flappy_best = int(_number(legacy.get("flappy_best")))
	if legacy.get("selected_hero") is String and legacy.selected_hero in HERO_IDS:
		data.hero = legacy.selected_hero
	for key: String in ["volume", "music_volume"]:
		data.settings[key] = clampf(_number(legacy.get(key), data.settings[key]), 0.0, 100.0)
	for key: String in ["touch_controls_enabled", "low_quality"]:
		if legacy.get(key) is bool:
			data.settings[key] = legacy[key]
	if data.flappy_best > 0:
		data.records["flappy"] = {"best": data.flappy_best, "plays": 0, "wins": 0, "stars": 0, "category": "Arcade"}

func _migrate_config() -> void:
	var config := ConfigFile.new()
	var source_path: String = legacy_config_path if legacy_config_path!='' else legacy_path.get_base_dir().path_join('iron_mario_save.cfg')
	if config.load(source_path) != OK: return
	data.best_streak = maxi(data.best_streak,int(_number(config.get_value('progress','best_streak',0))))
	data.flappy_best = maxi(data.flappy_best,int(_number(config.get_value('progress','flappy_best',0))))
	data.tournament_best = int(_number(config.get_value('progress','high_score',0)))
	data.total_wins = int(_number(config.get_value('progress','total_clears',0)))
	data.total_plays = data.total_wins
	data['legacy_profile'] = {'name':str(config.get_value('profile','name','PILOT')).substr(0,16),'hero':str(config.get_value('profile','hero_id','ember')),'reactor_style':int(_number(config.get_value('profile','reactor_style',0))),'highest_loop':int(_number(config.get_value('progress','highest_loop',1))),'tournaments_won':int(_number(config.get_value('progress','total_wins',0)))}
	var hero_map: Dictionary = {'ember':'dart','comet':'bolt','moon':'echo','tide':'frost','thread':'tether','copper':'snap','sun':'aegis','prism':'pulse','cipher':'lance'}
	data.hero = hero_map.get(data.legacy_profile.hero,'dart')
	data.settings.volume = clampf(_number(config.get_value('settings','volume',80)),0,100)
	if config.get_value('settings','muted',false) == true:
		data.settings.volume = 0
		data.settings.music_volume = 0
	if data.flappy_best>0:
		data.records['flappy_bonus'] = {'best':data.flappy_best,'plays':0,'wins':0,'stars':0,'category':'Flying'}

func save_profile() -> bool:
	if _future_version:
		return false
	var directory: String = ProjectSettings.globalize_path(profile_path).get_base_dir()
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		last_error = "Could not create profile directory."
		return false
	data.schema_version = VERSION
	var temporary: String = profile_path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_error = "Could not write profile."
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		last_error = "Could not flush profile."
		return false
	# Only rotate a readable profile, so recovering cannot replace a good backup with corruption.
	if _is_profile(_read(profile_path)):
		var backup_error: Error = DirAccess.copy_absolute(ProjectSettings.globalize_path(profile_path), ProjectSettings.globalize_path(profile_path + ".bak"))
		if backup_error != OK:
			last_error = "Could not back up profile."
			return false
	var replace_error: Error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(profile_path))
	if replace_error != OK:
		last_error = "Could not replace profile."
		return false
	last_error = ""
	return true

func _refresh_daily() -> void:
	var today: String = Time.get_date_string_from_system(true)
	if data.daily.get("date", "") != today:
		data.daily = {"date": today, "wins": 0, "plays": 0, "heroes": [], "claimed": [], "best": 0, "completed": 0}

func record_game(id: String, won: bool, score: int, category: String) -> Dictionary:
	_refresh_daily()
	var xp_reward: int = 30 if won else 10
	var coin_reward: int = 12 if won else 3
	var record: Dictionary = data.records.get(id, {"best": 0, "plays": 0, "wins": 0, "stars": 0})
	record.best = maxi(int(record.best), maxi(0, score))
	record.plays += 1
	record.wins += 1 if won else 0
	# Stars reflect repeated successful play rather than incomparable score scales.
	record.stars = 3 if record.wins >= 10 else (2 if record.wins >= 3 else (1 if record.wins >= 1 else 0))
	record.category = category
	data.records[id] = record
	data.xp += xp_reward
	data.coins += coin_reward
	data.total_plays += 1
	data.total_wins += 1 if won else 0
	data.mastery[data.hero] = int(data.mastery.get(data.hero, 0)) + xp_reward
	if data.hero not in data.heroes_used:
		data.heroes_used.append(data.hero)
	data.recent.erase(id)
	data.recent.push_front(id)
	data.recent.resize(mini(data.recent.size(), 20))
	data.daily.plays += 1
	data.daily.wins += 1 if won else 0
	if data.hero not in data.daily.heroes:
		data.daily.heroes.append(data.hero)
	var unlocked: Array = []
	for achievement: String in ["first_win", "ten_wins", "explorer", "hero_trio"]:
		var eligible: bool = {"first_win": data.total_wins >= 1, "ten_wins": data.total_wins >= 10, "explorer": data.records.size() >= 10, "hero_trio": data.heroes_used.size() >= 3}[achievement]
		if eligible and achievement not in data.achievements:
			data.achievements.append(achievement)
			unlocked.append(achievement)
	save_profile()
	profile_changed.emit()
	return {"xp": xp_reward, "coins": coin_reward, "stars": record.stars, "achievements": unlocked}

func toggle_favorite(id: String) -> void:
	if id in data.favorites:
		data.favorites.erase(id)
	else:
		data.favorites.append(id)
	save_profile()
	profile_changed.emit()

func equip_hero(id: String) -> bool:
	if id not in HERO_IDS:
		return false
	var previous: String=data.hero
	data.hero = id
	if not save_profile():
		data.hero=previous
		return false
	profile_changed.emit()
	return true

func buy_cosmetic(id: String, cost: int) -> bool:
	if not COSMETICS.has(id) or cost != int(COSMETICS[id]) or id in data.owned or int(data.coins) < cost:
		return false
	data.coins -= cost
	data.owned.append(id)
	data.equipped_cosmetic = id
	save_profile()
	profile_changed.emit()
	return true

func equip_cosmetic(id: String) -> bool:
	if id not in data.owned:
		return false
	data.equipped_cosmetic = id
	save_profile()
	profile_changed.emit()
	return true

func mission_progress() -> Array[Dictionary]:
	_refresh_daily()
	var missions: Array[Dictionary] = [
		{"id": "wins_5", "title": "Win 5 microgames", "progress": data.daily.wins, "target": 5, "reward": 60},
		{"id": "plays_10", "title": "Play 10 microgames", "progress": data.daily.plays, "target": 10, "reward": 50},
		{"id": "heroes_3", "title": "Play with 3 heroes", "progress": data.daily.heroes.size(), "target": 3, "reward": 75},
	]
	for mission: Dictionary in missions:
		mission.claimed = mission.id in data.daily.claimed
	return missions

func claim_mission(id: String) -> bool:
	for mission: Dictionary in mission_progress():
		if mission.id == id and not mission.claimed and mission.progress >= mission.target:
			data.daily.claimed.append(id)
			data.coins += mission.reward
			save_profile()
			profile_changed.emit()
			return true
	return false

func finish_run(run_mode: String, run_score: int, run_best_streak: int) -> void:
	data.best_streak = maxi(int(data.best_streak), run_best_streak)
	if run_mode.to_lower() == "tournament":
		data.tournament_best = maxi(int(data.tournament_best), run_score)
	elif run_mode.to_lower() == "daily":
		_refresh_daily()
		data.daily.best = maxi(int(data.daily.best), run_score)
		data.daily.completed += 1
	save_profile()
	profile_changed.emit()
