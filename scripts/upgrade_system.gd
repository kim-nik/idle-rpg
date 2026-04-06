extends Node

const BASE_UPGRADE_COSTS := {
	"damage": 10,
	"attack_speed": 15,
	"max_hp": 12,
	"crit_chance": 20,
	"crit_damage": 25
}

const COST_MULTIPLIERS := {
	"damage": 1.5,
	"attack_speed": 1.6,
	"max_hp": 1.4,
	"crit_chance": 1.7,
	"crit_damage": 1.6
}

const BASE_STATS := {
	"damage": 10.0,
	"attack_speed": 1.0,
	"max_hp": 100.0,
	"crit_chance": 5.0,
	"crit_damage": 150.0
}

var damage_level: int = 1
var attack_speed_level: int = 1
var max_hp_level: int = 1
var crit_chance_level: int = 1
var crit_damage_level: int = 1

func _ready() -> void:
	load_from_save()

func load_from_save() -> void:
	var save_manager = get_node("/root/SaveManager")
	damage_level = save_manager.save_data.get("damage_level", 1)
	attack_speed_level = save_manager.save_data.get("attack_speed_level", 1)
	max_hp_level = save_manager.save_data.get("max_hp_level", 1)
	crit_chance_level = save_manager.save_data.get("crit_chance_level", 1)
	crit_damage_level = save_manager.save_data.get("crit_damage_level", 1)

func get_upgrade_cost(upgrade_name: String, level: int) -> int:
	var base_cost = BASE_UPGRADE_COSTS.get(upgrade_name, 10)
	var multiplier = COST_MULTIPLIERS.get(upgrade_name, 1.5)
	return int(base_cost * pow(multiplier, level - 1))

func get_damage() -> float:
	return BASE_STATS.damage * (1.0 + (damage_level - 1) * 0.1)

func get_attack_speed() -> float:
	return BASE_STATS.attack_speed * (1.0 + (attack_speed_level - 1) * 0.1)

func get_max_hp() -> float:
	return BASE_STATS.max_hp + (max_hp_level - 1) * 20.0

func get_crit_chance() -> float:
	return BASE_STATS.crit_chance + (crit_chance_level - 1) * 5.0

func get_crit_damage() -> float:
	return BASE_STATS.crit_damage + (crit_damage_level - 1) * 25.0

func purchase_upgrade(upgrade_name: String) -> bool:
	var save_manager = get_node("/root/SaveManager")
	var current_level: int
	var cost: int
	
	match upgrade_name:
		"damage":
			current_level = damage_level
			cost = get_upgrade_cost("damage", current_level)
			if save_manager.save_data.gold >= cost:
				save_manager.save_data.gold -= cost
				damage_level += 1
				save_manager.save_data.damage_level = damage_level
				return true
		"attack_speed":
			current_level = attack_speed_level
			cost = get_upgrade_cost("attack_speed", current_level)
			if save_manager.save_data.gold >= cost:
				save_manager.save_data.gold -= cost
				attack_speed_level += 1
				save_manager.save_data.attack_speed_level = attack_speed_level
				return true
		"max_hp":
			current_level = max_hp_level
			cost = get_upgrade_cost("max_hp", current_level)
			if save_manager.save_data.gold >= cost:
				save_manager.save_data.gold -= cost
				max_hp_level += 1
				save_manager.save_data.max_hp_level = max_hp_level
				return true
		"crit_chance":
			current_level = crit_chance_level
			cost = get_upgrade_cost("crit_chance", current_level)
			if save_manager.save_data.gold >= cost:
				save_manager.save_data.gold -= cost
				crit_chance_level += 1
				save_manager.save_data.crit_chance_level = crit_chance_level
				return true
		"crit_damage":
			current_level = crit_damage_level
			cost = get_upgrade_cost("crit_damage", current_level)
			if save_manager.save_data.gold >= cost:
				save_manager.save_data.gold -= cost
				crit_damage_level += 1
				save_manager.save_data.crit_damage_level = crit_damage_level
				return true
	
	return false

func get_all_upgrades() -> Dictionary:
	return {
		"damage": {"level": damage_level, "cost": get_upgrade_cost("damage", damage_level)},
		"attack_speed": {"level": attack_speed_level, "cost": get_upgrade_cost("attack_speed", attack_speed_level)},
		"max_hp": {"level": max_hp_level, "cost": get_upgrade_cost("max_hp", max_hp_level)},
		"crit_chance": {"level": crit_chance_level, "cost": get_upgrade_cost("crit_chance", crit_chance_level)},
		"crit_damage": {"level": crit_damage_level, "cost": get_upgrade_cost("crit_damage", crit_damage_level)}
	}