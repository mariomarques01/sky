extends Node3D

func _ready() -> void:
	$Splinters.finished.connect(queue_free)
