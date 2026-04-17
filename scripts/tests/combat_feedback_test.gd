extends "res://scripts/tests/test_case.gd"

func get_name() -> String:
	return "combat feedback and hero state"

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
	var main_scene = environment.main_scene
	var monster_container = environment.get_monster_container()

	_expect(hero != null, "Hero instance is unavailable", failures)
	_expect(main_scene != null, "Main scene instance is unavailable", failures)
	_expect(monster_container != null, "Monster container is unavailable", failures)
	if hero == null or main_scene == null or monster_container == null:
		return failures

	hero.current_hp = 10.0
	hero.take_damage(3.0)
	_expect(is_equal_approx(hero.current_hp, 7.0), "Hero damage application is incorrect", failures)

	hero.heal(2.0)
	_expect(is_equal_approx(hero.current_hp, 9.0), "Hero healing application is incorrect", failures)

	hero.heal(999.0)
	_expect(is_equal_approx(hero.current_hp, hero.max_hp), "Hero healing exceeded max HP", failures)

	hero.current_hp = 50.0
	hero.health_regen = 4.0
	hero.apply_regeneration(2.0)
	_expect(is_equal_approx(hero.current_hp, 58.0), "Hero regeneration helper did not restore HP", failures)

	var floating_before = main_scene.get_children().filter(func(child): return child.name == "FloatingText").size()
	main_scene._spawn_floating_text("42", Vector2(320, 320), "crit")
	await environment.runner.get_tree().process_frame

	var floating_text = main_scene.get_node_or_null("FloatingText") as Label
	_expect(floating_text != null, "Floating damage text node was not spawned", failures)
	if floating_text:
		_expect(floating_text.text == "42", "Floating damage text did not preserve the provided value", failures)
		_expect(
			floating_text.modulate.r > 0.95 and floating_text.modulate.g > 0.75 and floating_text.modulate.b < 0.3,
			"Floating damage text color is incorrect",
			failures
		)

	var floating_after = main_scene.get_children().filter(func(child): return child.name == "FloatingText").size()
	_expect(floating_after == floating_before + 1, "Floating damage text count did not increase", failures)

	var floating_after_manual = main_scene.get_children().filter(func(child): return child.name == "FloatingText").size()
	main_scene._on_hero_attack_hit(Vector2(420, 360), 12.0, false)
	await environment.runner.get_tree().process_frame
	var spawned_texts = main_scene.get_children().filter(func(child): return child.name == "FloatingText")
	_expect(spawned_texts.size() >= floating_after_manual, "Hero-hit feedback did not keep floating combat text available", failures)

	var floating_after_hero = spawned_texts.size()
	main_scene._on_monster_attack_hit(Vector2(260, 360), 5.0)
	await environment.runner.get_tree().process_frame
	var total_texts = main_scene.get_children().filter(func(child): return child.name == "FloatingText")
	_expect(total_texts.size() >= floating_after_hero, "Monster-hit feedback did not keep floating combat text available", failures)

	return failures
