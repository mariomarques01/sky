extends "res://collectibles/pickup.gd"

func _animate_idle(_delta: float) -> void:
	$Visual/Lock.position.y = 0.33 + sin(clock * 2.4) * 0.025

func _animate_collection() -> void:
	var tween := create_tween()
	tween.tween_property($Visual/Lid, "rotation:x", -1.15, 0.25)
