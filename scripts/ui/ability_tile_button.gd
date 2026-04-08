extends Button

var ability_id: String = ""
var tile_role: String = "library"
var slot_index: int = -1

func _ready() -> void:
	pressed.connect(_on_pressed)

func configure(next_ability_id: String, next_tile_role: String, next_slot_index: int = -1) -> void:
	ability_id = next_ability_id
	tile_role = next_tile_role
	slot_index = next_slot_index

func _on_pressed() -> void:
	var controller = _find_ui_controller()
	if controller:
		controller.on_ability_tile_pressed(self)

func _get_drag_data(_at_position: Vector2):
	if ability_id.is_empty():
		return null
	var controller = _find_ui_controller()
	if controller == null:
		return null

	var preview := Label.new()
	preview.text = controller.get_ability_drag_preview_text(ability_id)
	preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview.custom_minimum_size = Vector2(120, 40)
	set_drag_preview(preview)
	return {
		"ability_id": ability_id,
		"source_role": tile_role,
		"source_slot_index": slot_index
	}

func _can_drop_data(_at_position: Vector2, data) -> bool:
	var controller = _find_ui_controller()
	if controller == null:
		return false
	return controller.can_drop_ability_tile(self, data)

func _drop_data(_at_position: Vector2, data) -> void:
	var controller = _find_ui_controller()
	if controller:
		controller.drop_ability_tile(self, data)

func _find_ui_controller():
	var node = get_parent()
	while node != null:
		if node.is_in_group("ui_controller"):
			return node
		node = node.get_parent()
	return null
