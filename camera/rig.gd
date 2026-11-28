extends Camera3D
@export var bounds := Vector2(-2,20)
var shake := 0.0
var arena_locked := false
var arena_position := Vector3.ZERO
var defeat_target: Node3D

func lock_arena(center: Vector3) -> void:
	arena_position = center + Vector3(0.0, 3.0, 12.2)
	arena_locked = true
	defeat_target = null

func focus_defeat(subject: Node3D) -> void:
	defeat_target = subject

func release_arena() -> void:
	arena_locked = false
	defeat_target = null
@onready var player := $"../Player" as CharacterBody3D
func _ready() -> void:
	player.connect("impact",func() -> void: shake = .12)
	position = Vector3(player.position.x+1.6,2.45,10.7)
	rotation.x = -.095
func _process(dt: float) -> void:
	var aim := clampf(player.position.x+1.6+player.velocity.x*.22,bounds.x,bounds.y)
	var vertical_lead := smoothstep(20.0, 24.0, player.position.x) * maxf(0.0, player.position.y - 2.6) * 0.17
	var temple_lead := smoothstep(55.0, 60.0, player.position.x) * (1.0 - smoothstep(66.0, 73.0, player.position.x)) * 0.55
	var target_y := 2.55 + maxf(0, player.position.y) * 0.73 + vertical_lead + temple_lead
	var goal := Vector3(aim, target_y, 10.7)
	if arena_locked:
		var framing := arena_position
		if is_instance_valid(defeat_target):
			framing = defeat_target.global_position + Vector3(0.0, 2.0, 7.6)
		goal = (get_parent() as Node3D).to_local(framing)
	position.x = lerpf(position.x, goal.x, 1.0 - exp(-6.0 * dt))
	position.y = lerpf(position.y, goal.y, 1.0 - exp(-5.0 * dt))
	position.z = lerpf(position.z, goal.z, 1.0 - exp(-6.0 * dt))
	shake = maxf(0,shake-dt)
	h_offset = shake*.25*sin(shake*100)
