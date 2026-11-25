extends Control
var actions := ["left","right","dash","jump"]
const ICONS := [
	[Vector2(-24,0),Vector2(17,-24),Vector2(17,24)],
	[Vector2(24,0),Vector2(-17,24),Vector2(-17,-24)],
	[Vector2(10,-32),Vector2(-21,5),Vector2(-4,5),Vector2(-11,33),Vector2(24,-9),Vector2(6,-9)],
	[Vector2(0,-30),Vector2(25,-4),Vector2(9,-4),Vector2(9,29),Vector2(-9,29),Vector2(-9,-4),Vector2(-25,-4)]
]
var centers: Array[Vector2] = []
var fingers: Dictionary = {}
var radius := 68.0
func layout() -> void:
	centers = [Vector2(96,size.y-94),Vector2(255,size.y-94),Vector2(size.x-255,size.y-94),Vector2(size.x-96,size.y-94)]
	queue_redraw()
func _draw() -> void:
	for i in centers.size():
		var pos := centers[i]
		draw_circle(pos,radius,Color(.09,.15,.23,.78 if actions[i] in fingers.values() else .46),true,-1,true)
		draw_arc(pos,radius,0,TAU,56,Color(.85,.95,1,.7),4,true)
		var polygon := PackedVector2Array()
		for point: Vector2 in ICONS[i]: polygon.append(pos+point)
		draw_colored_polygon(polygon,Color("#ffcf62") if i==2 else Color("#f0f5fc"))
func release_all() -> void:
	for a: String in fingers.values(): Input.action_release(a)
	fingers.clear()
	queue_redraw()
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	var index: int
	var point: Vector2
	if event is InputEventScreenTouch:
		index = event.index
		point = event.position if event.pressed else Vector2(-500,-500)
	elif event is InputEventScreenDrag:
		index = event.index
		point = event.position
	else: return
	var action := ""
	for i in centers.size():
		if (point-global_position).distance_to(centers[i])<=radius*1.13: action = actions[i]
	var previous: String = fingers.get(index,"")
	if previous==action: return
	fingers.erase(index)
	if previous!="" and previous not in fingers.values(): Input.action_release(previous)
	if action!="":
		fingers[index]=action
		Input.action_press(action)
	queue_redraw()
