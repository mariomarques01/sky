extends "res://enemies/mushroom/patrol.gd"

@export var amplitude := Vector2(1.35, .48)
@onready var origin := position

func advance_patrol(_dt: float) -> void:
	position = origin + Vector3(amplitude.x * sin(clock * speed), amplitude.y * sin(2 * clock * speed), 0)
	$Visual.rotation.z = .18 * cos(clock * speed)

func contact_player(body: CharacterBody3D) -> void:
	if is_stomp(body):
		defeat(body, true)
	else:
		body.hurt(global_position.x)
