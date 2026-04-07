extends RefCounted

func get_name() -> String:
	return "Unnamed test case"

func run(_environment) -> Array[String]:
	return []

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
