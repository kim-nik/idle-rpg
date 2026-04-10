class_name CombatFeedbackController
extends RefCounted

const FLOATING_TEXT_SCENE := preload("res://scenes/FloatingText.tscn")
const ABILITY_IMPACT_ICON_SCENE := preload("res://scenes/AbilityImpactIcon.tscn")
const MAX_ACTIVE_FLOATING_TEXTS := 12
const MAX_ACTIVE_ABILITY_ICONS := 16
const DAMAGE_TEXT_OFFSET := Vector2(-18, -72)
const HERO_DAMAGE_TEXT_OFFSET := Vector2(-18, -96)
const COMBAT_TEXT_STYLES := {
	"damage": {"color": Color(1.0, 0.95, 0.82, 1.0), "emphasized": false},
	"crit": {"color": Color(1.0, 0.82, 0.24, 1.0), "emphasized": true},
	"hero_damage": {"color": Color(1.0, 0.45, 0.45, 1.0), "emphasized": false},
	"ability": {"color": Color(0.48, 0.86, 1.0, 1.0), "emphasized": true},
	"heal": {"color": Color(0.45, 1.0, 0.55, 1.0), "emphasized": false},
	"dodge": {"color": Color(0.72, 0.92, 1.0, 1.0), "emphasized": true},
	"block": {"color": Color(0.7, 0.8, 1.0, 1.0), "emphasized": true},
	"resist": {"color": Color(0.82, 0.72, 1.0, 1.0), "emphasized": true}
}

var _host: Node
var _ability_effects_root: Node2D
var _floating_texts: Array[Label] = []
var _ability_impact_icons: Array[AbilityImpactIcon] = []

func setup(host: Node, ability_effects_root: Node2D) -> void:
	_host = host
	_ability_effects_root = ability_effects_root

func show_combat_text(text_value: String, world_position: Vector2, style_name: String) -> void:
	if _host == null:
		return

	var style = COMBAT_TEXT_STYLES.get(style_name, COMBAT_TEXT_STYLES.damage)
	var floating_text = _get_floating_text_node()
	if floating_text.get_parent() == null:
		_host.add_child(floating_text)
	floating_text.show_value(text_value, world_position, style.color, style.emphasized)
	floating_text.move_to_front()

func show_hero_attack_damage(target_position: Vector2, damage: float, is_crit: bool) -> void:
	var damage_text = str(int(round(damage)))
	show_combat_text(damage_text, target_position + DAMAGE_TEXT_OFFSET, "crit" if is_crit else "damage")

func show_hero_damage(target_position: Vector2, damage: float) -> void:
	var damage_text = str(int(round(damage)))
	show_combat_text(damage_text, target_position + HERO_DAMAGE_TEXT_OFFSET, "hero_damage")

func show_ability_impact(icon_texture: Texture2D, target_bounds: Rect2) -> void:
	if icon_texture == null:
		return
	var impact_icon = _get_ability_impact_icon_node()
	if impact_icon == null:
		return
	impact_icon.show_impact(icon_texture, target_bounds)

func _get_floating_text_node() -> Label:
	if _floating_texts.size() < MAX_ACTIVE_FLOATING_TEXTS:
		var new_text = FLOATING_TEXT_SCENE.instantiate() as Label
		_floating_texts.append(new_text)
		return new_text

	var recycled_text = _floating_texts.pop_front()
	_floating_texts.append(recycled_text)
	return recycled_text

func _get_ability_impact_icon_node() -> AbilityImpactIcon:
	if _ability_effects_root == null:
		return null

	for impact_icon in _ability_impact_icons:
		if not impact_icon.is_active():
			return impact_icon

	if _ability_impact_icons.size() >= MAX_ACTIVE_ABILITY_ICONS:
		var recycled_icon = _ability_impact_icons.pop_front()
		_ability_impact_icons.append(recycled_icon)
		return recycled_icon

	var new_icon = ABILITY_IMPACT_ICON_SCENE.instantiate() as AbilityImpactIcon
	new_icon.hide()
	_ability_effects_root.add_child(new_icon)
	_ability_impact_icons.append(new_icon)
	return new_icon
