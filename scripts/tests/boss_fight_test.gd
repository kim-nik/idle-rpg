extends "res://scripts/tests/test_case.gd"

func get_name() -> String:
	return "boss fight flow"

func run(environment) -> Array[String]:
	var failures: Array[String] = []

	var manual_context := await _load_test_context(environment, failures)
	if manual_context.is_empty():
		return failures

	_verify_boss_definition(manual_context.get("monster_scene"), failures)
	await _verify_manual_boss_flow(environment, manual_context, failures)

	var auto_context := await _load_test_context(environment, failures)
	if auto_context.is_empty():
		return failures
	_verify_auto_start_boss_flow(auto_context, failures)

	var timeout_context := await _load_test_context(environment, failures)
	if timeout_context.is_empty():
		return failures
	_verify_boss_timeout_flow(timeout_context, failures)

	await _verify_live_runtime_boss_flow(environment, failures)

	return failures

func _load_test_context(environment, failures: Array[String]) -> Dictionary:
	environment.reset_progress()
	var main_scene_loaded: bool = await environment.instantiate_main_scene()
	_expect(main_scene_loaded, "Main scene failed to instantiate for boss fight test", failures)
	if not main_scene_loaded:
		return {}

	environment.stabilize_main_scene()
	await environment.clear_monsters()

	var context := {
		"main_scene": environment.main_scene,
		"hero": environment.get_hero(),
		"wave_manager": environment.get_wave_manager(),
		"monster_container": environment.get_monster_container(),
		"ui": environment.get_ui(),
		"save_manager": environment.save_manager,
		"monster_scene": load("res://scenes/Monster.tscn") as PackedScene
	}
	_expect(context.get("main_scene") != null, "Main scene reference is unavailable", failures)
	_expect(context.get("hero") != null, "Hero instance is unavailable for boss fight test", failures)
	_expect(context.get("wave_manager") != null, "WaveManager is unavailable for boss fight test", failures)
	_expect(context.get("monster_container") != null, "Monster container is unavailable for boss fight test", failures)
	_expect(context.get("ui") != null, "UI controller is unavailable for boss fight test", failures)
	_expect(context.get("save_manager") != null, "SaveManager is unavailable for boss fight test", failures)
	_expect(context.get("monster_scene") != null, "Monster scene failed to load for boss fight test", failures)
	if context.get("hero") == null or context.get("wave_manager") == null:
		return {}
	return context

func _verify_boss_definition(monster_scene: PackedScene, failures: Array[String]) -> void:
	if monster_scene == null:
		return

	var probe = monster_scene.instantiate()
	var stats = probe.MONSTER_STATS
	_expect(stats.has("boss"), "Monster config does not define a dedicated boss enemy", failures)
	if stats.has("boss") and stats.has("demon"):
		var boss_stats: Dictionary = stats["boss"]
		var demon_stats: Dictionary = stats["demon"]
		_expect(float(boss_stats.get("hp", 0.0)) > float(demon_stats.get("hp", 0.0)), "Boss HP should exceed demon HP", failures)
		_expect(
			float(boss_stats.get("visual_scale", 1.0)) > float(demon_stats.get("visual_scale", 1.0)),
			"Boss should have a larger visual scale than regular monsters",
			failures
		)
	probe.queue_free()

func _verify_manual_boss_flow(environment, context: Dictionary, failures: Array[String]) -> void:
	var wave_manager = context.get("wave_manager")
	var save_manager = context.get("save_manager")
	var monster_container = context.get("monster_container")
	var ui = context.get("ui")
	var hero = context.get("hero")
	var main_scene = context.get("main_scene")

	_prime_wave_ten_completion(wave_manager, save_manager, 1, false)
	wave_manager._on_regular_monster_died(7)

	_expect(wave_manager.is_boss_unlocked, "Boss should unlock after clearing Wave 10", failures)
	_expect(not wave_manager.is_in_boss_fight, "Boss should not auto-start when Auto Start Boss is off", failures)
	_expect(not wave_manager.selected_boss, "Boss should remain unselected after Wave 10 clear with auto-start off", failures)
	_expect(wave_manager._status_message == "Boss unlocked", "Wave 10 clear should expose the boss unlocked status", failures)
	_expect(save_manager.save_data.campaign_boss_unlocked, "Boss unlock state was not persisted", failures)

	_expect(wave_manager.select_boss(), "Selecting the unlocked boss should succeed", failures)
	_expect(wave_manager.start_selected_target(), "Starting the selected boss encounter should succeed", failures)
	await environment.runner.get_tree().process_frame

	_expect(wave_manager.is_in_boss_fight, "Manual boss start did not enter boss fight state", failures)
	_expect(wave_manager.boss_fight.is_active(), "Boss fight runtime entity is not active after boss start", failures)
	_expect(monster_container.get_child_count() == 1, "Boss fight should spawn exactly one boss enemy", failures)

	var spawned_boss: Node2D = null
	if monster_container.get_child_count() == 1:
		spawned_boss = monster_container.get_child(0)
		_expect(spawned_boss.monster_type == "boss", "Boss encounter did not spawn the dedicated boss enemy", failures)
		_expect(wave_manager.boss_fight.get_boss_monster() == spawned_boss, "Boss runtime entity does not own the spawned boss", failures)

	ui._update_ui()
	_expect(ui.top_wave_label.text == "Chapter 1 - Boss", "UI header did not switch to boss state", failures)
	_expect(ui.wave_label.text == "Boss Fight", "UI did not replace the kill counter with a boss indicator", failures)
	_expect(
		ui.campaign_status_label.text.begins_with("Boss timer: 30.0s"),
		"UI did not show the full 30 second boss timer at fight start",
		failures
	)
	_expect(save_manager.save_data.campaign_in_boss, "Boss fight start was not persisted", failures)

	wave_manager._process(wave_manager.BETWEEN_WAVE_DELAY + 0.1)
	ui._update_ui()
	_expect(wave_manager.is_in_boss_fight, "Boss fight exited after the old between-wave delay", failures)
	_expect(wave_manager.current_chapter == 1, "Boss fight should stay in the current chapter until the boss dies", failures)
	_expect(
		is_equal_approx(wave_manager.boss_time_remaining, 26.9),
		"Boss timer did not continue inside the dedicated boss stage",
		failures
	)
	_expect(
		ui.campaign_status_label.text.begins_with("Boss timer: 26.9s"),
		"UI did not refresh the boss timer after elapsed time",
		failures
	)

	_expect(spawned_boss != null, "Boss fight did not expose a spawned boss instance", failures)
	if spawned_boss != null:
		spawned_boss.position = hero.position + Vector2(hero.attack_range - 10.0, 0.0)
		hero.base_damage = spawned_boss.current_hp + 50.0
		hero.attack_timer = hero.get_attack_interval()
		main_scene._attack_nearest_monster()
		await environment.runner.get_tree().create_timer(0.35).timeout

	_expect(not wave_manager.is_in_boss_fight, "Boss death did not end the boss fight state", failures)
	_expect(not wave_manager.boss_fight.is_active(), "Boss runtime entity stayed active after boss death", failures)
	_expect(wave_manager.current_chapter == 2, "Boss death did not advance the chapter", failures)
	_expect(wave_manager.current_wave == 1, "Boss death did not reset the next chapter to Wave 1", failures)
	_expect(wave_manager.highest_unlocked_wave == 1, "Boss death did not reset unlocked waves for the next chapter", failures)
	_expect(save_manager.save_data.campaign_chapter == 2, "Boss death did not persist the next chapter", failures)
	_expect(save_manager.save_data.campaign_wave == 1, "Boss death did not persist Wave 1 for the next chapter", failures)
	_expect(
		save_manager.save_data.campaign_highest_cleared_chapter == 1,
		"Boss death did not persist the cleared chapter marker",
		failures
	)

func _verify_auto_start_boss_flow(context: Dictionary, failures: Array[String]) -> void:
	var wave_manager = context.get("wave_manager")
	var save_manager = context.get("save_manager")
	var monster_container = context.get("monster_container")

	_prime_wave_ten_completion(wave_manager, save_manager, 2, true)
	wave_manager._on_regular_monster_died(9)

	_expect(wave_manager.is_boss_unlocked, "Boss should unlock before auto-starting", failures)
	_expect(wave_manager.selected_boss, "Boss should become the selected target when Auto Start Boss is on", failures)
	_expect(wave_manager.is_between_waves, "Wave manager should queue the boss during the intermission", failures)

	wave_manager._process(wave_manager.BETWEEN_WAVE_DELAY)

	_expect(wave_manager.is_in_boss_fight, "Auto Start Boss did not launch the boss fight after intermission", failures)
	_expect(wave_manager.boss_fight.is_active(), "Boss runtime entity is inactive in auto-start flow", failures)
	_expect(monster_container.get_child_count() == 1, "Auto Start Boss did not spawn the boss enemy", failures)
	_expect(
		is_equal_approx(wave_manager.boss_time_remaining, wave_manager.BOSS_FIGHT_DURATION),
		"Auto Start Boss did not start with the full boss timer",
		failures
	)

func _verify_boss_timeout_flow(context: Dictionary, failures: Array[String]) -> void:
	var wave_manager = context.get("wave_manager")
	var save_manager = context.get("save_manager")
	var monster_container = context.get("monster_container")
	var ui = context.get("ui")

	save_manager.save_data.setting_auto_start_boss = false
	wave_manager.current_chapter = 3
	wave_manager.current_wave = 10
	wave_manager.highest_unlocked_wave = 10
	wave_manager.selected_wave = 10
	wave_manager.selected_boss = false
	wave_manager.is_boss_unlocked = true
	wave_manager.is_in_boss_fight = false
	wave_manager.is_wave_active = false
	wave_manager.is_between_waves = false
	wave_manager.monsters_killed = 0
	wave_manager.monsters_in_wave = 0
	wave_manager.enemies_spawned_in_wave = 0
	wave_manager._persist_campaign_state("boss_timeout_setup")

	_expect(wave_manager.select_boss(), "Boss timeout setup failed to select the boss", failures)
	_expect(wave_manager.start_selected_target(), "Boss timeout setup failed to start the boss", failures)
	_expect(monster_container.get_child_count() == 1, "Boss timeout setup did not spawn the boss", failures)

	wave_manager._process(5.0)
	_expect(wave_manager.is_in_boss_fight, "Boss fight should remain active before the timer expires", failures)
	_expect(
		is_equal_approx(wave_manager.boss_time_remaining, 25.0),
		"Boss timer did not decrement during the fight",
		failures
	)

	wave_manager._process(25.0)
	ui._update_ui()
	_expect(not wave_manager.is_in_boss_fight, "Boss timeout should end the boss fight", failures)
	_expect(not wave_manager.boss_fight.is_active(), "Boss runtime entity stayed active after timeout", failures)
	_expect(wave_manager.current_chapter == 3, "Boss timeout should not advance the chapter", failures)
	_expect(wave_manager.current_wave == 10, "Boss timeout should roll the player back to Wave 10", failures)
	_expect(not wave_manager.selected_boss, "Boss timeout should clear boss selection", failures)
	_expect(not wave_manager.is_boss_unlocked, "Boss timeout should require Wave 10 to unlock the boss again", failures)
	_expect(monster_container.get_child_count() == 0, "Boss timeout should clear the boss from the scene", failures)
	_expect(
		wave_manager._status_message.begins_with("Boss timer expired."),
		"Boss timeout should expose a timeout-specific status message",
		failures
	)
	_expect(save_manager.save_data.campaign_wave == 10, "Boss timeout did not persist rollback to Wave 10", failures)
	_expect(not save_manager.save_data.campaign_in_boss, "Boss timeout did not clear persisted boss-fight state", failures)
	_expect(ui.top_wave_label.text == "Chapter 3 - Wave 10/10", "UI did not return to Wave 10 after boss timeout", failures)
	_expect(ui.wave_label.text == "Defeated 0/20", "UI did not restore the wave progress counter after boss timeout", failures)

func _prime_wave_ten_completion(wave_manager, save_manager, chapter: int, auto_start_boss: bool) -> void:
	save_manager.save_data.setting_auto_start_boss = auto_start_boss
	save_manager.save_data.setting_auto_next_wave = true

	wave_manager.current_chapter = chapter
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

func _verify_live_runtime_boss_flow(environment, failures: Array[String]) -> void:
	environment.reset_progress()
	var main_scene_loaded: bool = await environment.instantiate_main_scene()
	_expect(main_scene_loaded, "Live boss-flow scene failed to instantiate", failures)
	if not main_scene_loaded:
		return

	await environment.clear_monsters()
	await environment.runner.get_tree().process_frame

	var wave_manager = environment.get_wave_manager()
	var save_manager = environment.save_manager
	var monster_container = environment.get_monster_container()
	var hero = environment.get_hero()
	_expect(wave_manager != null, "Live boss-flow WaveManager is unavailable", failures)
	_expect(monster_container != null, "Live boss-flow monster container is unavailable", failures)
	_expect(hero != null, "Live boss-flow hero is unavailable", failures)
	if wave_manager == null or monster_container == null or hero == null:
		return

	hero.base_damage = 10.0
	hero.attack_timer = 0.0
	_prime_wave_ten_completion(wave_manager, save_manager, 1, true)
	wave_manager._on_regular_monster_died(5)
	await environment.runner.get_tree().create_timer(wave_manager.BETWEEN_WAVE_DELAY + 0.6).timeout

	_expect(wave_manager.is_in_boss_fight, "Live runtime did not enter boss fight after auto-start", failures)
	_expect(wave_manager.boss_fight.is_active(), "Live runtime boss entity is inactive after auto-start", failures)
	_expect(wave_manager.current_chapter == 1, "Live runtime advanced chapter before the boss died", failures)
	_expect(monster_container.get_child_count() == 1, "Live runtime boss stage did not keep exactly one boss alive", failures)
	if monster_container.get_child_count() == 1:
		var boss = monster_container.get_child(0)
		_expect(boss.monster_type == "boss", "Live runtime boss stage spawned a non-boss enemy", failures)
