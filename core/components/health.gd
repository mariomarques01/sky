extends Node
@export var immunity := 1.25
var shield := 0.0
func _physics_process(delta: float) -> void:
	shield = maxf(0,shield-delta)
func hit() -> bool:
	if shield > 0:
		return false
	shield = immunity
	Game.health -= 1
	Game.changed.emit()
	Audio.play(&"hurt")
	return true
func restore() -> void:
	Game.health = 3
	shield = immunity
	Game.changed.emit()
