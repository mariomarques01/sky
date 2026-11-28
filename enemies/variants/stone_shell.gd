extends "res://enemies/mushroom/patrol.gd"

func contact_player(body: CharacterBody3D) -> void:
	prepare_attack(body)

func take_ground_pound(player: CharacterBody3D) -> void:
	defeat(player, false)
