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
	var top_wave_banner = environment.main_scene.get_node_or_null("UIArea/TopWaveBanner") as Panel
	var top_wave_label = environment.main_scene.get_node_or_null("UIArea/TopWaveBanner/TopWaveLabel") as Label
	var gold_label = environment.main_scene.get_node_or_null("UIArea/TopWaveBanner/GoldLabel") as Label
	var campaign_status_label = environment.main_scene.get_node_or_null(
		"UIArea/Panel/MarginContainer/Content/StatsContainer/CampaignStatusLabel"
	) as Label
	var tab_bar = environment.main_scene.get_node_or_null("UIArea/Panel/MarginContainer/Content/TabBar") as HBoxContainer
	var upgrades_scroll = environment.main_scene.get_node_or_null(
		"UIArea/Panel/MarginContainer/Content/TabContentContainer/TabViewport/UpgradesScroll"
	) as ScrollContainer
	var abilities_scroll = environment.main_scene.get_node_or_null(
		"UIArea/Panel/MarginContainer/Content/TabContentContainer/TabViewport/AbilitiesScroll"
	) as ScrollContainer
	var map_scroll = environment.main_scene.get_node_or_null(
		"UIArea/Panel/MarginContainer/Content/TabContentContainer/TabViewport/MapScroll"
	) as ScrollContainer
	var settings_scroll = environment.main_scene.get_node_or_null(
		"UIArea/Panel/MarginContainer/Content/TabContentContainer/TabViewport/SettingsScroll"
	) as ScrollContainer
	var viewport_width = int(ProjectSettings.get_setting("display/window/size/viewport_width", 0))
	var viewport_height = int(ProjectSettings.get_setting("display/window/size/viewport_height", 0))
	var orientation = int(ProjectSettings.get_setting("display/window/handheld/orientation", -1))

	_expect(viewport_width == 1080, "Project width must stay at 1080", failures)
	_expect(viewport_height == 1920, "Project height must stay at 1920", failures)
	_expect(orientation == 1, "Handheld orientation must stay portrait", failures)
	_expect(combat_background != null, "Arena background node is missing", failures)
	_expect(divider != null, "Arena divider node is missing", failures)
	_expect(panel != null, "UI panel node is missing", failures)
	_expect(top_wave_banner != null, "Top wave banner is missing", failures)
	_expect(top_wave_label != null, "Top wave label is missing", failures)
	_expect(gold_label != null, "Top banner gold label is missing", failures)
	_expect(campaign_status_label != null, "Campaign status label is missing", failures)
	_expect(tab_bar != null, "Tab bar is missing", failures)
	_expect(upgrades_scroll != null, "Upgrades scroll container is missing", failures)
	_expect(abilities_scroll != null, "Abilities scroll container is missing", failures)
	_expect(map_scroll != null, "Map scroll container is missing", failures)
	_expect(settings_scroll != null, "Settings scroll container is missing", failures)

	if combat_background:
		_expect(is_equal_approx(combat_background.size.y, 960.0), "Combat area is not half-screen height", failures)
	if divider:
		_expect(is_equal_approx(divider.position.y, 960.0), "Arena divider is not centered vertically", failures)
	if panel:
		_expect(is_equal_approx(panel.position.y, 960.0), "UI panel does not start at half-screen", failures)
		_expect(is_equal_approx(panel.size.y, 960.0), "UI panel does not fill the bottom half", failures)
	if top_wave_banner:
		_expect(top_wave_banner.position.y < 120.0, "Top wave banner should remain near the top of the screen", failures)
	if top_wave_banner and gold_label:
		_expect(
			gold_label.get_parent() == top_wave_banner,
			"Gold label should live inside the top wave banner",
			failures
		)

	var upgrade_container = environment.main_scene.get_node_or_null(
		"UIArea/Panel/MarginContainer/Content/TabContentContainer/TabViewport/UpgradesScroll/UpgradesTab/UpgradeContainer"
	) as VBoxContainer
	var debug_row = environment.main_scene.get_node_or_null(
		"UIArea/Panel/MarginContainer/Content/TabContentContainer/TabViewport/UpgradesScroll/UpgradesTab/UpgradeContainer/DebugGoldRow"
	) as HBoxContainer
	var armor_row = environment.main_scene.get_node_or_null(
		"UIArea/Panel/MarginContainer/Content/TabContentContainer/TabViewport/UpgradesScroll/UpgradesTab/UpgradeContainer/ArmorRow"
	) as HBoxContainer
	var regen_row = environment.main_scene.get_node_or_null(
		"UIArea/Panel/MarginContainer/Content/TabContentContainer/TabViewport/UpgradesScroll/UpgradesTab/UpgradeContainer/RegenRow"
	) as HBoxContainer
	var reset_row = environment.main_scene.get_node_or_null(
		"UIArea/Panel/MarginContainer/Content/TabContentContainer/TabViewport/UpgradesScroll/UpgradesTab/UpgradeContainer/ResetProgressRow"
	) as HBoxContainer

	_expect(upgrade_container != null, "Upgrade stack is missing", failures)
	_expect(armor_row != null, "Armor row is missing", failures)
	_expect(regen_row != null, "Regen row is missing", failures)
	_expect(debug_row != null, "Debug gold row is missing", failures)
	_expect(reset_row != null, "Reset progress row is missing", failures)
	if upgrades_scroll:
		_expect(not upgrades_scroll.horizontal_scroll_mode, "Upgrades tab should not scroll horizontally", failures)
	if tab_bar:
		_expect(tab_bar.get_child_count() == 4, "Tab bar should contain four buttons", failures)
	if settings_scroll:
		_expect(not settings_scroll.visible, "Settings tab should be hidden by default", failures)

	if upgrade_container and debug_row:
		_expect(debug_row.get_parent() == upgrade_container, "Debug row is outside the upgrade stack", failures)
	if upgrade_container and reset_row:
		_expect(reset_row.get_parent() == upgrade_container, "Reset row is outside the upgrade stack", failures)

	if upgrade_container:
		for child in upgrade_container.get_children():
			var row = child as HBoxContainer
			_expect(row != null, "%s is not an HBoxContainer row" % child.name, failures)
			if row == null:
				continue
			_expect(row.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "%s row does not fill width" % row.name, failures)
			_expect(row.get_child_count() == 3, "%s should contain main, x10 and x100 buttons" % row.name, failures)
			for row_child in row.get_children():
				var button = row_child as Button
				_expect(button != null, "%s contains a non-button child" % row.name, failures)
				if button and button.name.ends_with("Button") and not button.name.contains("X"):
					_expect(
						button.size_flags_horizontal == Control.SIZE_EXPAND_FILL,
						"%s does not fill available width" % button.name,
						failures
					)
					_expect(button.custom_minimum_size.y >= 88.0, "%s should use taller upgrade cards" % button.name, failures)

	if ui:
		_expect(ui.map_wave_buttons.size() == 10, "Map tab should expose 10 wave buttons", failures)
		_expect(ui.map_boss_button != null, "Map tab is missing the boss button", failures)
		_expect(ui.map_start_selected_button != null, "Map tab is missing the start button", failures)
		_expect(ui.settings_auto_next_wave_toggle != null, "Settings tab is missing Auto Next Wave toggle", failures)
		_expect(ui.settings_auto_start_boss_toggle != null, "Settings tab is missing Auto Start Boss toggle", failures)

	return failures
