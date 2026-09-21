extends Node

# Original short PCM tones. Finite streams avoid generator underruns and overflow.
const MIX_RATE := 22050
var voices: Array[AudioStreamPlayer] = []
var tones: Dictionary = {}
var voice_index := 0

func _ready() -> void:
	for index in range(8):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)

func play_click() -> void:
	_chord([620.0], 0.055, 0.22)

func play_collect() -> void:
	_chord([880.0], 0.09, 0.26)

func play_success() -> void:
	_chord([660.0, 880.0, 1100.0], 0.22, 0.24)

func play_failure() -> void:
	_chord([220.0, 165.0], 0.25, 0.24)

func play_start() -> void:
	_chord([330.0, 495.0], 0.14, 0.18)

func play_countdown(step: int) -> void:
	_chord([920.0 if step <= 0 else 420.0 + float(step) * 70.0], 0.07, 0.18)

func _chord(frequencies: Array, duration: float, volume: float) -> void:
	if voices.is_empty() or Global.muted:
		return
	var key := str(frequencies) + str(duration) + str(volume)
	if not tones.has(key):
		var frame_count := int(MIX_RATE * duration)
		var data := PackedByteArray()
		data.resize(frame_count * 2)
		for frame in range(frame_count):
			var time := float(frame) / MIX_RATE
			var fade := minf(time / 0.005, 1.0) * (1.0 - float(frame) / frame_count)
			var sample := 0.0
			for frequency in frequencies:
				sample += sin(TAU * float(frequency) * time)
			data.encode_s16(frame * 2, int(sample / frequencies.size() * volume * fade * 32767.0))
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = MIX_RATE
		stream.data = data
		tones[key] = stream
	var voice := voices[voice_index]
	voice.stream = tones[key]
	voice.play()
	voice_index = (voice_index + 1) % voices.size()
