extends Node3D

var quality := 1
var clock := 0.0

func _ready() -> void:
	Game.begin()
	set_quality(int(Save.data.get_value("video", "perfil", 1)))

func set_quality(value: int) -> void:
	quality = clampi(value, 0, 2)
	get_viewport().scaling_3d_scale = [0.65, 0.82, 1.0][quality]
	$Sun.shadow_enabled = quality > 0
	$Sun.directional_shadow_max_distance = 18 if quality == 1 else 35

func _process(dt: float) -> void:
	clock += dt
