extends Marker3D

const Barrel = preload("res://enemies/barrels/Rolling.tscn")
@export_range(1.0, 10.0) var interval := 3.5
@export var activation_distance := 0.0
@onready var player := get_tree().get_first_node_in_group("player") as Node3D
var remaining := 0.0

func _physics_process(dt: float) -> void:
	if activation_distance > 0 and (not is_instance_valid(player) or absf(player.global_position.x - global_position.x) > activation_distance):
		return
	remaining -= dt
	if remaining <= 0:
		remaining = interval
		var barrel := Barrel.instantiate() as RigidBody3D
		get_parent().add_child(barrel)
		barrel.global_position = global_position
