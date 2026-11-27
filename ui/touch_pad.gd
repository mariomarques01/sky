extends Control

const STICK = preload("res://ui/hud_art/stick.png")
const THUMB = preload("res://ui/hud_art/stick_thumb.png")
const HUD_FONT = preload("res://ui/fonts/hud.ttf")
const JUMP = preload("res://ui/hud_art/jump.png")

var stick_center := Vector2.ZERO
var jump_center := Vector2.ZERO
var action_center := Vector2.ZERO
var unit := 1.0
var stick_vector := Vector2.ZERO
var stick_finger := -1
var jump_fingers: Dictionary = {}
var action_finger := -1
var gesture_finger := -1
var gesture_origin := Vector2.ZERO
var size_factor := 1.0
var left_handed := false
var minimum_target := 0.0
var active_actions: Dictionary = {}
var pulses: Dictionary = {}
var pulse_version := 0

func layout() -> void:
	unit = maxf(minf(size.x / 1280.0, size.y / 590.0) * size_factor, minimum_target / 96.0)
	stick_center = Vector2(110, -108) * unit + Vector2.DOWN * size.y
	jump_center = size - Vector2(82, 96) * unit
	action_center = size - Vector2(204, 82) * unit
	if left_handed:
		stick_center.x = size.x - stick_center.x
		jump_center.x = size.x - jump_center.x
		action_center.x = size.x - action_center.x
	queue_redraw()

func paint(texture: Texture2D, center: Vector2, diameter: float, shade: Color) -> void:
	var dimensions := Vector2(texture.get_size()) * (diameter * unit / texture.get_width())
	draw_texture_rect(texture, Rect2(center - dimensions * .5, dimensions), false, shade)

func _draw() -> void:
	if unit <= 0:
		return
	paint(STICK, stick_center, 190, Color(1, 1, 1, .78))
	paint(THUMB, stick_center + stick_vector * 42 * unit, 73, Color.WHITE)
	draw_circle(action_center, 48 * unit, Color("#443c38"))
	draw_arc(action_center, 46 * unit, 0, TAU, 48, Color("#efba66"), 3 * unit, true)
	draw_string(HUD_FONT, action_center + Vector2(-48, 8) * unit, "Ação",
		HORIZONTAL_ALIGNMENT_CENTER, 96 * unit, maxi(1, roundi(23 * unit)),
		Color("#ffcd82") if action_finger >= 0 else Color.WHITE)
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
	action_finger = -1
	gesture_finger = -1
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
			elif action_finger < 0 and point.distance_to(action_center) <= 48 * unit:
				action_finger = event.index
				set_action(&"dive", 1.0)
				handled = true
			elif gesture_finger < 0 and Rect2(Vector2(0, size.y * .5), Vector2(size.x, size.y * .5)).has_point(point):
				gesture_finger = event.index
				gesture_origin = point
				handled = true
		elif event.index == stick_finger:
			stick_finger = -1
			update_stick(stick_center)
			handled = true
		elif jump_fingers.erase(event.index):
			set_action(&"jump", 0.0 if jump_fingers.is_empty() else 1.0)
			handled = true
		elif event.index == action_finger:
			action_finger = -1
			set_action(&"dive", 0)
			handled = true
		elif event.index == gesture_finger:
			gesture_finger = -1
			handled = true
	elif event is InputEventScreenDrag:
		var point: Vector2 = event.position - global_position
		if event.index == stick_finger:
			update_stick(point)
			handled = true
		elif event.index == gesture_finger:
			var travel: Vector2 = point - gesture_origin
			if absf(travel.x) >= 42 * unit and absf(travel.x) > absf(travel.y):
				pulse(&"dash")
				gesture_finger = -1
			handled = true
		elif jump_fingers.has(event.index):
			handled = true
	if handled:
		get_viewport().set_input_as_handled()
		queue_redraw()
