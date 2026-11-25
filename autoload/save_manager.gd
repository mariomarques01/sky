extends Node
var data := ConfigFile.new()
const PATH := "user://skybound.cfg"
func _ready() -> void:
	if FileAccess.file_exists(PATH):
		data.load(PATH)
func write(section: String, key: String, value: Variant) -> void:
	data.set_value(section,key,value)
	data.save(PATH)
