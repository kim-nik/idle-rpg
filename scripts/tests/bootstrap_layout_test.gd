extends "res://scripts/tests/test_case.gd"

func get_name() -> String:
	return "bootstrap and layout"

func run(environment) -> Array[String]:
	var failures: Array[String] = []

	_expect(environment.has_autoloads(), "Autoloads SaveManager and UpgradeSystem are missing", failures)
	if not failures.is_empty():
		return failures

	environment.reset_progress()
	var main_scene_loaded: bool = await environment.instantiate_main_scene()
	_expect(main_scene_loaded, "Main scene resource failed to load", failures)
	if not main_scene_loaded:
		return failures

	var hero = environment.get_hero()
	var wave_manager = environment.get_wave_manager()
	var ui = environment.get_ui()

	_expect(hero != null, "Hero node not found in Main scene", failures)
	_expect(wave_manager != null, "WaveManager node not found in Main scene", failures)
	_expect(ui != null, "UIArea node not found in Main scene", failures)

	environment.stabilize_main_scene()

	var combat_background = environment.main_scene.get_node_or_null("ArenaBackground") as ColorRect
	var divider = environment.main_scene.get_node_or_null("ArenaDivider") as ColorRect
	var panel = environment.main_scene.get_node_or_null("UIArea/Panel") as Panel
	var viewport_width = int(ProjectSettings.get_setting("display/window/size/viewport_width", 0))
	var viewport_height = int(ProjectSettings.get_setting("display/window/size/viewport_height", 0))
	var orientation = int(ProjectSettings.get_setting("display/window/handheld/orientation", -1))

	_expect(viewport_width == 1080, "Project width must stay at 1080", failures)
	_expect(viewport_height == 1920, "Project height must stay at 1920", failures)
	_expect(orientation == 1, "Handheld orientation must stay portrait", failures)
	_expect(combat_background != null, "Arena background node is missing", failures)
	_expect(divider != null, "Arena divider node is missing", failures)
	_expect(panel != null, "UI panel node is missing", failures)

	if combat_background:
		_expect(is_equal_approx(combat_background.size.y, 960.0), "Combat area is not half-screen height", failures)
	if divider:
		_expect(is_equal_approx(divider.position.y, 960.0), "Arena divider is not centered vertically", failures)
	if panel:
		_expect(is_equal_approx(panel.position.y, 960.0), "UI panel does not start at half-screen", failures)
		_expect(is_equal_approx(panel.size.y, 960.0), "UI panel does not fill the bottom half", failures)

	var upgrade_container = environment.main_scene.get_node_or_null(
		"UIArea/Panel/MarginContainer/Content/UpgradeContainer"
	) as VBoxContainer
	var debug_button = environment.main_scene.get_node_or_null(
		"UIArea/Panel/MarginContainer/Content/UpgradeContainer/DebugGoldButton"
	) as Button
	var reset_button = environment.main_scene.get_node_or_null(
		"UIArea/Panel/MarginContainer/Content/UpgradeContainer/ResetProgressButton"
	) as Button

	_expect(upgrade_container != null, "Upgrade stack is missing", failures)
	_expect(debug_button != null, "Debug gold button is missing", failures)
	_expect(reset_button != null, "Reset progress button is missing", failures)

	if upgrade_container and debug_button:
		_expect(debug_button.get_parent() == upgrade_container, "Debug button is outside the upgrade stack", failures)
	if upgrade_container and reset_button:
		_expect(reset_button.get_parent() == upgrade_container, "Reset button is outside the upgrade stack", failures)

	if upgrade_container:
		for child in upgrade_container.get_children():
			var button = child as Button
			if button:
				_expect(
					button.size_flags_horizontal == Control.SIZE_EXPAND_FILL,
					"%s does not fill available width" % button.name,
					failures
				)

	return failures
