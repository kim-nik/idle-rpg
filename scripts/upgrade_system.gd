extends Node

const UPGRADE_CONFIGS := {
	"damage": {
		"save_key": "damage_level",
		"base_cost": 10,
		"cost_multiplier": 1.5,
		"base_value": 10.0,
		"value_type": "multiplier",
		"value_step": 0.1
	},
	"attack_speed": {
		"save_key": "attack_speed_level",
		"base_cost": 15,
		"cost_multiplier": 1.6,
		"base_value": 1.0,
		"value_type": "multiplier",
		"value_step": 0.1
	},
	"max_hp": {
		"save_key": "max_hp_level",
		"base_cost": 12,
		"cost_multiplier": 1.4,
		"base_value": 100.0,
		"value_type": "flat",
		"value_step": 20.0
	},
	"armor": {
		"save_key": "armor_level",
		"base_cost": 18,
		"cost_multiplier": 1.55,
		"base_value": 0.0,
		"value_type": "flat",
		"value_step": 4.0
	},
	"health_regen": {
		"save_key": "health_regen_level",
		"base_cost": 16,
		"cost_multiplier": 1.5,
		"base_value": 0.0,
		"value_type": "flat",
		"value_step": 1.5
	},
	"crit_chance": {
		"save_key": "crit_chance_level",
		"base_cost": 20,
		"cost_multiplier": 1.7,
		"base_value": 5.0,
		"value_type": "flat",
		"value_step": 5.0
	},
	"crit_damage": {
		"save_key": "crit_damage_level",
		"base_cost": 25,
		"cost_multiplier": 1.6,
		"base_value": 150.0,
		"value_type": "flat",
		"value_step": 25.0
	}
}

var damage_level: int = 1
var attack_speed_level: int = 1
var max_hp_level: int = 1
var armor_level: int = 1
var health_regen_level: int = 1
var crit_chance_level: int = 1
var crit_damage_level: int = 1

func _ready() -> void:
	load_from_save()

func load_from_save() -> void:
	var save_manager = get_node("/root/SaveManager")
	for upgrade_name in UPGRADE_CONFIGS.keys():
		var config = UPGRADE_CONFIGS[upgrade_name]
		var save_key = String(config.get("save_key", ""))
		if not save_key.is_empty():
			set(save_key, int(save_manager.save_data.get(save_key, 1)))

func get_upgrade_cost(upgrade_name: String, level: int) -> int:
	var config = UPGRADE_CONFIGS.get(upgrade_name, {})
	var base_cost = int(config.get("base_cost", 10))
	var multiplier = float(config.get("cost_multiplier", 1.5))
	return int(base_cost * pow(multiplier, level - 1))

func get_upgrade_level(upgrade_name: String) -> int:
	var config = UPGRADE_CONFIGS.get(upgrade_name, {})
	var save_key = String(config.get("save_key", ""))
	if save_key.is_empty():
		return 1
	return int(get(save_key))

func get_upgrade_value(upgrade_name: String) -> float:
	var config = UPGRADE_CONFIGS.get(upgrade_name, {})
	var base_value = float(config.get("base_value", 0.0))
	var value_step = float(config.get("value_step", 0.0))
	var level = get_upgrade_level(upgrade_name)
	var level_offset = max(level - 1, 0)

	match String(config.get("value_type", "flat")):
		"multiplier":
			return base_value * (1.0 + level_offset * value_step)
		_:
			return base_value + level_offset * value_step

func get_damage() -> float:
	return get_upgrade_value("damage")

func get_attack_speed() -> float:
	return get_upgrade_value("attack_speed")

func get_max_hp() -> float:
	return get_upgrade_value("max_hp")

func get_armor() -> float:
	return get_upgrade_value("armor")

func get_health_regen() -> float:
	return get_upgrade_value("health_regen")

func get_crit_chance() -> float:
	return get_upgrade_value("crit_chance")

func get_crit_damage() -> float:
	return get_upgrade_value("crit_damage")

func get_hero_stats() -> Dictionary:
	return {
		"max_hp": get_max_hp(),
		"attack_damage": get_damage(),
		"attack_speed": get_attack_speed(),
		"armor": get_armor(),
		"health_regen": get_health_regen(),
		"crit_chance": get_crit_chance(),
		"crit_damage": get_crit_damage()
	}

func purchase_upgrade(upgrade_name: String) -> bool:
	var config = UPGRADE_CONFIGS.get(upgrade_name, {})
	if config.is_empty():
		return false

	var save_manager = get_node("/root/SaveManager")
	var save_key = String(config.get("save_key", ""))
	var current_level = int(save_manager.save_data.get(save_key, 1))
	var cost = get_upgrade_cost(upgrade_name, current_level)
	if save_manager.save_data.gold < cost:
		return false

	save_manager.save_data.gold -= cost
	save_manager.save_data[save_key] = current_level + 1
	load_from_save()
	return true

func get_all_upgrades() -> Dictionary:
	var upgrades := {}
	for upgrade_name in UPGRADE_CONFIGS.keys():
		var level = get_upgrade_level(upgrade_name)
		upgrades[upgrade_name] = {
			"level": level,
			"cost": get_upgrade_cost(upgrade_name, level)
		}
	return upgrades
