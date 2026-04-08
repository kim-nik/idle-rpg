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

	_expect(ui != null, "UI controller is unavailable", failures)
	_expect(hero != null, "Hero instance is unavailable for UI assertions", failures)
	if ui == null or hero == null:
		return failures

	ui._update_ui()
	_expect(ui.gold_label.text == "Gold: 0", "Gold label did not show the baseline state", failures)
	_expect(ui.top_wave_label.text == "Wave 1", "Top wave label did not show the baseline wave", failures)
	_expect(ui.wave_label.text == "Monsters: 0/10", "Monster progress label did not show baseline progress", failures)
	_expect(ui.active_tab == ui.TAB_UPGRADES, "Upgrades tab should be active by default", failures)
	_expect(ui.damage_btn.disabled, "Damage button should be disabled without gold", failures)
	_expect(ui.armor_btn.disabled, "Armor button should be disabled without gold", failures)
	_expect(ui.regen_btn.disabled, "Regen button should be disabled without gold", failures)
	_expect(ui.upgrades_scroll.visible, "Upgrades scroll should be visible by default", failures)
	_expect(not ui.abilities_scroll.visible, "Abilities scroll should be hidden by default", failures)
	_expect(not ui.map_scroll.visible, "Map scroll should be hidden by default", failures)
	_expect(ui._is_quick_tap(120, 8.0), "Quick tap heuristic should accept a short tap", failures)
	_expect(not ui._is_quick_tap(250, 8.0), "Quick tap heuristic should reject long holds", failures)
	_expect(not ui._is_quick_tap(120, 30.0), "Quick tap heuristic should reject drags", failures)
	_expect(ui._should_start_scroll(250, 0.0), "Scroll heuristic should accept long holds", failures)
	_expect(ui._should_start_scroll(50, 30.0), "Scroll heuristic should accept drags", failures)

	ui.set_active_tab(ui.TAB_ABILITIES)
	_expect(ui.active_tab == ui.TAB_ABILITIES, "Abilities tab did not become active", failures)
	_expect(not ui.upgrades_scroll.visible, "Upgrades scroll should be hidden on abilities tab", failures)
	_expect(ui.abilities_scroll.visible, "Abilities scroll should be visible on abilities tab", failures)

	ui.set_active_tab(ui.TAB_MAP)
	_expect(ui.active_tab == ui.TAB_MAP, "Map tab did not become active", failures)
	_expect(ui.map_scroll.visible, "Map scroll should be visible on map tab", failures)

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
	_expect(save_manager.save_data.gold == 100, "Debug gold button did not add 100 gold", failures)
	_expect(ui.gold_label.text == "Gold: 100", "Gold label did not refresh after debug gold", failures)
	_expect(not ui.damage_btn.disabled, "Damage button stayed disabled after debug gold", failures)
	ui._add_debug_gold(10)
	ui._update_ui()
	_expect(save_manager.save_data.gold == 1100, "Debug x10 did not add 1000 gold", failures)
	ui._add_debug_gold(100)
	ui._update_ui()
	_expect(save_manager.save_data.gold == 11100, "Debug x100 did not add 10000 gold", failures)

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
	upgrade_system.load_from_save()
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
	_expect(save_manager.save_data.wave == 1, "Reset did not restore wave progress", failures)
	_expect(save_manager.save_data.monsters_killed == 0, "Reset did not clear monster kills", failures)
	_expect(hero.current_hp == hero.max_hp, "Hero health was not restored after reset", failures)
	_expect(ui.gold_label.text == "Gold: 0", "Gold label did not refresh after reset", failures)
	_expect(ui.top_wave_label.text == "Wave 1", "Top wave label did not refresh after reset", failures)
	_expect(ui.wave_label.text == "Monsters: 0/10", "Monster progress label did not refresh after reset", failures)
	_expect(ui.damage_btn.disabled, "Damage button should be disabled again after reset", failures)

	save_manager.save_data.gold = 999
	ui._reset_progress_multiple(10)
	_expect(save_manager.save_data.gold == 0, "Reset x10 did not keep baseline state", failures)

	return failures
