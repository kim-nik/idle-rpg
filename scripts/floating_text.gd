extends Label

const DEFAULT_DURATION: float = 0.65
const DEFAULT_RISE_DISTANCE: float = 72.0

var start_position: Vector2 = Vector2.ZERO
var end_position: Vector2 = Vector2.ZERO

func show_value(text_value: String, world_position: Vector2, color: Color, is_emphasized: bool = false) -> void:
	text = text_value
	global_position = world_position
	start_position = global_position
	end_position = start_position + Vector2(0, -DEFAULT_RISE_DISTANCE)
	modulate = color
	modulate.a = 1.0
	pivot_offset = size * 0.5
	scale = Vector2.ONE * (1.25 if is_emphasized else 1.0)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", end_position, DEFAULT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, DEFAULT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ONE, DEFAULT_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(queue_free, CONNECT_ONE_SHOT)
