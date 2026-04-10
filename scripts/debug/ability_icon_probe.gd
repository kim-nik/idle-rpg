extends Node

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const MONSTER_SCENE := preload("res://scenes/Monster.tscn")
const OUTPUT_DIR := "user://debug/ability_icon_probe"

func _ready() -> void:
	await _run_probe()

func _run_probe() -> void:
	var output_dir = ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)
	await _run_manual_probe()
	await _run_runtime_probe()
	get_tree().quit()

func _run_manual_probe() -> void:
	var output_dir = ProjectSettings.globalize_path(OUTPUT_DIR)
	var main_scene = await _create_probe_scene()
	var monster = await _spawn_probe_monster(main_scene, Vector2(420, 480))

	main_scene._on_ability_triggered("punch", monster, "42", "ability")

	_write_frame_metadata(output_dir, "manual_frame_00.txt", monster, main_scene.get_node("CombatArea/AbilityEffects"))
	await _capture_frame(main_scene, "manual_frame_00.png")
	await get_tree().process_frame
	_write_frame_metadata(output_dir, "manual_frame_01.txt", monster, main_scene.get_node("CombatArea/AbilityEffects"))
	await _capture_frame(main_scene, "manual_frame_01.png")
	await get_tree().create_timer(0.1).timeout
	_write_frame_metadata(output_dir, "manual_frame_02.txt", monster, main_scene.get_node("CombatArea/AbilityEffects"))
	await _capture_frame(main_scene, "manual_frame_02.png")
	await get_tree().create_timer(0.3).timeout
	_write_frame_metadata(output_dir, "manual_frame_03.txt", monster, main_scene.get_node("CombatArea/AbilityEffects"))
	await _capture_frame(main_scene, "manual_frame_03.png")

	_write_probe_metadata("%s/manual_metadata.txt" % output_dir, monster, main_scene.get_node("CombatArea/AbilityEffects"))
	main_scene.queue_free()
	await get_tree().process_frame

func _run_runtime_probe() -> void:
	var output_dir = ProjectSettings.globalize_path(OUTPUT_DIR)
	var main_scene = await _create_probe_scene()
	var hero = main_scene.get_node("CombatArea/Hero")
	var monster = await _spawn_probe_monster(main_scene, hero.position + Vector2(hero.attack_range - 10.0, 0.0))
	var ability_system = get_node("/root/AbilitySystem")

	ability_system.load_from_save()
	ability_system.equip_ability(0, "punch")
	ability_system.bind_runtime(
		main_scene,
		hero,
		main_scene.get_node("CombatArea/Monsters"),
		main_scene.get_node("WaveManager")
	)
	hero.attack_timer = 0.0
	main_scene.set_process(false)

	ability_system.advance_runtime(4.1)
	_write_frame_metadata(output_dir, "runtime_frame_00.txt", monster, main_scene.get_node("CombatArea/AbilityEffects"))
	await _capture_frame(main_scene, "runtime_frame_00.png")
	await get_tree().process_frame
	_write_frame_metadata(output_dir, "runtime_frame_01.txt", monster, main_scene.get_node("CombatArea/AbilityEffects"))
	await _capture_frame(main_scene, "runtime_frame_01.png")
	await get_tree().create_timer(0.1).timeout
	_write_frame_metadata(output_dir, "runtime_frame_02.txt", monster, main_scene.get_node("CombatArea/AbilityEffects"))
	await _capture_frame(main_scene, "runtime_frame_02.png")
	await get_tree().create_timer(0.3).timeout
	_write_frame_metadata(output_dir, "runtime_frame_03.txt", monster, main_scene.get_node("CombatArea/AbilityEffects"))
	await _capture_frame(main_scene, "runtime_frame_03.png")

	_write_probe_metadata("%s/runtime_metadata.txt" % output_dir, monster, main_scene.get_node("CombatArea/AbilityEffects"))
	main_scene.queue_free()
	await get_tree().process_frame

func _create_probe_scene() -> Node:
	var main_scene = MAIN_SCENE.instantiate()
	add_child(main_scene)
	await get_tree().process_frame

	var hero = main_scene.get_node("CombatArea/Hero")
	var monster_container = main_scene.get_node("CombatArea/Monsters")
	var wave_manager = main_scene.get_node("WaveManager")

	main_scene.set_process(false)
	hero.set_process(false)
	wave_manager.set_process(false)

	for child in monster_container.get_children():
		child.queue_free()
	await get_tree().process_frame
	return main_scene

func _spawn_probe_monster(main_scene: Node, spawn_position: Vector2) -> Node2D:
	var monster_container = main_scene.get_node("CombatArea/Monsters")
	var monster = MONSTER_SCENE.instantiate()
	monster_container.add_child(monster)
	monster.position = spawn_position
	monster.setup("slime", 1.0)
	monster.set_process(false)
	await get_tree().process_frame
	return monster

func _capture_frame(main_scene: Node, file_name: String) -> void:
	await main_scene.capture_debug_screenshot("ability_icon_probe/%s" % file_name)

func _write_probe_metadata(metadata_path: String, monster: Node2D, ability_effects: Node2D) -> void:
	var file = FileAccess.open(metadata_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write probe metadata: %s" % metadata_path)
		return

	file.store_line("monster_global_position=%s" % monster.global_position)
	if monster.has_method("get_visual_bounds"):
		file.store_line("monster_visual_bounds=%s" % str(monster.get_visual_bounds()))

	for child in ability_effects.get_children():
		if child is AbilityImpactIcon:
			var icon = child as AbilityImpactIcon
			file.store_line("icon_active=%s pos=%s rendered_size=%s" % [
				str(icon.is_active()),
				str(icon.global_position),
				str(icon.get_rendered_size())
			])

func _write_frame_metadata(output_dir: String, file_name: String, monster: Node2D, ability_effects: Node2D) -> void:
	var metadata_path = "%s/%s" % [output_dir, file_name]
	var file = FileAccess.open(metadata_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write frame metadata: %s" % metadata_path)
		return

	file.store_line("monster_global_position=%s" % monster.global_position)
	if monster.has_method("get_visual_bounds"):
		file.store_line("monster_visual_bounds=%s" % str(monster.get_visual_bounds()))

	for child in ability_effects.get_children():
		if child is AbilityImpactIcon:
			var icon = child as AbilityImpactIcon
			var sprite = icon.get_node_or_null("Sprite2D") as Sprite2D
			file.store_line("icon_active=%s local=%s global=%s canvas=%s rendered_size=%s" % [
				str(icon.is_active()),
				str(icon.position),
				str(icon.global_position),
				str(icon.get_global_transform_with_canvas().origin),
				str(icon.get_rendered_size())
			])
			if sprite:
				file.store_line("sprite_local=%s global=%s canvas=%s scale=%s texture_size=%s" % [
					str(sprite.position),
					str(sprite.global_position),
					str(sprite.get_global_transform_with_canvas().origin),
					str(sprite.scale),
					str(sprite.texture.get_size() if sprite.texture else Vector2.ZERO)
				])
