extends CharacterBody3D
signal impact
signal ground_pound(point: Vector3)

const GroundDust = preload("res://environment/effects/GroundDust.tscn")
const STOMP_STOP_SECONDS := 0.05
@export var run_speed := 6.6
@export var crouch_speed := 2.2
@export var crouch_height := 0.92
@export var slide_speed := 9.0
@export var slide_braking := 19.0
@export var acceleration := 21.0
@export var braking := 35.0
@export var air_control := .7
@export var jump_speed := 8.6
@export var double_jump_multiplier := 1.22
@export var gravity := 23.0
@export var grace := .13
@export var buffer_window := .14
var facing := 1.0
var coyote := 0.0
var buffered := 0.0
var jumps := 0
@onready var dash := $Dash as Node
var stun := 0.0
var recovery := 0.0
var landing := 0.0
var stomp_stop := 0.0
var slide_dust_timer := 0.0
var crouched := false
var sliding := false
const CHAIN_WINDOW := .25
const WALL_WINDOW := .233
const POUND_WINDUP := .5

var air_move: StringName = &""
var chain_stage := 0
var chain_time := 0.0
var ground_jump_stage := 0
var wall_time := 0.0
var wall_direction := 0.0
var last_kick_wall: RID
var skid_direction := 0.0
var pound_time := 0.0
var dive_used := false
var belly_slide := false
const STRIKE_DURATIONS := [.467, .533, .867]
const STRIKE_ACTIVE_FROM := [.067, .033, 0.0]
const STRIKE_ACTIVE_TO := [.167, .133, .267]
var strike_index := -1
var strike_time := 0.0
var combo_buffered := false
var slope_slide := false
var cannon: Node3D
var pole_height := 0.0
var pole: Node3D
var pole_cooldown := 0.0
var ledge: Node3D
var ledge_local_top := Vector3.ZERO
var ledge_local_hang := Vector3.ZERO
var ledge_elapsed := 0.0
var ledge_cooldown := 0.0
var standing_capsule: CapsuleShape3D
@onready var collision: CollisionShape3D = $Collision
@onready var capsule := collision.shape as CapsuleShape3D
@onready var states := $State as Node
@onready var health := $Health as Node
func _ready() -> void:
	standing_capsule = capsule.duplicate() as CapsuleShape3D

func update_stance(wants_crouch: bool) -> void:
	if wants_crouch == crouched:
		return
	if not wants_crouch:
		if not capsule_fits(global_position):
			return
	crouched = wants_crouch
	capsule.height = crouch_height if crouched else standing_capsule.height
	collision.position.y = capsule.height * .5

func capsule_fits(feet: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = standing_capsule
	query.transform = Transform3D(global_basis, feet + Vector3.UP * (standing_capsule.height * .5 + .015))
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func surface_between(start: Vector3, end: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(start, end, collision_mask, [get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query)

func try_ledge(normal: Vector3) -> bool:
	if ledge_cooldown > 0 or velocity.y > 0 or crouched:
		return false
	var probe := global_position - Vector3.RIGHT * signf(normal.x) * (capsule.radius + .22)
	var top := surface_between(probe + Vector3.UP * 1.32, probe + Vector3.UP * .72)
	if top.is_empty() or top.normal.y < .85 or not capsule_fits(top.position + Vector3.UP * .02):
		return false
	if not surface_between(global_position, global_position - Vector3.UP * .33).is_empty():
		return false
	ledge = top.collider as Node3D
	if not is_instance_valid(ledge):
		return false
	var hang := global_position
	hang.y = top.position.y - .95
	ledge_local_top = ledge.to_local(top.position + Vector3.UP * .02)
	ledge_local_hang = ledge.to_local(hang)
	ledge_elapsed = 0
	velocity = Vector3.ZERO
	wall_time = 0
	air_move = &""
	return true

func update_ledge(axis: float, dt: float) -> void:
	ledge_elapsed += dt
	var top := ledge.to_global(ledge_local_top)
	global_position = ledge.to_global(ledge_local_hang)
	var toward := signf(top.x - global_position.x)
	if Input.is_action_just_pressed("crouch") or (ledge_elapsed >= .2 and axis * toward < -.2):
		ledge = null
		ledge_cooldown = .35
	elif Input.is_action_just_pressed("jump") or (ledge_elapsed >= .33 and axis * toward > .2):
		if capsule_fits(top):
			global_position = top
			ledge = null
			ledge_cooldown = .35
			landing = .08
			buffered = 0
	states.enter(&"LedgeHang")
	$Visual.update_pose(&"LedgeHang", toward, 0, dt, health.shield)

func try_grab_pole() -> void:
	if pole_cooldown > 0 or not Input.is_action_pressed("climb"):
		return
	for candidate in get_tree().get_nodes_in_group("climb_pole"):
		var anchor := candidate as Node3D
		var offset := anchor.to_local(global_position) if anchor.is_in_group("swing_vine") else global_position - anchor.global_position
		if absf(offset.x) <= .55 and offset.y >= -.1 and offset.y <= 2.9:
			pole_height = offset.y
			pole = anchor
			reset_pole_motion()
			return

func reset_pole_motion() -> void:
	velocity = Vector3.ZERO
	air_move = &""
	coyote = 0
	chain_time = 0
	ground_jump_stage = 0
	wall_time = 0
	dash.remaining = 0

func update_pole(axis: float, dt: float) -> void:
	var anchor := pole.global_position
	if Input.is_action_just_pressed("jump"):
		pole = null
		pole_cooldown = .4
		facing = signf(axis) if absf(axis) > .1 else facing
		velocity = Vector3(facing * 5.6, jump_speed * 1.36, 0)
		jumps = 1
		air_move = &"PoleJump"
		return
	var climb_speed := 0.0
	if Input.is_action_pressed("climb"):
		climb_speed = 1.9
	elif Input.is_action_pressed("crouch"):
		climb_speed = -3.6
	var height := clampf(global_position.y + climb_speed * dt, anchor.y, anchor.y + 2.9)
	var feet := Vector3(anchor.x, height, 0)
	if pole.is_in_group("swing_vine"):
		pole_height = clampf(pole_height + climb_speed * dt, 0.0, 2.9)
		feet = pole.to_global(Vector3.UP * pole_height)
		height = anchor.y + pole_height
	if capsule_fits(feet):
		global_position = feet
	if climb_speed < 0 and height <= anchor.y:
		pole = null
		pole_cooldown = .4
	states.enter(&"Climb")
	$Visual.update_pose(&"Climb", facing, absf(climb_speed), dt, health.shield)

func wind_at_player() -> float:
	var gust := 0.0
	for zone in get_tree().get_nodes_in_group("movement_wind"):
		if zone is Area3D and zone.overlaps_body(self):
			gust += float(zone.get_meta("horizontal_speed", 2.0))
	return gust

func enter_cannon(barrel: Node3D) -> void:
	if recovery > 0 or stun > 0 or is_instance_valid(cannon):
		return
	reset_moves()
	cannon = barrel
	velocity = Vector3.ZERO
	dash.remaining = 0
	sliding = false
	buffered = 0
	stomp_stop = 0
	global_position = cannon.global_position
	states.enter(&"Cannon")

func update_cannon() -> void:
	if not (Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("dive") or Input.is_action_just_pressed("touch_attack")):
		return
	velocity = cannon.launch_velocity()
	cannon = null
	facing = signf(velocity.x)
	dash.air_available = true
	air_move = &"Jump"
	jumps = 1
	coyote = 0

func reset_moves() -> void:
	cannon = null
	strike_index = -1
	combo_buffered = false
	pole = null
	pole_cooldown = 0
	ledge = null
	ledge_cooldown = 0
	slope_slide = false
	air_move = &""
	chain_stage = 0
	chain_time = 0
	ground_jump_stage = 0
	wall_time = 0
	last_kick_wall = RID()
	skid_direction = 0
	pound_time = 0
	dive_used = false
	belly_slide = false

func strike_is_active() -> bool:
	return strike_index >= 0 and strike_time >= STRIKE_ACTIVE_FROM[strike_index] and strike_time <= STRIKE_ACTIVE_TO[strike_index]

func is_striking() -> bool:
	return strike_is_active() or sliding or belly_slide or slope_slide or air_move in [&"Dive", &"AirKick", &"GroundPound"]

func hurt(source_x: float) -> void:
	if recovery == 0 and stomp_stop <= 0.0 and health.hit():
		impact.emit()
		Audio.vibrate(45)
		if Game.health <= 0:
			die()
		else:
			reset_moves()
			stun = .23
			dash.remaining = 0
			sliding = false
			var away := signf(global_position.x - source_x)
			velocity = Vector3(4 * (away if away != 0 else -facing), 4, 0)
func die() -> void:
	stomp_stop = 0.0
	reset_moves()
	states.enter(&"Death")
	recovery = .35
	sliding = false
	coyote = 0
	buffered = 0
	landing = 0
	velocity = Vector3.ZERO
func bounce(launch_speed := 0.0) -> void:
	reset_moves()
	sliding = false
	coyote = 0
	velocity.y = launch_speed if launch_speed > 0 else jump_speed * .82
	air_move = &"Bounce"
	jumps = 1
	dash.air_available = true
func stomp_enemy(held: bool) -> void:
	bounce(jump_speed * 1.12 if held else 0.0)
	stomp_stop = STOMP_STOP_SECONDS
	impact.emit()
	Audio.play(&"stomp")
	Audio.vibrate(28)

func try_jump(axis: float, wants_crouch: bool) -> void:
	update_stance(false)
	if crouched:
		return
	var speed := absf(velocity.x)
	air_move = &"Jump"
	ground_jump_stage = 0
	if wall_time > 0:
		velocity = Vector3(wall_direction * 5.6, jump_speed * 1.36, 0)
		facing = wall_direction
		air_move = &"WallKick"
	elif coyote <= 0:
		velocity.y = jump_speed * double_jump_multiplier
		air_move = &"DoubleJump"
	elif belly_slide:
		velocity.y = jump_speed * .82
		air_move = &"Rollout"
	elif wants_crouch or sliding:
		if speed > 2.34:
			velocity.x = clampf(velocity.x * 1.5, -10.0, 10.0)
			velocity.y = jump_speed * .71
			air_move = &"LongJump"
		else:
			velocity.x = -facing * 3.3
			velocity.y = jump_speed * 1.36
			air_move = &"Backflip"
	elif skid_direction != 0:
		facing = signf(axis) if absf(axis) > .1 else -skid_direction
		velocity = Vector3(facing * 1.9, jump_speed * 1.36, 0)
		air_move = &"SideFlip"
	else:
		ground_jump_stage = 1
		velocity.y = jump_speed
		if chain_time > 0 and chain_stage == 1 and speed >= 1.0:
			ground_jump_stage = 2
			velocity.y = jump_speed * 1.18
			air_move = &"ChainJump"
		elif chain_time > 0 and chain_stage == 2 and speed >= 4.1:
			ground_jump_stage = 3
			velocity.y = jump_speed * 1.5
			air_move = &"TripleJump"
	jumps = 2 if air_move == &"DoubleJump" else 1
	sliding = false
	belly_slide = false
	strike_index = -1
	combo_buffered = false
	skid_direction = 0
	wall_time = 0
	buffered = 0
	coyote = 0
	chain_time = 0
	dash.remaining = 0
	Audio.play(&"jump")

func update_strike(dt: float) -> void:
	var was_active := strike_is_active()
	strike_time += dt
	if combo_buffered and strike_time >= STRIKE_ACTIVE_TO[strike_index]:
		strike_index += 1
		strike_time = 0
		combo_buffered = false
		was_active = false
	if strike_time >= STRIKE_DURATIONS[strike_index]:
		strike_index = -1
		return
	velocity.x = move_toward(velocity.x, facing * 1.8 if strike_is_active() else 0.0, 26.0 * dt)
	if not strike_is_active():
		return
	if not was_active:
		Audio.play(&"punch")
	var contact := surface_between(global_position + Vector3.UP * .34,
		global_position + Vector3.UP * .34 + Vector3.RIGHT * facing * .78)
	if not contact.is_empty() and contact.collider.has_method("take_movement_hit"):
		contact.collider.call("take_movement_hit")

func start_dive(grounded: bool, attack_only := false) -> void:
	if dive_used or crouched or dash.remaining > 0:
		return
	var speed := absf(velocity.x)
	if grounded and (attack_only or speed < run_speed * .87):
		if strike_index < 0:
			strike_index = 0
			strike_time = 0
			chain_time = 0
		elif strike_index < 2:
			combo_buffered = true
		return
	dive_used = true
	chain_time = 0
	ground_jump_stage = 0
	coyote = 0
	wall_time = 0
	skid_direction = 0
	if not grounded and (attack_only or speed < run_speed * .87):
		air_move = &"AirKick"
		velocity.y = 4.9
		return
	air_move = &"Dive"
	velocity.x = facing * minf(speed + 3.52, 10.5)
	velocity.y = 4.9 if grounded else maxf(velocity.y, 0.0)

func try_step_up(dt: float) -> bool:
	var motion := Vector3(velocity.x * dt, 0, 0)
	if motion.length() < .001:
		return false
	var contact := KinematicCollision3D.new()
	if not test_move(global_transform, motion, contact) or contact.get_normal().y > .65:
		return false
	var obstacle := contact.get_collider() as Node
	if is_instance_valid(obstacle) and obstacle.has_method("take_movement_hit"):
		return false
	var lift := Vector3.UP * .36
	var raised := global_transform.translated(lift)
	var forward := Vector3.RIGHT * signf(motion.x) * maxf(motion.length(), capsule.radius + .06)
	if test_move(global_transform, lift) or test_move(raised, forward):
		return false
	if not test_move(raised.translated(forward), -lift, contact) or contact.get_normal().y < .7:
		return false
	var height := lift.y + contact.get_travel().y
	if height < .008 or height > lift.y:
		return false
	global_position.y += height + .004
	$Visual.soften_step(height)
	return true

func handle_wall(pre_velocity: Vector3, grounded_before: bool, rushing: bool) -> void:
	if not is_on_wall() or absf(get_wall_normal().x) <= .7:
		return
	var normal := get_wall_normal()
	var incoming := -pre_velocity.dot(normal)
	for index in get_slide_collision_count():
		var contact := get_slide_collision(index)
		var target := contact.get_collider()
		if incoming > 1.0 and is_striking() and is_instance_valid(target) and target.has_method("take_movement_hit"):
			target.call("take_movement_hit")
	if rushing or (not grounded_before and incoming >= 8.5):
		dash.remaining = 0
		sliding = false
		belly_slide = false
		if not is_on_floor() and air_move != &"GroundPound":
			air_move = &"Bonk"
			velocity.x = signf(normal.x) * 2.4
			velocity.y = minf(velocity.y, 1.5)
		impact.emit()
	elif not is_on_floor() and incoming >= 3.3 and air_move not in [&"GroundPound", &"PoundWindup"]:
		if Input.get_axis("left", "right") * normal.x < -.1 and try_ledge(normal):
			return
		for index in get_slide_collision_count():
			var contact := get_slide_collision(index)
			if contact.get_normal().dot(normal) < .9 or contact.get_collider_rid() == last_kick_wall:
				continue
			last_kick_wall = contact.get_collider_rid()
			wall_direction = signf(normal.x)
			wall_time = WALL_WINDOW
			ground_jump_stage = 0
			break

func update_horizontal(axis: float, dt: float, grounded: bool) -> void:
	if air_move in [&"GroundPound", &"PoundWindup"]:
		velocity.x = 0
	elif not grounded and air_move == &"Dive":
		return
	elif grounded and slope_slide and coyote > 0:
		var downslope := get_floor_normal().x
		velocity.x = clampf((velocity.x + downslope * 40.0 * dt) * exp(-2.5 * dt), -10, 10)
	elif grounded and (sliding or belly_slide):
		var friction := 5.5 if belly_slide else slide_braking
		velocity.x = move_toward(velocity.x, 0, friction * dt)
		if absf(velocity.x) <= crouch_speed:
			sliding = false
			belly_slide = false
	elif grounded and skid_direction != 0:
		velocity.x = move_toward(velocity.x, 0, braking * dt)
		if is_zero_approx(velocity.x):
			skid_direction = 0
			velocity.x = axis * 1.65
	else:
		var rate := acceleration
		if is_zero_approx(axis):
			rate = braking
		elif grounded and absf(axis) < .99:
			rate *= lerpf(1.0, .55, clampf(absf(velocity.x) / run_speed, 0.0, 1.0))
		if not grounded and air_move == &"LongJump":
			rate = 3.4
		velocity.x = move_toward(velocity.x, axis * (crouch_speed if crouched else run_speed),
			rate * dt * (1.0 if grounded else air_control))

func update_vertical(dt: float) -> void:
	if dash.remaining > 0:
		velocity.y = 0
	elif air_move == &"PoundWindup":
		pound_time += dt
		velocity.y = maxf(0, 4.5 * (1.0 - pound_time / .333))
		if pound_time >= POUND_WINDUP:
			air_move = &"GroundPound"
			velocity.y = -11.72
	else:
		var gravity_scale := .5 if air_move == &"LongJump" else 1.0
		velocity.y = maxf(-18, velocity.y - gravity * gravity_scale * dt)
		if wall_time > 0:
			velocity.y = maxf(velocity.y, -2.5)

func emit_ground_dust(direction: Vector3, particles: int) -> void:
	var dust := GroundDust.instantiate() as CPUParticles3D
	dust.position = position + Vector3(0.0, 0.09, 0.25)
	dust.direction = direction
	dust.amount = particles
	get_parent().add_child(dust)

func handle_landing(incoming: Vector3) -> void:
	if air_move == &"GroundPound":
		Audio.play(&"pound")
		Audio.vibrate(40)
		emit_ground_dust(Vector3.UP, 13)
	elif incoming.y <= -2.8:
		Audio.play(&"land", -4.0)
		emit_ground_dust(Vector3.UP, 7)
	landing = .08
	wall_time = 0
	last_kick_wall = RID()
	dive_used = false
	chain_stage = ground_jump_stage
	chain_time = CHAIN_WINDOW if chain_stage > 0 else 0.0
	ground_jump_stage = 0
	if air_move == &"Dive":
		belly_slide = absf(velocity.x) > crouch_speed
	elif air_move == &"GroundPound":
		ground_pound.emit(global_position)
		for target in get_tree().get_nodes_in_group("slam_target"):
			if target is Node3D and target.global_position.distance_to(global_position) <= 1.45:
				target.call("take_movement_hit")
		stun = maxf(stun, .12)
	if air_move == &"GroundPound" or -incoming.y >= 12.0:
		impact.emit()
	air_move = &""
	for index in get_slide_collision_count():
		var contact := get_slide_collision(index)
		var surface := contact.get_collider() as Node
		if contact.get_normal().y <= .7 or not is_instance_valid(surface):
			continue
		if incoming.y < -1.0 and surface.is_in_group("surprise_crate") and surface.break_from_above(self):
			bounce()
			break
		if surface.has_method("bounce_strength"):
			bounce(float(surface.call("bounce_strength")))
			break

func _physics_process(dt: float) -> void:
	if is_instance_valid(cannon):
		update_cannon()
		return
	if stomp_stop > 0.0:
		stomp_stop = maxf(0.0, stomp_stop - dt)
		if stomp_stop < 0.0001:
			stomp_stop = 0.0
		return
	if recovery > 0:
		recovery = maxf(0,recovery-dt)
		$Visual.update_pose(&"Death", facing, 0, dt, 0)
		$Visual.death_arc(1.0 - recovery / .35)
		if recovery == 0:
			global_position = Game.checkpoint
			health.restore()
			states.enter(&"Respawn")
			dash.reset()
			$Visual.scale = Vector3.ONE
			$Visual.reset_after_death()
			stun = 0
			jumps = 0
		return
	ledge_cooldown = maxf(0, ledge_cooldown - dt)
	if is_instance_valid(ledge):
		update_ledge(Input.get_axis("left", "right"), dt)
		return
	pole_cooldown = maxf(0, pole_cooldown - dt)
	if stun <= 0 and not is_instance_valid(pole):
		try_grab_pole()
	if is_instance_valid(pole):
		update_pole(Input.get_axis("left", "right"), dt)
		return
	var floor_before := is_on_floor()
	slope_slide = floor_before and get_floor_angle() > deg_to_rad(15.0 if slope_slide else 38.0)
	if floor_before and not (air_move == &"Bounce" and velocity.y > 0):
		coyote = grace
		jumps = 0
		dash.air_available = true
	else:
		coyote = maxf(0,coyote-dt)
	buffered = buffer_window if Input.is_action_just_pressed("jump") else maxf(0,buffered-dt)
	dash.tick(dt,floor_before)
	stun = maxf(0,stun-dt)
	landing = maxf(0,landing-dt)
	chain_time = maxf(0, chain_time - dt)
	wall_time = maxf(0, wall_time - dt)
	var raw_axis := Input.get_axis("left", "right")
	var axis := raw_axis * absf(raw_axis)
	var wants_crouch := Input.is_action_pressed("crouch")
	var crouch_pressed := Input.is_action_just_pressed("crouch")
	if floor_before and stun <= 0 and dash.remaining <= 0 and not belly_slide:
		if crouch_pressed and absf(velocity.x) >= run_speed * .85:
			sliding = true
			velocity.x = signf(velocity.x) * slide_speed
		elif not crouched and skid_direction == 0 and absf(velocity.x) >= run_speed * .5 and axis * velocity.x < -.1:
			skid_direction = signf(velocity.x)
	update_stance(sliding or belly_slide or (wants_crouch and floor_before))
	if stun <= 0:
		if floor_before and absf(axis) > .1 and dash.remaining <= 0 and not sliding and not belly_slide and skid_direction == 0:
			facing = signf(axis)
		if not floor_before and crouch_pressed and air_move not in [&"PoundWindup", &"GroundPound"]:
			air_move = &"PoundWindup"
			pound_time = 0
			ground_jump_stage = 0
			dash.remaining = 0
			wall_time = 0
		if air_move not in [&"PoundWindup", &"GroundPound"]:
			if buffered > 0 and (coyote > 0 or jumps < 2 or wall_time > 0):
				try_jump(axis, wants_crouch)
			if Input.is_action_just_released("jump") and velocity.y > 2 and air_move not in [&"TripleJump", &"Backflip", &"SideFlip", &"Dive", &"AirKick"]:
				velocity.y *= .52
			if Input.is_action_just_pressed("touch_attack"):
				start_dive(floor_before and air_move == &"", true)
			elif Input.is_action_just_pressed("dive"):
				start_dive(floor_before and air_move == &"")
			if Input.is_action_just_pressed("dash") and not crouched:
				if not floor_before and absf(axis) > .1:
					facing = signf(axis)
				dash.launch(floor_before)
				if dash.remaining > 0:
					air_move = &""
					ground_jump_stage = 0
		if dash.remaining > 0:
			strike_index = -1
			combo_buffered = false
			velocity.x = facing * dash.speed
		elif strike_index >= 0 and floor_before:
			update_strike(dt)
		else:
			update_horizontal(axis, dt, floor_before)
	update_vertical(dt)
	velocity.z = 0
	var wind := wind_at_player() * (.5 if floor_before else 1.0)
	velocity.x += wind
	var pre_velocity := velocity
	var rushing: bool = sliding or belly_slide or dash.remaining > 0 or air_move == &"Dive"
	var stepped := floor_before and air_move == &"" and pre_velocity.y <= 0 and try_step_up(dt)
	move_and_slide()
	if stepped:
		apply_floor_snap()
	if not is_on_wall():
		velocity.x -= wind
	handle_wall(pre_velocity, floor_before, rushing)
	if not is_on_floor():
		sliding = false
		belly_slide = false
		skid_direction = 0
		strike_index = -1
		combo_buffered = false
	position.z = 0
	if position.y < -7:
		die()
		return
	if is_on_floor() and not floor_before:
		handle_landing(pre_velocity)
	if is_on_floor() and (sliding or belly_slide or slope_slide or skid_direction != 0) and absf(velocity.x) > 2.0:
		slide_dust_timer -= dt
		if slide_dust_timer <= 0.0:
			emit_ground_dust(Vector3(-signf(velocity.x), 0.38, 0.0).normalized(), 4)
			slide_dust_timer = 0.10
	else:
		slide_dust_timer = 0.0
	var next := &"Idle"
	if stun>0: next = &"Hurt"
	elif dash.remaining>0: next = &"Dash"
	elif wall_time > 0: next = &"WallSlide"
	elif not is_on_floor(): next = air_move if air_move != &"" and (air_move != &"Jump" or velocity.y > 0) else &"Fall"
	elif strike_index >= 0: next = &"Kick" if strike_index == 2 else &"Punch"
	elif belly_slide: next = &"BellySlide"
	elif slope_slide: next = &"SlopeSlide"
	elif skid_direction != 0: next = &"Skid"
	elif sliding: next = &"Slide"
	elif crouched: next = &"Crouch"
	elif landing>0: next = &"Landing"
	elif absf(velocity.x)>4: next = &"Run"
	elif absf(velocity.x)>.1: next = &"Walk"
	states.enter(next)
	$Visual.update_pose(next,facing,absf(velocity.x),dt,health.shield,velocity.y,landing)
