extends StaticBody3D

const Sparkles = preload("res://environment/effects/sparkles.gd")

@export var prize: PackedScene = preload("res://collectibles/Coin.tscn")
var broken := false

func break_from_above(player: CharacterBody3D) -> bool:
	if broken or absf(player.global_position.x - global_position.x) > 0.48:
		return false
	broken = true
	$Visual.hide()
	$Collision.set_deferred("disabled", true)
	_release_prize.call_deferred()
	return true

func _release_prize() -> void:
	var reward := prize.instantiate() as Area3D
	reward.position = position + Vector3.UP * 0.72
	get_parent().add_child(reward)

	var burst := Sparkles.new()
	burst.position = position + Vector3.UP * 0.45
	burst.tint = Color("#ffc566")
	get_parent().add_child(burst)
	Audio.cue(235)
	queue_free()
