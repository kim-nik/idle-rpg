extends "res://scripts/tests/test_case.gd"

const TEST_NOW := 1_700_003_660
const LAST_SEEN := 1_700_000_000

func get_name() -> String:
	return "afk rewards"

func run(environment) -> Array[String]:
	var failures: Array[String] = []
	var save_manager = environment.save_manager
	var main_scene: Node

	environment.reset_progress()
	var current_now := TEST_NOW
	save_manager.set_time_provider(func() -> int:
		return current_now
	)

	save_manager.save_data.campaign_chapter = 3
	save_manager.save_data.campaign_wave = 7
	save_manager.save_data.last_seen_unix = LAST_SEEN
	save_manager.save_data.pending_afk_gold = 0
	save_manager.save_data.pending_afk_seconds = 0
	save_manager.save()

	var main_scene_loaded: bool = await environment.instantiate_main_scene()
	_expect(main_scene_loaded, "Main scene failed to instantiate for AFK reward test", failures)
	if not main_scene_loaded:
		save_manager.clear_time_provider()
		return failures

	environment.stabilize_main_scene()
	main_scene = environment.main_scene
	var ui = environment.get_ui()
	_expect(ui != null, "UI controller is unavailable for AFK reward test", failures)
	if ui == null:
		save_manager.clear_time_provider()
		return failures

	ui._update_ui()

	var expected_seconds = TEST_NOW - LAST_SEEN
	var expected_minutes = int(expected_seconds / 60)
	var expected_reward = expected_minutes * (3 * 100 + 7 * 25)

	_expect(save_manager.save_data.pending_afk_seconds == expected_seconds, "AFK seconds were not queued", failures)
	_expect(save_manager.save_data.pending_afk_gold == expected_reward, "AFK gold was not queued", failures)
	_expect(save_manager.save_data.last_seen_unix == TEST_NOW, "AFK queue did not refresh last seen time", failures)
	_expect(ui.afk_popup_overlay_root.visible, "AFK popup should be visible when rewards are pending", failures)
	_expect(
		ui.afk_popup_duration_label.text == "Away for 1h 1m at Chapter 3, Wave 7.",
		"AFK popup did not show the expected duration and stage",
		failures
	)
	_expect(
		ui.afk_popup_gold_label.text == "Earned %d gold." % expected_reward,
		"AFK popup did not show the expected gold reward",
		failures
	)

	ui._on_collect_afk_rewards_pressed()
	ui._update_ui()

	_expect(save_manager.save_data.gold == expected_reward, "Collecting AFK rewards did not grant gold", failures)
	_expect(save_manager.save_data.pending_afk_gold == 0, "Collecting AFK rewards did not clear pending gold", failures)
	_expect(save_manager.save_data.pending_afk_seconds == 0, "Collecting AFK rewards did not clear pending time", failures)
	_expect(not ui.afk_popup_overlay_root.visible, "AFK popup should hide after collecting rewards", failures)
	_expect(ui.gold_label.text == "Gold: %d" % expected_reward, "Top gold label did not refresh after AFK collect", failures)
	ui.set_active_tab(ui.TAB_DEBUG)
	ui._on_simulate_afk_rewards_pressed()
	ui._update_ui()
	var debug_reward = 60 * (3 * 100 + 7 * 25)
	_expect(save_manager.save_data.pending_afk_seconds == 3600, "Debug AFK button should queue exactly one hour", failures)
	_expect(save_manager.save_data.pending_afk_gold == debug_reward, "Debug AFK button queued the wrong gold reward", failures)
	_expect(ui.afk_popup_overlay_root.visible, "Debug AFK button should reopen the AFK popup", failures)

	ui._on_collect_afk_rewards_pressed()
	ui._update_ui()
	save_manager.save_data.last_seen_unix = TEST_NOW - 120
	save_manager.save_data.pending_afk_gold = 0
	save_manager.save_data.pending_afk_seconds = 0
	save_manager.save()
	current_now = TEST_NOW + 120
	main_scene._queue_afk_rewards()
	ui._update_ui()
	var resume_reward = 2 * (3 * 100 + 7 * 25)
	_expect(save_manager.save_data.pending_afk_seconds == 120, "Resume should queue AFK time after a background pause", failures)
	_expect(save_manager.save_data.pending_afk_gold == resume_reward, "Resume queued the wrong AFK reward", failures)
	_expect(ui.afk_popup_overlay_root.visible, "Resume should reopen the AFK popup when rewards are pending", failures)

	save_manager.clear_time_provider()
	return failures
