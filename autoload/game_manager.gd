extends Node
signal changed
signal checkpoint_activated
signal collected(kind: int)
signal finished
var health := 3
var counts := [0,0,0]
var checkpoint := Vector3.ZERO
var complete := false
func begin() -> void:
	health = 3
	counts = [0,0,0]
	complete = false
	checkpoint = Vector3(-3,0.12,0)
	changed.emit()
func activate_checkpoint(point: Vector3) -> void:
	checkpoint = point
	checkpoint_activated.emit()

func collect(kind: int, completes_level := true) -> void:
	counts[kind] += 1
	Audio.play(&"coin" if kind == 1 else &"crystal")
	changed.emit()
	collected.emit(kind)
	if kind == 2 and completes_level:
		finish_level()

func finish_level() -> void:
	if not complete:
		complete = true
		Save.write("Jardins","concluido",true)
		Save.write("Jardins","recorde",maxi(counts[0],int(Save.data.get_value("Jardins","recorde",0))))
		finished.emit()
