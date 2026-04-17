extends Node

signal save_data_changed(change_reason: String)

const SAVE_FILE := "user://save.dat"
const SAVE_VERSION := 7
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
	"campaign_chapter": 1,
	"campaign_wave": 1,
	"campaign_in_boss": false,
	"campaign_active_boss_kind": "",
	"campaign_pending_boss_kind": "",
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

var save_data := duplicate_default_save_data()

func _ready() -> void:
	load_game()

func duplicate_default_save_data() -> Dictionary:
	return DEFAULT_SAVE_DATA.duplicate(true)

func save() -> void:
	_persist("save")

func set_save_field(key: String, value, persist_immediately: bool = false, change_reason: String = "field") -> void:
	save_data[key] = value
	if persist_immediately:
		_persist(change_reason)
		return
	_emit_save_data_changed(change_reason)

func add_gold(amount: int, persist_immediately: bool = false) -> int:
	save_data.gold = max(int(save_data.get("gold", 0)) + amount, 0)
	if persist_immediately:
		_persist("gold")
		return int(save_data.gold)
	_emit_save_data_changed("gold")
	return int(save_data.gold)

func add_monsters_killed(count: int = 1, persist_immediately: bool = false) -> int:
	save_data.monsters_killed = max(int(save_data.get("monsters_killed", 0)) + count, 0)
	if persist_immediately:
		_persist("monsters_killed")
		return int(save_data.monsters_killed)
	_emit_save_data_changed("monsters_killed")
	return int(save_data.monsters_killed)

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
		save_data = duplicate_default_save_data()

	_emit_save_data_changed("load")

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
		source_version = 4
	if source_version < 5:
		working_data = _migrate_to_v5(working_data)
		source_version = 5
	if source_version < 6:
		working_data = _migrate_to_v6(working_data)
		source_version = 6
	if source_version < 7:
		working_data = _migrate_to_v7(working_data)

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

func _migrate_to_v5(loaded_data: Dictionary) -> Dictionary:
	var migrated_data := loaded_data.duplicate(true)
	var legacy_wave = maxi(int(migrated_data.get("wave", 1)), 1)
	var campaign_chapter = int(floor(float(legacy_wave - 1) / 10.0)) + 1
	var campaign_wave = ((legacy_wave - 1) % 10) + 1

	migrated_data.campaign_chapter = campaign_chapter
	migrated_data.campaign_wave = campaign_wave
	migrated_data.campaign_in_boss = false
	migrated_data.campaign_highest_unlocked_wave = campaign_wave
	migrated_data.campaign_highest_cleared_chapter = max(campaign_chapter - 1, 0)
	migrated_data.campaign_boss_unlocked = false
	migrated_data.campaign_selected_wave = campaign_wave
	migrated_data.campaign_selected_boss = false
	migrated_data.setting_auto_next_wave = true
	migrated_data.setting_auto_start_boss = false
	migrated_data.wave = campaign_wave
	migrated_data.monsters_killed = maxi(int(migrated_data.get("monsters_killed", 0)), 0)
	migrated_data.version = 5
	return migrated_data

func _migrate_to_v6(loaded_data: Dictionary) -> Dictionary:
	var migrated_data := loaded_data.duplicate(true)
	if not migrated_data.has("campaign_highest_cleared_chapter"):
		migrated_data.campaign_highest_cleared_chapter = max(int(migrated_data.get("campaign_chapter", 1)) - 1, 0)
	migrated_data.version = 6
	return migrated_data

func _migrate_to_v7(loaded_data: Dictionary) -> Dictionary:
	var migrated_data := loaded_data.duplicate(true)
	if not migrated_data.has("campaign_active_boss_kind"):
		migrated_data.campaign_active_boss_kind = "super" if bool(migrated_data.get("campaign_in_boss", false)) else ""
	if not migrated_data.has("campaign_pending_boss_kind"):
		migrated_data.campaign_pending_boss_kind = ""
	migrated_data.version = 7
	return migrated_data

func _merge_with_defaults(loaded_data: Dictionary) -> Dictionary:
	var merged_data := duplicate_default_save_data()
	for key in loaded_data.keys():
		merged_data[key] = loaded_data[key]
	merged_data.version = SAVE_VERSION
	return merged_data

func reset() -> void:
	save_data = duplicate_default_save_data()
	_persist("reset")

func _persist(change_reason: String) -> void:
	save_data.version = SAVE_VERSION
	var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for writing: %s" % SAVE_FILE)
		return

	var json_string := JSON.stringify(save_data)
	file.store_line(json_string)
	file.close()
	_emit_save_data_changed(change_reason)

func _emit_save_data_changed(change_reason: String) -> void:
	emit_signal("save_data_changed", change_reason)
