extends Area3D
const Spores = preload("res://environment/effects/sparkles.gd")

@export var limits := Vector2(11.0,15.2)
@export var speed := 1.1
var direction := -1
var clock := 0.0
var defeated := false
func _physics_process(dt: float) -> void:
	if defeated: return
	clock += dt
	position.x += direction*dt*speed
	if position.x <= limits.x or position.x >= limits.y or not $Edge.is_colliding():
		direction = 1 if direction<0 else -1
	$Edge.position.x = direction*.42
	$Visual.position.y = absf(sin(clock*6))*.07
	$Visual.rotation.z = sin(clock*6)*.065
	for body: Node3D in get_overlapping_bodies():
		if not body.is_in_group("player"): continue
		var stomp: bool = body.get("velocity").y < 0 and body.global_position.y > global_position.y + .48
		if stomp or body.call("is_striking"):
			defeated = true
			if stomp:
				body.call("stomp_enemy", Input.is_action_pressed("jump"))
			Game.collect(1)
			var t := create_tween()
			if stomp:
				t.tween_interval(float(body.get("stomp_stop")))
			t.tween_property($Visual,"scale",Vector3(1.25,.12,1.25),.16)
			t.tween_property($Visual, "scale", Vector3(.85, 1.18, .85), .06)
			t.tween_callback(burst)
			return
		else: body.call("hurt",global_position.x)

func burst() -> void:
	var spores := Spores.new()
	spores.burst_amount = 8
	spores.tint = Color("#ffca83")
	get_parent().add_child(spores)
	spores.global_position = global_position + Vector3.UP * .45
	queue_free()
