extends Node3D

const BLEND_TIME := .14
const LEG_BONES := [["LeftUpLeg", "LeftLeg", "LeftFoot"], ["RightUpLeg", "RightLeg", "RightFoot"]]

@export_range(0.0, 0.4, 0.01) var stretch_intensity := 0.14
@export_range(0.0, 0.4, 0.01) var landing_squash := 0.22

@onready var explorer: Node3D = $Explorer
@onready var rig := explorer.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
@onready var library := explorer.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
var rest: Array[Transform3D] = []
var blend_from: Array[Transform3D] = []
var spin_from := Quaternion.IDENTITY
var pose_name: StringName
var pose_time := 0.0
var gait := 0.0
var low_gait := 0.0
var step_offset := 0.0

func _ready() -> void:
	rig.reset_bone_poses()
	for index in rig.get_bone_count():
		rest.append(rig.get_bone_global_rest(index))
	library.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL

func soften_step(rise: float) -> void:
	step_offset -= rise
	position.y = step_offset

func update_pose(next: StringName, facing: float, speed: float, dt: float, shield: float, vertical_speed := 0.0, landing := 0.0) -> void:
	var height := 1.0 + stretch_intensity * clampf(vertical_speed / 10.0, 0.0, 1.0)
	height -= landing_squash * clampf(landing / 0.08, 0.0, 1.0)
	var width := 1.0 / sqrt(height)
	scale = Vector3(width, height, width)
	$DashTrail.emitting = next == &"Dash"
	if next != pose_name:
		blend_from.clear()
		for index in rig.get_bone_count():
			blend_from.append(rig.get_bone_pose(index))
		spin_from = explorer.quaternion
		pose_name = next
		pose_time = 0
	pose_time += dt
	rotation.y = lerp_angle(rotation.y, facing * PI / 2.0, 1.0 - exp(-18.0 * dt))
	step_offset = move_toward(step_offset, 0.0, 2.8 * dt)
	position.y = step_offset

	if next in [&"Walk", &"Run"]:
		var clip := &"Running" if next == &"Run" else &"Walking"
		var stride := 2.6 if next == &"Run" else 1.65
		gait = fposmod(gait + speed * dt / stride, 1.0)
		if library.current_animation != clip:
			library.play(clip)
		library.seek(gait * library.get_animation(clip).length, true)
		# Keep the stride, with a tighter arm swing around the cuffs and belt.
		for side in ["Left", "Right"]:
			for label in ["Arm", "ForeArm", "Hand"]:
				var index := joint(side + label)
				var neutral := rig.get_bone_rest(index).basis.get_rotation_quaternion()
				var animated := rig.get_bone_pose_rotation(index)
				rig.set_bone_pose_rotation(index, neutral.slerp(animated, .63))
	else:
		rig.reset_bone_poses()
		pose_action(next, speed, dt, vertical_speed)

	var weight := smoothstep(0.0, BLEND_TIME, pose_time)
	if weight < 1.0:
		for index in rig.get_bone_count():
			rig.set_bone_pose(index, blend_from[index].interpolate_with(rig.get_bone_pose(index), weight))

	var spin := Vector3.ZERO
	match next:
		&"Run":
			spin.x = deg_to_rad(12.0) * clampf(speed / 7.0, 0.0, 1.0)
		&"Skid", &"Slide", &"SlopeSlide":
			spin.x = deg_to_rad(-16.0) * clampf(speed / 9.0, 0.0, 1.0)
		&"TripleJump", &"SideFlip", &"Rollout":
			spin.x = TAU * smoothstep(0.0, .54, pose_time)
		&"Backflip":
			spin.x = -TAU * smoothstep(0.0, .6, pose_time)
		&"PoundWindup":
			spin.x = TAU * smoothstep(0.0, .5, pose_time)
	explorer.quaternion = spin_from.slerp(Quaternion.from_euler(spin), weight)
	var pivot := Vector3.UP * .72
	explorer.position = pivot - explorer.basis * pivot
	visible = shield <= 0 or fmod(shield, .14) < .1

func death_arc(progress: float) -> void:
	position.y = 4.0 * progress * (1.0 - progress) - 0.65 * progress
	explorer.rotation.x = TAU * progress
	var pivot := Vector3.UP * 0.72
	explorer.position = pivot - explorer.basis * pivot

func reset_after_death() -> void:
	step_offset = 0.0
	position.y = 0.0
	explorer.rotation = Vector3.ZERO
	explorer.position = Vector3.ZERO

func joint(label: String) -> int:
	return rig.find_bone("mixamorig_" + label)

func pitch(label: String, degrees: float) -> void:
	var index := joint(label)
	var pose := rig.get_bone_global_pose(index)
	pose.basis = Basis(Vector3.RIGHT, deg_to_rad(degrees)) * pose.basis
	rig.set_bone_global_pose(index, pose)

func aim_bone(index: int, child: int, destination: Vector3) -> void:
	var pose := rig.get_bone_global_pose(index)
	var current := rig.get_bone_global_pose(child).origin - pose.origin
	var target := destination - pose.origin
	pose.basis = Basis(Quaternion(current.normalized(), target.normalized())) * pose.basis
	rig.set_bone_global_pose(index, pose)

func plant_leg(side: int, offset: Vector3, foot_pitch: float) -> void:
	var upper := joint(LEG_BONES[side][0])
	var knee := joint(LEG_BONES[side][1])
	var foot := joint(LEG_BONES[side][2])
	var hip := rig.get_bone_global_pose(upper).origin
	var thigh := rest[upper].origin.distance_to(rest[knee].origin)
	var shin := rest[knee].origin.distance_to(rest[foot].origin)
	var toward := rest[foot].origin + offset - hip
	var distance := clampf(toward.length(), absf(thigh - shin) + .001, thigh + shin - .001)
	var axis := toward.normalized()
	var forward := (Vector3.BACK - axis * axis.z).normalized()
	var along := (thigh * thigh - shin * shin + distance * distance) / (2.0 * distance)
	var knee_target := hip + axis * along + forward * sqrt(maxf(0.0, thigh * thigh - along * along))
	aim_bone(upper, knee, knee_target)
	aim_bone(knee, foot, hip + axis * distance)
	var ankle := rig.get_bone_global_pose(foot)
	ankle.basis = Basis(Vector3.RIGHT, deg_to_rad(foot_pitch)) * rest[foot].basis
	rig.set_bone_global_pose(foot, ankle)

func pose_action(next: StringName, speed: float, dt: float, vertical_speed: float) -> void:
	var sink := .008 * sin(3.8 * pose_time)
	var lean := sink * 100.0
	var arms := Vector2.ZERO
	var feet := [Vector3.ZERO, Vector3.ZERO]
	var toe_angle := 0.0
	match next:
		&"Crouch":
			sink = .26
			lean = 31.0
			arms = Vector2(-28.0, -28.0)
			low_gait = fposmod(low_gait + minf(speed / .57, 5.5) * dt, 1.0)
			for side in 2:
				var phase := fposmod(low_gait + side * .5, 1.0)
				if phase < .6:
					feet[side].z = lerpf(.16, -.16, phase / .6)
				else:
					var swing := (phase - .6) / .4
					feet[side].z = lerpf(-.16, .16, smoothstep(0.0, 1.0, swing))
					feet[side].y = sin(PI * swing) * .07
				feet[side] *= smoothstep(.03, .65, speed)
		&"Slide", &"SlopeSlide", &"Skid":
			sink = .24
			lean = -22.0
			arms = Vector2(-36.0, -43.0)
			feet[0].z = .23
			feet[1].z = .09
		&"Dive", &"BellySlide":
			sink = .26 if next == &"BellySlide" else .10
			lean = 63.0
			arms = Vector2(-96.0, -96.0)
			feet[0] = Vector3(0, .18, -.22)
			feet[1] = Vector3(0, .14, -.16)
		&"Landing", &"Hurt", &"Bonk":
			sink = .14 * (1.0 - smoothstep(.02, .22, pose_time))
			lean = 24.0 if next == &"Landing" else -21.0
			arms = Vector2(-32.0, 16.0)
		&"Jump", &"DoubleJump", &"ChainJump", &"TripleJump", &"Backflip", &"SideFlip", &"Bounce", &"WallKick", &"PoleJump", &"Fall", &"Rollout":
			var tuck := smoothstep(-8.0, 4.0, vertical_speed)
			lean = lerpf(-8.0, 18.0, tuck)
			arms = Vector2(-18.0 - 29.0 * tuck, 12.0 - 30.0 * tuck)
			feet[0] = Vector3(0, .055 + .19 * tuck, .035 + .14 * tuck)
			feet[1] = Vector3(0, .025 + .12 * tuck, -.085)
			toe_angle = 13.0 * tuck
		&"LongJump", &"AirKick", &"Kick":
			lean = 25.0 if next == &"LongJump" else -20.0
			arms = Vector2(-73.0, -19.0)
			feet[0] = Vector3(0, .23, .31)
			feet[1] = Vector3(0, .12, -.18)
		&"PoundWindup", &"GroundPound":
			var tuck := 1.0 if next == &"PoundWindup" else .4
			lean = 30.0 * tuck
			arms = Vector2(-61.0, -61.0)
			feet[0] = Vector3(0, .42, .19) * tuck
			feet[1] = feet[0]
		&"LedgeHang", &"WallSlide", &"Climb":
			var climb := sin(pose_time * 11.0) if next == &"Climb" else 0.0
			arms = Vector2(-140.0 + 24.0 * climb, -140.0 - 24.0 * climb)
			feet[0] = Vector3(0, .15 + .10 * climb, .11)
			feet[1] = Vector3(0, .15 - .10 * climb, .11)
		&"Punch", &"Dash":
			lean = 25.0
			arms = Vector2(-75.0, 27.0)
	var hips := joint("Hips")
	rig.set_bone_pose_position(hips, rig.get_bone_pose_position(hips) - Vector3.UP * sink)
	pitch("Spine", lean)
	pitch("Head", -lean * .43)
	pitch("LeftArm", arms.x)
	pitch("RightArm", arms.y)
	if next == &"Crouch":
		pitch("LeftForeArm", -29.0)
		pitch("RightForeArm", -29.0)
	for side in 2:
		plant_leg(side, feet[side], toe_angle)
