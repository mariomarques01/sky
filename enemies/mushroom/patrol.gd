extends Area3D
const Spores = preload("res://environment/effects/sparkles.gd")
const ANTICIPATION := .15

@export var limits := Vector2(11.0,15.2)
@export var speed := 1.1
@export var spore_tint := Color("#ffca83")
var direction := -1
var clock := 0.0
var defeated := false
var turn_remaining := 0.0
var attack_remaining := 0.0
var attack_target: CharacterBody3D
@onready var visual := $Visual as Node3D
@onready var visual_scale := visual.scale

func _physics_process(dt: float) -> void:
	if defeated:
		return
	clock += dt
	advance_patrol(dt)
	var previous_target := attack_target
	for body: Node3D in get_overlapping_bodies():
		if body.is_in_group("player"):
			contact_player(body)
			if defeated:
				return
	if is_instance_valid(attack_target):
		if not overlaps_body(attack_target):
			attack_target = null
		elif attack_target == previous_target:
			attack_remaining = maxf(0.0, attack_remaining - dt)
			if attack_remaining <= .0001:
				attack_target.hurt(global_position.x)
				attack_target = null

	var attack_cue := 1.0 - attack_remaining / ANTICIPATION if is_instance_valid(attack_target) else 0.0
	var cue := maxf(turn_cue(), attack_cue)
	visual.scale = visual_scale * Vector3(1.0 + .10 * cue, 1.0 - .20 * cue, 1.0 + .10 * cue)

func advance_patrol(dt: float) -> void:
	var edge := $Edge as RayCast3D
	if turn_remaining > 0.0:
		turn_remaining = maxf(0.0, turn_remaining - dt)
		if turn_remaining <= .0001:
			turn_remaining = 0.0
			direction = -direction
			edge.position.x = direction * .42
	else:
		var limit := limits.x if direction < 0 else limits.y
		if not edge.is_colliding() or (limit - position.x) * direction <= 0:
			turn_remaining = ANTICIPATION
		else:
			position.x = move_toward(position.x, limit, speed * dt)
			if position.x == limit:
				turn_remaining = ANTICIPATION
	visual.position.y = absf(sin(clock * 6)) * .07
	visual.rotation.z = sin(clock * 6) * .065

func turn_cue() -> float:
	return 1.0 - turn_remaining / ANTICIPATION if turn_remaining > 0.0 else 0.0

func prepare_attack(body: CharacterBody3D) -> void:
	if not is_instance_valid(attack_target) or not overlaps_body(attack_target):
		attack_target = body
		attack_remaining = ANTICIPATION

func is_stomp(body: CharacterBody3D) -> bool:
	return body.velocity.y < 0 and body.global_position.y > global_position.y + .48

func contact_player(body: CharacterBody3D) -> void:
	var stomp := is_stomp(body)
	if stomp or body.is_striking():
		defeat(body, stomp)
	else:
		prepare_attack(body)

func defeat(body: CharacterBody3D, stomp: bool) -> void:
	if defeated:
		return
	defeated = true
	if stomp:
		body.stomp_enemy(Input.is_action_pressed("jump"))
	Game.collect(1)
	var t := create_tween()
	if stomp:
		t.tween_interval(body.stomp_stop)
	var base := visual_scale
	var away := signf(global_position.x - body.global_position.x)
	if is_zero_approx(away):
		away = body.facing
	t.tween_property(visual, "scale", base * Vector3(1.24, .48, 1.24), .09)
	t.tween_property(visual, "scale", base, .12)
	t.parallel().tween_property(visual, "position", visual.position + Vector3(.28 * away, .68, 0), .15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(visual, "rotation:z", -away * 1.45, .15)
	t.tween_property(visual, "position:y", .18, .20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(visual, "scale", base * .55, .20)
	t.tween_callback(burst)

func burst() -> void:
	var spores := Spores.new()
	spores.burst_amount = 8
	spores.tint = spore_tint
	spores.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	spores.position = get_parent().to_local(visual.global_position + Vector3.UP * .35)
	get_parent().add_child(spores)
	queue_free()
