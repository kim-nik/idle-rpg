extends "res://scripts/tests/test_case.gd"

func get_name() -> String:
	return "combat and wave flow"

func run(environment) -> Array[String]:
	var failures: Array[String] = []

	environment.reset_progress()
	var main_scene_loaded: bool = await environment.instantiate_main_scene()
	_expect(main_scene_loaded, "Main scene failed to instantiate", failures)
	if not main_scene_loaded:
		return failures

	environment.stabilize_main_scene()
	await environment.clear_monsters()

	var hero = environment.get_hero()
	var wave_manager = environment.get_wave_manager()
	var monster_container = environment.get_monster_container()
	var save_manager = environment.save_manager

	_expect(hero != null, "Hero instance is unavailable", failures)
	_expect(wave_manager != null, "WaveManager instance is unavailable", failures)
	_expect(monster_container != null, "Monster container is unavailable", failures)
	if hero == null or wave_manager == null or monster_container == null:
		return failures

	_expect(wave_manager.get_monster_type_for_wave(1) == "slime", "Wave 1 must spawn slimes", failures)
	_expect(wave_manager.get_monster_type_for_wave(4) == "goblin", "Wave 4 must spawn goblins", failures)
	_expect(wave_manager.get_monster_type_for_wave(7) == "orc", "Wave 7 must spawn orcs", failures)
	_expect(wave_manager.get_monster_type_for_wave(10) == "demon", "Wave 10 must spawn demons", failures)
	_expect(wave_manager.total_monsters_in_wave == wave_manager.ENEMIES_PER_WAVE, "Regular wave size must stay at 20", failures)
	_expect(wave_manager.MAX_ACTIVE_MONSTERS == 10, "Active monster cap must stay at 10", failures)

	wave_manager.restart_from_save()
	wave_manager.spawn_interval = 0.0
	for _i in range(15):
		wave_manager._process(wave_manager.spawn_interval)
	await environment.runner.get_tree().process_frame
	_expect(monster_container.get_child_count() == 10, "WaveManager should not exceed 10 active monsters", failures)
	await environment.clear_monsters()
	wave_manager.restart_from_save()
	wave_manager._spawn_regular_monster()
	await environment.runner.get_tree().process_frame

	_expect(monster_container.get_child_count() == 1, "WaveManager did not spawn exactly one monster", failures)
	if monster_container.get_child_count() != 1:
		return failures

	var monster = monster_container.get_child(0)
	monster.set_process(false)
	monster.position = hero.position + Vector2(180.0, 64.0)
	monster._process(0.1)
	_expect(
		is_equal_approx(monster.position.y, hero.position.y),
		"Monster did not align to the hero lane during movement",
		failures
	)

	var hero_hp_before = hero.current_hp
	monster.attack_hero(hero)
	await environment.runner.get_tree().create_timer(0.25).timeout
	_expect(hero.current_hp < hero_hp_before, "Monster attack did not damage the hero", failures)

	var second_monster_scene = load("res://scenes/Monster.tscn") as PackedScene
	var second_monster = second_monster_scene.instantiate()
	monster_container.add_child(second_monster)
	second_monster.setup("slime", 1.0)
	second_monster.position = hero.position + Vector2(260.0, 0.0)
	monster.position = hero.position + Vector2(monster.attack_range, 0.0)
	monster.set_process(true)
	second_monster.set_process(true)
	monster._process(0.1)
	second_monster._process(0.1)
	_expect(
		second_monster.global_position.x >= monster.global_position.x + monster.QUEUE_SPACING - 2.0,
		"Second monster did not queue behind the front monster",
		failures
	)
	second_monster.queue_free()
	await environment.runner.get_tree().process_frame
	monster.set_process(false)

	hero.base_damage = monster.current_hp + 10.0
	hero.attack_timer = hero.get_attack_interval()
	environment.main_scene._attack_nearest_monster()
	await environment.runner.get_tree().create_timer(0.25).timeout

	_expect(monster.is_dead, "Monster did not die after lethal damage", failures)
	_expect(save_manager.save_data.gold == monster.gold_reward, "Gold reward was not granted on kill", failures)
	_expect(save_manager.save_data.monsters_killed == 1, "Monster kill was not persisted", failures)

	wave_manager.current_wave = 1
	wave_manager.current_chapter = 1
	wave_manager.highest_unlocked_wave = 1
	wave_manager.selected_wave = 1
	wave_manager.selected_boss = false
	wave_manager.is_in_boss_fight = false
	wave_manager.is_boss_unlocked = false
	wave_manager.monsters_killed = 19
	wave_manager.monsters_in_wave = 1
	wave_manager.total_monsters_in_wave = wave_manager.ENEMIES_PER_WAVE
	wave_manager.enemies_spawned_in_wave = wave_manager.ENEMIES_PER_WAVE
	wave_manager.is_wave_active = true
	wave_manager.is_between_waves = false
	save_manager.save_data.setting_auto_next_wave = true

	wave_manager._on_regular_monster_died(5)
	environment.upgrade_system.load_from_save()

	_expect(wave_manager.current_wave == 2, "Current wave did not advance after completion", failures)
	_expect(wave_manager.highest_unlocked_wave == 2, "Highest unlocked wave did not advance after completion", failures)
	_expect(save_manager.save_data.wave == 2, "Completed wave alias was not persisted", failures)
	_expect(save_manager.save_data.campaign_wave == 2, "Completed campaign wave was not persisted", failures)
	_expect(wave_manager.is_between_waves, "Wave manager did not enter intermission state", failures)
	_expect(save_manager.save_data.gold == 5, "Wave completion reward was not saved", failures)
	_expect(save_manager.save_data.monsters_killed == 20, "Monster kill counter did not reach the wave total", failures)

	save_manager.reset()
	environment.upgrade_system.load_from_save()
	wave_manager.restart_from_save()
	save_manager.save_data.setting_auto_next_wave = false
	wave_manager.current_wave = 4
	wave_manager.current_chapter = 1
	wave_manager.highest_unlocked_wave = 4
	wave_manager.selected_wave = 4
	wave_manager.selected_boss = false
	wave_manager.is_in_boss_fight = false
	wave_manager.is_boss_unlocked = false
	wave_manager.monsters_killed = 19
	wave_manager.monsters_in_wave = 1
	wave_manager.total_monsters_in_wave = wave_manager.ENEMIES_PER_WAVE
	wave_manager.enemies_spawned_in_wave = wave_manager.ENEMIES_PER_WAVE
	wave_manager.is_wave_active = true
	wave_manager.is_between_waves = false

	wave_manager._on_regular_monster_died(6)
	wave_manager._process(wave_manager.BETWEEN_WAVE_DELAY)
	_expect(wave_manager.current_wave == 4, "Auto Next Wave OFF should repeat the same wave", failures)
	_expect(wave_manager.highest_unlocked_wave == 5, "Repeating a wave should still unlock the next wave", failures)
	_expect(wave_manager._status_message == "Repeating wave", "Auto Next Wave OFF should expose repeat-wave status", failures)

	save_manager.reset()
	environment.upgrade_system.load_from_save()
	wave_manager.restart_from_save()
	save_manager.save_data.setting_auto_start_boss = false
	wave_manager.current_wave = 10
	wave_manager.current_chapter = 1
	wave_manager.highest_unlocked_wave = 10
	wave_manager.selected_wave = 10
	wave_manager.selected_boss = false
	wave_manager.is_in_boss_fight = false
	wave_manager.is_boss_unlocked = false
	wave_manager.monsters_killed = 19
	wave_manager.monsters_in_wave = 1
	wave_manager.total_monsters_in_wave = wave_manager.ENEMIES_PER_WAVE
	wave_manager.enemies_spawned_in_wave = wave_manager.ENEMIES_PER_WAVE
	wave_manager.is_wave_active = true
	wave_manager.is_between_waves = false

	wave_manager._on_regular_monster_died(7)
	_expect(wave_manager.is_boss_unlocked, "Boss should unlock after clearing Wave 10", failures)
	_expect(not wave_manager.selected_boss, "Boss should not auto-select when Auto Start Boss is off", failures)
	_expect(save_manager.save_data.campaign_boss_unlocked, "Boss unlock state was not persisted", failures)
	_expect(wave_manager._status_message == "Boss unlocked", "Wave 10 clear should expose boss unlock status", failures)
	wave_manager._process(wave_manager.BETWEEN_WAVE_DELAY)
	_expect(not wave_manager.is_in_boss_fight, "Auto Start Boss OFF should not start boss fight automatically", failures)
	_expect(wave_manager.current_wave == 10, "Auto Start Boss OFF should keep repeating Wave 10", failures)

	await environment.clear_monsters()
	var lingering_monster_scene = load("res://scenes/Monster.tscn") as PackedScene
	var lingering_monster = lingering_monster_scene.instantiate()
	monster_container.add_child(lingering_monster)
	lingering_monster.setup("demon", 1.0)
	lingering_monster.position = hero.position + Vector2(hero.attack_range - 10.0, 0.0)
	hero.base_damage = lingering_monster.current_hp + 50.0
	hero.attack_timer = hero.get_attack_interval()
	_expect(hero.start_attack(lingering_monster), "Hero failed to start the lingering pre-boss attack", failures)
	_expect(wave_manager.select_boss(), "Selecting boss should work after unlock", failures)
	_expect(wave_manager.start_selected_target(), "Starting selected boss should succeed", failures)
	await environment.runner.get_tree().create_timer(0.25).timeout
	_expect(wave_manager.is_in_boss_fight, "Boss selection did not enter boss fight", failures)
	_expect(wave_manager.current_chapter == 1, "Starting boss should not skip directly to the next chapter", failures)
	_expect(wave_manager.total_monsters_in_wave == 1, "Boss fight should only track one enemy", failures)
	await environment.runner.get_tree().process_frame
	var spawned_boss: Node2D = null
	_expect(monster_container.get_child_count() == 1, "Boss fight should spawn the boss immediately", failures)
	if monster_container.get_child_count() == 1:
		spawned_boss = monster_container.get_child(0)
		_expect(spawned_boss.monster_type == "boss", "Boss encounter did not spawn the dedicated boss monster", failures)
	_expect(
		is_equal_approx(wave_manager.boss_time_remaining, wave_manager.BOSS_FIGHT_DURATION),
		"Boss fight did not start with the full timer",
		failures
	)

	_expect(spawned_boss != null, "Boss stage did not expose a spawned boss instance", failures)
	if spawned_boss != null:
		spawned_boss.die()
	_expect(wave_manager.current_chapter == 2, "Boss clear did not advance the chapter", failures)
	_expect(wave_manager.current_wave == 1, "Boss clear did not reset the wave to 1", failures)
	_expect(wave_manager.highest_unlocked_wave == 1, "Boss clear did not reset unlocked waves for the new chapter", failures)
	_expect(save_manager.save_data.campaign_chapter == 2, "Boss clear did not persist the new chapter", failures)
	_expect(save_manager.save_data.campaign_wave == 1, "Boss clear did not persist the new chapter wave", failures)
	_expect(
		save_manager.save_data.campaign_highest_cleared_chapter == 1,
		"Boss clear did not persist the cleared chapter marker",
		failures
	)

	save_manager.reset()
	environment.upgrade_system.load_from_save()
	wave_manager.restart_from_save()
	wave_manager.current_chapter = 2
	wave_manager.current_wave = 10
	wave_manager.highest_unlocked_wave = 10
	wave_manager.selected_wave = 10
	wave_manager.is_boss_unlocked = true
	wave_manager.select_boss()
	_expect(wave_manager.start_selected_target(), "Boss timeout setup failed to start the selected boss", failures)
	wave_manager._process(wave_manager.BOSS_FIGHT_DURATION)
	await environment.runner.get_tree().process_frame
	_expect(not wave_manager.is_in_boss_fight, "Boss timeout should end the boss fight", failures)
	_expect(wave_manager.current_wave == 10, "Boss timeout should send the player back to Wave 10", failures)
	_expect(not wave_manager.is_boss_unlocked, "Boss timeout should clear boss unlock state", failures)
	_expect(
		wave_manager._status_message.begins_with("Boss timer expired."),
		"Boss timeout should expose a timeout-specific status message",
		failures
	)
	_expect(save_manager.save_data.campaign_wave == 10, "Boss timeout did not persist rollback to Wave 10", failures)

	wave_manager.current_chapter = 1
	wave_manager.current_wave = 4
	wave_manager.highest_unlocked_wave = 4
	wave_manager.selected_wave = 4
	wave_manager.selected_boss = false
	wave_manager.is_in_boss_fight = false
	wave_manager.is_boss_unlocked = false
	wave_manager.handle_hero_defeat()
	_expect(wave_manager.current_wave == 3, "Regular defeat should roll back to the previous wave", failures)
	_expect(wave_manager.highest_unlocked_wave == 3, "Regular defeat should roll back unlocked wave access", failures)
	_expect(save_manager.save_data.campaign_wave == 3, "Regular defeat did not persist rollback wave", failures)

	wave_manager.current_chapter = 2
	wave_manager.current_wave = 10
	wave_manager.highest_unlocked_wave = 10
	wave_manager.selected_wave = 10
	wave_manager.selected_boss = true
	wave_manager.is_in_boss_fight = true
	wave_manager.is_boss_unlocked = true
	wave_manager.handle_hero_defeat()
	_expect(not wave_manager.is_in_boss_fight, "Boss defeat should exit boss fight state", failures)
	_expect(not wave_manager.selected_boss, "Boss defeat should clear boss selection", failures)
	_expect(wave_manager.current_wave == 10, "Boss defeat should send the player back to Wave 10", failures)
	_expect(not wave_manager.is_boss_unlocked, "Boss defeat should require Wave 10 clear again", failures)

	await _verify_live_runtime_auto_progression(environment, failures)

	return failures

func _verify_live_runtime_auto_progression(environment, failures: Array[String]) -> void:
	environment.reset_progress()
	var main_scene_loaded: bool = await environment.instantiate_main_scene()
	_expect(main_scene_loaded, "Live auto-progression scene failed to instantiate", failures)
	if not main_scene_loaded:
		return

	await environment.clear_monsters()
	await environment.runner.get_tree().process_frame

	var wave_manager = environment.get_wave_manager()
	var save_manager = environment.save_manager
	_expect(wave_manager != null, "Live auto-progression WaveManager is unavailable", failures)
	if wave_manager == null:
		return

	save_manager.save_data.setting_auto_next_wave = false
	save_manager.save_data.setting_auto_start_boss = false

	wave_manager.current_chapter = 1
	wave_manager.current_wave = 4
	wave_manager.highest_unlocked_wave = 4
	wave_manager.selected_wave = 4
	wave_manager.selected_boss = false
	wave_manager.is_in_boss_fight = false
	wave_manager.is_boss_unlocked = false
	wave_manager.monsters_killed = 19
	wave_manager.monsters_in_wave = 1
	wave_manager.total_monsters_in_wave = wave_manager.ENEMIES_PER_WAVE
	wave_manager.enemies_spawned_in_wave = wave_manager.ENEMIES_PER_WAVE
	wave_manager.is_wave_active = true
	wave_manager.is_between_waves = false
	wave_manager.spawn_timer = 0.0
	wave_manager.wave_delay_timer = 0.0
	wave_manager._status_message = ""
	wave_manager._on_regular_monster_died(3)
	await environment.runner.get_tree().create_timer(wave_manager.BETWEEN_WAVE_DELAY + 0.2).timeout

	_expect(wave_manager.current_wave == 4, "Live runtime should repeat the same wave when Auto Next Wave is off", failures)
	_expect(wave_manager.highest_unlocked_wave == 5, "Live runtime should still unlock the next wave while repeating", failures)
	_expect(wave_manager._status_message == "Repeating wave", "Live runtime should expose the repeat-wave status", failures)

	wave_manager.current_chapter = 1
	wave_manager.current_wave = 10
	wave_manager.highest_unlocked_wave = 10
	wave_manager.selected_wave = 10
	wave_manager.selected_boss = false
	wave_manager.is_in_boss_fight = false
	wave_manager.is_boss_unlocked = false
	wave_manager.monsters_killed = 19
	wave_manager.monsters_in_wave = 1
	wave_manager.total_monsters_in_wave = wave_manager.ENEMIES_PER_WAVE
	wave_manager.enemies_spawned_in_wave = wave_manager.ENEMIES_PER_WAVE
	wave_manager.is_wave_active = true
	wave_manager.is_between_waves = false
	wave_manager.spawn_timer = 0.0
	wave_manager.wave_delay_timer = 0.0
	wave_manager._status_message = ""
	wave_manager._on_regular_monster_died(4)
	await environment.runner.get_tree().create_timer(wave_manager.BETWEEN_WAVE_DELAY + 0.2).timeout

	_expect(not wave_manager.is_in_boss_fight, "Live runtime should not auto-start boss when Auto Start Boss is off", failures)
	_expect(wave_manager.current_wave == 10, "Live runtime should keep repeating Wave 10 when Auto Start Boss is off", failures)
	_expect(wave_manager.is_boss_unlocked, "Live runtime should leave boss unlocked after Wave 10 clear", failures)
