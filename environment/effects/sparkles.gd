extends CPUParticles3D
@export var tint := Color("#fff1a3")
@export var burst_amount := 9
@export var continuous := false
func _ready() -> void:
	var shape := SphereMesh.new()
	shape.radius = .029
	shape.height = .058
	shape.radial_segments = 5
	shape.rings = 2
	var glow := StandardMaterial3D.new()
	glow.albedo_color = tint
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shape.material = glow
	mesh = shape
	amount = burst_amount if not continuous else 15
	lifetime = .43 if not continuous else .85
	one_shot = not continuous
	explosiveness = 0 if continuous else .96
	direction = Vector3.UP
	spread = 70.0
	initial_velocity_min = .8
	initial_velocity_max = 2.1
	gravity = Vector3(0,-3.1,0)
	emitting = true
	if one_shot: finished.connect(queue_free)
