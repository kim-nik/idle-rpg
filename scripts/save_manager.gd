extends Node

const SAVE_FILE := "user://save.dat"

var save_data := {
	"gold": 0,
	"damage_level": 1,
	"attack_speed_level": 1,
	"max_hp_level": 1,
	"crit_chance_level": 1,
	"crit_damage_level": 1,
	"wave": 1,
	"monsters_killed": 0
}

func _ready() -> void:
	load_game()

func save() -> void:
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
					save_data = loaded_data
			file.close()

func reset() -> void:
	save_data = {
		"gold": 0,
		"damage_level": 1,
		"attack_speed_level": 1,
		"max_hp_level": 1,
		"crit_chance_level": 1,
		"crit_damage_level": 1,
		"wave": 1,
		"monsters_killed": 0
	}
	save()