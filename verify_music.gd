extends Node
## Headless verification for the Music autoload.
##
## Run as a real main scene (`godot --headless res://verify_music.tscn`) so the
## autoloads resolve -- a bare SceneTree script cannot see Global or Music.
## Exits the process with a non-zero code if anything fails.

var _checks := 0
var _failed := 0

func _ready() -> void:
	_run()

func _check(label: String, ok: bool, detail: String = "") -> void:
	_checks += 1
	if ok:
		print("  PASS  %s  %s" % [label, detail])
	else:
		_failed += 1
		print("  FAIL  %s  %s" % [label, detail])

func _playing_voice() -> AudioStreamPlayer:
	for child in Music.get_children():
		if child is AudioStreamPlayer and child.playing:
			return child
	return null

func _playing_count() -> int:
	var n := 0
	for child in Music.get_children():
		if child is AudioStreamPlayer and child.playing:
			n += 1
	return n

func _run() -> void:
	print("\n=== MUSIC VERIFICATION ===")

	await _verify_bus()
	await _verify_loops()
	await _verify_retarget()
	await _verify_one_shot()
	await _verify_stop()
	_verify_trim()
	_verify_persistence()

	print("\n--- %d checks, %d failed ---" % [_checks, _failed])
	get_tree().quit(1 if _failed > 0 else 0)

## The Music bus must exist and feed Master, or the slider addresses nothing.
func _verify_bus() -> void:
	var idx := AudioServer.get_bus_index(Global.MUSIC_BUS)
	_check("Music bus exists", idx != -1, "index=%d" % idx)
	if idx == -1:
		return
	var send := AudioServer.get_bus_send(idx)
	_check("Music sends to Master", send == "Master", send)

## Imported WAVs are all loop_mode=0, so Music must flip the three loopers.
## The tracks import with compress/mode=2 (QOA), so data.size() is compressed
## bytes and cannot be used to derive a frame count.
func _verify_loops() -> void:
	for track in ["title", "gauntlet", "danger"]:
		var stream := load("res://assets/audio/music_%s.wav" % track) as AudioStreamWAV
		_check("%s imported non-looping" % track,
			stream.loop_mode == AudioStreamWAV.LOOP_DISABLED,
			"importer mode=%d" % stream.loop_mode)
		Music.play(track, 0.0)
		await get_tree().process_frame
		# get_length() is the only API that accounts for the compression mode.
		var frames := int(round(stream.get_length() * stream.mix_rate))
		print("    [%s] data=%d B  format=%d stereo=%s rate=%d  len=%.3f s  frames=%d" % [
			track, stream.data.size(), stream.format, str(stream.stereo),
			stream.mix_rate, stream.get_length(), frames])
		_check("%s loops forward" % track,
			stream.loop_mode == AudioStreamWAV.LOOP_FORWARD,
			"mode=%d" % stream.loop_mode)
		_check("%s loop_end spans the whole clip" % track,
			stream.loop_end == frames,
			"loop_end=%d frames=%d" % [stream.loop_end, frames])

## Same-track play must re-trim in place. A restart would build a new voice and
## stop the old one, so the identity of the playing player is the tell.
func _verify_retarget() -> void:
	Music.play("title", 0.0, -8.0)
	await get_tree().process_frame
	var before := _playing_voice()
	_check("title playing before retarget", before != null)
	if before == null:
		return
	Music.play("title", 0.0, -14.0)
	await get_tree().process_frame
	var after := _playing_voice()
	_check("retarget reuses the same voice", before == after,
		"same=%s" % str(before == after))
	_check("retarget re-trims to -14 dB", is_equal_approx(after.volume_db, -14.0),
		"volume_db=%.2f" % after.volume_db)
	_check("retarget keeps one voice alive", _playing_count() == 1,
		"count=%d" % _playing_count())

## The intermission sting must not loop, or it would never end.
func _verify_one_shot() -> void:
	Music.play("intermission", 0.0)
	await get_tree().process_frame
	var sting := load("res://assets/audio/music_intermission.wav") as AudioStreamWAV
	_check("intermission stays one-shot",
		sting.loop_mode == AudioStreamWAV.LOOP_DISABLED,
		"mode=%d" % sting.loop_mode)
	_check("intermission is the current track",
		Music.current_track() == "intermission", Music.current_track())

func _verify_stop() -> void:
	Music.stop(0.0)
	await get_tree().process_frame
	_check("stop halts playback", not Music.is_playing())
	_check("stop clears the current track", Music.current_track() == "",
		"'%s'" % Music.current_track())
	_check("stop releases every voice", _playing_count() == 0,
		"count=%d" % _playing_count())

## The slider must reach the Music bus without touching Master, and must mute
## cleanly at zero instead of going to -inf.
func _verify_trim() -> void:
	var idx := AudioServer.get_bus_index(Global.MUSIC_BUS)
	if idx == -1:
		return
	var master_before := AudioServer.get_bus_volume_db(0)
	var original := Global.music_volume

	Global.music_volume = 25.0
	Global._apply_music_volume()
	_check("25% maps to -12.04 dB on Music",
		is_equal_approx(AudioServer.get_bus_volume_db(idx), linear_to_db(0.25)),
		"%.3f dB" % AudioServer.get_bus_volume_db(idx))
	_check("Music slider leaves Master alone",
		is_equal_approx(AudioServer.get_bus_volume_db(0), master_before),
		"master=%.3f dB" % AudioServer.get_bus_volume_db(0))

	Global.music_volume = 0.0
	Global._apply_music_volume()
	_check("0% silences rather than -inf",
		AudioServer.get_bus_volume_db(idx) <= -79.9,
		"%.1f dB" % AudioServer.get_bus_volume_db(idx))

	Global.music_volume = original
	Global._apply_music_volume()

## Round-trips through the real save file, with the player's own save backed up
## and restored so a headless run cannot clobber stored progress.
func _verify_persistence() -> void:
	var path := ProjectSettings.globalize_path(Global.SAVE_PATH)
	var had_save := FileAccess.file_exists(path)
	var backup := FileAccess.get_file_as_string(path) if had_save else ""
	var original := Global.music_volume

	Global.music_volume = 33.0
	Global.save()
	Global.music_volume = 0.0
	Global.load_save()
	_check("music_volume survives save/load",
		is_equal_approx(Global.music_volume, 33.0),
		"got %.1f" % Global.music_volume)

	if had_save:
		var restore := FileAccess.open(Global.SAVE_PATH, FileAccess.WRITE)
		if restore != null:
			restore.store_string(backup)
	elif FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

	Global.music_volume = original
	_check("original music_volume restored in memory",
		is_equal_approx(Global.music_volume, original),
		"%.1f" % Global.music_volume)
