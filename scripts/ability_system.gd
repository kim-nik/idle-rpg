extends Node

signal loadout_changed()
signal ability_unlocked(ability_id: String)
signal ability_triggered(ability_id: String, target: Node2D, text_value: String, style_name: String)

const SLOT_COUNT := 8
const TRIGGER_PASSIVE := "passive"
const TRIGGER_PERIODIC := "periodic"
const TRIGGER_ON_HIT := "on_hit"
const EFFECT_DIRECT_DAMAGE_TARGETS := "direct_damage_targets"

const CombatMathRef = preload("res://scripts/combat_math.gd")
const GameServicesRef = preload("res://scripts/core/game_services.gd")
const ABILITY_DEFINITIONS: Array[AbilityDefinition] = [
	preload("res://resources/abilities/punch.tres"),
	preload("res://resources/abilities/leg_sweep.tres"),
	preload("res://resources/abilities/evil_eye.tres")
]

var _definitions_by_id: Dictionary = {}
var _unlocked_ability_ids: Array[String] = []
var _equipped_ability_slots: Array[String] = []
var _runtime_cooldowns: Dictionary = {}

var _runtime_scene: Node = null
var _runtime_hero: Node2D = null
var _runtime_monster_container: Node = null
var _runtime_wave_manager: Node = null
var _tracked_monsters: Dictionary = {}

func _ready() -> void:
	_build_definition_index()
	load_from_save()
	set_process(true)

func _process(delta: float) -> void:
	advance_runtime(delta)

func _build_definition_index() -> void:
	_definitions_by_id.clear()
	for definition in ABILITY_DEFINITIONS:
		if definition == null or definition.ability_id.is_empty():
			continue
		_definitions_by_id[definition.ability_id] = definition

func load_from_save() -> void:
	var save_manager = GameServicesRef.require_save_manager(self)
	if save_manager == null:
		return

	var migrated_unlocked = _sanitize_unlocked_ids(save_manager.save_data.get("unlocked_ability_ids", []))
	var migrated_slots = _sanitize_slot_payload(save_manager.save_data.get("equipped_ability_slots", []), migrated_unlocked)
	var did_change = migrated_unlocked != save_manager.save_data.get("unlocked_ability_ids", []) \
		or migrated_slots != save_manager.save_data.get("equipped_ability_slots", [])

	_unlocked_ability_ids = migrated_unlocked
	_equipped_ability_slots = migrated_slots
	_trim_runtime_state()

	save_manager.save_data.unlocked_ability_ids = _unlocked_ability_ids.duplicate()
	save_manager.save_data.equipped_ability_slots = _equipped_ability_slots.duplicate()
	if did_change:
		save_manager.save()
	emit_signal("loadout_changed")

func bind_runtime(main_scene: Node, hero: Node2D, monster_container: Node, wave_manager: Node) -> void:
	_unbind_runtime()
	_runtime_scene = main_scene
	_runtime_hero = hero
	_runtime_monster_container = monster_container
	_runtime_wave_manager = wave_manager

	if _runtime_hero and _runtime_hero.has_signal("attack_resolved"):
		_runtime_hero.attack_resolved.connect(_on_hero_attack_resolved)

	if _runtime_wave_manager and _runtime_wave_manager.has_signal("monster_spawned"):
		_runtime_wave_manager.monster_spawned.connect(_on_monster_spawned)

	if _runtime_monster_container:
		for child in _runtime_monster_container.get_children():
			var monster = child as Node2D
			if monster:
				_track_monster(monster)

	for ability_id in get_equipped_ability_ids():
		var definition = get_definition(ability_id)
		if definition and definition.trigger_type == TRIGGER_PERIODIC and not _runtime_cooldowns.has(ability_id):
			_runtime_cooldowns[ability_id] = definition.cooldown_seconds

func advance_runtime(delta: float) -> void:
	if delta <= 0.0:
		return
	if _runtime_hero == null or not is_instance_valid(_runtime_hero):
		return

	for ability_id in _runtime_cooldowns.keys():
		_runtime_cooldowns[ability_id] = max(float(_runtime_cooldowns[ability_id]) - delta, 0.0)

	for ability_id in _equipped_ability_slots:
		if ability_id.is_empty():
			continue
		var definition = get_definition(ability_id)
		if definition == null or definition.trigger_type != TRIGGER_PERIODIC:
			continue
		if get_cooldown_remaining(ability_id) > 0.0:
			continue
		if _execute_ability(definition, {}):
			_runtime_cooldowns[ability_id] = definition.cooldown_seconds

func get_all_definitions() -> Array[AbilityDefinition]:
	var definitions: Array[AbilityDefinition] = []
	for definition in ABILITY_DEFINITIONS:
		if definition:
			definitions.append(definition)
	return definitions

func get_definition(ability_id: String) -> AbilityDefinition:
	return _definitions_by_id.get(ability_id)

func get_unlocked_ability_ids() -> Array[String]:
	return _unlocked_ability_ids.duplicate()

func get_equipped_ability_slots() -> Array[String]:
	return _equipped_ability_slots.duplicate()

func get_equipped_ability_ids() -> Array[String]:
	var equipped_ids: Array[String] = []
	for ability_id in _equipped_ability_slots:
		if not ability_id.is_empty():
			equipped_ids.append(ability_id)
	return equipped_ids

func get_ability_slot(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return ""
	return _equipped_ability_slots[slot_index]

func get_equipped_slot_for_ability(ability_id: String) -> int:
	return _equipped_ability_slots.find(ability_id)

func is_unlocked(ability_id: String) -> bool:
	return _unlocked_ability_ids.has(ability_id)

func unlock_ability(ability_id: String) -> bool:
	var definition = get_definition(ability_id)
	if definition == null:
		return false
	if is_unlocked(ability_id):
		return true

	var save_manager = GameServicesRef.require_save_manager(self)
	if save_manager == null or save_manager.save_data.gold < definition.unlock_cost:
		return false

	save_manager.save_data.gold -= definition.unlock_cost
	_unlocked_ability_ids.append(ability_id)
	_unlocked_ability_ids.sort()
	save_manager.save_data.unlocked_ability_ids = _unlocked_ability_ids.duplicate()
	save_manager.save()
	emit_signal("ability_unlocked", ability_id)
	emit_signal("loadout_changed")
	return true

func equip_ability(slot_index: int, ability_id: String) -> bool:
	var definition = get_definition(ability_id)
	if definition == null or not is_unlocked(ability_id):
		return false
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return false

	var previous_slot = get_equipped_slot_for_ability(ability_id)
	if previous_slot == slot_index:
		return true

	if previous_slot >= 0:
		_equipped_ability_slots[previous_slot] = ""

	_equipped_ability_slots[slot_index] = ability_id
	_trim_runtime_state()
	_seed_periodic_cooldown(definition)
	_persist_loadout()
	emit_signal("loadout_changed")
	return true

func clear_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return false
	if _equipped_ability_slots[slot_index].is_empty():
		return false

	_equipped_ability_slots[slot_index] = ""
	_trim_runtime_state()
	_persist_loadout()
	emit_signal("loadout_changed")
	return true

func get_passive_bonuses() -> Dictionary:
	var combined := {}
	for ability_id in get_equipped_ability_ids():
		var definition = get_definition(ability_id)
		if definition == null:
			continue
		for stat_name in definition.passive_bonuses.keys():
			combined[stat_name] = float(combined.get(stat_name, 0.0)) + float(definition.passive_bonuses[stat_name])
	return combined

func get_cooldown_remaining(ability_id: String) -> float:
	return float(_runtime_cooldowns.get(ability_id, 0.0))

func reset_runtime_cooldowns() -> void:
	_runtime_cooldowns.clear()
	for ability_id in get_equipped_ability_ids():
		var definition = get_definition(ability_id)
		if definition:
			_runtime_cooldowns[ability_id] = max(definition.cooldown_seconds, 0.0)

func _persist_loadout() -> void:
	var save_manager = GameServicesRef.require_save_manager(self)
	if save_manager == null:
		return
	save_manager.save_data.equipped_ability_slots = _equipped_ability_slots.duplicate()
	save_manager.save_data.unlocked_ability_ids = _unlocked_ability_ids.duplicate()
	save_manager.save()

func _sanitize_unlocked_ids(payload) -> Array[String]:
	var unlocked_ids: Array[String] = []
	if payload is Array:
		for raw_value in payload:
			var ability_id = String(raw_value)
			if _definitions_by_id.has(ability_id) and not unlocked_ids.has(ability_id):
				unlocked_ids.append(ability_id)

	for definition in ABILITY_DEFINITIONS:
		if definition and definition.starts_unlocked and not unlocked_ids.has(definition.ability_id):
			unlocked_ids.append(definition.ability_id)

	unlocked_ids.sort()
	return unlocked_ids

func _sanitize_slot_payload(payload, unlocked_ids: Array[String]) -> Array[String]:
	var slots: Array[String] = []
	var used_ids: Array[String] = []
	if payload is Array:
		for raw_value in payload:
			if slots.size() >= SLOT_COUNT:
				break
			var ability_id = String(raw_value)
			if ability_id.is_empty() or not unlocked_ids.has(ability_id) or used_ids.has(ability_id):
				slots.append("")
				continue
			used_ids.append(ability_id)
			slots.append(ability_id)

	while slots.size() < SLOT_COUNT:
		slots.append("")
	return slots

func _seed_periodic_cooldown(definition: AbilityDefinition) -> void:
	if definition.trigger_type == TRIGGER_PERIODIC:
		_runtime_cooldowns[definition.ability_id] = max(definition.cooldown_seconds, 0.0)

func _trim_runtime_state() -> void:
	var equipped_ids = get_equipped_ability_ids()
	for ability_id in _runtime_cooldowns.keys():
		if not equipped_ids.has(String(ability_id)):
			_runtime_cooldowns.erase(ability_id)

func _unbind_runtime() -> void:
	if _runtime_hero and is_instance_valid(_runtime_hero) and _runtime_hero.has_signal("attack_resolved"):
		var hero_callable := Callable(self, "_on_hero_attack_resolved")
		if _runtime_hero.is_connected("attack_resolved", hero_callable):
			_runtime_hero.disconnect("attack_resolved", hero_callable)

	if _runtime_wave_manager and is_instance_valid(_runtime_wave_manager) and _runtime_wave_manager.has_signal("monster_spawned"):
		var monster_callable := Callable(self, "_on_monster_spawned")
		if _runtime_wave_manager.is_connected("monster_spawned", monster_callable):
			_runtime_wave_manager.disconnect("monster_spawned", monster_callable)

	for monster_id in _tracked_monsters.keys():
		var monster = _tracked_monsters[monster_id]
		if is_instance_valid(monster):
			var died_callable := Callable(self, "_on_monster_died")
			if monster.is_connected("monster_died", died_callable):
				monster.disconnect("monster_died", died_callable)
	_tracked_monsters.clear()
	_runtime_scene = null
	_runtime_hero = null
	_runtime_monster_container = null
	_runtime_wave_manager = null

func _on_monster_spawned(monster: Node2D) -> void:
	_track_monster(monster)

func _track_monster(monster: Node2D) -> void:
	if monster == null or not is_instance_valid(monster):
		return
	var instance_id = monster.get_instance_id()
	if _tracked_monsters.has(instance_id):
		return
	_tracked_monsters[instance_id] = monster
	if monster.has_signal("monster_died"):
		monster.monster_died.connect(func(_gold_reward: int) -> void:
			_on_monster_died(monster)
		, CONNECT_ONE_SHOT)

func _on_monster_died(monster: Node2D) -> void:
	if monster and is_instance_valid(monster):
		_tracked_monsters.erase(monster.get_instance_id())

func _on_hero_attack_resolved(target: Node2D, damage_output: Dictionary) -> void:
	for ability_id in get_equipped_ability_ids():
		var definition = get_definition(ability_id)
		if definition == null or definition.trigger_type != TRIGGER_ON_HIT:
			continue
		if get_cooldown_remaining(ability_id) > 0.0:
			continue
		if _execute_ability(definition, {"target": target, "damage_output": damage_output}):
			_runtime_cooldowns[ability_id] = definition.cooldown_seconds

func _execute_ability(definition: AbilityDefinition, context: Dictionary) -> bool:
	match definition.effect_type:
		EFFECT_DIRECT_DAMAGE_TARGETS:
			return _apply_damage_effect(definition, _resolve_targets(definition, context))
		_:
			return false

func _apply_damage_effect(definition: AbilityDefinition, targets: Array[Node2D]) -> bool:
	if _runtime_hero == null or not is_instance_valid(_runtime_hero):
		return false
	if targets.is_empty():
		return false

	var base_stats = _runtime_hero.get_combat_stats()
	var attacker_stats = base_stats.duplicate(true)
	var effect_values = definition.effect_values
	var damage_multiplier = float(effect_values.get("damage_multiplier", 1.0))
	var flat_bonus = float(effect_values.get("flat_bonus", 0.0))
	attacker_stats.attack_damage = base_stats.attack_damage * damage_multiplier + flat_bonus
	attacker_stats.crit_chance = 0.0
	attacker_stats.crit_damage = 100.0

	var applied = false
	for target in targets:
		if target == null or not is_instance_valid(target) or target.get("is_dead"):
			continue
		var damage_output = CombatMathRef.resolve_attack(attacker_stats, target.get_combat_stats(), 1.0)
		target.take_damage(damage_output.final_damage)
		emit_signal(
			"ability_triggered",
			definition.ability_id,
			target,
			str(int(round(damage_output.final_damage))),
			"ability"
		)
		applied = true
	return applied

func _resolve_targets(definition: AbilityDefinition, context: Dictionary) -> Array[Node2D]:
	var ordered_monsters = _get_ordered_monsters()
	if ordered_monsters.is_empty():
		return []

	match definition.target_rule:
		"nearest_enemy":
			return [ordered_monsters[0]]
		"nearest_enemies":
			var target_count = int(definition.effect_values.get("target_count", 1))
			return ordered_monsters.slice(0, min(target_count, ordered_monsters.size()))
		"enemy_position":
			var target_index = int(definition.effect_values.get("target_index", 0))
			if target_index >= 0 and target_index < ordered_monsters.size():
				return [ordered_monsters[target_index]]
			return []
		"hit_target":
			var hit_target = context.get("target") as Node2D
			if hit_target and is_instance_valid(hit_target) and not hit_target.get("is_dead"):
				return [hit_target]
			return []
		_:
			return []

func _get_ordered_monsters() -> Array[Node2D]:
	var ordered_monsters: Array[Node2D] = []
	if _runtime_hero == null or _runtime_monster_container == null:
		return ordered_monsters

	for child in _runtime_monster_container.get_children():
		var monster = child as Node2D
		if monster == null or monster.get("is_dead"):
			continue
		ordered_monsters.append(monster)

	ordered_monsters.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		var distance_a = a.global_position.distance_to(_runtime_hero.global_position)
		var distance_b = b.global_position.distance_to(_runtime_hero.global_position)
		if is_equal_approx(distance_a, distance_b):
			return a.get_instance_id() < b.get_instance_id()
		return distance_a < distance_b
	)
	return ordered_monsters
