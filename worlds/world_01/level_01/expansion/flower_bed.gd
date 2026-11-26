extends MultiMeshInstance3D

const Blossoms = preload("res://environment/Blossoms.glb")

@export var width := 6.0
@export var amount := 24
@export var seed_value := 1

func _ready() -> void:
	var model := Blossoms.instantiate()
	var source := model.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var bed := MultiMesh.new()
	bed.transform_format = MultiMesh.TRANSFORM_3D
	bed.mesh = source.mesh
	model.free()
	bed.instance_count = amount
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	for index in amount:
		var x := width * (float(index) / maxf(1.0, amount - 1) - 0.5)
		var size := random.randf_range(0.60, 0.98)
		var basis := Basis(Vector3.UP, random.randf_range(0, TAU)).scaled(Vector3.ONE * size)
		var origin := Vector3(x + random.randf_range(-0.13, 0.13), 0, random.randf_range(-0.32, 0.32))
		bed.set_instance_transform(index, Transform3D(basis, origin))
	multimesh = bed
