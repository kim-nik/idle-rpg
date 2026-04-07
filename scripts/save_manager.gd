extends Node

const SAVE_FILE := "user://save.dat"
const SAVE_VERSION := 2
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
	"monsters_killed": 0
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
					save_data = _merge_with_defaults(loaded_data)
			file.close()
	else:
		save_data = DEFAULT_SAVE_DATA.duplicate(true)

func _merge_with_defaults(loaded_data: Dictionary) -> Dictionary:
	var merged_data := DEFAULT_SAVE_DATA.duplicate(true)
	for key in loaded_data.keys():
		merged_data[key] = loaded_data[key]
	merged_data.version = SAVE_VERSION
	return merged_data

func reset() -> void:
	save_data = DEFAULT_SAVE_DATA.duplicate(true)
	save()
