extends Area3D

func _ready() -> void:
	body_entered.connect(_finish)

func _finish(body: Node3D) -> void:
	if body.is_in_group("player"):
		Game.finish_level()
