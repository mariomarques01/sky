extends Control

const STICK = preload("res://ui/hud_art/stick.png")
const THUMB = preload("res://ui/hud_art/stick_thumb.png")
const DASH = preload("res://ui/hud_art/dash.png")
const JUMP = preload("res://ui/hud_art/jump.png")

var stick_center := Vector2.ZERO
var jump_center := Vector2.ZERO
var dash_center := Vector2.ZERO
var unit := 1.0
var stick_vector := Vector2.ZERO
var stick_finger := -1
var jump_fingers: Dictionary = {}
var dash_finger := -1
var dash_origin := Vector2.ZERO
var dive_swipe := false
var active_actions: Dictionary = {}
var pulses: Dictionary = {}
var pulse_version := 0

func layout() -> void:
	unit = minf(size.x / 1280.0, size.y / 590.0)
	if size.x < size.y:
		unit *= 1.28
	stick_center = Vector2(134 * unit, size.y - 120 * unit)
	jump_center = size - Vector2(94, 105) * unit
	dash_center = size - Vector2(211, 90) * unit
	queue_redraw()

func paint(texture: Texture2D, center: Vector2, diameter: float, shade: Color) -> void:
	var dimensions := Vector2(texture.get_size()) * (diameter * unit / texture.get_width())
	draw_texture_rect(texture, Rect2(center - dimensions * .5, dimensions), false, shade)

func _draw() -> void:
	if unit <= 0:
		return
	paint(STICK, stick_center, 190, Color(1, 1, 1, .78))
	paint(THUMB, stick_center + stick_vector * 42 * unit, 73, Color.WHITE)
	paint(DASH, dash_center, 89, Color(1, .86, .58) if dash_finger >= 0 else Color.WHITE)
	paint(JUMP, jump_center, 130, Color(1, .86, .58) if not jump_fingers.is_empty() else Color.WHITE)

func set_action(action: StringName, strength: float) -> void:
	var previous := float(active_actions.get(action, 0.0))
	if is_equal_approx(previous, strength):
		return
	if strength > 0:
		active_actions[action] = strength
		Input.action_press(action, strength)
	else:
		active_actions.erase(action)
		Input.action_release(action)

func update_stick(point: Vector2) -> void:
	stick_vector = ((point - stick_center) / (62 * unit)).limit_length()
	var horizontal := absf(stick_vector.x) >= absf(stick_vector.y)
	var strength := clampf((stick_vector.length() - .20) / .70, 0, 1)
	set_action(&"left", strength if horizontal and stick_vector.x < 0 else 0.0)
	set_action(&"right", strength if horizontal and stick_vector.x > 0 else 0.0)
	set_action(&"climb", strength if not horizontal and stick_vector.y < 0 else 0.0)
	set_action(&"crouch", strength if not horizontal and stick_vector.y > 0 else 0.0)

func pulse(action: StringName) -> void:
	pulse_version += 1
	var version := pulse_version
	pulses[action] = version
	set_action(action, 1.0)
	await get_tree().create_timer(.045, true, true).timeout
	if pulses.get(action) == version:
		pulses.erase(action)
		set_action(action, 0.0)

func release_all() -> void:
	for action: StringName in active_actions.keys():
		set_action(action, 0.0)
	stick_finger = -1
	dash_finger = -1
	stick_vector = Vector2.ZERO
	jump_fingers.clear()
	pulses.clear()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if is_visible_in_tree():
		handle_touch(event)

func handle_touch(event: InputEvent) -> void:
	if unit <= 0:
		return
	var handled := false
	if event is InputEventScreenTouch:
		var point: Vector2 = event.position - global_position
		if event.pressed:
			if stick_finger < 0 and point.distance_to(stick_center) <= 95 * unit:
				stick_finger = event.index
				update_stick(point)
				handled = true
			elif point.distance_to(jump_center) <= 65 * unit:
				jump_fingers[event.index] = true
				set_action(&"jump", 1.0)
				handled = true
			elif dash_finger < 0 and point.distance_to(dash_center) <= 48 * unit:
				dash_finger = event.index
				dash_origin = point
				dive_swipe = false
				handled = true
		elif event.index == stick_finger:
			stick_finger = -1
			update_stick(stick_center)
			handled = true
		elif jump_fingers.erase(event.index):
			set_action(&"jump", 0.0 if jump_fingers.is_empty() else 1.0)
			handled = true
		elif event.index == dash_finger:
			dash_finger = -1
			if not dive_swipe and not event.canceled:
				pulse(&"dash")
			handled = true
	elif event is InputEventScreenDrag:
		var point: Vector2 = event.position - global_position
		if event.index == stick_finger:
			update_stick(point)
			handled = true
		elif event.index == dash_finger:
			if not dive_swipe and dash_origin.y - point.y > 37 * unit:
				pulse(&"dive")
				dive_swipe = true
			handled = true
		elif jump_fingers.has(event.index):
			handled = true
	if handled:
		get_viewport().set_input_as_handled()
		queue_redraw()
