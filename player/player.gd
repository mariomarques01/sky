extends CharacterBody3D
signal impact
@export var run_speed := 6.6
@export var crouch_speed := 2.2
@export var crouch_height := 0.92
@export var slide_speed := 9.0
@export var slide_braking := 19.0
@export var acceleration := 21.0
@export var braking := 35.0
@export var air_control := .7
@export var jump_speed := 8.6
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
var crouched := false
var sliding := false
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
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = standing_capsule
		query.transform = Transform3D(global_basis, global_position + Vector3.UP * (standing_capsule.height * .5 + safe_margin))
		query.collision_mask = collision_mask
		query.exclude = [get_rid()]
		if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			return
	crouched = wants_crouch
	capsule.height = crouch_height if crouched else standing_capsule.height
	collision.position.y = capsule.height * .5

func hurt(source_x: float) -> void:
	if recovery == 0 and health.hit():
		impact.emit()
		if Game.health <= 0:
			die()
		else:
			stun = .23
			dash.remaining = 0
			sliding = false
			var away := signf(global_position.x - source_x)
			velocity = Vector3(4 * (away if away != 0 else -facing), 4, 0)
func die() -> void:
	states.enter(&"Death")
	recovery = .35
	sliding = false
	coyote = 0
	buffered = 0
	landing = 0
	velocity = Vector3.ZERO
func bounce() -> void:
	sliding = false
	coyote = 0
	velocity.y = jump_speed*.82
	jumps = 1
	dash.air_available = true
func try_jump() -> void:
	update_stance(false)
	if crouched:
		return
	sliding = false
	jumps = 1 if coyote > 0 else 2
	velocity.y = jump_speed * (1.0 if jumps == 1 else .9)
	buffered = 0
	coyote = 0
	dash.remaining = 0
	Audio.cue(410)

func _physics_process(dt: float) -> void:
	if recovery > 0:
		recovery = maxf(0,recovery-dt)
		$Visual.scale = Vector3.ONE*maxf(.02,recovery/.35)
		if recovery == 0:
			global_position = Game.checkpoint
			health.restore()
			states.enter(&"Respawn")
			dash.reset()
			$Visual.scale = Vector3.ONE
			stun = 0
			jumps = 0
		return
	var floor_before := is_on_floor()
	if floor_before:
		coyote = grace
		jumps = 0
		dash.air_available = true
	else:
		coyote = maxf(0,coyote-dt)
	buffered = buffer_window if Input.is_action_just_pressed("jump") else maxf(0,buffered-dt)
	dash.tick(dt,floor_before)
	stun = maxf(0,stun-dt)
	landing = maxf(0,landing-dt)
	var axis := Input.get_axis("left","right")
	var wants_crouch := Input.is_action_pressed("crouch")
	if floor_before and stun <= 0 and dash.remaining <= 0 \
			and Input.is_action_just_pressed("crouch") and absf(velocity.x) >= run_speed * .85:
		sliding = true
		velocity.x = signf(velocity.x) * slide_speed
	update_stance(sliding or (wants_crouch and floor_before))
	if stun <= 0:
		if absf(axis)>.1 and dash.remaining<=0 and not sliding:
			facing = signf(axis)
		if buffered>0 and (coyote>0 or jumps<2):
			try_jump()
		if Input.is_action_just_released("jump") and velocity.y>2:
			velocity.y *= .52
		if Input.is_action_just_pressed("dash") and not crouched:
			dash.launch(floor_before)
		if dash.remaining>0:
			velocity.x = facing*dash.speed
			velocity.y = 0
		elif sliding:
			velocity.x = move_toward(velocity.x, 0, slide_braking * dt)
			sliding = absf(velocity.x) > crouch_speed
		else:
			var rate := braking if is_zero_approx(axis) else acceleration
			velocity.x = move_toward(velocity.x,axis*(crouch_speed if crouched else run_speed),rate*dt*(1.0 if floor_before else air_control))
	if dash.remaining<=0:
		velocity.y = maxf(-18,velocity.y-gravity*dt)
	velocity.z = 0
	var descent_speed := -velocity.y
	var rushing: bool = sliding or dash.remaining > 0
	move_and_slide()
	if rushing and is_on_wall() and absf(get_wall_normal().x) > .7:
		dash.remaining = 0
		sliding = false
		impact.emit()
	if not is_on_floor():
		sliding = false
	position.z = 0
	if position.y < -7:
		die()
		return
	if is_on_floor() and not floor_before:
		landing = .08
		if descent_speed >= jump_speed * 1.35:
			impact.emit()
	var next := &"Idle"
	if stun>0: next = &"Hurt"
	elif dash.remaining>0: next = &"Dash"
	elif not is_on_floor(): next = (&"DoubleJump" if jumps==2 else &"Jump") if velocity.y>0 else &"Fall"
	elif sliding: next = &"Slide"
	elif crouched: next = &"Crouch"
	elif landing>0: next = &"Landing"
	elif absf(velocity.x)>4: next = &"Run"
	elif absf(velocity.x)>.1: next = &"Walk"
	states.enter(next)
	$Visual.update_pose(next,facing,absf(velocity.x),dt,health.shield)
