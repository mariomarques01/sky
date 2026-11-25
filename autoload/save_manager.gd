extends Node
var data := ConfigFile.new()
const PATH := "user://skybound.cfg"
func _ready() -> void:
	if FileAccess.file_exists(PATH):
		data.load(PATH)
func write(section: String, key: String, value: Variant) -> void:
	data.set_value(section,key,value)
	data.save(PATH)

func claim(section: String, key: String) -> bool:
	if data.get_value(section, key, false):
		return false
	data.set_value(section, key, true)
	var error := data.save(PATH)
	if error != OK:
		data.erase_section_key(section, key)
		push_warning("Falha ao gravar a recompensa %s (%s)" % [key, error_string(error)])
		return false
	return true
