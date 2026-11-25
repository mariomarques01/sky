extends Node
signal entered(current: StringName)
var current: StringName = &"Idle"
func enter(value: StringName) -> void:
	if current != value:
		current = value
		entered.emit(value)
