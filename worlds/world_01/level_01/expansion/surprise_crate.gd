extends StaticBody3D

const WoodBurst = preload("res://environment/effects/WoodBurst.tscn")

@export var prize: PackedScene = preload("res://collectibles/Coin.tscn")
var broken := false

func break_from_above(player: CharacterBody3D) -> bool:
	if broken or absf(player.global_position.x - global_position.x) > 0.48:
		return false
	take_movement_hit()
	return true

func take_movement_hit() -> void:
	if broken:
		return
	broken = true
	$Collision.set_deferred("disabled", true)
	var crush := create_tween()
	crush.tween_property($Visual, "scale", Vector3(1.10, 0.62, 1.08), 0.075)
	crush.tween_callback(_shatter)

func _shatter() -> void:
	var reward := prize.instantiate() as Area3D
	reward.position = position + Vector3.UP * 0.72
	get_parent().add_child(reward)

	var burst := WoodBurst.instantiate() as Node3D
	burst.position = position + Vector3(0, 0.52, 0.24)
	get_parent().add_child(burst)
	Audio.play(&"crate")
	queue_free()
