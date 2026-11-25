extends Node
func _ready() -> void:
	var world := $World
	world.set_quality(2)
	var camera := world.get_node("CameraRig") as Camera3D
	var player := world.get_node("Player") as CharacterBody3D
	for shot: Array in [["inicio",-3.0,0.05],["ponte",6.4,0.08],["arco",18.1,1.52]]:
		world.get_node("CanvasLayer").pad.visible = shot[0]=="ponte"
		player.position = Vector3(shot[1],shot[2],0)
		camera.position.x = player.position.x+1.65
		camera.position.y = 2.55+player.position.y*.73
		for frame in 24: await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://docs/"+str(shot[0])+".png")
	get_tree().quit()
