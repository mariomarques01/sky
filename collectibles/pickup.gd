extends Area3D

const RewardProfile = preload("res://collectibles/reward_profile.gd")
const CrystalShader = preload("res://shaders/crystal.gdshader")
const Sparkles = preload("res://environment/effects/sparkles.gd")
const CLAIMS := "JardinsTesouros"

@export_enum("Ouro","Moeda","Celeste") var kind := 0
@export var completes_level := true
@export var reward: RewardProfile
@export var persistent_id := ""

var clock := 0.0
var taken := false
static var reward_materials: Dictionary = {}

func _ready() -> void:
	if not persistent_id.is_empty() and Save.data.get_value(CLAIMS, persistent_id, false):
		taken = true
		monitoring = false
		visible = false
		set_process(false)
		queue_free()
		return
	clock = global_position.x
	if reward:
		if not reward_materials.has(reward):
			var material := ShaderMaterial.new()
			material.shader = CrystalShader
			material.set_shader_parameter("hue", reward.tint)
			material.set_shader_parameter("emission_strength", reward.emission)
			reward_materials[reward] = material
		for part: MeshInstance3D in $Visual.find_children("*", "MeshInstance3D", true, false):
			if reward.healing or (not part.material_override and not part.mesh is PrimitiveMesh):
				part.material_override = reward_materials[reward]
	body_entered.connect(_touch)

func _process(dt: float) -> void:
	clock += dt
	if not taken:
		_animate_idle(dt)

func _animate_idle(dt: float) -> void:
	$Visual.position.y = sin(clock * 2.4) * (reward.hover if reward else 0.10)
	$Visual.rotate_y(dt * (reward.spin if reward else 1.75))

func _touch(body: Node3D) -> void:
	if taken or not body.is_in_group("player"):
		return
	if reward and reward.healing and Game.health == 3:
		return
	if not persistent_id.is_empty() and not Save.claim(CLAIMS, persistent_id):
		return
	taken = true
	var dust := Sparkles.new()
	dust.position = position
	dust.tint = reward.tint if reward else (Color("#8fe9ff") if kind == 2 else Color("#ffdb65"))
	if reward:
		dust.burst_amount = reward.particles
	get_parent().add_child(dust)
	set_deferred("monitoring", false)
	_animate_collection()
	if reward and reward.healing:
		Game.health += 1
		Game.changed.emit()
		Audio.play(&"heal")
	else:
		Game.collect(kind, completes_level)

func _animate_collection() -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property($Visual, "position:y", 0.65, 0.19)
	tween.tween_property($Visual, "scale", Vector3.ONE * 0.02, 0.19)
	tween.chain().tween_callback(queue_free)
