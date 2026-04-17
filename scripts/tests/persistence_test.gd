extends "res://scripts/tests/test_case.gd"

const EXPECTED_DEFAULT_SAVE := {
	"version": 6,
	"gold": 0,
	"damage_level": 1,
	"attack_speed_level": 1,
	"max_hp_level": 1,
	"armor_level": 1,
	"health_regen_level": 1,
	"crit_chance_level": 1,
	"crit_damage_level": 1,
	"wave": 1,
	"monsters_killed": 0,
	"campaign_chapter": 1,
	"campaign_wave": 1,
	"campaign_in_boss": false,
	"campaign_highest_unlocked_wave": 1,
	"campaign_highest_cleared_chapter": 0,
	"campaign_boss_unlocked": false,
	"campaign_selected_wave": 1,
	"campaign_selected_boss": false,
	"setting_auto_next_wave": true,
	"setting_auto_start_boss": false,
	"unlocked_ability_ids": ["evil_eye", "leg_sweep", "punch"],
	"equipped_ability_slots": ["", "", "", "", "", "", "", ""]
}

func get_name() -> String:
	return "save persistence"

func run(environment) -> Array[String]:
	var failures: Array[String] = []
	var save_manager = environment.save_manager
	var upgrade_system = environment.upgrade_system
	var ability_system = environment.ability_system

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
		"monsters_killed": 9,
		"unlocked_ability_ids": ["punch", "leg_sweep", "evil_eye"],
		"equipped_ability_slots": ["punch", "leg_sweep", "evil_eye", "", "", "", "", ""]
	}
	save_manager.save()

	save_manager.save_data.gold = 0
	save_manager.save_data.wave = 1
	save_manager.save_data.damage_level = 1
	save_manager.load_game()
	upgrade_system.load_from_save()
	ability_system.load_from_save()

	_expect(save_manager.save_data.gold == 77, "Gold did not survive save/load roundtrip", failures)
	_expect(save_manager.save_data.wave == 6, "Wave alias did not survive save/load roundtrip", failures)
	_expect(save_manager.save_data.campaign_chapter == 1, "Campaign chapter did not migrate from legacy wave", failures)
	_expect(save_manager.save_data.campaign_wave == 6, "Campaign wave did not migrate from legacy wave", failures)
	_expect(
		save_manager.save_data.campaign_highest_unlocked_wave == 6,
		"Highest unlocked wave did not migrate from legacy wave",
		failures
	)
	_expect(
		save_manager.save_data.campaign_highest_cleared_chapter == 0,
		"Cleared chapter marker did not migrate from legacy wave",
		failures
	)
	_expect(save_manager.save_data.damage_level == 3, "Damage level did not survive save/load roundtrip", failures)
	_expect(save_manager.save_data.armor_level == 5, "Armor level did not survive save/load roundtrip", failures)
	_expect(save_manager.save_data.health_regen_level == 3, "Health regen level did not survive save/load roundtrip", failures)
	_expect(save_manager.save_data.unlocked_ability_ids.has("leg_sweep"), "Unlocked abilities did not survive save/load roundtrip", failures)
	_expect(save_manager.save_data.equipped_ability_slots[1] == "leg_sweep", "Equipped ability slot did not survive save/load", failures)
	_expect(upgrade_system.damage_level == 3, "Upgrade system did not reload damage level from save", failures)
	_expect(upgrade_system.max_hp_level == 4, "Upgrade system did not reload max HP level from save", failures)
	_expect(upgrade_system.armor_level == 5, "Upgrade system did not reload armor level from save", failures)
	_expect(upgrade_system.health_regen_level == 3, "Upgrade system did not reload health regen level from save", failures)
	_expect(upgrade_system.crit_damage_level == 3, "Upgrade system did not reload crit damage level from save", failures)
	_expect(ability_system.is_unlocked("leg_sweep"), "Ability system did not reload unlocked abilities", failures)
	_expect(ability_system.get_ability_slot(1) == "leg_sweep", "Ability system did not reload equipped slots", failures)

	save_manager.save_data = {"gold": 10}
	save_manager.save()
	save_manager.load_game()
	ability_system.load_from_save()
	_expect(save_manager.save_data.version == 6, "Save migration did not stamp the current version", failures)
	_expect(save_manager.save_data.damage_level == 1, "Save migration did not restore missing damage level", failures)
	_expect(save_manager.save_data.armor_level == 1, "Save migration did not restore missing armor level", failures)
	_expect(save_manager.save_data.health_regen_level == 1, "Save migration did not restore missing regen level", failures)
	_expect(save_manager.save_data.campaign_chapter == 1, "Save migration did not restore default campaign chapter", failures)
	_expect(save_manager.save_data.campaign_wave == 1, "Save migration did not restore default campaign wave", failures)
	_expect(
		save_manager.save_data.campaign_highest_unlocked_wave == 1,
		"Save migration did not restore default highest unlocked wave",
		failures
	)
	_expect(
		save_manager.save_data.campaign_highest_cleared_chapter == 0,
		"Save migration did not restore default cleared chapter marker",
		failures
	)
	_expect(save_manager.save_data.setting_auto_next_wave, "Save migration did not restore Auto Next Wave default", failures)
	_expect(
		not save_manager.save_data.setting_auto_start_boss,
		"Save migration did not restore Auto Start Boss default",
		failures
	)
	_expect(
		save_manager.save_data.unlocked_ability_ids == ["evil_eye", "leg_sweep", "punch"],
		"Save migration did not restore starter abilities",
		failures
	)
	_expect(
		save_manager.save_data.equipped_ability_slots == ["", "", "", "", "", "", "", ""],
		"Save migration did not restore empty ability slots",
		failures
	)

	save_manager.save_data = {
		"version": 3,
		"gold": 25,
		"damage_level": 2,
		"attack_speed_level": 2,
		"max_hp_level": 2,
		"crit_chance_level": 2,
		"crit_damage_level": 2,
		"wave": 13,
		"monsters_killed": 4
	}
	save_manager.save()
	save_manager.load_game()
	_expect(save_manager.save_data.version == 6, "Versioned migration did not advance the save version", failures)
	_expect(save_manager.save_data.armor_level == 1, "Versioned migration did not add armor level", failures)
	_expect(save_manager.save_data.health_regen_level == 1, "Versioned migration did not add regen level", failures)
	_expect(save_manager.save_data.wave == 3, "Versioned migration did not remap the legacy wave alias", failures)
	_expect(save_manager.save_data.campaign_chapter == 2, "Versioned migration did not compute campaign chapter", failures)
	_expect(save_manager.save_data.campaign_wave == 3, "Versioned migration did not compute campaign wave", failures)
	_expect(
		save_manager.save_data.campaign_highest_unlocked_wave == 3,
		"Versioned migration did not compute highest unlocked wave",
		failures
	)
	_expect(
		save_manager.save_data.campaign_highest_cleared_chapter == 1,
		"Versioned migration did not compute cleared chapter marker",
		failures
	)
	_expect(
		save_manager.save_data.unlocked_ability_ids.has("punch")
			and save_manager.save_data.unlocked_ability_ids.has("leg_sweep")
			and save_manager.save_data.unlocked_ability_ids.has("evil_eye"),
		"Versioned migration did not add starter ability unlocks",
		failures
	)
	_expect(
		save_manager.save_data.equipped_ability_slots == ["", "", "", "", "", "", "", ""],
		"Versioned migration did not add empty ability slots",
		failures
	)

	return failures
