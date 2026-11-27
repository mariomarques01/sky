extends Node3D

func _ready() -> void:
	if int(Save.data.get_value("video", "perfil", 1)) == 0:
		$Boards.amount = 3
		$Splinters.amount = 6
	$Splinters.finished.connect(queue_free)
	$Boards.emitting = true
	$Splinters.emitting = true
