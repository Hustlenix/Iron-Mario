extends Node
## Autoloaded music director.
##
## Owns a small pool of AudioStreamPlayers so scene changes can crossfade
## between tracks without tearing down audio nodes, and so that asking for the
## track that is already playing is a no-op rather than a restart. The interlude
## sting is a one-shot; the three loops are flagged at runtime because the
## importer leaves WAV looping off.

const TRACK_PATHS := {
	"title": "res://assets/audio/music_title.wav",
	"gauntlet": "res://assets/audio/music_gauntlet.wav",
	"danger": "res://assets/audio/music_danger.wav",
	"intermission": "res://assets/audio/music_intermission.wav",
}

## Tracks that loop seamlessly. The intermission sting must not loop.
const LOOPING := ["title", "gauntlet", "danger"]

const DEFAULT_FADE := 1.0
## Low enough to be inaudible, high enough to keep tween math away from -inf.
const SILENT_DB := -60.0
## title + one crossfade target + one more is the deepest overlap we ever need.
const POOL_SIZE := 3


class Voice extends RefCounted:
	var player: AudioStreamPlayer
	var track: String = ""
	var offset_db: float = 0.0
	var tween: Tween

	func _init(p: AudioStreamPlayer) -> void:
		player = p


var _pool: Array[AudioStreamPlayer] = []
var _voices: Array[Voice] = []
var _streams: Dictionary = {}
var _current: Voice = null


func _ready() -> void:
	# Autoloads default to inheriting, which would freeze crossfades on a paused
	# tree; music should ride through pause anyway.
	process_mode = Node.PROCESS_MODE_ALWAYS
	if AudioServer.get_bus_index("Music") == -1:
		push_warning("Music bus missing; music will play on Master. Check default_bus_layout.tres.")
	for i in POOL_SIZE:
		_pool.append(_make_player())


## Crossfade to `track`. If it is already playing, only the trim is retargeted so
## the melody is never cut off. `offset_db` is a per-request trim in decibels on
## top of the Music bus, used to duck one scene relative to another.
func play(track: String, fade: float = DEFAULT_FADE, offset_db: float = 0.0) -> void:
	if not TRACK_PATHS.has(track):
		push_warning("Music.play: unknown track '%s'" % track)
		return
	if _current != null and is_instance_valid(_current) and _current.track == track:
		_retarget(_current, offset_db, fade)
		return
	var stream := _stream_for(track)
	if stream == null:
		return

	var voice := Voice.new(_acquire_player())
	voice.track = track
	voice.offset_db = offset_db
	voice.player.stream = stream
	voice.player.volume_db = SILENT_DB
	voice.player.play()
	_voices.append(voice)

	var outgoing := _current
	_current = voice
	_voice_to(voice, offset_db, fade)
	if outgoing != null:
		_voice_to(outgoing, SILENT_DB, fade)


## Fade everything out. `stop(0.0)` cuts immediately.
func stop(fade: float = DEFAULT_FADE) -> void:
	_current = null
	for voice in _voices.duplicate():
		_voice_to(voice, SILENT_DB, fade)


func current_track() -> String:
	if _current == null or not is_instance_valid(_current):
		return ""
	return _current.track


func is_playing() -> bool:
	return _current != null and is_instance_valid(_current) and _current.player.playing


## Duck the live voice without touching the track, e.g. while a minigame starts.
func set_trim(offset_db: float, fade: float = 0.4) -> void:
	if _current == null or not is_instance_valid(_current):
		return
	_retarget(_current, offset_db, fade)


func _retarget(v: Voice, offset_db: float, fade: float) -> void:
	if is_zero_approx(offset_db - v.offset_db):
		return
	v.offset_db = offset_db
	_voice_to(v, offset_db, fade)


## Drives a voice's volume toward `target_db`; reaching SILENT_DB parks it.
func _voice_to(v: Voice, target_db: float, seconds: float) -> void:
	if not is_instance_valid(v.player):
		return
	if v.tween != null and v.tween.is_valid():
		v.tween.kill()
		v.tween = null
	if seconds <= 0.0:
		v.player.volume_db = target_db
		if target_db <= SILENT_DB:
			_settle(v, target_db)
		return
	v.tween = create_tween()
	# Sine ease is what makes a crossfade read as music rather than a volume ramp.
	v.tween.tween_property(v.player, "volume_db", target_db, seconds) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	v.tween.tween_callback(_settle.bind(v, target_db))


func _settle(v: Voice, target_db: float) -> void:
	if target_db > SILENT_DB or not is_instance_valid(v.player):
		return
	v.player.stop()
	v.player.stream = null
	_release(v)


func _release(v: Voice) -> void:
	if v.tween != null and v.tween.is_valid():
		v.tween.kill()
	v.tween = null
	_voices.erase(v)
	if is_instance_valid(v.player) and not _pool.has(v.player):
		_pool.append(v.player)


func _make_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Music"
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(p)
	return p


func _acquire_player() -> AudioStreamPlayer:
	if _pool.is_empty():
		return _make_player()
	return _pool.pop_back()


## Imported WAVs arrive with looping off, so switch it on here for the three
## seamless loops and leave the sting one-shot.
func _stream_for(track: String) -> AudioStream:
	if _streams.has(track):
		return _streams[track]
	var path: String = TRACK_PATHS[track]
	if not ResourceLoader.exists(path):
		push_warning("Music: missing stream %s" % path)
		_streams[track] = null
		return null
	var stream: AudioStream = load(path)
	if stream is AudioStreamWAV and LOOPING.has(track):
		var wav := stream as AudioStreamWAV
		# These import with compress/mode=2 (QOA), so data.size() is a count of
		# *compressed* bytes and cannot be divided into a frame count. Dividing
		# it anyway put loop_end about a fifth of the way into each track, which
		# loops audibly early. get_length() is the only size that accounts for
		# the codec, and loop_end is expressed in source frames.
		var frames := int(round(wav.get_length() * wav.mix_rate))
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = maxi(1, frames)
	_streams[track] = stream
	return stream
