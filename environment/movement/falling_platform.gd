@tool
extends "res://worlds/world_01/level_01/expansion/floating_platform.gd"

var timer := -1.0
@onready var resting_position := position

func _has_landed_player() -> bool:
	for candidate in $Sensor.get_overlapping_bodies():
		var player := candidate as CharacterBody3D
		if not player or not player.is_in_group("player") or not player.is_on_floor():
			continue
		for index in player.get_slide_collision_count():
			var contact := player.get_slide_collision(index)
			if contact.get_collider() == self and contact.get_normal().y > 0.7:
				return true
	return false

func _physics_process(dt: float) -> void:
	if Engine.is_editor_hint():
		return
	if timer < 0:
		if not _has_landed_player():
			return
		timer = 0.0
	timer += dt
	if timer >= 3.4:
		position = resting_position
		visible = true
		$Collision.set_deferred("disabled", false)
		timer = -1
	elif timer >= 1.65:
		visible = false
		$Collision.set_deferred("disabled", true)
	elif timer >= .62:
		position = resting_position - Vector3.UP * 10.0 * pow(timer - .62, 2)
	else:
		position.x = resting_position.x + sin(timer * 68.0) * .035
