extends RigidBody3D

var age := 0.0

func _physics_process(dt: float) -> void:
	age += dt
	if age >= 9 or global_position.y < -6:
		queue_free()
		return
	for body in $Contact.get_overlapping_bodies():
		if not body.is_in_group("player"):
			continue
		if body.is_striking() and body.strike_is_active() and body.strike_index < 2:
			queue_free()
			return
		body.hurt(global_position.x)
