extends Area3D
@export_enum("Ouro","Moeda","Celeste") var kind := 0
var clock := 0.0
var taken := false
func _ready() -> void:
	clock = position.x
	body_entered.connect(_touch)
func _process(dt: float) -> void:
	clock += dt
	if not taken:
		$Visual.position.y = sin(clock*2.4)*.10
		$Visual.rotate_y(dt*1.75)
func _touch(body: Node3D) -> void:
	if taken or not body.is_in_group("player"): return
	taken = true
	var dust := preload("res://environment/effects/sparkles.gd").new()
	dust.position = position
	dust.tint = Color("#8fe9ff") if kind==2 else Color("#ffdb65")
	get_parent().add_child(dust)
	set_deferred("monitoring",false)
	var tween := create_tween().set_parallel()
	tween.tween_property($Visual,"position:y",.65,.19)
	tween.tween_property($Visual,"scale",Vector3.ONE*.02,.19)
	Game.collect(kind)
	tween.chain().tween_callback(queue_free)
