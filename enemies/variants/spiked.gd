extends "res://enemies/mushroom/patrol.gd"

func contact_player(body: CharacterBody3D) -> void:
	if body.is_striking() and body.air_move == &"GroundPound":
		defeat(body, false)
	else:
		body.hurt(global_position.x)

func _ready() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.ground_pound.connect(on_ground_pound.bind(player))

func on_ground_pound(point: Vector3, player: CharacterBody3D) -> void:
	if player.is_striking() and point.distance_to(global_position) <= 1.45:
		defeat(player, false)
