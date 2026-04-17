class_name CampaignUiPresenter
extends RefCounted

func build_fallback_campaign_state(save_data: Dictionary) -> Dictionary:
	var fallback_wave = clampi(int(save_data.get("campaign_wave", save_data.get("wave", 1))), 1, 10)
	return {
		"chapter": max(int(save_data.get("campaign_chapter", 1)), 1),
		"wave": fallback_wave,
		"highest_unlocked_wave": clampi(
			int(save_data.get("campaign_highest_unlocked_wave", fallback_wave)),
			1,
			10
		),
		"in_boss_fight": bool(save_data.get("campaign_in_boss", false)),
		"boss_unlocked": bool(save_data.get("campaign_boss_unlocked", false)),
		"selected_wave": clampi(int(save_data.get("campaign_selected_wave", fallback_wave)), 1, 10),
		"selected_boss": bool(save_data.get("campaign_selected_boss", false)),
		"monsters_killed": max(int(save_data.get("monsters_killed", 0)), 0),
		"total_monsters": 1 if bool(save_data.get("campaign_in_boss", false)) else 20,
		"auto_next_wave": bool(save_data.get("setting_auto_next_wave", true)),
		"auto_start_boss": bool(save_data.get("setting_auto_start_boss", false)),
		"boss_time_remaining": 30.0 if bool(save_data.get("campaign_in_boss", false)) else 0.0,
		"status_message": "",
		"cleared_chapters": max(
			int(save_data.get("campaign_highest_cleared_chapter", int(save_data.get("campaign_chapter", 1)) - 1)),
			0
		)
	}

func update_summary_labels(
	top_wave_label: Label,
	wave_label: Label,
	campaign_status_label: Label,
	campaign_state: Dictionary
) -> void:
	if top_wave_label:
		top_wave_label.text = build_campaign_header_text(campaign_state)
	if wave_label:
		if bool(campaign_state.get("in_boss_fight", false)):
			wave_label.text = "Boss Fight"
		else:
			wave_label.text = "Defeated %d/%d" % [
				int(campaign_state.get("monsters_killed", 0)),
				int(campaign_state.get("total_monsters", 20))
			]
	if campaign_status_label:
		var status_text = build_campaign_status_text(campaign_state)
		campaign_status_label.text = status_text
		campaign_status_label.visible = not status_text.is_empty()

func update_map_ui(
	chapter_label: Label,
	current_state_label: Label,
	cleared_chapters_label: Label,
	auto_summary_label: Label,
	wave_buttons: Array[Button],
	boss_button: Button,
	start_selected_button: Button,
	campaign_state: Dictionary
) -> void:
	if chapter_label == null:
		return

	var current_wave_number = int(campaign_state.get("wave", 1))
	var highest_wave = int(campaign_state.get("highest_unlocked_wave", 1))
	var selected_wave_number = int(campaign_state.get("selected_wave", current_wave_number))
	var boss_unlocked = bool(campaign_state.get("boss_unlocked", false))
	var in_boss_fight = bool(campaign_state.get("in_boss_fight", false))
	var selected_boss_now = bool(campaign_state.get("selected_boss", false))

	chapter_label.text = "Chapter %d" % int(campaign_state.get("chapter", 1))
	current_state_label.text = build_map_current_state_text(campaign_state)
	cleared_chapters_label.text = "Cleared Chapters: %d" % int(campaign_state.get("cleared_chapters", 0))
	auto_summary_label.text = "Auto Next Wave: %s | Auto Start Boss: %s" % [
		_bool_label(bool(campaign_state.get("auto_next_wave", true))),
		_bool_label(bool(campaign_state.get("auto_start_boss", false)))
	]

	for index in range(wave_buttons.size()):
		var wave_number = index + 1
		var button = wave_buttons[index]
		var is_unlocked = wave_number <= highest_wave
		var is_current = not in_boss_fight and wave_number == current_wave_number
		var is_selected = not selected_boss_now and wave_number == selected_wave_number
		var is_cleared = wave_number < highest_wave or (boss_unlocked and wave_number == 10)
		button.disabled = not is_unlocked
		button.text = build_wave_button_text(wave_number, is_unlocked, is_current, is_selected, is_cleared)
		button.set_pressed_no_signal(is_selected)

	var boss_available = boss_unlocked or in_boss_fight
	boss_button.disabled = not boss_available
	boss_button.text = build_boss_button_text(boss_available, in_boss_fight, selected_boss_now)
	boss_button.set_pressed_no_signal(selected_boss_now)

	var can_start_selection = boss_available if selected_boss_now else selected_wave_number <= highest_wave
	start_selected_button.disabled = not can_start_selection

func update_settings_ui(
	auto_next_wave_toggle: CheckButton,
	auto_start_boss_toggle: CheckButton,
	campaign_state: Dictionary
) -> void:
	if auto_next_wave_toggle:
		auto_next_wave_toggle.set_pressed_no_signal(bool(campaign_state.get("auto_next_wave", true)))
	if auto_start_boss_toggle:
		auto_start_boss_toggle.set_pressed_no_signal(bool(campaign_state.get("auto_start_boss", false)))

func build_campaign_header_text(campaign_state: Dictionary) -> String:
	var chapter_number = int(campaign_state.get("chapter", 1))
	if bool(campaign_state.get("in_boss_fight", false)):
		return "Chapter %d - Boss" % chapter_number
	return "Chapter %d - Wave %d/10" % [chapter_number, int(campaign_state.get("wave", 1))]

func build_campaign_status_text(campaign_state: Dictionary) -> String:
	var status_text = String(campaign_state.get("status_message", ""))
	if not status_text.is_empty():
		return status_text
	if bool(campaign_state.get("in_boss_fight", false)):
		return "Boss timer: %.1fs remaining" % float(campaign_state.get("boss_time_remaining", 0.0))
	if bool(campaign_state.get("boss_unlocked", false)) and not bool(campaign_state.get("auto_start_boss", false)):
		return "Boss unlocked. Start it from Map or keep farming Wave 10."
	if not bool(campaign_state.get("auto_next_wave", true)):
		return "Auto Next Wave is off. Cleared waves repeat until started from Map."
	return ""

func build_map_current_state_text(campaign_state: Dictionary) -> String:
	var current_text = ""
	if bool(campaign_state.get("in_boss_fight", false)):
		current_text = "Current: Boss fight"
	elif bool(campaign_state.get("boss_unlocked", false)):
		current_text = "Current: Wave 10 cleared, boss ready"
	else:
		current_text = "Current: Wave %d/10" % int(campaign_state.get("wave", 1))

	var selected_text = "Selected: Boss" if bool(campaign_state.get("selected_boss", false)) else (
		"Selected: Wave %d" % int(campaign_state.get("selected_wave", 1))
	)
	return "%s | %s" % [current_text, selected_text]

func build_wave_button_text(
	wave_number: int,
	is_unlocked: bool,
	is_current: bool,
	is_selected: bool,
	is_cleared: bool
) -> String:
	var state_label = "Locked"
	if is_current:
		state_label = "Current"
	elif is_selected:
		state_label = "Selected"
	elif is_cleared:
		state_label = "Cleared"
	elif is_unlocked:
		state_label = "Unlocked"
	return "Wave %d\n%s" % [wave_number, state_label]

func build_boss_button_text(is_available: bool, is_current: bool, is_selected: bool) -> String:
	var state_label = "Locked"
	if is_current:
		state_label = "Current"
	elif is_selected:
		state_label = "Selected"
	elif is_available:
		state_label = "Unlocked"
	return "Boss\n%s" % state_label

func _bool_label(value: bool) -> String:
	return "ON" if value else "OFF"
