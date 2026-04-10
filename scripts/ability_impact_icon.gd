class_name AbilityImpactIcon
extends Node2D

const DISPLAY_DURATION := 1.0
const VERTICAL_MARGIN := 4.0

@onready var sprite: Sprite2D = $Sprite2D

var active_tween: Tween
var current_texture: Texture2D = null
var current_size := Vector2.ZERO
var draw_alpha: float = 0.0:
	set(value):
		draw_alpha = clampf(value, 0.0, 1.0)
		if sprite:
			sprite.modulate = Color(1.0, 1.0, 1.0, draw_alpha)

func _ready() -> void:
	z_index = 20
	_reset_visual_state()

func show_impact(icon_texture: Texture2D, target_bounds: Rect2) -> void:
	if icon_texture == null:
		return
	if is_instance_valid(active_tween):
		active_tween.kill()
		active_tween = null

	_reset_visual_state()

	var texture_size = icon_texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0 or target_bounds.size.x <= 0.0:
		return

	var scale_factor = target_bounds.size.x / texture_size.x
	current_texture = icon_texture
	sprite.texture = current_texture
	sprite.scale = Vector2.ONE * scale_factor
	current_size = texture_size * scale_factor
	global_position = _get_impact_world_position(target_bounds, current_size.y)

	await get_tree().process_frame

	draw_alpha = 1.0
	show()

	active_tween = create_tween()
	active_tween.tween_property(self, "draw_alpha", 0.0, DISPLAY_DURATION)
	active_tween.finished.connect(_on_impact_finished, CONNECT_ONE_SHOT)

func _get_impact_world_position(target_bounds: Rect2, scaled_height: float) -> Vector2:
	return Vector2(
		target_bounds.position.x + target_bounds.size.x * 0.5,
		target_bounds.position.y - VERTICAL_MARGIN - scaled_height * 0.5
	)

func _on_impact_finished() -> void:
	active_tween = null
	_reset_visual_state()

func _reset_visual_state() -> void:
	hide()
	current_texture = null
	current_size = Vector2.ZERO
	draw_alpha = 0.0
	position = Vector2.ZERO
	sprite.texture = null
	sprite.scale = Vector2.ONE

func is_active() -> bool:
	return visible or is_instance_valid(active_tween)

func get_rendered_size() -> Vector2:
	return current_size
