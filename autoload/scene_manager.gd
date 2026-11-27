extends Node
func restart() -> void:
	Game.cancel_hit_stop()
	Audio.stop_all()
	get_tree().paused = false
	get_tree().reload_current_scene.call_deferred()
