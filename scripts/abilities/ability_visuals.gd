class_name AbilityVisuals
extends RefCounted

static var _ability_icons := {
	"punch": preload("res://assets/ui/abilities/punch.svg"),
	"leg_sweep": preload("res://assets/ui/abilities/leg-sweep.svg"),
	"evil_eye": preload("res://assets/ui/abilities/evil-eye.svg")
}

static func get_icon(ability_id: String) -> Texture2D:
	return _ability_icons.get(ability_id)
