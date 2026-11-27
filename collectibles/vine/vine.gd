extends Node3D

@export var swing_degrees := 30.0
var clock := 0.0

func _physics_process(dt: float) -> void:
	clock += dt
	rotation.z = deg_to_rad(swing_degrees) * sin(clock * 1.45)
