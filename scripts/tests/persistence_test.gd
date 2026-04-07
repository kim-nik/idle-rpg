extends "res://scripts/tests/test_case.gd"

const EXPECTED_DEFAULT_SAVE := {
	"gold": 0,
	"damage_level": 1,
	"attack_speed_level": 1,
	"max_hp_level": 1,
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
		"gold": 77,
		"damage_level": 3,
		"attack_speed_level": 2,
		"max_hp_level": 4,
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
	_expect(upgrade_system.damage_level == 3, "Upgrade system did not reload damage level from save", failures)
	_expect(upgrade_system.max_hp_level == 4, "Upgrade system did not reload max HP level from save", failures)
	_expect(upgrade_system.crit_damage_level == 3, "Upgrade system did not reload crit damage level from save", failures)

	return failures
