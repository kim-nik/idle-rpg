class_name AbilityDefinition
extends Resource

@export var ability_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var trigger_type: String = "passive"
@export var unlock_cost: int = 0
@export var starts_unlocked: bool = false
@export var cooldown_seconds: float = 0.0
@export var target_rule: String = "self"
@export var passive_bonuses: Dictionary = {}
@export var effect_type: String = ""
@export var effect_values: Dictionary = {}

func get_meta_summary() -> String:
	var parts: Array[String] = []
	parts.append("Trigger: %s" % trigger_type.capitalize())
	if cooldown_seconds > 0.0:
		parts.append("Cooldown: %.1fs" % cooldown_seconds)
	if unlock_cost > 0:
		parts.append("Unlock: %d gold" % unlock_cost)
	return " | ".join(parts)
