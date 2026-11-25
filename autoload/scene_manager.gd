extends Node
func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene.call_deferred()
