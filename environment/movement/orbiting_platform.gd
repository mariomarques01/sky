@tool
extends "res://worlds/world_01/level_01/expansion/moving_platform.gd"

@export var vertical_radius := 1.0

func _physics_process(dt: float) -> void:
	if Engine.is_editor_hint():
		return
	super(dt)
	position.y = origin.y + vertical_radius * cos(TAU * elapsed / period)
