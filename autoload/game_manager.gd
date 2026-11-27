extends Node
signal changed
signal checkpoint_activated
signal collected(kind: int)
signal finished
var health := 3
var counts := [0,0,0]
var checkpoint := Vector3.ZERO
var complete := false
const MIN_IMPACT_TIME_SCALE := .001
const TIMER_EPSILON := .000001
var impact_timer: SceneTreeTimer
var previous_time_scale := 1.0

func hit_stop(duration: float) -> void:
	if duration <= 0.0:
		return
	var wait := maxf(duration - TIMER_EPSILON, TIMER_EPSILON)
	if impact_timer:
		impact_timer.time_left = maxf(impact_timer.time_left, wait)
		return
	previous_time_scale = Engine.time_scale
	# A nonzero step keeps the physics solver stable.
	Engine.time_scale = MIN_IMPACT_TIME_SCALE
	impact_timer = get_tree().create_timer(wait, true, false, true)
	impact_timer.timeout.connect(cancel_hit_stop)

func is_hit_stopped() -> bool:
	return impact_timer != null

func cancel_hit_stop() -> void:
	if impact_timer:
		impact_timer.timeout.disconnect(cancel_hit_stop)
		impact_timer = null
		Engine.time_scale = previous_time_scale

func begin() -> void:
	cancel_hit_stop()
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
		Audio.stop_music()
		Audio.play(&"victory")
		Save.write("Jardins","concluido",true)
		Save.write("Jardins","recorde",maxi(counts[0],int(Save.data.get_value("Jardins","recorde",0))))
		finished.emit()
