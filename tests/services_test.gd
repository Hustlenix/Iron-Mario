extends SceneTree

const SaveStoreScript = preload("res://core/save_store.gd")
const RunScript = preload("res://core/run_director.gd")
const PlatformScript = preload("res://core/platform_services.gd")
var failures: int = 0
var checks: int = 0
var folder: String = ""

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)

func write_file(path: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func _run() -> void:
	folder = "user://services_test_%s" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var profile = SaveStoreScript.new()
	profile.profile_path = folder + "/profile.json"
	profile.legacy_path = folder + "/save.dat"
	var original: String = JSON.stringify({"selected_hero": "frost", "volume": 42, "music_volume": 21, "best_streak": 17, "flappy_best": 29, "low_quality": true, "touch_controls_enabled": false})
	write_file(profile.legacy_path, original)
	profile.load_profile()
	check(profile.data.hero == "frost", "Migrates selected hero")
	check(profile.data.settings.volume == 42 and profile.data.settings.music_volume == 21, "Migrates independent volumes")
	check(profile.data.best_streak == 17 and profile.data.records.flappy.best == 29, "Migrates legacy streak and Flappy score")
	check(profile.data.settings.low_quality and not profile.data.settings.touch_controls_enabled, "Migrates legacy device settings")
	check(FileAccess.get_file_as_string(profile.legacy_path) == original, "Legacy source remains untouched")
	check(profile.save_profile(), "Atomically replaces existing file")
	check(FileAccess.file_exists(profile.profile_path + ".bak"), "Creates backup")
	profile.data.coins = 321
	check(profile.save_profile(), "Saves updated profile")
	profile.load_profile()
	check(profile.data.coins == 321, "Round trips v2 profile")
	write_file(profile.profile_path, "{broken json")
	profile.load_profile()
	check(profile.recovered_from_backup, "Recovers corrupt profile from backup")
	check(profile.data.hero == "frost", "Recovery preserves prior valid data")
	check(FileAccess.get_file_as_string(profile.legacy_path) == original, "Recovery does not overwrite legacy")
	write_file(profile.profile_path, "corrupt primary")
	write_file(profile.profile_path + ".bak", "corrupt backup")
	profile.load_profile()
	check(not profile.recovered_from_backup and profile.data.hero == "frost", "Both corrupt copies fall back to intact legacy")
	profile.legacy_path = folder + "/absent_legacy.dat"
	profile.load_profile()
	check(profile.data.hero == "dart" and profile.data.total_plays == 0, "Corrupt save without legacy falls back to playable defaults")
	check(profile.save_profile(), "Default recovery can replace corrupt save")
	profile.legacy_path = folder + "/save.dat"
	# Nested bad types must fall back without invalid casts or crashes.
	write_file(profile.profile_path, JSON.stringify({"schema_version": 2, "xp": [], "coins": "999", "hero": {}, "records": {"bad": [], "safe": {"wins": "oops", "stars": 99, "best": -1}}, "mastery": {"dart": []}, "settings": {"volume": {}, "music_volume": -30, "shake": "false"}, "favorites": [true, "a", "a", {}], "daily": {"date": Time.get_date_string_from_system(true), "heroes": {}, "wins": []}, "owned": null, "onboarded": "true"}))
	profile.load_profile()
	check(profile.data.xp == 0 and profile.data.coins == 0 and profile.data.hero == "dart", "Sanitizes numeric and hero types")
	check(profile.data.settings.volume == 80 and profile.data.settings.music_volume == 0 and profile.data.settings.shake, "Sanitizes settings types and ranges")
	check(profile.data.favorites == ["a"] and profile.data.records.safe.stars == 3 and not profile.data.records.has("bad"), "Sanitizes arrays and nested records")
	check(not profile.data.onboarded and profile.data.owned == ["classic"], "Restores mandatory defaults")
	check(not profile.claim_mission("wins_5"), "Cannot claim unearned mission")
	for i: int in range(10):
		profile.equip_hero(["dart", "bolt", "echo"][i % 3])
		profile.record_game("test_%s" % (i % 4), i < 5, 100 + i, "Timing")
	check(profile.data.total_plays == 10 and profile.data.total_wins == 5, "Tracks actual plays and wins")
	check(profile.data.mastery.size() >= 3 and profile.data.heroes_used.size() == 3, "Tracks used heroes")
	check(profile.claim_mission("wins_5") and profile.claim_mission("plays_10") and profile.claim_mission("heroes_3"), "Claims all three earned daily missions")
	var coins: int = profile.data.coins
	check(not profile.claim_mission("wins_5") and profile.data.coins == coins, "Mission cannot pay twice")
	profile.data.daily.date = "2000-01-01"
	var reset_missions: Array[Dictionary] = profile.mission_progress()
	check(reset_missions[0].progress == 0 and not reset_missions[0].claimed and profile.data.daily.heroes.is_empty(), "New UTC day resets missions and claims")
	profile.toggle_favorite("test_0")
	check("test_0" in profile.data.favorites, "Adds favorite")
	profile.toggle_favorite("test_0")
	check("test_0" not in profile.data.favorites, "Removes favorite")
	profile.data.coins = 200
	check(not profile.buy_cosmetic("midnight", -1) and not profile.buy_cosmetic("unknown", 0), "Rejects invalid cosmetic transactions")
	check(profile.buy_cosmetic("midnight", 180) and profile.data.coins == 20 and profile.data.equipped_cosmetic == "midnight", "Cosmetic purchase deducts earned coins")
	check(not profile.buy_cosmetic("midnight", 180) and not profile.buy_cosmetic("sunshine", 180), "Rejects duplicate and unaffordable purchases")
	profile.finish_run("tournament", 2345, 23)
	profile.load_profile()
	check(profile.data.tournament_best == 2345 and profile.data.best_streak == 23, "Persists run records")
	write_file(profile.profile_path, JSON.stringify({"schema_version": 9, "coins": 777}))
	profile.load_profile()
	check(not profile.save_profile() and profile.data.coins == 777, "Never downgrades a future schema")
	profile.free()
	var config_profile = SaveStoreScript.new()
	config_profile.profile_path = folder+'/from_config.json'
	config_profile.legacy_path = folder+'/absent.dat'
	var legacy_config := ConfigFile.new()
	legacy_config.set_value('progress','best_streak',31)
	legacy_config.set_value('progress','high_score',4400)
	legacy_config.set_value('progress','total_clears',22)
	legacy_config.set_value('progress','flappy_best',45)
	legacy_config.set_value('profile','name','OLD PILOT')
	legacy_config.set_value('profile','hero_id','prism')
	legacy_config.set_value('settings','muted',true)
	legacy_config.save(folder+'/iron_mario_save.cfg')
	config_profile.load_profile()
	check(config_profile.data.hero=='pulse' and config_profile.data.legacy_profile.name=='OLD PILOT','Migrates deployed hero and preserves profile identity')
	check(config_profile.data.best_streak==31 and config_profile.data.tournament_best==4400 and config_profile.data.total_wins==22,'Migrates deployed records')
	check(config_profile.data.settings.volume==0 and config_profile.data.settings.music_volume==0,'Preserves deployed mute preference')
	check(config_profile.data.records.flappy_bonus.best==45,'Preserves deployed Flappy record')
	config_profile.save_profile()
	config_profile.load_profile()
	check(config_profile.data.legacy_profile.name=='OLD PILOT','Migrated identity survives reload')
	config_profile.free()
	_test_director()
	var services = PlatformScript.new()
	check(not services.analytics_enabled and not services.billing_available() and not services.rewarded_ads_available(), "Platform services disabled by default")
	check(not services.purchase("coins").ok and not services.show_rewarded_ad().rewarded, "No fake purchase or ad success")
	services.free()
	for filename: String in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(folder.path_join(filename)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(folder))
	print("SERVICES: %s checks, %s failures" % [checks, failures])
	quit(1 if failures else 0)

func _test_director() -> void:
	var ids: Array = ["a", "b", "c", "d"]
	var daily: Array = RunScript.daily_ids(ids, "2026-09-27")
	check(daily.size() == 10 and daily == RunScript.daily_ids(ids, "2026-09-27"), "Daily schedule is deterministic")
	check(daily == RunScript.daily_ids(["d", "c", "b", "a"], "2026-09-27"), "Daily ignores catalog order")
	check(daily != RunScript.daily_ids(ids, "2026-09-28"), "Daily rotates by date")
	for index: int in range(1, daily.size()):
		check(daily[index] != daily[index - 1], "Daily has no consecutive duplicate")
	var director = RunScript.new()
	for session: int in range(3):
		director.begin("tournament", ids)
		check(director.lives == 5 and director.score == 0 and director.round_index == 0 and director.streak == 0 and director.difficulty == 1.0 and not director.finished, "Tournament restarts cleanly")
		var previous: String = ""
		for round_number: int in range(15):
			var id: String = director.next_id()
			check(id != previous and id in ids and id == director.next_id(), "Random bag avoids repeat and repeated query is stable")
			check(director.special_round == ((round_number + 1) % 10 == 0), "Special every tenth round")
			if round_number == 5:
				check(director.difficulty > 1.0, "Difficulty rises after five rounds")
			director.submit(true, 100)
			previous = id
		check(director.score == 3000 and director.best_streak == 15, "Score multiplier and streak accumulate")
		for loss: int in range(5):
			director.next_id()
			director.submit(false, -50)
		check(director.finished and director.lives == 0 and director.streak == 0 and director.score == 3000, "Five failures end tournament and negative scores ignored")
		director.submit(true, 999)
		check(director.score == 3000 and director.next_id().is_empty(), "Completed run ignores late results")
	director.begin("daily", ids, "2026-09-27")
	for index: int in range(10):
		check(director.next_id() == daily[index], "Daily plays generated schedule in order")
		director.submit(true, 10)
	check(director.finished and director.round_index == 10 and director.score == 100, "Daily ends after ten games")
	director.begin("practice", ["a"])
	check(director.next_id() == "a", "Single-entry pool works")
	director.submit(false, 0)
	check(director.finished and director.lives == 4, "Practice ends after one game")
	director.begin("tournament", [])
	check(director.finished and director.next_id().is_empty(), "Empty catalog finishes safely")
