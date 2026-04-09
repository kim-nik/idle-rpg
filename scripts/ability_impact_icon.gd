extends Sprite2D

const DISPLAY_DURATION := 0.5
const RISE_DISTANCE := 24.0
const TARGET_VISUAL_SIZE := 56.0

var active_tween: Tween

func _init() -> void:
	centered = true
	z_index = 20
	_reset_visual_state()

func _ready() -> void:
	_apply_white_icon_shader()

func show_impact(icon_texture: Texture2D, local_position: Vector2) -> void:
	if icon_texture == null:
		return
	if is_instance_valid(active_tween):
		active_tween.kill()

	texture = icon_texture
	position = local_position
	modulate = Color(1, 1, 1, 1)
	scale = _get_base_scale(icon_texture) * 0.9
	visible = true

	active_tween = create_tween()
	active_tween.set_parallel(true)
	active_tween.tween_property(self, "position:y", local_position.y - RISE_DISTANCE, DISPLAY_DURATION)
	active_tween.tween_property(self, "modulate:a", 0.0, DISPLAY_DURATION)
	active_tween.tween_property(self, "scale", _get_base_scale(icon_texture) * 1.05, DISPLAY_DURATION)
	active_tween.finished.connect(_reset_visual_state, CONNECT_ONE_SHOT)

func _apply_white_icon_shader() -> void:
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nvoid fragment(){ vec4 tex = texture(TEXTURE, UV); COLOR = vec4(vec3(1.0), tex.a * COLOR.a); }"
	var shader_material := ShaderMaterial.new()
	shader_material.shader = shader
	material = shader_material

func _get_base_scale(icon_texture: Texture2D) -> Vector2:
	if icon_texture == null:
		return Vector2.ONE
	var texture_size = icon_texture.get_size()
	var largest_side = max(texture_size.x, texture_size.y)
	if largest_side <= 0.0:
		return Vector2.ONE
	var scale_factor = TARGET_VISUAL_SIZE / largest_side
	return Vector2.ONE * scale_factor

func _reset_visual_state() -> void:
	visible = false
	texture = null
	modulate = Color(1, 1, 1, 1)
	scale = Vector2.ONE
