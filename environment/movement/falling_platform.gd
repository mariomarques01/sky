@tool
extends "res://worlds/world_01/level_01/expansion/floating_platform.gd"

var timer := -1.0
@onready var resting_position := position

func _ready() -> void:
	super()
	if not Engine.is_editor_hint():
		$Sensor.body_entered.connect(_on_contact)

func _on_contact(body: Node3D) -> void:
	if timer < 0 and body.is_in_group("player") and body.global_position.y > global_position.y:
		timer = 0

func _physics_process(dt: float) -> void:
	if Engine.is_editor_hint() or timer < 0:
		return
	timer += dt
	if timer >= 3.4:
		position = resting_position
		visible = true
		$Collision.set_deferred("disabled", false)
		timer = -1
	elif timer >= 1.65:
		visible = false
		$Collision.set_deferred("disabled", true)
	elif timer >= .62:
		position = resting_position - Vector3.UP * 10.0 * pow(timer - .62, 2)
	else:
		position.x = resting_position.x + sin(timer * 68.0) * .035
