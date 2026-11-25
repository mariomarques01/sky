extends CanvasLayer
const Pad = preload("res://ui/touch_pad.gd")
var safe := Control.new()
var health := Label.new()
var totals := Label.new()
var pad := Pad.new()
var modal := ColorRect.new()
var title := Label.new()
var resume := Button.new()
var profile := Button.new()
var portrait := TextureRect.new()
func panel(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(3)
	box.set_corner_radius_all(radius)
	return box
func label_style(label: Label, px: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size",px)
	label.modulate = color
	label.add_theme_constant_override("outline_size",5)
	label.add_theme_color_override("font_outline_color",Color("#362b31"))
func button(b: Button, caption: String, callback: Callable) -> void:
	b.text = caption
	b.custom_minimum_size = Vector2(0,74)
	b.add_theme_font_size_override("font_size",32)
	b.add_theme_stylebox_override("normal",panel(Color("#243c50ed"),Color("#cbab68"),16))
	b.pressed.connect(callback)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(safe)
	safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar := Panel.new()
	safe.add_child(bar)
	bar.position = Vector2(22,20)
	bar.size = Vector2(468,106)
	bar.add_theme_stylebox_override("panel",panel(Color("#203343db"),Color("#a88749"),54))
	var frame := Panel.new()
	bar.add_child(frame)
	frame.position = Vector2(3,3)
	frame.size = Vector2(100,100)
	frame.add_theme_stylebox_override("panel",panel(Color("#d6a653"),Color("#ffe5ac"),50))
	frame.add_child(portrait)
	portrait.position = Vector2(5,5)
	portrait.size = Vector2(90,90)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.texture = preload("res://ui/portrait.jpg")
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){COLOR=texture(TEXTURE,UV); COLOR.a*=1.0-smoothstep(.48,.50,distance(UV,vec2(.5)));}"
	var matte := ShaderMaterial.new()
	matte.shader = shader
	portrait.material = matte
	bar.add_child(health)
	health.position = Vector2(118,0)
	label_style(health,47,Color("#ff6357"))
	bar.add_child(totals)
	totals.position = Vector2(122,56)
	label_style(totals,25,Color("#ffdc84"))
	var pause_button := Button.new()
	safe.add_child(pause_button)
	pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause_button.offset_left = -110
	pause_button.offset_right = -24
	pause_button.offset_top = 24
	button(pause_button,"Ⅱ",toggle_pause)
	safe.add_child(pad)
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.visible = DisplayServer.is_touchscreen_available()
	pad.resized.connect(pad.layout)
	add_child(modal)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.color = Color("#14293bdc")
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
	if OS.has_feature("mobile"):
		var rect := DisplayServer.get_display_safe_area()
		var screen := Vector2(DisplayServer.window_get_size())
		if screen.x>0 and rect.has_area():
			safe.position = Vector2(rect.position)*visible_size/screen
			safe.size = Vector2(rect.size)*visible_size/screen
	pad.layout()
func refresh() -> void:
	health.text = "♥".repeat(Game.health)+"♡".repeat(3-Game.health)
	totals.text = "◆  %03d     ●  %02d     ◈  %d" % Game.counts
func cycle_profile() -> void:
	var world := get_parent()
	var q := (int(world.get("quality"))+1)%3
	world.call("set_quality",q)
	Save.write("video","perfil",q)
	update_profile()
func update_profile() -> void:
	profile.text = "Gráficos · "+str(["Baixo","Médio","Alto"][int(get_parent().get("quality"))])
func toggle_pause() -> void:
	if Game.complete: return
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
		pad.release_all()
		pad.visible = not pad.visible
func fade_in() -> void:
	var veil := ColorRect.new()
	add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.color = Color("#283f53")
	var fade := create_tween()
	fade.tween_property(veil,"modulate:a",0.0,.28)
	fade.tween_callback(veil.queue_free)
