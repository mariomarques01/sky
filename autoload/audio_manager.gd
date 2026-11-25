extends Node
var voice := AudioStreamPlayer.new()
var sounds: Dictionary = {}
func _ready() -> void:
	add_child(voice)
	voice.volume_db = -18
func cue(hz: float) -> void:
	if not sounds.has(hz):
		var sound := AudioStreamWAV.new()
		sound.mix_rate = 22050
		sound.format = AudioStreamWAV.FORMAT_16_BITS
		var samples := PackedByteArray()
		samples.resize(5292)
		for i in 2646:
			var t := i/22050.0
			samples.encode_s16(i*2,int(19000*sin(TAU*hz*t)*exp(-30*t)*minf(1,t*300)))
		sound.data = samples
		sounds[hz] = sound
	voice.stream = sounds[hz]
	voice.play()
