extends Camera3D
@export var bounds := Vector2(-2,20)
var shake := 0.0
@onready var player := $"../Player" as CharacterBody3D
func _ready() -> void:
	player.connect("impact",func() -> void: shake = .12)
	position = Vector3(player.position.x+1.6,2.45,10.7)
	rotation.x = -.095
func _process(dt: float) -> void:
	var aim := clampf(player.position.x+1.6+player.velocity.x*.22,bounds.x,bounds.y)
	position.x = lerpf(position.x,aim,1-exp(-6*dt))
	var vertical_lead := smoothstep(20.0, 24.0, player.position.x) * maxf(0.0, player.position.y - 2.6) * 0.17
	var temple_lead := smoothstep(55.0, 60.0, player.position.x) * (1.0 - smoothstep(66.0, 73.0, player.position.x)) * 0.55
	var target_y := 2.55 + maxf(0, player.position.y) * 0.73 + vertical_lead + temple_lead
	position.y = lerpf(position.y, target_y, 1-exp(-5*dt))
	shake = maxf(0,shake-dt)
	h_offset = shake*.25*sin(shake*100)
