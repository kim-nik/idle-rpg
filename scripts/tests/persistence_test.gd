extends "res://scripts/tests/test_case.gd"

const EXPECTED_DEFAULT_SAVE := {
	"version": 2,
	"gold": 0,
	"damage_level": 1,
	"attack_speed_level": 1,
	"max_hp_level": 1,
	"armor_level": 1,
	"health_regen_level": 1,
	"crit_chance_level": 1,
	"crit_damage_level": 1,
	"wave": 1,
	"monsters_killed": 0
}

func get_name() -> String:
	return "save persistence"

func run(environment) -> Array[String]:
	var failures: Array[String] = []
	var save_manager = environment.save_manager
	var upgrade_system = environment.upgrade_system

	environment.reset_progress()
	_expect(save_manager.save_data == EXPECTED_DEFAULT_SAVE, "Reset did not restore the default save payload", failures)

	save_manager.save_data = {
		"version": 1,
		"gold": 77,
		"damage_level": 3,
		"attack_speed_level": 2,
		"max_hp_level": 4,
		"armor_level": 5,
		"health_regen_level": 3,
		"crit_chance_level": 2,
		"crit_damage_level": 3,
		"wave": 6,
		"monsters_killed": 9
	}
	save_manager.save()

	save_manager.save_data.gold = 0
	save_manager.save_data.wave = 1
	save_manager.save_data.damage_level = 1
	save_manager.load_game()
	upgrade_system.load_from_save()

	_expect(save_manager.save_data.gold == 77, "Gold did not survive save/load roundtrip", failures)
	_expect(save_manager.save_data.wave == 6, "Wave did not survive save/load roundtrip", failures)
	_expect(save_manager.save_data.damage_level == 3, "Damage level did not survive save/load roundtrip", failures)
	_expect(save_manager.save_data.armor_level == 5, "Armor level did not survive save/load roundtrip", failures)
	_expect(save_manager.save_data.health_regen_level == 3, "Health regen level did not survive save/load roundtrip", failures)
	_expect(upgrade_system.damage_level == 3, "Upgrade system did not reload damage level from save", failures)
	_expect(upgrade_system.max_hp_level == 4, "Upgrade system did not reload max HP level from save", failures)
	_expect(upgrade_system.armor_level == 5, "Upgrade system did not reload armor level from save", failures)
	_expect(upgrade_system.health_regen_level == 3, "Upgrade system did not reload health regen level from save", failures)
	_expect(upgrade_system.crit_damage_level == 3, "Upgrade system did not reload crit damage level from save", failures)

	save_manager.save_data = {"gold": 10}
	save_manager.save()
	save_manager.load_game()
	_expect(save_manager.save_data.version == 2, "Save migration did not stamp the current version", failures)
	_expect(save_manager.save_data.damage_level == 1, "Save migration did not restore missing damage level", failures)
	_expect(save_manager.save_data.armor_level == 1, "Save migration did not restore missing armor level", failures)
	_expect(save_manager.save_data.health_regen_level == 1, "Save migration did not restore missing regen level", failures)

	save_manager.save_data = {
		"version": 1,
		"gold": 25,
		"damage_level": 2,
		"attack_speed_level": 2,
		"max_hp_level": 2,
		"crit_chance_level": 2,
		"crit_damage_level": 2,
		"wave": 3,
		"monsters_killed": 4
	}
	save_manager.save()
	save_manager.load_game()
	_expect(save_manager.save_data.version == 2, "Versioned migration did not advance the save version", failures)
	_expect(save_manager.save_data.armor_level == 1, "Versioned migration did not add armor level", failures)
	_expect(save_manager.save_data.health_regen_level == 1, "Versioned migration did not add regen level", failures)

	return failures
