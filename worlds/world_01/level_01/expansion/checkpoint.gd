extends Area3D

@export var respawn_offset := Vector3(0.20, -0.45, 0)
var activated := false

func _ready() -> void:
	body_entered.connect(_activate)

func _activate(body: Node3D) -> void:
	if activated or not body.is_in_group("player"):
		return
	activated = true
	Game.checkpoint = global_position + respawn_offset
	$Flame.scale *= 1.4
	Audio.cue(890)
