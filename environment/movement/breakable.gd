extends StaticBody3D

var broken := false

func take_movement_hit() -> void:
	if broken:
		return
	broken = true
	$Collision.set_deferred("disabled", true)
	Audio.cue(220)
	var animation := create_tween()
	animation.tween_property($Mesh, "scale", Vector3.ONE * .05, .16)
	animation.tween_callback(queue_free)
