extends Node

const SAVE_FILE := "user://save.dat"
const SAVE_VERSION := 4
const DEFAULT_SAVE_DATA := {
	"version": SAVE_VERSION,
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
	"unlocked_ability_ids": ["evil_eye", "leg_sweep", "punch"],
	"equipped_ability_slots": ["", "", "", "", "", "", "", ""]
}

var save_data := DEFAULT_SAVE_DATA.duplicate(true)

func _ready() -> void:
	load_game()

func save() -> void:
	save_data.version = SAVE_VERSION
	var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		var json_string := JSON.stringify(save_data)
		file.store_line(json_string)
		file.close()

func load_game() -> void:
	if FileAccess.file_exists(SAVE_FILE):
		var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
		if file:
			var json_string := file.get_line()
			var json := JSON.new()
			if json.parse(json_string) == OK:
				var loaded_data = json.get_data()
				if loaded_data is Dictionary:
					save_data = _migrate_save_data(loaded_data)
			file.close()
	else:
		save_data = DEFAULT_SAVE_DATA.duplicate(true)

func _migrate_save_data(loaded_data: Dictionary) -> Dictionary:
	var working_data := loaded_data.duplicate(true)
	var source_version = int(working_data.get("version", 0))

	if source_version < 1:
		working_data = _migrate_to_v1(working_data)
		source_version = 1
	if source_version < 2:
		working_data = _migrate_to_v2(working_data)
		source_version = 2
	if source_version < 3:
		working_data = _migrate_to_v3(working_data)
		source_version = 3
	if source_version < 4:
		working_data = _migrate_to_v4(working_data)

	return _merge_with_defaults(working_data)

func _migrate_to_v1(loaded_data: Dictionary) -> Dictionary:
	var migrated_data := loaded_data.duplicate(true)
	migrated_data.version = 1
	return migrated_data

func _migrate_to_v2(loaded_data: Dictionary) -> Dictionary:
	var migrated_data := loaded_data.duplicate(true)
	if not migrated_data.has("armor_level"):
		migrated_data.armor_level = 1
	if not migrated_data.has("health_regen_level"):
		migrated_data.health_regen_level = 1
	migrated_data.version = 2
	return migrated_data

func _migrate_to_v3(loaded_data: Dictionary) -> Dictionary:
	var migrated_data := loaded_data.duplicate(true)
	if not migrated_data.has("unlocked_ability_ids"):
		migrated_data.unlocked_ability_ids = ["punch", "leg_sweep", "evil_eye"]
	if not migrated_data.has("equipped_ability_slots"):
		migrated_data.equipped_ability_slots = ["", "", "", "", "", "", "", ""]
	migrated_data.version = 3
	return migrated_data

func _migrate_to_v4(loaded_data: Dictionary) -> Dictionary:
	var migrated_data := loaded_data.duplicate(true)
	migrated_data.unlocked_ability_ids = ["punch", "leg_sweep", "evil_eye"]
	if not migrated_data.has("equipped_ability_slots"):
		migrated_data.equipped_ability_slots = ["", "", "", "", "", "", "", ""]
	migrated_data.version = 4
	return migrated_data

func _merge_with_defaults(loaded_data: Dictionary) -> Dictionary:
	var merged_data := DEFAULT_SAVE_DATA.duplicate(true)
	for key in loaded_data.keys():
		merged_data[key] = loaded_data[key]
	merged_data.version = SAVE_VERSION
	return merged_data

func reset() -> void:
	save_data = DEFAULT_SAVE_DATA.duplicate(true)
	save()
