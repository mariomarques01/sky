extends Node3D
@export var stage_music_intro: AudioStreamWAV
@export var stage_music_loop: AudioStreamWAV

var clock := 0.0
var quality := 1
func _ready() -> void:
	Game.begin()
	Audio.play_stage_music(stage_music_intro, stage_music_loop)
	decorate()
	$Player.position = Game.checkpoint
	$Gameplay/Checkpoints/Beacon.body_entered.connect(_checkpoint)
	set_quality(int(Save.data.get_value("video","perfil",1)))
func _checkpoint(body: Node3D) -> void:
	if body.is_in_group("player") and Game.checkpoint.x<0:
		Game.checkpoint = Vector3(10.6,.8,0)
		Audio.play(&"checkpoint")
		$Gameplay/Checkpoints/Beacon/Flame.scale *= 1.4
func set_quality(value: int) -> void:
	quality = clampi(value,0,2)
	get_viewport().scaling_3d_scale = [0.65,0.82,1.0][quality]
	$DirectionalLight3D.shadow_enabled = quality>0
	$DirectionalLight3D.directional_shadow_max_distance = 18 if quality==1 else 35
	$Background/FarClouds.visible = quality>0
	$Expansion/Scenery/FarClouds.visible = quality>0
	$Environment/Motes.emitting = quality>0
	$Environment/Mist.emitting = quality>0
	var water := $Environment/Waterfalls/Falls0.material_override as ShaderMaterial
	water.set_shader_parameter("simple",quality==0)
	for waterfall: MeshInstance3D in $Expansion.find_children("Waterfall*", "MeshInstance3D", true, false):
		waterfall.material_override = water
func _process(dt: float) -> void:
	clock += dt
	$Gameplay/WoodenBridge/Planks.position.y = sin(clock*1.8)*.019
	for butterfly: Node3D in $Environment/Butterflies.get_children():
		butterfly.position.y = 1.9+sin(clock*1.6+butterfly.position.x)*.32
		butterfly.rotation.y = sin(clock*2+butterfly.position.x)*.7
		butterfly.scale.x = .45+.5*absf(sin(clock*10))
func decorate() -> void:
	var flowers := preload("res://environment/Blossoms.glb").instantiate()
	var mesh := flowers.find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
	for border: MultiMeshInstance3D in $Environment/Vegetation.find_children("*","MultiMeshInstance3D",false,false):
		border.multimesh.mesh = mesh.mesh
	var wind := ShaderMaterial.new()
	wind.shader = preload("res://shaders/vegetation.gdshader")
	var terrain := ShaderMaterial.new()
	terrain.shader = preload("res://shaders/terrain.gdshader")
	for surface in mesh.mesh.get_surface_count():
		var original := mesh.mesh.surface_get_material(surface)
		mesh.mesh.surface_set_material(surface,wind if original.resource_name=="Foliage" else terrain)
	flowers.free()
	for model: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		if not model.mesh: continue
		for surface in model.mesh.get_surface_count():
			var mat := model.mesh.surface_get_material(surface)
			if mat and mat.resource_name == "Stone":
				model.set_surface_override_material(surface,terrain)
			elif mat and mat.resource_name == "Foliage":
				model.set_surface_override_material(surface,wind)
	var amber := ShaderMaterial.new()
	amber.shader = preload("res://shaders/crystal.gdshader")
	var azure := amber.duplicate() as ShaderMaterial
	azure.set_shader_parameter("hue",Color("#29bafa"))
	var pickups := $Gameplay/Collectibles.get_children()
	for item in $Expansion.find_children("*", "Area3D", true, true):
		if item.get_script() == preload("res://collectibles/pickup.gd"):
			pickups.append(item)
	for item: Area3D in pickups:
		for part: MeshInstance3D in item.find_children("*","MeshInstance3D",true,false):
			if not item.get("reward"):
				part.material_override = azure if item.get("kind")==2 else amber
	var mist := preload("res://environment/effects/sparkles.gd").new()
	mist.name = "Mist"
	mist.continuous = true
	mist.tint = Color("#c4edff")
	mist.position = Vector3(11.4,-4.55,1.5)
	$Environment.add_child(mist)
