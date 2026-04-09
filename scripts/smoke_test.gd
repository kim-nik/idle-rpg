extends Node

const TEST_CASE_SCRIPTS := [
	"res://scripts/tests/bootstrap_layout_test.gd",
	"res://scripts/tests/progression_test.gd",
	"res://scripts/tests/ui_test.gd",
	"res://scripts/tests/navigation_smoke_test.gd",
	"res://scripts/tests/persistence_test.gd",
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
