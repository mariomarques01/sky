extends CanvasLayer
const Pad = preload("res://ui/touch_pad.gd")
var safe := Control.new()
const STATUS = preload("res://ui/hud_art/status.png")
const HEART = preload("res://ui/hud_art/heart.png")
const CHARGE = preload("res://ui/hud_art/charge.png")
const PAUSE = preload("res://ui/hud_art/pause.png")

var status := TextureRect.new()
var hearts: Array[TextureRect] = []
var totals: Array[Label] = []
var charge := TextureProgressBar.new()
var pause_button := TextureButton.new()
@onready var dash: Node = get_parent().get_node("Player/Dash")
var pad := Pad.new()
var touch_visibility_overridden := false
var modal := ColorRect.new()
var title := Label.new()
var resume := Button.new()
var profile := Button.new()
func panel(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(3)
	box.set_corner_radius_all(radius)
	return box
func label_style(label: Label, px: int, color: Color) -> void:
	label.add_theme_font_override("font",preload("res://ui/fonts/hud.ttf"))
	label.add_theme_font_size_override("font_size",px)
	label.modulate = color
	label.add_theme_constant_override("outline_size",5)
	label.add_theme_color_override("font_outline_color",Color("#362b31"))
func button(b: Button, caption: String, callback: Callable) -> void:
	b.add_theme_font_override("font",preload("res://ui/fonts/hud.ttf"))
	b.text = caption
	b.custom_minimum_size = Vector2(0,74)
	b.add_theme_font_size_override("font_size",32)
	b.add_theme_stylebox_override("normal",panel(Color("#23252fee"),Color("#e4a545"),16))
	b.pressed.connect(callback)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(safe)
	safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe.add_child(status)
	status.texture = STATUS
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for index in 3:
		var heart := TextureRect.new()
		status.add_child(heart)
		heart.texture = HEART
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		heart.position = Vector2(192 + 60 * index, 16)
		hearts.append(heart)
	status.add_child(charge)
	charge.position = Vector2(190, 73)
	charge.texture_progress = CHARGE
	charge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	charge.max_value = 1
	charge.step = 0
	charge.value = 1
	for x in [241, 387, 527]:
		var label := Label.new()
		status.add_child(label)
		label.position = Vector2(x, 120)
		label_style(label, 29, Color("#ffe06e"))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		totals.append(label)
	safe.add_child(pause_button)
	pause_button.texture_normal = PAUSE
	pause_button.ignore_texture_size = true
	pause_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	pause_button.tooltip_text = "Pausar"
	pause_button.pressed.connect(toggle_pause)
	safe.add_child(pad)
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Web play keeps the virtual controls available even when the browser reports no touchscreen.
	pad.visible = OS.has_feature("web") or OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	pad.resized.connect(pad.layout)
	add_child(modal)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.color = Color("#14151edc")
	var center := CenterContainer.new()
	modal.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var stack := VBoxContainer.new()
	center.add_child(stack)
	stack.custom_minimum_size.x = 520
	stack.add_theme_constant_override("separation",18)
	stack.add_child(title)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_style(title,52,Color("#ffe4a7"))
	stack.add_child(resume)
	button(resume,"Continuar",toggle_pause)
	stack.add_child(profile)
	button(profile,"",cycle_profile)
	var restart := Button.new()
	stack.add_child(restart)
	button(restart,"Reiniciar fase",Scenes.restart)
	modal.hide()
	Game.changed.connect(refresh)
	Game.finished.connect(finish)
	get_viewport().size_changed.connect(layout)
	fade_in()
	layout()
	refresh()
func layout() -> void:
	var visible_size := get_viewport().get_visible_rect().size
	safe.position = Vector2.ZERO
	safe.size = visible_size
	if OS.has_feature("web"):
		var region = JavaScriptBridge.eval("""(() => {
			const guide = document.getElementById("skybound-safe-area");
			if (!guide || !innerWidth || !innerHeight) return "";
			const bounds = guide.getBoundingClientRect();
			if (bounds.width <= 0 || bounds.height <= 0) return "";
			return JSON.stringify([bounds.x / innerWidth, bounds.y / innerHeight,
				bounds.width / innerWidth, bounds.height / innerHeight]);
		})()""")
		if region is String and not region.is_empty():
			var rectangle = JSON.parse_string(region)
			if rectangle is Array and rectangle.size() == 4:
				safe.position = Vector2(rectangle[0], rectangle[1]) * visible_size
				safe.size = Vector2(rectangle[2], rectangle[3]) * visible_size
	elif OS.has_feature("mobile"):
		var rect := DisplayServer.get_display_safe_area()
		var screen := Vector2(DisplayServer.window_get_size())
		if screen.x>0 and rect.has_area():
			safe.position = Vector2(rect.position)*visible_size/screen
			safe.size = Vector2(rect.size)*visible_size/screen
	var unit := minf(safe.size.x / 1280.0, safe.size.y / 590.0)
	status.position = Vector2(16, 15) * unit
	status.scale = Vector2.ONE * .555 * unit
	var pause_diameter := 64.0 * unit * (1.25 if safe.size.x < safe.size.y else 1.0)
	pause_button.size = Vector2.ONE * pause_diameter
	pause_button.position = Vector2(safe.size.x - pause_diameter - 16 * unit, 15 * unit)
	pad.layout()

func _process(_delta: float) -> void:
	charge.value = clampf(1.0 - float(dash.cooldown) / maxf(float(dash.recharge), .001), 0, 1) if dash.air_available else 0

func refresh() -> void:
	for index in hearts.size():
		hearts[index].modulate = Color.WHITE if index < Game.health else Color(.33, .30, .35, .73)
	totals[0].text = "%03d" % Game.counts[0]
	totals[1].text = "%02d" % Game.counts[1]
	totals[2].text = str(Game.counts[2])
func cycle_profile() -> void:
	Audio.play(&"ui")
	var world := get_parent()
	var q := (int(world.get("quality"))+1)%3
	world.call("set_quality",q)
	Save.write("video","perfil",q)
	update_profile()
func update_profile() -> void:
	profile.text = "Gráficos · "+str(["Baixo","Médio","Alto"][int(get_parent().get("quality"))])
func toggle_pause() -> void:
	if Game.complete: return
	Audio.play(&"ui")
	modal.visible = not modal.visible
	get_tree().paused = modal.visible
	title.text = "Jardins Celestiais"
	pad.release_all()
	pad.set_process_input(not modal.visible)
	update_profile()
	if modal.visible: resume.grab_focus()
func finish() -> void:
	title.text = "Jardins concluídos"
	resume.hide()
	modal.show()
	pad.release_all()
	pad.set_process_input(false)
	update_profile()
	get_tree().paused = true
	profile.grab_focus()
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"): toggle_pause()
	if event.is_action_pressed("touch_toggle"):
		touch_visibility_overridden = true
		pad.release_all()
		pad.visible = not pad.visible
	if event is InputEventScreenTouch and event.pressed and not touch_visibility_overridden and not pad.visible:
		pad.show()
		if not modal.visible:
			pad.handle_touch(event)

func fade_in() -> void:
	var veil := ColorRect.new()
	add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.color = Color("#283f53")
	var fade := create_tween()
	fade.tween_property(veil,"modulate:a",0.0,.28)
	fade.tween_callback(veil.queue_free)
