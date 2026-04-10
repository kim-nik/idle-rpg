class_name AbilityVisuals
extends RefCounted

static var _source_ability_icons := {
	"punch": preload("res://assets/ui/abilities/punch.svg"),
	"leg_sweep": preload("res://assets/ui/abilities/leg-sweep.svg"),
	"evil_eye": preload("res://assets/ui/abilities/evil-eye.svg")
}

static func get_icon(ability_id: String) -> Texture2D:
	return _source_ability_icons.get(ability_id) as Texture2D
