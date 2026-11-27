extends Node

const DustScript = preload("res://environment/effects/ground_dust.gd")
var failed := 0
@onready var world := $World
@onready var player := $World/Player as CharacterBody3D
func check(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ")+label)
	if not condition: failed += 1
func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame
func check_stance() -> void:
	var collision := player.get_node("Collision") as CollisionShape3D
	var capsule := collision.shape as CapsuleShape3D
	var standing_height := capsule.height
	Input.action_press("crouch")
	await frames(3)
	check(capsule.height < standing_height and is_equal_approx(collision.position.y, capsule.height * .5), "agachamento mantém os pés no chão")

	var roof := StaticBody3D.new()
	var roof_collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.5, .2, 1.5)
	roof_collision.shape = box
	roof.add_child(roof_collision)
	add_child(roof)
	roof.global_position = player.global_position + Vector3.UP * 1.23
	await frames(3)
	Input.action_release("crouch")
	await frames(3)
	check(capsule.height < standing_height, "teto bloqueia retorno à postura em pé")
	roof.queue_free()
	await frames(4)
	check(is_equal_approx(capsule.height, standing_height), "retorno à postura em pé após liberar espaço")

func dust_is_visible() -> bool:
	return world.get_children().any(func(child: Node) -> bool: return child.get_script() == DustScript)

func check_slide() -> void:
	player.global_position = Vector3(1.0, .8, 0)
	player.velocity = Vector3.ZERO
	await frames(20)
	check(player.is_on_floor() and dust_is_visible(), "pouso solta poeira")
	Input.action_press("right")
	await frames(24)
	Input.action_press("crouch")
	await frames(2)
	Input.action_release("crouch")
	Input.action_release("right")
	check(player.get("sliding") and player.velocity.x > 6.6, "deslizada conserva impulso após soltar")
	check(dust_is_visible(), "derrapagem solta poeira")
	var wall := StaticBody3D.new()
	var wall_collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(.15, 2, 1.5)
	wall_collision.shape = box
	wall.add_child(wall_collision)
	add_child(wall)
	wall.global_position = player.global_position + Vector3(.65, .6, 0)
	var impacts: Array[bool] = []
	player.connect("impact", func() -> void: impacts.append(true), CONNECT_ONE_SHOT)
	await frames(8)
	check(not player.get("sliding") and impacts.size() == 1, "parede encerra deslizada e registra impacto")
	wall.queue_free()

func check_audio() -> void:
	var music := Audio.music.stream as AudioStreamWAV
	check(Audio.voices.size() == 8 and Audio.music.bus == &"Música" and Audio.music.playing, "oito vozes de efeitos e música dedicada")
	check(music.loop_mode == AudioStreamWAV.LOOP_DISABLED and is_equal_approx(music.get_length(), 4.8)
		and Audio.looping_track.loop_mode == AudioStreamWAV.LOOP_FORWARD
		and is_equal_approx(Audio.looping_track.get_length(), 19.2), "intro única seguida por uma faixa em loop")
	Audio.play(&"jump")
	Audio.play(&"coin")
	Audio.play(&"ui")
	var jump_voice := Audio.voices[0]
	var coin_voice := Audio.voices[1]
	var ui_voice := Audio.voices[2]
	check(jump_voice.playing and coin_voice.playing and ui_voice.playing
		and jump_voice.stream != coin_voice.stream and jump_voice.bus == &"SFX" and ui_voice.bus == &"UI",
		"pulo, moeda, UI e música podem tocar juntos")
	check(jump_voice.pitch_scale >= .94 and jump_voice.pitch_scale <= 1.06, "pitch dos efeitos varia dentro do intervalo")

func measure_stomp(enemy: Area3D, hold_jump: bool) -> float:
	var impact_samples: Array = []
	var record := func() -> void:
		if player.get("stomp_stop") > 0.0:
			impact_samples.append([Engine.get_physics_frames(), player.position])
	player.connect("impact", record)
	if hold_jump:
		Input.action_press("jump")
		await frames(2)
	player.position = enemy.position + Vector3(0, 1.30, 0)
	player.velocity = Vector3(0, -5, 0)
	player.set("buffered", 0.0)
	for frame in 16:
		await frames(1)
		if impact_samples.is_empty():
			continue
		player.disconnect("impact", record)
		var launch := player.velocity.y
		while player.get("stomp_stop") > 0.0:
			await frames(1)
		var impact_frame: int = impact_samples[0][0]
		var impact_position: Vector3 = impact_samples[0][1]
		check(player.position.is_equal_approx(impact_position) and Engine.get_physics_frames() - impact_frame == 3,
			"stomp mantém o impacto por três ciclos a 60 Hz")
		var peak := player.position.y
		for sample in 32:
			await frames(1)
			peak = maxf(peak, player.position.y)
		Input.action_release("jump")
		check(launch > 0 and not is_instance_valid(enemy), "o inimigo derrotado libera o quique")
		return peak - impact_position.y
	player.disconnect("impact", record)
	Input.action_release("jump")
	check(false, "o salto deve atingir o inimigo por cima")
	return 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	check_audio()
	await frames(20)
	check(player.is_on_floor(),"spawn e chão")
	await check_stance()
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("/tmp/sky-start.png")
	var hud := world.get_node("CanvasLayer")
	var pad := hud.get("pad") as Control
	pad.hide()
	var touch_targets: Array[Vector2] = [pad.get("stick_center") + Vector2.RIGHT * 66 * float(pad.get("unit")), pad.get("jump_center"), pad.get("action_center")]
	for index in touch_targets.size():
		var down := InputEventScreenTouch.new()
		down.index=index
		down.pressed=true
		down.position=pad.global_position+touch_targets[index]
		get_viewport().push_input(down,true)
	await frames(2)
	check(pad.visible and Input.is_action_pressed("right") and Input.is_action_pressed("jump") and Input.is_action_pressed("dive"), "primeiro toque revela os controles e permite multitouch")
	for index in touch_targets.size():
		var up := InputEventScreenTouch.new()
		up.index=index
		up.pressed=false
		get_viewport().push_input(up,true)
	var dash_touch := InputEventScreenTouch.new()
	dash_touch.index = 4
	dash_touch.position = pad.global_position + pad.size * Vector2(.5, .75)
	dash_touch.pressed = true
	get_viewport().push_input(dash_touch, true)
	var swipe := InputEventScreenDrag.new()
	swipe.index = dash_touch.index
	swipe.position = dash_touch.position + Vector2.RIGHT * 50 * float(pad.get("unit"))
	get_viewport().push_input(swipe, true)
	dash_touch.pressed = false
	get_viewport().push_input(dash_touch, true)
	check(Input.is_action_pressed("dash") and not Input.is_action_pressed("dive"), "gesto horizontal dispara dash")
	await frames(70)
	player.position = Vector3(-3, .12, 0)
	player.velocity = Vector3.ZERO
	player.get_node("Dash").reset()
	await frames(10)
	check(not Input.is_action_pressed("jump") and not Input.is_action_pressed("right"),"liberação dos dedos")
	var toggle := InputEventAction.new()
	toggle.action = &"touch_toggle"
	toggle.pressed = true
	get_viewport().push_input(toggle)
	hud.layout()
	check(not pad.visible, "atalho mantém os controles ocultos após recalcular o layout")
	get_viewport().push_input(toggle)
	check(pad.visible, "atalho volta a exibir os controles")
	Input.action_press("right")
	await frames(33)
	check(player.velocity.x>5,"aceleração até corrida")
	Input.action_press("jump")
	await frames(7)
	check(player.position.y>.4,"salto")
	Input.action_release("jump")
	await frames(2)
	Input.action_press("jump")
	await frames(3)
	check(player.get_node("State").get("current")==&"DoubleJump","salto duplo")
	Input.action_release("jump")
	Input.action_press("dash")
	await frames(3)
	check(player.velocity.x>10,"dash aéreo")
	Input.action_release("dash")
	Input.action_release("right")
	player.position=Vector3(4.1,.18,0)
	player.velocity=Vector3.ZERO
	await frames(20)
	Input.action_press("right")
	await frames(68)
	Input.action_release("right")
	check(player.position.x>10 and player.position.y>0,"travessia da ponte curva")
	await frames(22)
	check(Game.counts[0]>0,"Area3D de coleta")
	check(Game.checkpoint.x>0,"checkpoint")
	player.position.y=-9
	await frames(32)
	check(absf(player.position.x-Game.checkpoint.x)<.2 and Game.health==3,"respawn no checkpoint")
	await frames(85)
	var enemy := world.get_node("Gameplay/Enemies/Sporeling") as Area3D
	player.position = enemy.position + Vector3(.37,.01,0)
	await frames(4)
	check(Game.health==2,"dano lateral")
	await frames(4)
	check(Game.health==2,"invulnerabilidade")
	var enemy_position := enemy.position
	var normal_height := await measure_stomp(enemy, false)
	var second_enemy := preload("res://enemies/mushroom/Mushroom.tscn").instantiate() as Area3D
	second_enemy.position = enemy_position
	world.get_node("Gameplay/Enemies").add_child(second_enemy)
	var held_height := await measure_stomp(second_enemy, true)
	check(Game.counts[1] >= 2 and held_height > normal_height + 0.55, "segurar pulo no stomp aumenta a altura do quique")
	hud.toggle_pause()
	check(get_tree().paused,"menu pausa")
	hud.toggle_pause()
	hud.cycle_profile()
	check(world.quality==int(Save.data.get_value("video","perfil",-1)),"perfil persistido")
	player.position=Vector3(19.7,2,0)
	await frames(25)
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("/tmp/sky-gate.png")
	player.position=Vector3(20.1,3.05,0)
	await frames(5)
	check(not Game.complete and Game.counts[2]==1 and not get_tree().paused,"cristal azul sem concluir a fase")
	get_tree().paused = false
	await check_slide()
	Audio.stop_all()
	await get_tree().create_timer(.3,true,false,true).timeout
	get_tree().quit(failed)
