extends "res://scripts/tests/test_case.gd"

func get_name() -> String:
	return "navigation and menu smoke"

func run(environment) -> Array[String]:
	var failures: Array[String] = []

	environment.reset_progress()
	var main_scene_loaded: bool = await environment.instantiate_main_scene()
	_expect(main_scene_loaded, "Main scene failed to instantiate", failures)
	if not main_scene_loaded:
		return failures

	var ui = environment.get_ui()
	var save_manager = environment.save_manager
	var upgrade_system = environment.upgrade_system

	_expect(ui != null, "UI controller is unavailable", failures)
	if ui == null:
		return failures

	await environment.runner.get_tree().process_frame

	var tab_sequence = [
		{"button": ui.upgrades_tab_button, "tab": ui.TAB_UPGRADES, "scroll": ui.upgrades_scroll},
		{"button": ui.abilities_tab_button, "tab": ui.TAB_ABILITIES, "scroll": ui.abilities_scroll},
		{"button": ui.map_tab_button, "tab": ui.TAB_MAP, "scroll": ui.map_scroll},
		{"button": ui.settings_tab_button, "tab": ui.TAB_SETTINGS, "scroll": ui.settings_scroll},
		{"button": ui.debug_tab_button, "tab": ui.TAB_DEBUG, "scroll": ui.debug_scroll}
	]

	for item in tab_sequence:
		var button = item.button as Button
		var expected_tab = String(item.tab)
		var expected_scroll = item.scroll as ScrollContainer
		_expect(button != null, "Tab button is missing for %s" % expected_tab, failures)
		_expect(expected_scroll != null, "Scroll container is missing for %s" % expected_tab, failures)
		if button == null or expected_scroll == null:
			continue

		button.emit_signal("pressed")
		await environment.runner.get_tree().process_frame
		_expect(ui.active_tab == expected_tab, "Pressing %s tab button did not activate the tab" % expected_tab, failures)
		_expect(expected_scroll.visible, "%s scroll container did not become visible" % expected_tab, failures)

	ui.debug_tab_button.emit_signal("pressed")
	await environment.runner.get_tree().process_frame
	_expect(ui.active_tab == ui.TAB_DEBUG, "Failed to return to debug tab", failures)

	var wave_manager = environment.get_wave_manager()
	if wave_manager:
		wave_manager.highest_unlocked_wave = 2
		wave_manager.current_wave = 1
		wave_manager.selected_wave = 1
		wave_manager._persist_campaign_state("nav_test")

	ui.map_tab_button.emit_signal("pressed")
	await environment.runner.get_tree().process_frame
	await _tap_button(environment, ui.map_wave_buttons[1], 0, Vector2(40, 40))
	_expect(ui.active_tab == ui.TAB_MAP, "Map tab should stay active after selecting a wave", failures)
	_expect(environment.save_manager.save_data.campaign_selected_wave == 2, "Wave 2 selection was not persisted", failures)
	_expect(wave_manager.selected_wave == 2, "Wave 2 tap did not update WaveManager selection", failures)

	if wave_manager:
		environment.save_manager.save_data.setting_auto_start_boss = false
		wave_manager.current_chapter = 1
		wave_manager.current_wave = 4
		wave_manager.highest_unlocked_wave = 4
		wave_manager.selected_wave = 4
		wave_manager.selected_boss = false
		wave_manager.pending_boss_kind = "wave"
		wave_manager.active_boss_kind = ""
		wave_manager.is_boss_unlocked = false
		wave_manager.is_in_boss_fight = false
		wave_manager._persist_campaign_state("nav_boss_touch")
		ui._update_ui()

	await _tap_button(environment, ui.wave_boss_button, 1, Vector2(44, 44))
	await environment.runner.get_tree().process_frame
	_expect(wave_manager.is_in_boss_fight, "Boss banner tap did not enter wave boss fight state", failures)
	var boss_container = environment.get_monster_container()
	_expect(boss_container.get_child_count() == 1, "Boss banner tap did not spawn the boss", failures)

	ui.settings_tab_button.emit_signal("pressed")
	await environment.runner.get_tree().process_frame
	await _tap_button(environment, ui.settings_auto_next_wave_toggle, 3, Vector2(52, 52))
	_expect(
		not environment.save_manager.save_data.setting_auto_next_wave,
		"Auto Next Wave toggle did not persist the new value",
		failures
	)
	await _tap_button(environment, ui.settings_auto_start_boss_toggle, 4, Vector2(56, 56))
	_expect(
		environment.save_manager.save_data.setting_auto_start_boss,
		"Auto Start Boss toggle did not persist the new value",
		failures
	)

	var initial_gold = save_manager.save_data.gold
	var quick_press = InputEventScreenTouch.new()
	quick_press.index = 0
	quick_press.pressed = true
	quick_press.position = Vector2(40, 40)
	ui.debug_gold_btn.emit_signal("gui_input", quick_press)
	var quick_release = InputEventScreenTouch.new()
	quick_release.index = 0
	quick_release.pressed = false
	quick_release.position = Vector2(40, 40)
	ui.debug_gold_btn.emit_signal("gui_input", quick_release)
	await environment.runner.get_tree().process_frame
	_expect(save_manager.save_data.gold == initial_gold + 100000, "Debug gold button press did not update gold", failures)
	ui.simulate_afk_btn.emit_signal("gui_input", quick_press)
	ui.simulate_afk_btn.emit_signal("gui_input", quick_release)
	await environment.runner.get_tree().process_frame
	_expect(save_manager.save_data.pending_afk_seconds == 3600, "Debug AFK button did not queue one hour", failures)
	_expect(ui.afk_popup_overlay_root.visible, "Debug AFK button did not open AFK rewards popup", failures)
	ui._on_collect_afk_rewards_pressed()

	var damage_level_before = upgrade_system.damage_level
	var damage_press = InputEventScreenTouch.new()
	damage_press.index = 1
	damage_press.pressed = true
	damage_press.position = Vector2(48, 48)
	ui.damage_btn.emit_signal("gui_input", damage_press)
	var damage_release = InputEventScreenTouch.new()
	damage_release.index = 1
	damage_release.pressed = false
	damage_release.position = Vector2(48, 48)
	ui.damage_btn.emit_signal("gui_input", damage_release)
	await environment.runner.get_tree().process_frame
	_expect(upgrade_system.damage_level >= damage_level_before, "Damage button press caused an invalid state", failures)

	var reset_press = InputEventScreenTouch.new()
	reset_press.index = 2
	reset_press.pressed = true
	reset_press.position = Vector2(50, 50)
	ui.reset_progress_btn.emit_signal("gui_input", reset_press)
	var reset_release = InputEventScreenTouch.new()
	reset_release.index = 2
	reset_release.pressed = false
	reset_release.position = Vector2(50, 50)
	ui.reset_progress_btn.emit_signal("gui_input", reset_release)
	await environment.runner.get_tree().process_frame
	_expect(save_manager.save_data.gold == 0, "Reset progress button press did not restore baseline gold", failures)
	_expect(upgrade_system.damage_level == 1, "Reset progress button press did not restore baseline damage level", failures)

	if ui.upgrades_scroll:
		ui.upgrades_scroll.scroll_vertical = 0
		var scroll_press = InputEventScreenTouch.new()
		scroll_press.index = 3
		scroll_press.pressed = true
		scroll_press.position = Vector2(60, 60)
		ui.damage_btn.emit_signal("gui_input", scroll_press)
		var scroll_drag = InputEventScreenDrag.new()
		scroll_drag.index = 3
		scroll_drag.position = Vector2(60, 10)
		scroll_drag.relative = Vector2(0, -50)
		ui.damage_btn.emit_signal("gui_input", scroll_drag)
		var scroll_release = InputEventScreenTouch.new()
		scroll_release.index = 3
		scroll_release.pressed = false
		scroll_release.position = Vector2(60, 10)
		ui.damage_btn.emit_signal("gui_input", scroll_release)
		await environment.runner.get_tree().process_frame
		_expect(ui.upgrades_scroll.scroll_vertical > 0, "Drag on an upgrade button did not begin scrolling", failures)

	return failures

func _tap_button(environment, button: Button, pointer_index: int, position: Vector2) -> void:
	var press = InputEventScreenTouch.new()
	press.index = pointer_index
	press.pressed = true
	press.position = position
	button.emit_signal("gui_input", press)

	var release = InputEventScreenTouch.new()
	release.index = pointer_index
	release.pressed = false
	release.position = position
	button.emit_signal("gui_input", release)
	await environment.runner.get_tree().process_frame
