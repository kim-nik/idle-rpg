extends "res://scripts/tests/test_case.gd"

func get_name() -> String:
	return "progression mechanics"

func run(environment) -> Array[String]:
	var failures: Array[String] = []

	environment.reset_progress()
	var main_scene_loaded: bool = await environment.instantiate_main_scene()
	_expect(main_scene_loaded, "Main scene failed to instantiate", failures)
	if not main_scene_loaded:
		return failures

	environment.stabilize_main_scene()

	var hero = environment.get_hero()
	var upgrade_system = environment.upgrade_system
	var save_manager = environment.save_manager

	_expect(hero != null, "Hero instance is unavailable", failures)
	if hero == null:
		return failures

	hero.update_stats()

	_expect(hero.max_hp == upgrade_system.get_max_hp(), "Hero max HP does not match upgrade system", failures)
	_expect(hero.base_damage == upgrade_system.get_damage(), "Hero damage does not match upgrade system", failures)
	_expect(hero.attack_speed == upgrade_system.get_attack_speed(), "Hero attack speed does not match upgrade system", failures)
	_expect(hero.armor == upgrade_system.get_armor(), "Hero armor does not match upgrade system", failures)
	_expect(hero.health_regen == upgrade_system.get_health_regen(), "Hero health regen does not match upgrade system", failures)
	_expect(hero.current_hp > 0, "Hero current HP is invalid", failures)
	_expect(
		is_equal_approx(hero.get_attack_interval(), 1.0 / upgrade_system.get_attack_speed()),
		"Attack interval does not match the configured attack speed",
		failures
	)

	hero.base_damage = 25.0
	hero.crit_chance = 100.0
	hero.crit_multiplier = 200.0
	var crit_damage_output = hero.get_damage_output()
	_expect(crit_damage_output.get("is_crit", false), "100% crit chance did not guarantee a critical hit", failures)
	_expect(
		is_equal_approx(crit_damage_output.get("raw_damage", 0.0), 50.0),
		"Critical damage multiplier is incorrect",
		failures
	)

	hero.crit_chance = 0.0
	hero.crit_multiplier = 250.0
	var normal_damage_output = hero.get_damage_output()
	_expect(not normal_damage_output.get("is_crit", true), "0% crit chance still produced a critical hit", failures)
	_expect(
		is_equal_approx(normal_damage_output.get("raw_damage", 0.0), 25.0),
		"Base damage should stay unchanged without a critical hit",
		failures
	)

	var armored_defender_stats = {"armor": 100.0}
	var mitigated_output = hero.get_damage_output(armored_defender_stats)
	_expect(mitigated_output.get("final_damage", 0.0) < mitigated_output.get("raw_damage", 0.0), "Armor did not mitigate damage", failures)

	hero.max_hp = 100.0
	hero.current_hp = 40.0
	hero.health_regen = 5.0
	hero.apply_regeneration(2.0)
	_expect(is_equal_approx(hero.current_hp, 50.0), "Hero regeneration did not restore HP over time", failures)

	save_manager.save_data.gold = 100
	var previous_damage = upgrade_system.get_damage()
	var previous_gold = save_manager.save_data.gold
	var purchase_success = upgrade_system.purchase_upgrade("damage")
	hero.update_stats()

	_expect(purchase_success, "Damage upgrade purchase failed with sufficient gold", failures)
	_expect(upgrade_system.damage_level == 2, "Damage level did not increase after purchase", failures)
	_expect(save_manager.save_data.gold < previous_gold, "Gold was not spent on damage upgrade", failures)
	_expect(hero.base_damage > previous_damage, "Hero damage did not increase after upgrade", failures)

	save_manager.save_data.gold = 1000
	var previous_armor = upgrade_system.get_armor()
	var previous_regen = upgrade_system.get_health_regen()
	_expect(upgrade_system.purchase_upgrade("armor"), "Armor upgrade purchase failed with sufficient gold", failures)
	_expect(upgrade_system.purchase_upgrade("health_regen"), "Health regen upgrade purchase failed with sufficient gold", failures)
	hero.update_stats()
	_expect(hero.armor > previous_armor, "Hero armor did not increase after armor upgrade", failures)
	_expect(hero.health_regen > previous_regen, "Hero regen did not increase after regen upgrade", failures)

	var attack_speed_level_before = upgrade_system.attack_speed_level
	save_manager.save_data.gold = 0
	var insufficient_purchase = upgrade_system.purchase_upgrade("attack_speed")
	_expect(not insufficient_purchase, "Upgrade purchase succeeded without enough gold", failures)
	_expect(
		upgrade_system.attack_speed_level == attack_speed_level_before,
		"Attack speed level changed after a failed purchase",
		failures
	)

	return failures
