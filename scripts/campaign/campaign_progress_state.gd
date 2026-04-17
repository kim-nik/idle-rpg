class_name CampaignProgressState
extends RefCounted

const WAVES_PER_CHAPTER := 10

var current_chapter: int = 1
var current_wave: int = 1
var highest_unlocked_wave: int = 1
var highest_cleared_chapter: int = 0
var is_boss_unlocked: bool = false
var is_in_boss_fight: bool = false
var selected_wave: int = 1
var selected_boss: bool = false
var status_message: String = ""

func load_from_save(save_data: Dictionary) -> void:
	current_chapter = maxi(int(save_data.get("campaign_chapter", 1)), 1)
	current_wave = clampi(int(save_data.get("campaign_wave", 1)), 1, WAVES_PER_CHAPTER)
	highest_unlocked_wave = clampi(
		int(save_data.get("campaign_highest_unlocked_wave", current_wave)),
		1,
		WAVES_PER_CHAPTER
	)
	highest_cleared_chapter = max(int(save_data.get("campaign_highest_cleared_chapter", current_chapter - 1)), 0)
	is_boss_unlocked = bool(save_data.get("campaign_boss_unlocked", false))
	is_in_boss_fight = bool(save_data.get("campaign_in_boss", false))
	selected_wave = clampi(int(save_data.get("campaign_selected_wave", current_wave)), 1, WAVES_PER_CHAPTER)
	selected_boss = bool(save_data.get("campaign_selected_boss", false)) and is_boss_unlocked
	_sync_cleared_chapter_access()
	if not is_boss_unlocked:
		selected_boss = false

func write_to_save(save_data: Dictionary) -> void:
	save_data.wave = current_wave
	save_data.campaign_chapter = current_chapter
	save_data.campaign_wave = current_wave
	save_data.campaign_in_boss = is_in_boss_fight
	save_data.campaign_highest_unlocked_wave = highest_unlocked_wave
	save_data.campaign_highest_cleared_chapter = highest_cleared_chapter
	save_data.campaign_boss_unlocked = is_boss_unlocked
	save_data.campaign_selected_wave = selected_wave
	save_data.campaign_selected_boss = selected_boss

func clear_status() -> void:
	status_message = ""

func select_wave(wave_number: int) -> bool:
	var clamped_wave = clampi(wave_number, 1, WAVES_PER_CHAPTER)
	if clamped_wave > highest_unlocked_wave:
		return false
	selected_wave = clamped_wave
	selected_boss = false
	return true

func select_boss() -> bool:
	if not is_boss_unlocked:
		return false
	selected_boss = true
	selected_wave = WAVES_PER_CHAPTER
	return true

func begin_regular_wave(wave_number: int) -> void:
	current_wave = clampi(wave_number, 1, WAVES_PER_CHAPTER)
	is_in_boss_fight = false
	selected_wave = current_wave
	selected_boss = false

func begin_boss_fight() -> void:
	current_wave = WAVES_PER_CHAPTER
	is_in_boss_fight = true
	is_boss_unlocked = true
	selected_wave = WAVES_PER_CHAPTER
	selected_boss = true

func restore_boss_ready(next_status_message: String = "Boss unlocked") -> void:
	current_wave = WAVES_PER_CHAPTER
	highest_unlocked_wave = max(highest_unlocked_wave, WAVES_PER_CHAPTER)
	is_boss_unlocked = true
	is_in_boss_fight = false
	selected_wave = WAVES_PER_CHAPTER
	selected_boss = false
	status_message = next_status_message

func complete_regular_wave(auto_next_wave: bool, auto_start_boss: bool) -> Dictionary:
	var completed_wave = current_wave
	var transition := {
		"completed_wave": completed_wave,
		"queue_kind": "regular_wave",
		"queue_wave": completed_wave
	}

	if completed_wave < WAVES_PER_CHAPTER:
		highest_unlocked_wave = min(max(highest_unlocked_wave, completed_wave + 1), WAVES_PER_CHAPTER)
		if auto_next_wave:
			current_wave = highest_unlocked_wave
			selected_wave = current_wave
			selected_boss = false
			status_message = ""
			transition.queue_wave = current_wave
			return transition

		current_wave = completed_wave
		selected_wave = completed_wave
		selected_boss = false
		status_message = "Repeating wave"
		return transition

	current_wave = WAVES_PER_CHAPTER
	is_boss_unlocked = true
	if auto_start_boss:
		selected_wave = WAVES_PER_CHAPTER
		selected_boss = true
		status_message = ""
		transition.queue_kind = "boss_fight"
		return transition

	selected_wave = WAVES_PER_CHAPTER
	selected_boss = false
	status_message = "Boss unlocked"
	transition.queue_wave = WAVES_PER_CHAPTER
	return transition

func complete_boss() -> Dictionary:
	var completed_chapter = current_chapter
	highest_cleared_chapter = max(highest_cleared_chapter, completed_chapter)
	current_chapter += 1
	current_wave = 1
	highest_unlocked_wave = 1
	selected_wave = 1
	selected_boss = false
	is_boss_unlocked = false
	is_in_boss_fight = false
	status_message = ""
	return {
		"completed_chapter": completed_chapter,
		"queue_wave": 1
	}

func apply_defeat(defeat_reason: String) -> void:
	if is_in_boss_fight:
		current_wave = WAVES_PER_CHAPTER
		selected_wave = WAVES_PER_CHAPTER
		selected_boss = false
		is_in_boss_fight = false
		is_boss_unlocked = false
		if defeat_reason == "boss_timeout":
			status_message = "Boss timer expired. Retrying Chapter %d Boss access from Wave %d" % [
				current_chapter,
				WAVES_PER_CHAPTER
			]
			return
		status_message = "Retrying Chapter %d Boss access from Wave %d" % [current_chapter, WAVES_PER_CHAPTER]
		return

	var rollback_wave = maxi(current_wave - 1, 1)
	current_wave = rollback_wave
	selected_wave = rollback_wave
	selected_boss = false
	highest_unlocked_wave = rollback_wave
	is_boss_unlocked = false
	status_message = "Retrying Wave %d" % rollback_wave

func create_snapshot(
	monsters_killed: int,
	total_monsters: int,
	auto_next_wave: bool,
	auto_start_boss: bool,
	boss_stage_active: bool,
	boss_time_remaining: float
) -> Dictionary:
	return {
		"chapter": current_chapter,
		"wave": current_wave,
		"highest_unlocked_wave": highest_unlocked_wave,
		"in_boss_fight": boss_stage_active,
		"boss_unlocked": is_boss_unlocked,
		"selected_wave": selected_wave,
		"selected_boss": selected_boss,
		"monsters_killed": monsters_killed,
		"total_monsters": total_monsters,
		"auto_next_wave": auto_next_wave,
		"auto_start_boss": auto_start_boss,
		"boss_time_remaining": boss_time_remaining,
		"status_message": status_message,
		"cleared_chapters": highest_cleared_chapter
	}

func _sync_cleared_chapter_access() -> void:
	if current_chapter > highest_cleared_chapter:
		return
	highest_unlocked_wave = WAVES_PER_CHAPTER
	is_boss_unlocked = true
