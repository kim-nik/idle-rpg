extends Node

var tests_passed: int = 0
var tests_failed: int = 0

var main_scene: Node
var save_manager: Node
var upgrade_system: Node

func _ready() -> void:
	await run_smoke_test()

func run_smoke_test() -> void:
	print("=== SMOKE TEST STARTED ===")
	save_manager = get_node_or_null("/root/SaveManager")
	upgrade_system = get_node_or_null("/root/UpgradeSystem")

	var original_save_data: Dictionary = {}
	if save_manager:
		original_save_data = save_manager.save_data.duplicate(true)

	await _record_test("autoloads", test_autoloads())

	if save_manager and upgrade_system:
		save_manager.reset()
		upgrade_system.load_from_save()

	await _record_test("main scene bootstrap", await test_main_scene_bootstrap())
	await _record_test("screen layout", test_screen_layout())
	await _record_test("hero baseline stats", test_hero_baseline_stats())
	await _record_test("debug screenshot", await test_debug_screenshot())
	await _record_test("debug gold button", test_debug_gold_button())
	await _record_test("reset progress button", test_reset_progress_button())
	await _record_test("upgrade purchase flow", test_upgrade_purchase_flow())
	await _record_test("save roundtrip", test_save_roundtrip())
	await _record_test("monster spawn and combat", await test_monster_spawn_and_combat())
	await _record_test("wave completion persistence", test_wave_completion_persistence())

	if save_manager:
		save_manager.save_data = original_save_data
		save_manager.save()
	if upgrade_system:
		upgrade_system.load_from_save()

	if is_instance_valid(main_scene):
		main_scene.queue_free()
		await get_tree().process_frame

	print("=== SMOKE TEST RESULTS ===")
	print("Passed: %d | Failed: %d" % [tests_passed, tests_failed])

	if tests_failed > 0:
		push_error("Smoke test FAILED")
		get_tree().quit(1)
	else:
		print("Smoke test PASSED")
		get_tree().quit(0)

func _record_test(name: String, passed: bool) -> void:
	if passed:
		tests_passed += 1
		print("  %s: OK" % name)
	else:
		tests_failed += 1
		push_error("%s: FAILED" % name)
	await get_tree().process_frame

func test_autoloads() -> bool:
	return save_manager != null and upgrade_system != null

func test_main_scene_bootstrap() -> bool:
	var main_scene_resource := load("res://scenes/Main.tscn") as PackedScene
	if main_scene_resource == null:
		push_error("Main scene resource failed to load")
		return false

	main_scene = main_scene_resource.instantiate()
	main_scene.name = "MainUnderTest"
	add_child(main_scene)
	await get_tree().process_frame

	var hero = main_scene.get_node_or_null("CombatArea/Hero")
	var wave_manager = main_scene.get_node_or_null("WaveManager")
	var ui_area = main_scene.get_node_or_null("UIArea")

	if hero == null:
		push_error("Hero node not found in Main scene")
		return false
	if wave_manager == null:
		push_error("WaveManager node not found in Main scene")
		return false
	if ui_area == null:
		push_error("UIArea node not found in Main scene")
		return false

	main_scene.set_process(false)
	wave_manager.set_process(false)
	ui_area.set_process(false)
	return true

func test_hero_baseline_stats() -> bool:
	var hero = _get_hero()
	if hero == null:
		push_error("Hero instance is unavailable")
		return false

	hero.update_stats()

	if hero.max_hp != upgrade_system.get_max_hp():
		push_error("Hero max HP does not match upgrade system")
		return false
	if hero.base_damage != upgrade_system.get_damage():
		push_error("Hero damage does not match upgrade system")
		return false
	if hero.attack_speed != upgrade_system.get_attack_speed():
		push_error("Hero attack speed does not match upgrade system")
		return false
	if hero.current_hp <= 0:
		push_error("Hero current HP is invalid")
		return false

	return true

func test_screen_layout() -> bool:
	var combat_background = main_scene.get_node_or_null("ArenaBackground") as ColorRect
	var divider = main_scene.get_node_or_null("ArenaDivider") as ColorRect
	var panel = main_scene.get_node_or_null("UIArea/Panel") as Panel
	var viewport_width = int(ProjectSettings.get_setting("display/window/size/viewport_width", 0))
	var viewport_height = int(ProjectSettings.get_setting("display/window/size/viewport_height", 0))
	var orientation = int(ProjectSettings.get_setting("display/window/handheld/orientation", -1))

	if viewport_width != 1080 or viewport_height != 1920:
		push_error("Project resolution is %dx%d instead of 1080x1920" % [viewport_width, viewport_height])
		return false
	if orientation != 1:
		push_error("Handheld orientation is %d instead of portrait" % orientation)
		return false
	if combat_background == null or divider == null or panel == null:
		push_error("Main layout nodes are missing")
		return false
	if not is_equal_approx(combat_background.size.y, 960.0):
		push_error("Combat area is not half-screen height")
		return false
	if not is_equal_approx(divider.position.y, 960.0):
		push_error("Arena divider is not centered vertically")
		return false
	if not is_equal_approx(panel.position.y, 960.0):
		push_error("UI panel does not start at half-screen")
		return false
	if not is_equal_approx(panel.size.y, 960.0):
		push_error("UI panel does not fill the bottom half")
		return false

	var upgrade_container = main_scene.get_node_or_null("UIArea/Panel/MarginContainer/Content/UpgradeContainer") as VBoxContainer
	var debug_button = main_scene.get_node_or_null("UIArea/Panel/MarginContainer/Content/UpgradeContainer/DebugGoldButton") as Button
	var reset_button = main_scene.get_node_or_null("UIArea/Panel/MarginContainer/Content/UpgradeContainer/ResetProgressButton") as Button
	if upgrade_container == null or debug_button == null or reset_button == null:
		push_error("Upgrade stack or utility buttons are missing")
		return false
	if debug_button.get_parent() != upgrade_container:
		push_error("Debug button is not inside the upgrade stack")
		return false
	if reset_button.get_parent() != upgrade_container:
		push_error("Reset button is not inside the upgrade stack")
		return false

	for child in upgrade_container.get_children():
		var button = child as Button
		if button and button.size_flags_horizontal != Control.SIZE_EXPAND_FILL:
			push_error("Upgrade button does not fill available width")
			return false

	return true

func test_debug_screenshot() -> bool:
	if main_scene == null or not main_scene.has_method("capture_debug_screenshot"):
		push_error("Main scene does not expose debug screenshot capture")
		return false

	var screenshot_path = await main_scene.capture_debug_screenshot("smoke_test.png")
	if screenshot_path.is_empty():
		push_error("Screenshot path was empty")
		return false
	if not FileAccess.file_exists(screenshot_path):
		push_error("Screenshot file was not created: %s" % screenshot_path)
		return false

	return true

func test_debug_gold_button() -> bool:
	var ui = main_scene.get_node_or_null("UIArea")
	if ui == null or not ui.has_method("_on_debug_gold_clicked"):
		push_error("UI debug gold action is unavailable")
		return false

	save_manager.save_data.gold = 0
	ui._on_debug_gold_clicked()

	if save_manager.save_data.gold != 100:
		push_error("Debug gold button did not add 100 gold")
		return false

	return true

func test_reset_progress_button() -> bool:
	var ui = main_scene.get_node_or_null("UIArea")
	var hero = _get_hero()
	if ui == null or not ui.has_method("_on_reset_progress_clicked") or hero == null:
		push_error("UI reset progress action is unavailable")
		return false

	save_manager.save_data.gold = 345
	save_manager.save_data.damage_level = 4
	save_manager.save_data.attack_speed_level = 3
	save_manager.save_data.max_hp_level = 5
	save_manager.save_data.crit_chance_level = 2
	save_manager.save_data.crit_damage_level = 6
	save_manager.save_data.wave = 8
	save_manager.save_data.monsters_killed = 7
	upgrade_system.load_from_save()
	hero.current_hp = 1

	ui._on_reset_progress_clicked()

	if save_manager.save_data.gold != 0:
		push_error("Reset did not clear gold")
		return false
	if save_manager.save_data.damage_level != 1 or save_manager.save_data.attack_speed_level != 1:
		push_error("Reset did not restore upgrade levels")
		return false
	if save_manager.save_data.max_hp_level != 1 or save_manager.save_data.crit_chance_level != 1 or save_manager.save_data.crit_damage_level != 1:
		push_error("Reset did not restore all progression levels")
		return false
	if save_manager.save_data.wave != 1 or save_manager.save_data.monsters_killed != 0:
		push_error("Reset did not restore wave progress")
		return false
	if upgrade_system.damage_level != 1 or upgrade_system.max_hp_level != 1:
		push_error("Upgrade system was not refreshed after reset")
		return false
	if hero.current_hp != hero.max_hp:
		push_error("Hero health was not restored after reset")
		return false

	return true

func test_upgrade_purchase_flow() -> bool:
	var hero = _get_hero()
	if hero == null:
		push_error("Hero instance is unavailable")
		return false

	save_manager.save_data.gold = 100
	var previous_damage = upgrade_system.get_damage()
	var previous_gold = save_manager.save_data.gold

	if not upgrade_system.purchase_upgrade("damage"):
		push_error("Damage upgrade purchase failed")
		return false

	hero.update_stats()

	if upgrade_system.damage_level != 2:
		push_error("Damage level did not increase")
		return false
	if save_manager.save_data.gold >= previous_gold:
		push_error("Gold was not spent on upgrade")
		return false
	if hero.base_damage <= previous_damage:
		push_error("Hero damage did not increase after upgrade")
		return false

	return true

func test_monster_spawn_and_combat() -> bool:
	var hero = _get_hero()
	var wave_manager = _get_wave_manager()
	var monster_container = main_scene.get_node_or_null("CombatArea/Monsters")

	if hero == null or wave_manager == null or monster_container == null:
		push_error("Combat graph is incomplete")
		return false

	for child in monster_container.get_children():
		child.queue_free()
	await get_tree().process_frame

	save_manager.save_data.gold = 0
	save_manager.save_data.monsters_killed = 0
	wave_manager.monsters_in_wave = 0
	wave_manager.monsters_killed = 0
	wave_manager.is_wave_active = true
	wave_manager.is_between_waves = false

	wave_manager.spawn_monster()
	await get_tree().process_frame

	if monster_container.get_child_count() != 1:
		push_error("WaveManager did not spawn exactly one monster")
		return false

	var monster = monster_container.get_child(0)
	monster.position = hero.position + Vector2(120.0, 0.0)
	hero.base_damage = monster.current_hp + 10.0
	main_scene._attack_nearest_monster()
	await get_tree().process_frame

	if not monster.is_dead:
		push_error("Monster did not die after lethal damage")
		return false
	if save_manager.save_data.gold != monster.gold_reward:
		push_error("Gold reward was not granted")
		return false
	if save_manager.save_data.monsters_killed != 1:
		push_error("Monster kill was not persisted")
		return false
	if not is_equal_approx(monster.position.y, hero.position.y):
		push_error("Monster did not stay on the hero's horizontal line")
		return false

	return true

func test_save_roundtrip() -> bool:
	save_manager.save_data = {
		"gold": 77,
		"damage_level": 3,
		"attack_speed_level": 2,
		"max_hp_level": 4,
		"crit_chance_level": 2,
		"crit_damage_level": 3,
		"wave": 6,
		"monsters_killed": 9
	}
	save_manager.save()

	save_manager.save_data.gold = 0
	save_manager.save_data.wave = 1
	save_manager.load_game()
	upgrade_system.load_from_save()

	if save_manager.save_data.gold != 77:
		push_error("Gold did not survive save/load roundtrip")
		return false
	if save_manager.save_data.wave != 6:
		push_error("Wave did not survive save/load roundtrip")
		return false
	if upgrade_system.damage_level != 3:
		push_error("Upgrade levels were not reloaded from save")
		return false
	if upgrade_system.max_hp_level != 4:
		push_error("Max HP level was not reloaded from save")
		return false

	return true

func test_wave_completion_persistence() -> bool:
	var wave_manager = _get_wave_manager()
	if wave_manager == null:
		push_error("WaveManager instance is unavailable")
		return false

	save_manager.reset()
	upgrade_system.load_from_save()
	wave_manager.load_wave_from_save()
	wave_manager.start_next_wave()

	save_manager.save_data.wave = 1
	save_manager.save_data.monsters_killed = 9
	wave_manager.current_wave = 1
	wave_manager.monsters_killed = 9
	wave_manager.monsters_in_wave = 1
	wave_manager.is_wave_active = true
	wave_manager.is_between_waves = false

	wave_manager._on_monster_died(5)
	upgrade_system.load_from_save()

	if wave_manager.current_wave != 2:
		push_error("Current wave did not advance after completion")
		return false
	if save_manager.save_data.wave != 2:
		push_error("Completed wave was not persisted")
		return false
	if not wave_manager.is_between_waves:
		push_error("Wave manager did not enter intermission state")
		return false
	if save_manager.save_data.gold != 5:
		push_error("Wave completion reward was not saved")
		return false
	if save_manager.save_data.monsters_killed != 10:
		push_error("Monster kill counter did not reach the wave total")
		return false

	return true

func _get_hero() -> Node2D:
	if not is_instance_valid(main_scene):
		return null
	return main_scene.get_node_or_null("CombatArea/Hero")

func _get_wave_manager() -> Node:
	if not is_instance_valid(main_scene):
		return null
	return main_scene.get_node_or_null("WaveManager")
