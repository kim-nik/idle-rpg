extends Label

const DEFAULT_DURATION: float = 0.65
const DEFAULT_RISE_DISTANCE: float = 72.0

var start_position: Vector2 = Vector2.ZERO
var end_position: Vector2 = Vector2.ZERO
var active_tween: Tween

func reset_state() -> void:
	if is_instance_valid(active_tween):
		active_tween.kill()
	active_tween = null
	visible = true
	modulate.a = 1.0
	scale = Vector2.ONE

func show_value(text_value: String, world_position: Vector2, color: Color, is_emphasized: bool = false) -> void:
	reset_state()
	text = text_value
	global_position = world_position
	start_position = global_position
	end_position = start_position + Vector2(0, -DEFAULT_RISE_DISTANCE)
	modulate = color
	modulate.a = 1.0
	pivot_offset = size * 0.5
	scale = Vector2.ONE * (1.25 if is_emphasized else 1.0)

	active_tween = create_tween()
	active_tween.set_parallel(true)
	active_tween.tween_property(self, "global_position", end_position, DEFAULT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(self, "modulate:a", 0.0, DEFAULT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	active_tween.tween_property(self, "scale", Vector2.ONE, DEFAULT_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
