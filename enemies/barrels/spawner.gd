extends Marker3D

const Barrel = preload("res://enemies/barrels/Rolling.tscn")
@export_range(1.0, 10.0) var interval := 3.5
var remaining := 0.0

func _physics_process(dt: float) -> void:
	remaining -= dt
	if remaining <= 0:
		remaining = interval
		var barrel := Barrel.instantiate() as RigidBody3D
		get_parent().add_child(barrel)
		barrel.global_position = global_position
