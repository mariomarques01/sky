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
const SIZES := [0.8, 1.0, 1.25]
const OPACITIES := [0.4, 0.65, 0.85, 1.0]
var size_button := Button.new()
var opacity_button := Button.new()
var side_button := Button.new()
var size_index := 1
var opacity_index := 3
var menu_buttons: Array[Button] = []
var notice := Label.new()
var result := Label.new()
var restart := Button.new()
var counter_tweens: Dictionary = {}
var notice_tween: Tween
var stack := VBoxContainer.new()

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
	get_window().focus_exited.connect(pad.release_all)
	safe.add_child(pad)
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Web play keeps the virtual controls available even when the browser reports no touchscreen.
	pad.visible = OS.has_feature("web") or OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	pad.resized.connect(pad.layout)
	safe.add_child(modal)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.color = Color("#14151edc")
	var center := CenterContainer.new()
	var scroll := ScrollContainer.new()
	modal.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.add_child(center)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
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
	stack.add_child(size_button)
	button(size_button, "", change_size)
	stack.add_child(opacity_button)
	button(opacity_button, "", change_opacity)
	stack.add_child(side_button)
	button(side_button, "", change_side)
	size_index = clampi(int(Save.data.get_value("toque", "tamanho", 1)), 0, SIZES.size()-1)
	opacity_index = clampi(int(Save.data.get_value("toque", "opacidade", 3)), 0, OPACITIES.size()-1)
	pad.left_handed = bool(Save.data.get_value("toque", "canhoto", false))
	apply_touch_settings()
	stack.add_child(result)
	label_style(result, 36, Color.WHITE)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.hide()
	stack.add_child(restart)
	button(restart,"Reiniciar fase",Scenes.restart)
	menu_buttons = [resume, profile, size_button, opacity_button, side_button, restart]
	modal.hide()
	safe.add_child(notice)
	notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	notice.grow_horizontal = Control.GROW_DIRECTION_BOTH
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice.text = "Checkpoint ativado"
	label_style(notice, 38, Color("#ffe4a7"))
	notice.hide()
	Game.checkpoint_activated.connect(show_checkpoint)
	Game.collected.connect(pulse_counter)
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
		var window := Rect2i(DisplayServer.window_get_position(), DisplayServer.window_get_size())
		var rect := DisplayServer.get_display_safe_area().intersection(window)
		var screen := Vector2(DisplayServer.window_get_size())
		if screen.x>0 and rect.has_area():
			safe.position = Vector2(rect.position - window.position)*visible_size/screen
			safe.size = Vector2(rect.size)*visible_size/screen
	var unit := minf(safe.size.x / 1280.0, safe.size.y / 590.0)
	status.position = Vector2(16, 15) * unit
	status.scale = Vector2.ONE * .555 * unit
	var window_size := Vector2(DisplayServer.window_get_size())
	var pixels_to_ui := visible_size / window_size.max(Vector2.ONE)
	var dpi := DisplayServer.screen_get_dpi(DisplayServer.window_get_current_screen())
	pad.minimum_target = ceilf(9.0 * maxi(dpi, 96) / 25.4 * maxf(pixels_to_ui.x, pixels_to_ui.y))
	for item in menu_buttons:
		item.custom_minimum_size.y = maxf(74.0, pad.minimum_target)
	var pause_diameter := 64.0 * unit * (1.25 if safe.size.x < safe.size.y else 1.0)
	pause_diameter = maxf(pause_diameter, pad.minimum_target)
	pause_button.size = Vector2.ONE * pause_diameter
	pause_button.position = Vector2(safe.size.x - pause_diameter - 16 * unit, 15 * unit)
	pad.layout()

func change_size() -> void:
	size_index = (size_index + 1) % SIZES.size()
	Save.write("toque", "tamanho", size_index)
	apply_touch_settings()

func change_opacity() -> void:
	opacity_index = (opacity_index + 1) % OPACITIES.size()
	Save.write("toque", "opacidade", opacity_index)
	apply_touch_settings()

func change_side() -> void:
	pad.left_handed = not pad.left_handed
	Save.write("toque", "canhoto", pad.left_handed)
	apply_touch_settings()

func apply_touch_settings() -> void:
	pad.size_factor = SIZES[size_index]
	pad.modulate.a = OPACITIES[opacity_index]
	size_button.text = "Tamanho · %d%%" % roundi(pad.size_factor * 100)
	opacity_button.text = "Opacidade · %d%%" % roundi(pad.modulate.a * 100)
	side_button.text = "Direcional · " + ("Direita (canhoto)" if pad.left_handed else "Esquerda")
	pad.layout()

func _process(_delta: float) -> void:
	charge.value = clampf(1.0 - float(dash.cooldown) / maxf(float(dash.recharge), .001), 0, 1) if dash.air_available else 0

func refresh() -> void:
	for index in hearts.size():
		hearts[index].modulate = Color.WHITE if index < Game.health else Color(.33, .30, .35, .73)
	totals[0].text = "%03d" % Game.counts[0]
	totals[1].text = "%02d" % Game.counts[1]
	totals[2].text = str(Game.counts[2])
func pulse_counter(kind: int) -> void:
	if counter_tweens.has(kind):
		counter_tweens[kind].kill()
	var label := totals[kind]
	label.pivot_offset = label.size * .5
	label.scale = Vector2.ONE * 1.32
	var tween := create_tween()
	counter_tweens[kind] = tween
	tween.tween_property(label, "scale", Vector2.ONE, .22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func show_checkpoint() -> void:
	if notice_tween:
		notice_tween.kill()
	notice.modulate.a = 1
	notice.show()
	notice_tween = create_tween()
	notice_tween.tween_interval(1.3)
	notice_tween.tween_property(notice, "modulate:a", 0.0, .3)
	notice_tween.tween_callback(notice.hide)

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
	for item in [resume, profile, size_button, opacity_button, side_button]:
		item.hide()
	notice.hide()
	var seconds := floori(float(get_parent().get("clock")))
	result.text = "Tempo · %d:%02d\nMoedas · %d\nRecorde de cristais dourados · %d" % [
		seconds / 60, seconds % 60, Game.counts[1], Save.data.get_value("Jardins", "recorde", 0)]
	result.show()
	modal.show()
	pad.release_all()
	pad.set_process_input(false)
	update_profile()
	get_tree().paused = true
	restart.grab_focus()
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
