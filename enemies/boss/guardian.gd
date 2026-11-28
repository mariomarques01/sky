extends "res://enemies/mushroom/patrol.gd"

signal health_changed(current: int)

enum Action { WINDUP, ATTACK, RECOVER }

const MAX_HEALTH := 3
const GUARDIAN_MUSIC := preload("res://audio/music/guardian_loop.wav")
const REWARD := preload("res://collectibles/Aether.tscn")
const CameraRig = preload("res://camera/rig.gd")
const MUSIC_FADE := .5
const HIT_STOP := .05
const WINDUP_TIME := .4
const JUMP_TIME := .66
const CHARGE_TIME := .55
const RECOVERY_TIME := .4
const ARENA_RADIUS := 3.0

@export var activation_distance := 7.0

var stage_loop: AudioStreamWAV
var health := MAX_HEALTH
var cooldown := 0.0
var active := false
var action := Action.WINDUP
var action_time := 0.0
var attack_start_x := 0.0
var attack_end_x := 0.0
var camera: CameraRig
var flash_material := StandardMaterial3D.new()
var mesh_parts: Array[MeshInstance3D] = []
var original_materials: Array[Material] = []
var flashing := false

@onready var origin := position
@onready var target := get_tree().get_first_node_in_group("player") as CharacterBody3D

func _ready() -> void:
	Audio.prepare_music_loop(GUARDIAN_MUSIC)
	flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for part in visual.find_children("*", "MeshInstance3D", true, false):
		mesh_parts.append(part)
		original_materials.append(part.material_override)
	if target:
		target.get_node("State").entered.connect(_on_player_state)

func advance_patrol(dt: float) -> void:
	if not active:
		clock = 0.0
		if not is_instance_valid(target) or target.recovery > 0.0:
			return
		var distance := (target.global_position - global_position).abs()
		if distance.x >= activation_distance or distance.y >= 3.0:
			return
		active = true
		stage_loop = Audio.current_track
		Audio.play_stage_music(null, GUARDIAN_MUSIC, MUSIC_FADE)
		camera = get_viewport().get_camera_3d() as CameraRig
		if camera:
			camera.lock_arena(global_position)
		health_changed.emit(health)
	cooldown = maxf(0.0, cooldown - dt)
	if health == MAX_HEALTH:
		position.x = origin.x + 2.4 * sin(clock * 1.3)
	else:
		_advance_attack(dt)

func _advance_attack(dt: float) -> void:
	action_time += dt
	match action:
		Action.WINDUP:
			if action_time >= WINDUP_TIME - .0001:
				_start_attack()
			else:
				_set_flash(fmod(action_time, .16) < .08)
		Action.ATTACK:
			var duration := JUMP_TIME if health == 2 else CHARGE_TIME
			var progress := clampf(action_time / duration, 0.0, 1.0)
			position.x = lerpf(attack_start_x, attack_end_x, progress)
			if health == 2:
				position.y = origin.y + 7.2 * progress * (1.0 - progress)
			if action_time >= duration:
				action = Action.RECOVER
				action_time = 0.0
		Action.RECOVER:
			if action_time >= RECOVERY_TIME:
				_start_windup()

func _start_windup() -> void:
	action = Action.WINDUP
	action_time = 0.0
	flash_material.albedo_color = Color("#ffe58b") if health == 2 else Color("#ff6748")
	_set_flash(true)

func _start_attack() -> void:
	action = Action.ATTACK
	action_time = 0.0
	_set_flash(false)
	attack_start_x = position.x
	var toward := clampf((get_parent() as Node3D).to_local(target.global_position).x, origin.x - ARENA_RADIUS, origin.x + ARENA_RADIUS)
	if health == 2:
		attack_end_x = move_toward(position.x, toward, 2.8)
	else:
		attack_end_x = origin.x + ARENA_RADIUS * (1.0 if toward >= position.x else -1.0)
		if is_equal_approx(attack_end_x, attack_start_x):
			attack_end_x = origin.x - (attack_end_x - origin.x)

func _set_flash(enabled: bool) -> void:
	if flashing == enabled:
		return
	flashing = enabled
	for index in mesh_parts.size():
		mesh_parts[index].material_override = flash_material if enabled else original_materials[index]

func contact_player(body: CharacterBody3D) -> void:
	if not active or defeated or cooldown > 0.0 or body.recovery > 0.0:
		return
	var stomp := is_stomp(body)
	if not stomp and not body.is_striking():
		body.hurt(global_position.x)
		return
	Game.hit_stop(HIT_STOP)
	health -= 1
	health_changed.emit(health)
	if health == 0:
		_set_flash(false)
		if camera:
			camera.focus_defeat(visual)
		Audio.play(&"boss_defeat")
		defeat(body, stomp, false)
		return
	Audio.play(&"boss_hit")
	if stomp:
		body.stomp_enemy(Input.is_action_pressed("jump"))
	cooldown = .85
	clock = 0.0
	position.y = origin.y
	_start_windup()

func _on_player_state(state: StringName) -> void:
	if state != &"Death" or not active or defeated:
		return
	active = false
	health = MAX_HEALTH
	cooldown = 0.0
	clock = 0.0
	action = Action.WINDUP
	action_time = 0.0
	position = origin
	_set_flash(false)
	_release_arena()
	health_changed.emit(health)

func burst() -> void:
	emit_defeat_particles()
	visual.hide()
	var effects := create_tween()
	effects.tween_interval(.43)
	effects.tween_callback(_drop_reward)

func _drop_reward() -> void:
	var crystal := REWARD.instantiate() as Area3D
	crystal.name = "GuardianCrystal"
	crystal.position = origin + Vector3(2.4, .72, 0)
	get_parent().add_child(crystal)
	active = false
	_release_arena()
	queue_free()

func _release_arena() -> void:
	if camera:
		camera.release_arena()
		camera = null
	if Audio.current_track == GUARDIAN_MUSIC:
		if stage_loop:
			Audio.play_stage_music(null, stage_loop, MUSIC_FADE)
		else:
			Audio.stop_music(MUSIC_FADE)
