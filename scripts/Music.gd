extends Node
## Two players let character previews crossfade without restarting every scene.
const Catalog = preload("res://scripts/HeroCatalog.gd")
var players: Array[AudioStreamPlayer] = []
var active := 0
var current_hero := ""
var mood := "menu"
var fade: Tween

func _ready() -> void:
	for index in range(2):
		var player := AudioStreamPlayer.new()
		player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		player.volume_db = -60
		add_child(player)
		players.append(player)

func play_theme(id: String, next_mood: String = "menu") -> void:
	if players.is_empty():
		return
	mood = next_mood
	var target_db := -17.0 if mood == "mission" else -13.0
	if mood == "death":
		target_db = -22.0
	id = Catalog.valid_id(id)
	if fade:
		fade.kill()
	fade = create_tween().set_parallel(true)
	if current_hero != id:
		var old := active
		active = 1 - active
		players[active].stop()
		players[active].stream = load("res://assets/audio/heroes/" + id + ".wav")
		if players[active].stream is AudioStreamWAV:
			players[active].stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			players[active].stream.loop_end = players[active].stream.data.size() / 2
		players[active].volume_db = -60
		# Headless exports have no audio device. Still load/configure tracks for
		# validation, but leave real playback to the windowed/browser build.
		if DisplayServer.get_name() != "headless":
			players[active].play()
		current_hero = id
		fade.tween_property(players[old], "volume_db", -60.0, 0.4)
		fade.chain().tween_callback(players[old].stop)
	fade.tween_property(players[active], "volume_db", target_db, 0.4)
	fade.tween_property(players[active], "pitch_scale", 0.85 if mood == "death" else (1.04 if mood == "mission" else 1.0), 0.4)

func stop_music() -> void:
	if fade:
		fade.kill()
		fade = null
	for player in players:
		player.stop()
		player.stream = null
	current_hero = ""

func _exit_tree() -> void:
	stop_music()
