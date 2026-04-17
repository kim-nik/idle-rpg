extends RefCounted

const MAIN_SCENE_PATH := "res://scenes/Main.tscn"

var runner: Node
var save_manager: Node
var upgrade_system: Node
var ability_system: Node
var main_scene: Node
var original_save_data: Dictionary = {}

func _init(test_runner: Node) -> void:
	runner = test_runner
	save_manager = runner.get_node_or_null("/root/SaveManager")
	upgrade_system = runner.get_node_or_null("/root/UpgradeSystem")
	ability_system = runner.get_node_or_null("/root/AbilitySystem")
	if save_manager:
		original_save_data = save_manager.save_data.duplicate(true)

func has_autoloads() -> bool:
	return save_manager != null and upgrade_system != null and ability_system != null

func reset_progress() -> void:
	if not has_autoloads():
		return

	if save_manager and save_manager.has_method("clear_time_provider"):
		save_manager.clear_time_provider()
	save_manager.reset()
	upgrade_system.load_from_save()
	ability_system.load_from_save()

func instantiate_main_scene() -> bool:
	await clear_main_scene()

	var main_scene_resource := load(MAIN_SCENE_PATH) as PackedScene
	if main_scene_resource == null:
		return false

	main_scene = main_scene_resource.instantiate()
	main_scene.name = "MainUnderTest"
	runner.add_child(main_scene)
	await runner.get_tree().process_frame
	return true

func stabilize_main_scene() -> void:
	if not is_instance_valid(main_scene):
		return

	main_scene.set_process(false)

	var hero = get_hero()
	if hero:
		hero.set_process(false)

	var wave_manager = get_wave_manager()
	if wave_manager:
		wave_manager.set_process(false)

	var ui = get_ui()
	if ui:
		ui.set_process(false)

func clear_main_scene() -> void:
	if is_instance_valid(main_scene):
		main_scene.queue_free()
		await runner.get_tree().process_frame
	main_scene = null

func restore_original_state() -> void:
	await clear_main_scene()

	if save_manager:
		if save_manager.has_method("clear_time_provider"):
			save_manager.clear_time_provider()
		save_manager.save_data = original_save_data.duplicate(true)
		save_manager.save()

	if upgrade_system:
		upgrade_system.load_from_save()
	if ability_system:
		ability_system.load_from_save()

func clear_monsters() -> void:
	var monster_container = get_monster_container()
	if monster_container == null:
		return

	for child in monster_container.get_children():
		child.queue_free()

	await runner.get_tree().process_frame

func get_hero() -> Node2D:
	if not is_instance_valid(main_scene):
		return null
	return main_scene.get_node_or_null("CombatArea/Hero")

func get_wave_manager() -> Node:
	if not is_instance_valid(main_scene):
		return null
	return main_scene.get_node_or_null("WaveManager")

func get_ui() -> CanvasLayer:
	if not is_instance_valid(main_scene):
		return null
	return main_scene.get_node_or_null("UIArea")

func get_monster_container() -> Node:
	if not is_instance_valid(main_scene):
		return null
	return main_scene.get_node_or_null("CombatArea/Monsters")
