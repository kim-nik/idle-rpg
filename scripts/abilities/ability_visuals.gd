class_name AbilityVisuals
extends RefCounted

static var _source_ability_icons := {
	"punch": preload("res://assets/ui/abilities/punch.svg"),
	"leg_sweep": preload("res://assets/ui/abilities/leg-sweep.svg"),
	"evil_eye": preload("res://assets/ui/abilities/evil-eye.svg")
}
static var _runtime_icon_cache: Dictionary = {}

static func get_icon(ability_id: String) -> Texture2D:
	if _runtime_icon_cache.has(ability_id):
		return _runtime_icon_cache[ability_id]

	var source_texture = _source_ability_icons.get(ability_id) as Texture2D
	if source_texture == null:
		return null

	var source_image = source_texture.get_image()
	if source_image == null:
		return source_texture

	var runtime_texture = ImageTexture.create_from_image(source_image)
	_runtime_icon_cache[ability_id] = runtime_texture
	return runtime_texture
