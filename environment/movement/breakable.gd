extends StaticBody3D

const WoodBurst = preload("res://environment/effects/WoodBurst.tscn")

var broken := false

func take_movement_hit() -> void:
	if broken:
		return
	broken = true
	$Collision.set_deferred("disabled", true)
	Audio.cue(220)
	var animation := create_tween()
	animation.tween_property($Mesh, "scale", Vector3(1.1, 0.62, 1.08), .075)
	animation.tween_callback(_shatter)

func _shatter() -> void:
	var burst := WoodBurst.instantiate() as Node3D
	burst.position = position + Vector3.BACK * 0.24
	get_parent().add_child(burst)
	queue_free()
