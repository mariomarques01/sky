extends "res://enemies/mushroom/patrol.gd"

@export var amplitude := Vector2(1.35, .48)
@onready var origin := position

func advance_patrol(_dt: float) -> void:
	position = origin + Vector3(amplitude.x * sin(clock * speed), amplitude.y * sin(2 * clock * speed), 0)
	$Visual.rotation.z = .18 * cos(clock * speed)

func turn_cue() -> float:
	if is_zero_approx(speed) or is_zero_approx(amplitude.x):
		return 0.0
	var phase := clock * absf(speed)
	var angle_to_turn := fposmod(PI * .5 - phase, PI)
	return clampf(1.0 - angle_to_turn / (absf(speed) * ANTICIPATION), 0.0, 1.0)

func contact_player(body: CharacterBody3D) -> void:
	if is_stomp(body):
		defeat(body, true)
	else:
		prepare_attack(body)
