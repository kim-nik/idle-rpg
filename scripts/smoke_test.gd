extends Node

const TEST_CASE_SCRIPTS := [
	"res://scripts/tests/bootstrap_layout_test.gd",
	"res://scripts/tests/progression_test.gd",
	"res://scripts/tests/ui_test.gd",
	"res://scripts/tests/navigation_smoke_test.gd",
	"res://scripts/tests/persistence_test.gd",
	"res://scripts/tests/boss_fight_test.gd",
	"res://scripts/tests/combat_wave_test.gd",
	"res://scripts/tests/combat_feedback_test.gd",
	"res://scripts/tests/ability_system_test.gd"
]

var tests_passed: int = 0
var tests_failed: int = 0
var assertion_failures: int = 0

func _ready() -> void:
	await run_smoke_test()

func run_smoke_test() -> void:
	print("=== SMOKE TEST STARTED ===")
	if not _verify_script_compilation():
		push_error("Smoke test FAILED during script compilation preflight")
		get_tree().quit(1)
		return

	var environment_script = load("res://scripts/tests/test_environment.gd")
	if environment_script == null:
		push_error("Smoke test environment failed to load")
		get_tree().quit(1)
		return

	var environment = environment_script.new(self)

	for script_path in TEST_CASE_SCRIPTS:
		var test_script = load(script_path)
		if test_script == null:
			tests_failed += 1
			assertion_failures += 1
			push_error("Failed to load test case: %s" % script_path)
			continue

		var test_case = test_script.new()
		var case_name := test_case.get_name()
		var failures: Array[String] = await test_case.run(environment)

		if failures.is_empty():
			tests_passed += 1
			print("  %s: OK" % case_name)
		else:
			tests_failed += 1
			assertion_failures += failures.size()
			push_error("%s: FAILED" % case_name)
			for failure in failures:
				push_error("    - %s" % failure)

		await environment.clear_main_scene()
		await get_tree().process_frame

	await environment.restore_original_state()

	print("=== SMOKE TEST RESULTS ===")
	print("Cases passed: %d | Cases failed: %d | Assertions failed: %d" % [
		tests_passed,
		tests_failed,
		assertion_failures
	])

	if tests_failed > 0:
		push_error("Smoke test FAILED")
		get_tree().quit(1)
	else:
		print("Smoke test PASSED")
		get_tree().quit(0)

func _verify_script_compilation() -> bool:
	var script_paths: Array[String] = []
	_collect_gd_scripts("res://scripts", script_paths)
	script_paths.sort()

	var all_loaded := true
	for script_path in script_paths:
		var script_resource = load(script_path)
		if script_resource == null:
			all_loaded = false
			push_error("Failed to load script during smoke preflight: %s" % script_path)
	return all_loaded

func _collect_gd_scripts(path: String, output: Array[String]) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		push_error("Smoke preflight could not open directory: %s" % path)
		return

	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry.begins_with("."):
			entry = directory.get_next()
			continue

		var child_path = "%s/%s" % [path, entry]
		if directory.current_is_dir():
			_collect_gd_scripts(child_path, output)
		elif entry.ends_with(".gd"):
			output.append(child_path)
		entry = directory.get_next()
	directory.list_dir_end()
