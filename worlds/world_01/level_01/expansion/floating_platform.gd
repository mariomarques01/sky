@tool
extends PhysicsBody3D

@export var dimensions := Vector3(2.1, 2.9, 2.45):
	set(value):
		dimensions = value
		_fit()
@export var meadow := false:
	set(value):
		meadow = value
		_fit()

const Horizon = preload("res://environment/Horizon.glb")
const Meadow = preload("res://environment/Meadow.glb")

func _ready() -> void:
	_fit()

func _fit() -> void:
	if not is_node_ready():
		return
	var visual := $Visual as Node3D
	for child in visual.get_children():
		visual.remove_child(child)
		child.queue_free()
	var cliffs := (Meadow if meadow else Horizon).instantiate() as Node3D
	var reference := Vector3(11.5, 5.0, 4.6) if meadow else Vector3(7.66, 5.0, 3.4)
	cliffs.scale = dimensions / reference
	visual.add_child(cliffs)
	var collision := $Collision as CollisionShape3D
	var shape := BoxShape3D.new()
	shape.size = Vector3(dimensions.x, 0.25, dimensions.z * 0.55)
	collision.shape = shape
