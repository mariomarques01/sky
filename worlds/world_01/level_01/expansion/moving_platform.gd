@tool
extends "res://worlds/world_01/level_01/expansion/floating_platform.gd"

@export var travel := Vector3(1, 0, 0)
@export_range(1.0, 12.0) var period := 4.0
@onready var origin := position
var elapsed := 0.0

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	elapsed = fmod(elapsed + delta, period)
	position = origin + travel * sin(TAU * elapsed / period)
