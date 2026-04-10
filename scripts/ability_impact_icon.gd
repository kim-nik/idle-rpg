class_name AbilityImpactIcon
extends Node2D

const DISPLAY_DURATION := 1.0
const VERTICAL_MARGIN := 4.0

var active_tween: Tween
var current_texture: Texture2D = null
var current_size := Vector2.ZERO
var draw_alpha: float = 1.0:
	set(value):
		draw_alpha = value
		queue_redraw()

func _init() -> void:
	z_index = 20
	top_level = true

func _ready() -> void:
	_reset_visual_state()

func show_impact(icon_texture: Texture2D, target_bounds: Rect2) -> void:
	if icon_texture == null:
		return
	if is_instance_valid(active_tween):
		active_tween.kill()

	_reset_visual_state()
	var impact_scale = _get_impact_scale(icon_texture, target_bounds.size.x)
	current_texture = icon_texture
	current_size = icon_texture.get_size() * impact_scale
	global_position = _get_impact_position(target_bounds, icon_texture, impact_scale)
	draw_alpha = 1.0
	force_update_transform()
	visible = true
	queue_redraw()

	active_tween = create_tween()
	active_tween.tween_property(self, "draw_alpha", 0.0, DISPLAY_DURATION)
	active_tween.finished.connect(_reset_visual_state, CONNECT_ONE_SHOT)

func _draw() -> void:
	if current_texture == null or current_size == Vector2.ZERO or draw_alpha <= 0.0:
		return
	var draw_rect = Rect2(-current_size * 0.5, current_size)
	draw_texture_rect(current_texture, draw_rect, false, Color(1.0, 1.0, 1.0, draw_alpha))

func _get_impact_scale(icon_texture: Texture2D, target_width: float) -> Vector2:
	if icon_texture == null:
		return Vector2.ONE
	var texture_size = icon_texture.get_size()
	if texture_size.x <= 0.0:
		return Vector2.ONE
	var scale_factor = max(target_width, 1.0) / texture_size.x
	return Vector2.ONE * scale_factor

func _get_impact_position(target_bounds: Rect2, icon_texture: Texture2D, impact_scale: Vector2) -> Vector2:
	if icon_texture == null:
		return target_bounds.position + target_bounds.size * 0.5
	var scaled_height = icon_texture.get_size().y * impact_scale.y
	return Vector2(
		target_bounds.position.x + target_bounds.size.x * 0.5,
		target_bounds.position.y - VERTICAL_MARGIN - scaled_height * 0.5
	)

func _reset_visual_state() -> void:
	visible = false
	current_texture = null
	current_size = Vector2.ZERO
	draw_alpha = 1.0
	queue_redraw()

func is_active() -> bool:
	return visible and current_texture != null and current_size != Vector2.ZERO and draw_alpha > 0.0

func get_rendered_size() -> Vector2:
	return current_size
