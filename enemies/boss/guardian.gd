extends "res://enemies/mushroom/patrol.gd"

signal health_changed(current: int)
const MAX_HEALTH := 3
var health := MAX_HEALTH
var cooldown := 0.0
var active := false
var charge_direction := 1.0
@onready var origin := position
@onready var target := get_tree().get_first_node_in_group("player") as CharacterBody3D

func advance_patrol(dt: float) -> void:
	if not active:
		active = is_instance_valid(target) and absf(target.global_position.x - global_position.x) < 7
		clock = 0
		if not active:
			return
		health_changed.emit(health)
	cooldown = maxf(0, cooldown - dt)
	match health:
		3:
			# Patrulha horizontal.
			position.x = origin.x + 2.4 * sin(clock * 1.3)
		2:
			# Saltos ao redor do centro da arena.
			position.x = origin.x + 2.1 * sin(clock * 1.9)
			position.y = origin.y + absf(sin(clock * 3.2)) * 1.8
		1:
			# Mira durante a pausa, depois investe na direção escolhida.
			if fmod(clock, 1.5) < .65:
				charge_direction = signf(target.global_position.x - global_position.x)
			else:
				position.x = clampf(position.x + charge_direction * 8 * dt, origin.x - 3, origin.x + 3)

func contact_player(body: CharacterBody3D) -> void:
	if cooldown > 0:
		return
	var stomp := is_stomp(body)
	if not stomp and not body.is_striking():
		body.hurt(global_position.x)
		return
	health -= 1
	health_changed.emit(health)
	if health == 0:
		defeat(body, stomp)
		return
	if stomp:
		body.stomp_enemy(Input.is_action_pressed("jump"))
	cooldown = .85
	clock = 0
	position.y = origin.y
