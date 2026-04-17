extends "res://scripts/tests/test_case.gd"

func get_name() -> String:
	return "ui and debug actions"

func run(environment) -> Array[String]:
	var failures: Array[String] = []

	environment.reset_progress()
	var main_scene_loaded: bool = await environment.instantiate_main_scene()
	_expect(main_scene_loaded, "Main scene failed to instantiate", failures)
	if not main_scene_loaded:
		return failures

	environment.stabilize_main_scene()

	var ui = environment.get_ui()
	var hero = environment.get_hero()
	var save_manager = environment.save_manager
	var upgrade_system = environment.upgrade_system
	var ability_system = environment.ability_system
	var wave_manager = environment.get_wave_manager()

	_expect(ui != null, "UI controller is unavailable", failures)
	_expect(hero != null, "Hero instance is unavailable for UI assertions", failures)
	_expect(wave_manager != null, "WaveManager is unavailable for UI assertions", failures)
	if ui == null or hero == null or wave_manager == null:
		return failures

	ui._update_ui()
	_expect(ui.gold_label.text == "Gold: 0", "Gold label did not show the baseline state", failures)
	_expect(ui.top_wave_label.text == "Chapter 1 - Wave 1/10", "Top wave label did not show the baseline wave", failures)
	_expect(ui.wave_label.text == "Defeated 0/20", "Monster progress label did not show baseline progress", failures)
	_expect(ui.active_tab == ui.TAB_UPGRADES, "Upgrades tab should be active by default", failures)
	_expect(ui.damage_btn.disabled, "Damage button should be disabled without gold", failures)
	_expect(ui.armor_btn.disabled, "Armor button should be disabled without gold", failures)
	_expect(ui.regen_btn.disabled, "Regen button should be disabled without gold", failures)
	_expect(ui.upgrades_scroll.visible, "Upgrades scroll should be visible by default", failures)
	_expect(not ui.abilities_scroll.visible, "Abilities scroll should be hidden by default", failures)
	_expect(not ui.map_scroll.visible, "Map scroll should be hidden by default", failures)
	_expect(not ui.settings_scroll.visible, "Settings scroll should be hidden by default", failures)
	_expect(ui._is_quick_tap(120, 8.0), "Quick tap heuristic should accept a short tap", failures)
	_expect(not ui._is_quick_tap(250, 8.0), "Quick tap heuristic should reject long holds", failures)
	_expect(not ui._is_quick_tap(120, 30.0), "Quick tap heuristic should reject drags", failures)
	_expect(ui._should_start_scroll(250, 0.0), "Scroll heuristic should accept long holds", failures)
	_expect(ui._should_start_scroll(50, 30.0), "Scroll heuristic should accept drags", failures)

	ui.set_active_tab(ui.TAB_ABILITIES)
	_expect(ui.active_tab == ui.TAB_ABILITIES, "Abilities tab did not become active", failures)
	_expect(not ui.upgrades_scroll.visible, "Upgrades scroll should be hidden on abilities tab", failures)
	_expect(ui.abilities_scroll.visible, "Abilities scroll should be visible on abilities tab", failures)
	_expect(ui.ability_slot_buttons.size() == 8, "Abilities tab should expose 8 loadout slots", failures)
	_expect(ui.ability_slot_buttons[0].get_display_name() == "Empty", "Empty active slot should show placeholder text", failures)
	_expect(ui.ability_library_buttons.has("punch"), "Ability library should contain Punch", failures)
	_expect(ui.ability_library_buttons["punch"].get_display_name() == "Punch", "Punch tile should show the ability name", failures)

	ui.on_ability_tile_pressed(ui.ability_library_buttons["punch"])
	_expect(ui.ability_popup_overlay.visible, "Ability popup should open from library tile tap", failures)
	_expect(ui.ability_popup_action_button.text == "Add", "Library popup action should add the ability", failures)
	ui._on_popup_ability_action_pressed()
	_expect(ability_system.get_ability_slot(0) == "punch", "Equipping Punch from UI failed", failures)

	ui.on_ability_tile_pressed(ui.ability_library_buttons["leg_sweep"])
	ui._on_popup_ability_action_pressed()
	_expect(ability_system.get_ability_slot(1) == "leg_sweep", "Equipping Leg Sweep from UI failed", failures)

	ui.on_ability_tile_pressed(ui.ability_library_buttons["evil_eye"])
	ui._on_popup_ability_action_pressed()
	_expect(ability_system.get_ability_slot(2) == "evil_eye", "Equipping Evil Eye from UI failed", failures)

	ui.on_ability_tile_pressed(ui.ability_slot_buttons[2])
	_expect(ui.ability_popup_action_button.text == "Remove", "Active slot popup action should remove the ability", failures)
	ui._on_popup_ability_action_pressed()
	_expect(ability_system.get_ability_slot(2).is_empty(), "Removing an equipped ability from UI failed", failures)

	ui.drop_ability_tile(ui.ability_slot_buttons[3], {"ability_id": "evil_eye", "source_role": "library", "source_slot_index": -1})
	_expect(ability_system.get_ability_slot(3) == "evil_eye", "Dragging Evil Eye to active slot failed", failures)

	ui.set_active_tab(ui.TAB_MAP)
	_expect(ui.active_tab == ui.TAB_MAP, "Map tab did not become active", failures)
	_expect(ui.map_scroll.visible, "Map scroll should be visible on map tab", failures)
	_expect(ui.map_wave_buttons.size() == 10, "Map tab should expose 10 wave buttons", failures)
	_expect(not ui.map_wave_buttons[0].disabled, "Wave 1 should be unlocked by default", failures)
	_expect(ui.map_wave_buttons[1].disabled, "Wave 2 should stay locked by default", failures)
	_expect(ui.map_start_selected_button != null and not ui.map_start_selected_button.disabled, "Start button should be ready for Wave 1", failures)
	_expect(ui.map_boss_button.disabled, "Boss button should be locked at the start", failures)

	wave_manager.highest_unlocked_wave = 3
	wave_manager.current_wave = 2
	wave_manager.selected_wave = 2
	wave_manager._persist_campaign_state("ui_unlock")
	ui._update_ui()
	ui._on_map_wave_pressed(3)
	_expect(wave_manager.selected_wave == 3, "Map wave selection did not update WaveManager", failures)
	_expect(ui.map_wave_buttons[2].button_pressed, "Wave 3 button did not become selected", failures)

	wave_manager.is_boss_unlocked = true
	wave_manager.select_boss()
	ui._update_ui()
	_expect(not ui.map_boss_button.disabled, "Boss button should unlock after boss access is granted", failures)
	_expect(ui.map_boss_button.button_pressed, "Boss button should become selected", failures)
	ui._on_map_start_selected_pressed()
	_expect(wave_manager.is_in_boss_fight, "Starting the selected boss did not enter boss fight state", failures)
	ui._update_ui()
	_expect(ui.top_wave_label.text == "Chapter 1 - Boss", "Top wave label did not switch to boss state", failures)
	_expect(ui.wave_label.text == "Boss Fight", "Boss fight should replace the kill counter with a boss indicator", failures)
	_expect(
		ui.campaign_status_label.text.begins_with("Boss timer: 30.0s"),
		"Boss fight should expose the 30 second timer in the UI",
		failures
	)
	var boss_container = environment.get_monster_container()
	_expect(boss_container.get_child_count() == 1, "Boss fight should spawn the boss immediately", failures)
	if boss_container.get_child_count() == 1:
		var boss = boss_container.get_child(0)
		_expect(boss.monster_type == "boss", "Boss fight did not spawn the dedicated boss monster", failures)

	ui.set_active_tab(ui.TAB_SETTINGS)
	_expect(ui.active_tab == ui.TAB_SETTINGS, "Settings tab did not become active", failures)
	_expect(ui.settings_scroll.visible, "Settings scroll should be visible on settings tab", failures)
	ui._on_auto_next_wave_toggled(false)
	ui._on_auto_start_boss_toggled(true)
	_expect(not save_manager.save_data.setting_auto_next_wave, "Auto Next Wave setting did not persist from UI", failures)
	_expect(save_manager.save_data.setting_auto_start_boss, "Auto Start Boss setting did not persist from UI", failures)

	ui.set_active_tab(ui.TAB_UPGRADES)

	if environment.main_scene.has_method("capture_debug_screenshot"):
		var screenshot_path = await environment.main_scene.capture_debug_screenshot("smoke_test.png")
		_expect(not screenshot_path.is_empty(), "Screenshot path was empty", failures)
		if not screenshot_path.is_empty():
			_expect(FileAccess.file_exists(screenshot_path), "Screenshot file was not created", failures)
	else:
		failures.append("Main scene does not expose debug screenshot capture")

	ui._on_debug_gold_clicked()
	ui._update_ui()
	_expect(save_manager.save_data.gold == 100000, "Debug gold button did not add 100000 gold", failures)
	_expect(ui.gold_label.text == "Gold: 100000", "Gold label did not refresh after debug gold", failures)
	_expect(not ui.damage_btn.disabled, "Damage button stayed disabled after debug gold", failures)
	ui._add_debug_gold(10)
	ui._update_ui()
	_expect(save_manager.save_data.gold == 1100000, "Debug x10 did not add 1000000 gold", failures)
	ui._add_debug_gold(100)
	ui._update_ui()
	_expect(save_manager.save_data.gold == 11100000, "Debug x100 did not add 10000000 gold", failures)

	save_manager.save_data.gold = 1000
	upgrade_system.load_from_save()
	ui._purchase_upgrade_multiple("damage", 10)
	_expect(upgrade_system.damage_level > 1, "Damage x10 did not purchase upgrades", failures)
	_expect(save_manager.save_data.gold < 1000, "Damage x10 did not spend gold", failures)

	save_manager.save_data.gold = 1000
	upgrade_system.load_from_save()
	ui._purchase_upgrade("armor")
	ui._purchase_upgrade("health_regen")
	_expect(upgrade_system.armor_level > 1, "Armor purchase did not increase armor level", failures)
	_expect(upgrade_system.health_regen_level > 1, "Regen purchase did not increase regen level", failures)

	save_manager.save_data.gold = 345
	save_manager.save_data.damage_level = 4
	save_manager.save_data.attack_speed_level = 3
	save_manager.save_data.max_hp_level = 5
	save_manager.save_data.armor_level = 4
	save_manager.save_data.health_regen_level = 3
	save_manager.save_data.crit_chance_level = 2
	save_manager.save_data.crit_damage_level = 6
	save_manager.save_data.wave = 8
	save_manager.save_data.monsters_killed = 7
	save_manager.save_data.campaign_chapter = 3
	save_manager.save_data.campaign_wave = 8
	save_manager.save_data.campaign_highest_unlocked_wave = 8
	save_manager.save_data.campaign_highest_cleared_chapter = 2
	save_manager.save_data.campaign_boss_unlocked = true
	save_manager.save_data.campaign_selected_wave = 8
	save_manager.save_data.campaign_selected_boss = false
	save_manager.save_data.setting_auto_next_wave = false
	save_manager.save_data.setting_auto_start_boss = true
	save_manager.save_data.unlocked_ability_ids = ["evil_eye", "leg_sweep", "punch"]
	save_manager.save_data.equipped_ability_slots = ["punch", "leg_sweep", "evil_eye", "", "", "", "", ""]
	upgrade_system.load_from_save()
	ability_system.load_from_save()
	wave_manager.restart_from_save()
	hero.current_hp = 1

	ui._on_reset_progress_clicked()
	ui._update_ui()

	_expect(save_manager.save_data.gold == 0, "Reset did not clear gold", failures)
	_expect(save_manager.save_data.damage_level == 1, "Reset did not restore damage level", failures)
	_expect(save_manager.save_data.attack_speed_level == 1, "Reset did not restore attack speed level", failures)
	_expect(save_manager.save_data.max_hp_level == 1, "Reset did not restore max HP level", failures)
	_expect(save_manager.save_data.armor_level == 1, "Reset did not restore armor level", failures)
	_expect(save_manager.save_data.health_regen_level == 1, "Reset did not restore regen level", failures)
	_expect(save_manager.save_data.crit_chance_level == 1, "Reset did not restore crit chance level", failures)
	_expect(save_manager.save_data.crit_damage_level == 1, "Reset did not restore crit damage level", failures)
	_expect(save_manager.save_data.wave == 1, "Reset did not restore wave alias", failures)
	_expect(save_manager.save_data.monsters_killed == 0, "Reset did not clear monster kills", failures)
	_expect(save_manager.save_data.campaign_chapter == 1, "Reset did not restore campaign chapter", failures)
	_expect(save_manager.save_data.campaign_wave == 1, "Reset did not restore campaign wave", failures)
	_expect(
		save_manager.save_data.campaign_highest_unlocked_wave == 1,
		"Reset did not restore highest unlocked wave",
		failures
	)
	_expect(
		save_manager.save_data.campaign_highest_cleared_chapter == 0,
		"Reset did not restore cleared chapter marker",
		failures
	)
	_expect(not save_manager.save_data.campaign_boss_unlocked, "Reset did not clear boss unlock state", failures)
	_expect(save_manager.save_data.campaign_selected_wave == 1, "Reset did not restore selected wave", failures)
	_expect(not save_manager.save_data.campaign_selected_boss, "Reset did not clear selected boss state", failures)
	_expect(save_manager.save_data.setting_auto_next_wave, "Reset did not restore Auto Next Wave default", failures)
	_expect(not save_manager.save_data.setting_auto_start_boss, "Reset did not restore Auto Start Boss default", failures)
	_expect(
		save_manager.save_data.unlocked_ability_ids == ["evil_eye", "leg_sweep", "punch"],
		"Reset did not restore starter abilities",
		failures
	)
	_expect(
		save_manager.save_data.equipped_ability_slots == ["", "", "", "", "", "", "", ""],
		"Reset did not clear equipped ability slots",
		failures
	)
	_expect(hero.current_hp == hero.max_hp, "Hero health was not restored after reset", failures)
	_expect(ui.gold_label.text == "Gold: 0", "Gold label did not refresh after reset", failures)
	_expect(ui.top_wave_label.text == "Chapter 1 - Wave 1/10", "Top wave label did not refresh after reset", failures)
	_expect(ui.wave_label.text == "Defeated 0/20", "Monster progress label did not refresh after reset", failures)
	_expect(ui.damage_btn.disabled, "Damage button should be disabled again after reset", failures)
	_expect(wave_manager.current_chapter == 1, "WaveManager chapter did not reset", failures)
	_expect(wave_manager.current_wave == 1, "WaveManager wave did not reset", failures)

	save_manager.save_data.gold = 999
	ui._reset_progress_multiple(10)
	_expect(save_manager.save_data.gold == 0, "Reset x10 did not keep baseline state", failures)

	return failures
