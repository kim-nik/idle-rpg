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
	await _record_test("hero baseline stats", test_hero_baseline_stats())
	await _record_test("upgrade purchase flow", test_upgrade_purchase_flow())
	await _record_test("monster spawn and combat", await test_monster_spawn_and_combat())

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

	return true

func _get_hero() -> Node2D:
	if not is_instance_valid(main_scene):
		return null
	return main_scene.get_node_or_null("CombatArea/Hero")

func _get_wave_manager() -> Node:
	if not is_instance_valid(main_scene):
		return null
	return main_scene.get_node_or_null("WaveManager")
