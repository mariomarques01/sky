extends Node

const VOICE_COUNT := 8
const MUSIC_BUS := &"Música"
const SFX_BUS := &"SFX"
const UI_BUS := &"UI"
const EFFECTS := {
	&"jump": preload("res://audio/sfx/jump.wav"),
	&"land": preload("res://audio/sfx/land.wav"),
	&"punch": preload("res://audio/sfx/punch.wav"),
	&"pound": preload("res://audio/sfx/pound.wav"),
	&"coin": preload("res://audio/sfx/coin.wav"),
	&"stomp": preload("res://audio/sfx/stomp.wav"),
	&"hurt": preload("res://audio/sfx/hurt.wav"),
	&"crystal": preload("res://audio/sfx/crystal.wav"),
	&"heal": preload("res://audio/sfx/heal.wav"),
	&"checkpoint": preload("res://audio/sfx/checkpoint.wav"),
	&"crate": preload("res://audio/sfx/crate.wav"),
	&"dash": preload("res://audio/sfx/dash.wav"),
	&"ui": preload("res://audio/sfx/ui.wav"),
}
var voices: Array[AudioStreamPlayer] = []
var cursor := 0
@onready var music := $StageMusic as AudioStreamPlayer
var current_track: AudioStreamWAV
var looping_track: AudioStreamWAV
var supports_haptics := false

func _ready() -> void:
	voices.assign($Effects.get_children())
	music.finished.connect(_play_music_loop)
	supports_haptics = OS.has_feature("mobile")
	if OS.has_feature("web"):
		music.playback_type = AudioServer.PLAYBACK_TYPE_SAMPLE
		for voice in voices:
			voice.playback_type = AudioServer.PLAYBACK_TYPE_SAMPLE
		supports_haptics = JavaScriptBridge.eval("typeof navigator.vibrate === 'function'") == true

func play(effect: StringName, volume_db := 0.0) -> void:
	var stream := EFFECTS.get(effect) as AudioStream
	if not stream:
		return
	var voice := _next_voice()
	voice.bus = UI_BUS if effect == &"ui" else SFX_BUS
	voice.pitch_scale = randf_range(0.94, 1.06)
	voice.volume_db = volume_db
	voice.stream = stream
	voice.play()

func _next_voice() -> AudioStreamPlayer:
	for offset in VOICE_COUNT:
		var index := (cursor + offset) % VOICE_COUNT
		if not voices[index].playing:
			cursor = (index + 1) % VOICE_COUNT
			return voices[index]
	var voice := voices[cursor]
	cursor = (cursor + 1) % VOICE_COUNT
	voice.stop()
	return voice

func play_stage_music(intro: AudioStreamWAV, loop: AudioStreamWAV) -> void:
	if not loop or (music.playing and current_track == loop):
		return
	current_track = loop
	looping_track = loop.duplicate() as AudioStreamWAV
	looping_track.loop_mode = AudioStreamWAV.LOOP_FORWARD
	looping_track.loop_begin = 0
	looping_track.loop_end = roundi(loop.get_length() * loop.mix_rate)
	music.stream = intro if intro else looping_track
	music.play()

func _play_music_loop() -> void:
	if looping_track and music.stream != looping_track:
		music.stream = looping_track
		music.play()

func stop_all() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
	music.stop()
	music.stream = null
	current_track = null
	looping_track = null

func vibrate(duration_ms: int) -> void:
	if supports_haptics:
		Input.vibrate_handheld(duration_ms)
