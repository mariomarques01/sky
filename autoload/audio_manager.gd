extends Node

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
	&"double_jump": preload("res://audio/sfx/double_jump.wav"),
	&"triple_jump": preload("res://audio/sfx/triple_jump.wav"),
	&"wall_kick": preload("res://audio/sfx/wall_kick.wav"),
	&"dive": preload("res://audio/sfx/dive.wav"),
	&"boss_hit": preload("res://audio/sfx/boss_hit.wav"),
	&"boss_defeat": preload("res://audio/sfx/boss_defeat.wav"),
	&"victory": preload("res://audio/sfx/victory.wav"),
	&"ui": preload("res://audio/sfx/ui.wav"),
}
var voices: Array[AudioStreamPlayer] = []
var cursor := 0
@onready var music := $StageMusic as AudioStreamPlayer
@onready var spare_music := $StageMusicAlt as AudioStreamPlayer
var music_fade: Tween
var prepared_loops: Dictionary[AudioStreamWAV, AudioStreamWAV] = {}
var current_track: AudioStreamWAV
var looping_track: AudioStreamWAV
var supports_haptics := false

func _ready() -> void:
	voices.assign($Effects.get_children())
	music.finished.connect(_play_music_loop.bind(music))
	spare_music.finished.connect(_play_music_loop.bind(spare_music))
	supports_haptics = OS.has_feature("mobile")
	if OS.has_feature("web"):
		music.playback_type = AudioServer.PLAYBACK_TYPE_SAMPLE
		spare_music.playback_type = AudioServer.PLAYBACK_TYPE_SAMPLE
		for voice in voices:
			voice.playback_type = AudioServer.PLAYBACK_TYPE_SAMPLE
		for stream in EFFECTS.values():
			_register_sample(stream)
		supports_haptics = JavaScriptBridge.eval("typeof navigator.vibrate === 'function'") == true

func _register_sample(stream: AudioStream) -> void:
	if OS.has_feature("web") and stream and not AudioServer.is_stream_registered_as_sample(stream):
		AudioServer.register_stream_as_sample(stream)

func play(effect: StringName, volume_db := 0.0) -> void:
	var stream := EFFECTS.get(effect) as AudioStream
	if not stream:
		return
	var voice := _next_voice()
	voice.bus = UI_BUS if effect == &"ui" else SFX_BUS
	voice.pitch_scale = 1.0 if effect == &"victory" else randf_range(0.94, 1.06)
	voice.volume_db = volume_db
	voice.stream = stream
	voice.play()

func _next_voice() -> AudioStreamPlayer:
	for offset in voices.size():
		var index := (cursor + offset) % voices.size()
		if not voices[index].playing:
			cursor = (index + 1) % voices.size()
			return voices[index]
	var voice := AudioStreamPlayer.new()
	voice.playback_type = voices[0].playback_type
	$Effects.add_child(voice)
	voices.append(voice)
	cursor = 0
	return voice

func prepare_music_loop(loop: AudioStreamWAV) -> AudioStreamWAV:
	if not prepared_loops.has(loop):
		var track := loop.duplicate() as AudioStreamWAV
		track.loop_mode = AudioStreamWAV.LOOP_FORWARD
		track.loop_begin = 0
		track.loop_end = roundi(loop.get_length() * loop.mix_rate)
		_register_sample(track)
		prepared_loops[loop] = track
	return prepared_loops[loop]

func play_stage_music(intro: AudioStreamWAV, loop: AudioStreamWAV, fade := 0.0) -> void:
	if not loop or (music.playing and current_track == loop):
		return
	_clear_music_fade()
	var outgoing := music
	music = spare_music
	spare_music = outgoing
	current_track = loop
	looping_track = prepare_music_loop(loop)
	music.stream = intro if intro else looping_track
	_register_sample(intro)
	music.volume_db = -60.0 if fade > 0.0 else 0.0
	music.play()
	if fade > 0.0:
		music_fade = create_tween().set_ignore_time_scale().set_parallel()
		music_fade.tween_property(music, "volume_db", 0.0, fade)
		music_fade.tween_property(outgoing, "volume_db", -60.0, fade)
		music_fade.chain().tween_callback(_clear_player.bind(outgoing))
	else:
		_clear_player(outgoing)

func _play_music_loop(player: AudioStreamPlayer) -> void:
	if player == music and looping_track and music.stream != looping_track:
		music.stream = looping_track
		music.play()

func _clear_player(player: AudioStreamPlayer) -> void:
	player.stop()
	player.stream = null

func _clear_music_fade() -> void:
	if music_fade:
		music_fade.kill()
		music_fade = null
	_clear_player(spare_music)

func stop_music(fade := 0.0) -> void:
	_clear_music_fade()
	current_track = null
	looping_track = null
	if fade > 0.0 and music.playing:
		music_fade = create_tween().set_ignore_time_scale()
		music_fade.tween_property(music, "volume_db", -60.0, fade)
		music_fade.tween_callback(_clear_player.bind(music))
	else:
		_clear_player(music)

func stop_all() -> void:
	for voice in voices:
		_clear_player(voice)
	stop_music()

func vibrate(duration_ms: int) -> void:
	if supports_haptics:
		Input.vibrate_handheld(duration_ms)
