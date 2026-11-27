extends Area3D

@export var launch_speed := 14.0
var clock := 0.0

func _ready() -> void:
	body_entered.connect(capture)

func capture(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.enter_cannon(self)

func _physics_process(dt: float) -> void:
	clock += dt
	$Tube.rotation.z = deg_to_rad(-45.0 + 30.0 * sin(clock * 1.8))

func launch_velocity() -> Vector3:
	return $Tube.global_transform.basis.y.normalized() * launch_speed
