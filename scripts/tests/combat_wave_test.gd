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

	save_manager.save_data.gold = 0
	save_manager.save_data.monsters_killed = 0
	wave_manager.monsters_in_wave = 0
	wave_manager.monsters_killed = 0
	wave_manager.is_wave_active = true
	wave_manager.is_between_waves = false

	wave_manager.spawn_monster()
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
	_expect(hero.current_hp < hero_hp_before, "Monster attack did not damage the hero", failures)

	hero.base_damage = monster.current_hp + 10.0
	environment.main_scene._attack_nearest_monster()
	await environment.runner.get_tree().process_frame

	_expect(monster.is_dead, "Monster did not die after lethal damage", failures)
	_expect(save_manager.save_data.gold == monster.gold_reward, "Gold reward was not granted on kill", failures)
	_expect(save_manager.save_data.monsters_killed == 1, "Monster kill was not persisted", failures)

	save_manager.reset()
	environment.upgrade_system.load_from_save()
	wave_manager.load_wave_from_save()
	wave_manager.start_next_wave()

	save_manager.save_data.wave = 1
	save_manager.save_data.monsters_killed = 9
	wave_manager.current_wave = 1
	wave_manager.monsters_killed = 9
	wave_manager.monsters_in_wave = 1
	wave_manager.total_monsters_in_wave = 10
	wave_manager.is_wave_active = true
	wave_manager.is_between_waves = false

	wave_manager._on_monster_died(5)
	environment.upgrade_system.load_from_save()

	_expect(wave_manager.current_wave == 2, "Current wave did not advance after completion", failures)
	_expect(save_manager.save_data.wave == 2, "Completed wave was not persisted", failures)
	_expect(wave_manager.is_between_waves, "Wave manager did not enter intermission state", failures)
	_expect(save_manager.save_data.gold == 5, "Wave completion reward was not saved", failures)
	_expect(save_manager.save_data.monsters_killed == 10, "Monster kill counter did not reach the wave total", failures)

	return failures
