extends "res://scripts/tests/test_case.gd"

func get_name() -> String:
	return "ability system"

func run(environment) -> Array[String]:
	var failures: Array[String] = []

	environment.reset_progress()
	var main_scene_loaded: bool = await environment.instantiate_main_scene()
	_expect(main_scene_loaded, "Main scene failed to instantiate", failures)
	if not main_scene_loaded:
		return failures

	environment.stabilize_main_scene()

	var hero = environment.get_hero()
	var monster_container = environment.get_monster_container()
	var wave_manager = environment.get_wave_manager()
	var ability_system = environment.ability_system

	_expect(hero != null, "Hero instance is unavailable", failures)
	_expect(ability_system != null, "Ability system autoload is unavailable", failures)
	if hero == null or ability_system == null:
		return failures

	_expect(ability_system.is_unlocked("punch"), "Punch should be unlocked by default", failures)
	_expect(ability_system.is_unlocked("leg_sweep"), "Leg Sweep should be unlocked by default", failures)
	_expect(ability_system.is_unlocked("evil_eye"), "Evil Eye should be unlocked by default", failures)

	_expect(ability_system.equip_ability(0, "punch"), "Punch failed to equip", failures)
	_expect(ability_system.equip_ability(1, "leg_sweep"), "Leg Sweep failed to equip", failures)
	_expect(ability_system.equip_ability(2, "evil_eye"), "Evil Eye failed to equip", failures)
	_expect(ability_system.get_ability_slot(0) == "punch", "Punch was not stored in slot 1", failures)
	_expect(ability_system.get_ability_slot(1) == "leg_sweep", "Leg Sweep was not stored in slot 2", failures)
	_expect(ability_system.get_ability_slot(2) == "evil_eye", "Evil Eye was not stored in slot 3", failures)

	var monster_scene := load("res://scenes/Monster.tscn") as PackedScene
	var monsters: Array = []
	for index in range(4):
		var monster = monster_scene.instantiate()
		monster_container.add_child(monster)
		monster.position = Vector2(280 + index * 60, 480)
		monster.setup("slime", 1.0)
		monsters.append(monster)
	await environment.runner.get_tree().process_frame

	ability_system.bind_runtime(environment.main_scene, hero, monster_container, wave_manager)
	var ability_effects = environment.main_scene.get_node_or_null("CombatArea/AbilityEffects") as Node2D
	_expect(ability_effects != null, "Ability effects container is missing", failures)
	if ability_effects:
		_expect(
			ability_effects.get_child_count() == environment.main_scene.MAX_ACTIVE_ABILITY_ICONS,
			"Ability impact icon pool was not prewarmed",
			failures
		)

	var hp_before_punch = monsters[0].current_hp
	ability_system.advance_runtime(4.1)
	_expect(monsters[0].current_hp < hp_before_punch, "Punch did not hit the nearest enemy", failures)
	var icon_nodes_after_punch: Array = []
	if ability_effects:
		icon_nodes_after_punch = ability_effects.get_children().filter(func(child): return child.name == "AbilityImpactIcon")
	_expect(not icon_nodes_after_punch.is_empty(), "Punch did not spawn an ability impact icon", failures)
	if not icon_nodes_after_punch.is_empty():
		var first_icon = _find_nearest_visible_icon(icon_nodes_after_punch, monsters[0].global_position)
		_expect(first_icon != null, "Ability impact icon instance is invalid", failures)
		if first_icon:
			var monster_bounds = monsters[0].get_visual_bounds()
			var rendered_size = first_icon.get_rendered_size()
			var expected_y = monster_bounds.position.y - 4.0 - (rendered_size.y * 0.5)
			_expect(first_icon.get_parent() == ability_effects, "Ability impact icon is attached outside the combat 2D layer", failures)
			_expect(is_equal_approx(rendered_size.x, monster_bounds.size.x), "Ability impact icon width should match target width", failures)
			_expect(
				first_icon.global_position.is_equal_approx(Vector2(monster_bounds.get_center().x, expected_y)),
				"Ability impact icon did not appear directly above the target",
				failures
			)
			_expect(first_icon.is_active(), "Ability impact icon should be visible while the animation is active", failures)

	var hp_before_sweep := []
	for monster in monsters:
		hp_before_sweep.append(monster.current_hp)
	ability_system.advance_runtime(4.0)
	_expect(monsters[0].current_hp < hp_before_sweep[0], "Leg Sweep did not affect the first enemy", failures)
	_expect(monsters[1].current_hp < hp_before_sweep[1], "Leg Sweep did not affect the second enemy", failures)
	_expect(monsters[2].current_hp < hp_before_sweep[2], "Leg Sweep did not affect the third enemy", failures)
	_expect(is_equal_approx(monsters[3].current_hp, hp_before_sweep[3]), "Leg Sweep should not affect the fourth enemy", failures)
	var icon_nodes_after_sweep = ability_effects.get_children().filter(func(child): return child.name == "AbilityImpactIcon") if ability_effects else []
	_expect(icon_nodes_after_sweep.size() >= 3, "Leg Sweep should spawn impact icons for multiple targets", failures)

	var hp_before_eye = monsters[3].current_hp
	ability_system.advance_runtime(0.1)
	_expect(monsters[3].current_hp < hp_before_eye, "Evil Eye did not target the fourth enemy", failures)

	_expect(ability_system.clear_slot(2), "Clearing Evil Eye slot failed", failures)
	var hp_before_cleared_eye = monsters[3].current_hp
	ability_system.advance_runtime(2.1)
	_expect(is_equal_approx(monsters[3].current_hp, hp_before_cleared_eye), "Cleared ability slot still triggered", failures)

	return failures

func _find_nearest_visible_icon(icon_nodes: Array, target_position: Vector2) -> AbilityImpactIcon:
	var nearest_icon: AbilityImpactIcon = null
	var nearest_distance := INF
	for node in icon_nodes:
		var icon = node as AbilityImpactIcon
		if icon == null or not icon.is_active():
			continue
		var distance = icon.global_position.distance_to(target_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_icon = icon
	return nearest_icon
