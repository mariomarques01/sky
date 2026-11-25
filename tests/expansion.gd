extends Node

const Pickup = preload("res://collectibles/pickup.gd")
const World = preload("res://worlds/world_01/level_01/World_01_Level_01.tscn")
@onready var world := $World
@onready var player := $World/Player as CharacterBody3D
@onready var expansion := $World/Expansion
var failures := 0

func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame

func check(condition: bool, label: String) -> bool:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		failures += 1
	return condition

func stop_input() -> void:
	for action in [&"left", &"right", &"jump", &"dash"]:
		Input.action_release(action)

func steer(target_x: float) -> void:
	var remaining := target_x - player.position.x
	var braking_distance := player.velocity.x * absf(player.velocity.x) / 49.0
	var side := signf(remaining)
	var still_approaching := signf(braking_distance) == side and absf(remaining) > absf(braking_distance)
	Input.action_release("left")
	Input.action_release("right")
	if absf(remaining) > 0.12 and (still_approaching or absf(player.velocity.x) < 0.25):
		Input.action_press("right" if side > 0 else "left")

func jump_to(target: Node3D, double_jump := false, dash := false, delay := 0) -> bool:
	var left_floor := false
	var used_dash := false
	var start_x := player.position.x
	if dash:
		steer(target.global_position.x)
		await frames(2)
	Input.action_press("jump")
	for frame in 130:
		var goal := target.global_position
		if frame >= delay:
			steer(goal.x)
		if double_jump and frame == 17:
			Input.action_release("jump")
		if double_jump and frame == 19:
			Input.action_press("jump")
		if dash and frame == 6:
			Input.action_press("dash")
		await frames(1)
		used_dash = used_dash or absf(player.velocity.x) > 10.0
		left_floor = left_floor or not player.is_on_floor()
		if left_floor and player.is_on_floor() and absf(player.position.x - goal.x) < 0.55 and absf(player.position.y - goal.y) < 0.2:
			stop_input()
			await frames(9)
			return check(not dash or used_dash, str(target.name))
		if player.get("recovery") > 0:
			break
	stop_input()
	return check(false, "%s de %.2f com chegada %s" % [target.name, start_x, player.position])

func run_to(x: float, limit: int) -> bool:
	for i in limit:
		steer(x)
		await frames(1)
		if absf(player.position.x - x) < .24 or Game.complete:
			stop_input()
			return true
	stop_input()
	return false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	await frames(5)
	# Start at the end of the original continuously tested route.
	player.position = Vector3(20.8, 1.85, 0)
	await frames(18)
	var crossing: Node3D = expansion.get_node("IslandCrossing")
	for island in ["FirstIsland", "LowIsland", "Ferry", "HighIsland"]:
		if not await jump_to(crossing.get_node(island)):
			get_tree().quit(1)
			return
		if island == "Ferry":
			var before := player.position.x
			await frames(30)
			check(player.is_on_floor() and absf(player.position.x - before) > .1, "ferry transporta o jogador")
	var ruins := expansion.get_node("RuinsSection")
	# Approach the ruins from the last crossing island using a full jump.
	var landing := Marker3D.new()
	landing.name = "EntradaDasRuinas"
	ruins.add_child(landing)
	landing.position = Vector3(38.65, 1.54, 0)
	await jump_to(landing)
	await jump_to(ruins.get_node("UpperWalk"))
	await jump_to(ruins.get_node("HiddenShelf"), true, false, 17)
	check(Save.data.get_value(Pickup.CLAIMS, "ruins_alcove", false), "coleta na passagem secreta")
	landing.position = Vector3(47, 1.54, 0)
	check(await run_to(47, 170), "saída da passagem secreta")
	check(Game.checkpoint.x > 46, "checkpoint da ponte")
	player.position.y = -9
	await frames(38)
	check(absf(player.position.x - Game.checkpoint.x) < .12 and player.is_on_floor(), "queda e respawn antes da ponte")
	check(await run_to(55.2, 170) and player.is_on_floor(), "travessia a pé da ponte")
	check(await run_to(62, 145) and player.position.y > 3.0, "escadas e chegada ao templo")
	check(Save.data.get_value(Pickup.CLAIMS, "temple_crystal", false), "cristal lendário")
	stop_input()
	player.position = Vector3(20.8, 1.85, 0)
	player.velocity = Vector3.ZERO
	await frames(18)
	var route := expansion.get_node("TreasureRoute")
	var chest := route.get_node("GoldenChest") as Area3D
	var chest_lid := chest.get_node("Visual/Lid") as Node3D
	for i in range(1, 8):
		# A missing health point makes the heart collectible.
		if i == 3:
			Game.health = 2
		var island := route.get_node("TreasureIsland" + str(i))
		if not await jump_to(island, i != 7, i == 5):
			get_tree().quit(1)
			return
		if i == 3:
			check(Game.health == 3, "coração restaura um ponto")
		if i == 6:
			check(chest_lid.rotation.x < -0.5, "animação de abertura do baú")
	for claim in ["sapphire_route", "amethyst_route", "golden_chest"]:
		check(Save.data.get_value(Pickup.CLAIMS, claim, false), claim)
	var camera := world.get_node("CameraRig") as Camera3D
	check(camera.position.x > 40 and camera.position.y > 6.0, "câmera acompanha a rota elevada")
	check(await run_to(49.25, 130), "saída da rota secreta")
	await frames(42)
	check(player.is_on_floor() and player.position.y < 2.1, "retorno da rota secreta à ponte")
	var rare_count: int = Game.counts[2]
	player.position.y = -9
	await frames(45)
	check(Game.counts[2] == rare_count and not chest.monitoring, "respawn preserva as coletas e o baú aberto")
	check(await run_to(66.4, 250) and Game.complete, "conclusão após o templo")
	get_tree().paused = false
	Audio.voice.stop()
	world.queue_free()
	await frames(3)
	var from_disk := ConfigFile.new()
	check(from_disk.load(Save.PATH) == OK, "arquivo de recompensas gravado")
	Save.data = from_disk
	world = World.instantiate()
	add_child(world)
	await frames(3)
	route = world.get_node("Expansion/TreasureRoute")
	check(not route.has_node("Sapphire") and not route.has_node("Amethyst") and not route.has_node("GoldenChest"), "recarregamento não duplica tesouros")
	world.get_node("Player").position = Vector3(66.3, 2.31, 0)
	await frames(6)
	check(Game.complete and Game.counts[2] == 0, "conclusão disponível em nova partida")
	get_tree().paused = false
	Audio.voice.stop()
	await get_tree().create_timer(.5).timeout
	get_tree().quit(failures)
