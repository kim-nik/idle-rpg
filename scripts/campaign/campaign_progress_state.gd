class_name CampaignProgressState
extends RefCounted

const WAVES_PER_CHAPTER := 10
const BOSS_KIND_NONE := ""
const BOSS_KIND_WAVE := "wave"
const BOSS_KIND_SUPER := "super"

var current_chapter: int = 1
var current_wave: int = 1
var highest_unlocked_wave: int = 1
var highest_cleared_chapter: int = 0
var is_boss_unlocked: bool = false
var is_in_boss_fight: bool = false
var boss_stage_kind: String = BOSS_KIND_NONE
var pending_boss_kind: String = BOSS_KIND_NONE
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
	boss_stage_kind = _normalize_boss_kind(
		save_data.get("campaign_active_boss_kind", BOSS_KIND_SUPER if is_in_boss_fight else BOSS_KIND_NONE)
	)
	pending_boss_kind = _normalize_boss_kind(save_data.get("campaign_pending_boss_kind", BOSS_KIND_NONE))
	selected_wave = clampi(int(save_data.get("campaign_selected_wave", current_wave)), 1, WAVES_PER_CHAPTER)
	selected_boss = bool(save_data.get("campaign_selected_boss", false)) and is_boss_unlocked
	_sync_cleared_chapter_access()
	if boss_stage_kind == BOSS_KIND_WAVE or pending_boss_kind == BOSS_KIND_WAVE:
		selected_boss = false
	if not is_boss_unlocked:
		selected_boss = false

func write_to_save(save_data: Dictionary) -> void:
	save_data.wave = current_wave
	save_data.campaign_chapter = current_chapter
	save_data.campaign_wave = current_wave
	save_data.campaign_in_boss = is_in_boss_fight
	save_data.campaign_active_boss_kind = boss_stage_kind
	save_data.campaign_pending_boss_kind = pending_boss_kind
	save_data.campaign_highest_unlocked_wave = highest_unlocked_wave
	save_data.campaign_highest_cleared_chapter = highest_cleared_chapter
	save_data.campaign_boss_unlocked = is_boss_unlocked
	save_data.campaign_selected_wave = selected_wave
	save_data.campaign_selected_boss = selected_boss

func clear_status() -> void:
	status_message = ""

func select_wave(wave_number: int) -> bool:
	if pending_boss_kind == BOSS_KIND_WAVE or boss_stage_kind == BOSS_KIND_WAVE:
		return false
	var clamped_wave = clampi(wave_number, 1, WAVES_PER_CHAPTER)
	if clamped_wave > highest_unlocked_wave:
		return false
	selected_wave = clamped_wave
	selected_boss = false
	return true

func select_boss() -> bool:
	if pending_boss_kind == BOSS_KIND_WAVE or boss_stage_kind == BOSS_KIND_WAVE:
		return false
	if not is_boss_unlocked:
		return false
	selected_boss = true
	selected_wave = WAVES_PER_CHAPTER
	return true

func begin_regular_wave(wave_number: int, preserve_pending_wave_boss: bool = false) -> void:
	current_wave = clampi(wave_number, 1, WAVES_PER_CHAPTER)
	is_in_boss_fight = false
	boss_stage_kind = BOSS_KIND_NONE
	if not preserve_pending_wave_boss:
		pending_boss_kind = BOSS_KIND_NONE
	selected_wave = current_wave
	selected_boss = false

func begin_boss_fight(kind: String) -> void:
	boss_stage_kind = _normalize_boss_kind(kind)
	pending_boss_kind = BOSS_KIND_NONE
	is_in_boss_fight = boss_stage_kind != BOSS_KIND_NONE
	selected_wave = current_wave
	selected_boss = boss_stage_kind == BOSS_KIND_SUPER
	if boss_stage_kind == BOSS_KIND_SUPER:
		current_wave = WAVES_PER_CHAPTER
		is_boss_unlocked = true
		selected_wave = WAVES_PER_CHAPTER

func restore_wave_boss_pending(next_status_message: String = "Wave boss incoming") -> void:
	is_in_boss_fight = false
	boss_stage_kind = BOSS_KIND_NONE
	pending_boss_kind = BOSS_KIND_WAVE
	selected_wave = current_wave
	selected_boss = false
	status_message = next_status_message

func restore_super_boss_ready(next_status_message: String = "Super Boss unlocked") -> void:
	current_wave = WAVES_PER_CHAPTER
	highest_unlocked_wave = max(highest_unlocked_wave, WAVES_PER_CHAPTER)
	is_boss_unlocked = true
	is_in_boss_fight = false
	boss_stage_kind = BOSS_KIND_NONE
	pending_boss_kind = BOSS_KIND_NONE
	selected_wave = WAVES_PER_CHAPTER
	selected_boss = false
	status_message = next_status_message

func complete_regular_wave(auto_start_boss: bool) -> Dictionary:
	var completed_wave = current_wave
	var transition := {
		"completed_wave": completed_wave,
		"queue_kind": "regular_wave",
		"queue_wave": completed_wave,
		"preserve_pending_wave_boss": false
	}

	if completed_wave < WAVES_PER_CHAPTER:
		pending_boss_kind = BOSS_KIND_WAVE
		if auto_start_boss:
			selected_wave = completed_wave
			selected_boss = false
			status_message = "Wave boss incoming"
			transition.queue_kind = "wave_boss"
			return transition

		current_wave = completed_wave
		selected_wave = completed_wave
		selected_boss = false
		status_message = "Boss available"
		transition.queue_wave = completed_wave
		transition.preserve_pending_wave_boss = true
		return transition

	current_wave = WAVES_PER_CHAPTER
	is_boss_unlocked = true
	if auto_start_boss:
		pending_boss_kind = BOSS_KIND_SUPER
		selected_wave = WAVES_PER_CHAPTER
		selected_boss = true
		status_message = ""
		transition.queue_kind = "super_boss"
		return transition

	pending_boss_kind = BOSS_KIND_NONE
	selected_wave = WAVES_PER_CHAPTER
	selected_boss = false
	status_message = "Super Boss unlocked"
	transition.queue_wave = WAVES_PER_CHAPTER
	return transition

func resolve_boss_victory(auto_next_wave: bool) -> Dictionary:
	if boss_stage_kind == BOSS_KIND_WAVE:
		var completed_wave = current_wave
		highest_unlocked_wave = min(max(highest_unlocked_wave, completed_wave + 1), WAVES_PER_CHAPTER)
		is_in_boss_fight = false
		boss_stage_kind = BOSS_KIND_NONE
		pending_boss_kind = BOSS_KIND_NONE
		var next_wave = highest_unlocked_wave if auto_next_wave else completed_wave
		current_wave = next_wave
		selected_wave = next_wave
		selected_boss = false
		status_message = "" if auto_next_wave else "Repeating wave"
		return {
			"queue_wave": next_wave,
			"chapter_completed": 0
		}

	var completed_chapter = current_chapter
	highest_cleared_chapter = max(highest_cleared_chapter, completed_chapter)
	current_chapter += 1
	current_wave = 1
	highest_unlocked_wave = 1
	selected_wave = 1
	selected_boss = false
	is_boss_unlocked = false
	is_in_boss_fight = false
	boss_stage_kind = BOSS_KIND_NONE
	pending_boss_kind = BOSS_KIND_NONE
	status_message = ""
	return {
		"completed_chapter": completed_chapter,
		"queue_wave": 1
	}

func apply_defeat(defeat_reason: String) -> void:
	if is_in_boss_fight:
		var active_boss_kind = boss_stage_kind
		is_in_boss_fight = false
		boss_stage_kind = BOSS_KIND_NONE
		pending_boss_kind = BOSS_KIND_NONE
		selected_boss = false
		selected_wave = current_wave
		if active_boss_kind == BOSS_KIND_WAVE:
			status_message = "Retrying Wave %d Boss" % current_wave
			return

		current_wave = WAVES_PER_CHAPTER
		selected_wave = WAVES_PER_CHAPTER
		is_boss_unlocked = false
		if defeat_reason == "boss_timeout":
			status_message = "Super Boss timer expired. Retrying Chapter %d from Wave %d" % [
				current_chapter,
				WAVES_PER_CHAPTER
			]
			return
		status_message = "Retrying Chapter %d Super Boss access from Wave %d" % [current_chapter, WAVES_PER_CHAPTER]
		return

	var rollback_wave = maxi(current_wave - 1, 1)
	current_wave = rollback_wave
	selected_wave = rollback_wave
	selected_boss = false
	highest_unlocked_wave = min(highest_unlocked_wave, rollback_wave)
	is_boss_unlocked = false
	pending_boss_kind = BOSS_KIND_NONE
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
		"boss_kind": boss_stage_kind,
		"pending_boss_kind": pending_boss_kind,
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

func _normalize_boss_kind(value) -> String:
	var normalized = String(value)
	match normalized:
		BOSS_KIND_WAVE, BOSS_KIND_SUPER:
			return normalized
		_:
			return BOSS_KIND_NONE
