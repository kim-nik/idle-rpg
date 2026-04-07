class_name CombatMath
extends RefCounted

const DEFAULT_STATS := {
	"max_hp": 100.0,
	"attack_damage": 10.0,
	"attack_speed": 1.0,
	"crit_chance": 5.0,
	"crit_damage": 150.0,
	"armor": 0.0,
	"health_regen": 0.0
}

static func create_stat_block(values: Dictionary = {}) -> Dictionary:
	var stat_block := DEFAULT_STATS.duplicate(true)
	for key in values.keys():
		stat_block[key] = float(values[key])
	return stat_block

static func build_hero_stats(upgrade_system: Node) -> Dictionary:
	return create_stat_block({
		"max_hp": upgrade_system.get_max_hp(),
		"attack_damage": upgrade_system.get_damage(),
		"attack_speed": upgrade_system.get_attack_speed(),
		"crit_chance": upgrade_system.get_crit_chance(),
		"crit_damage": upgrade_system.get_crit_damage(),
		"armor": upgrade_system.get_armor(),
		"health_regen": upgrade_system.get_health_regen()
	})

static func build_monster_stats(monster_config: Dictionary, wave_bonus: float = 1.0) -> Dictionary:
	return create_stat_block({
		"max_hp": monster_config.get("hp", DEFAULT_STATS.max_hp) * wave_bonus,
		"attack_damage": monster_config.get("atk", DEFAULT_STATS.attack_damage) * wave_bonus,
		"attack_speed": monster_config.get("attack_speed", 1.0),
		"armor": monster_config.get("armor", 0.0) * wave_bonus,
		"health_regen": monster_config.get("health_regen", 0.0) * wave_bonus
	})

static func get_attack_interval(stats: Dictionary) -> float:
	return 1.0 / max(float(stats.get("attack_speed", 1.0)), 0.01)

static func calculate_armor_multiplier(armor: float) -> float:
	var safe_armor = max(armor, 0.0)
	return 100.0 / (100.0 + safe_armor)

static func roll_attack(attacker_stats: Dictionary, rng_value: float = randf()) -> Dictionary:
	var attack_damage = max(float(attacker_stats.get("attack_damage", 0.0)), 0.0)
	var crit_chance = clamp(float(attacker_stats.get("crit_chance", 0.0)), 0.0, 100.0)
	var crit_multiplier = max(float(attacker_stats.get("crit_damage", 100.0)) / 100.0, 1.0)
	var is_crit = rng_value * 100.0 < crit_chance
	var raw_damage = attack_damage
	if is_crit:
		raw_damage *= crit_multiplier

	return {
		"base_damage": attack_damage,
		"raw_damage": raw_damage,
		"is_crit": is_crit
	}

static func resolve_attack(attacker_stats: Dictionary, defender_stats: Dictionary, rng_value: float = randf()) -> Dictionary:
	var attack_roll = roll_attack(attacker_stats, rng_value)
	var armor = float(defender_stats.get("armor", 0.0))
	var armor_multiplier = calculate_armor_multiplier(armor)
	var final_damage = attack_roll.raw_damage * armor_multiplier
	if attack_roll.raw_damage > 0.0:
		final_damage = max(final_damage, 1.0)

	return {
		"base_damage": attack_roll.base_damage,
		"raw_damage": attack_roll.raw_damage,
		"final_damage": final_damage,
		"armor": armor,
		"armor_multiplier": armor_multiplier,
		"is_crit": attack_roll.is_crit
	}

static func apply_regeneration(current_hp: float, max_hp: float, health_regen: float, delta: float) -> float:
	if current_hp <= 0.0 or health_regen <= 0.0 or delta <= 0.0:
		return current_hp
	return min(current_hp + health_regen * delta, max_hp)
