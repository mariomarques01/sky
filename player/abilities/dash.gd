extends Node
@export var speed := 12.5
@export var duration := .16
@export var recharge := .42
var remaining := 0.0
var cooldown := 0.0
var air_available := true
func tick(delta: float, grounded: bool) -> void:
	cooldown = maxf(0,cooldown-delta)
	remaining = maxf(0,remaining-delta)
	if grounded: air_available = true
func launch(grounded: bool) -> void:
	if cooldown>0 or not air_available: return
	remaining = duration
	cooldown = recharge
	air_available = grounded
	Audio.cue(295)
func reset() -> void:
	remaining = 0
	cooldown = 0
	air_available = true
