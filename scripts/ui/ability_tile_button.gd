extends Button

var ability_id: String = ""
var tile_role: String = "library"
var slot_index: int = -1
var icon_rect: TextureRect
var name_label: Label
var cooldown_label: Label

func _ready() -> void:
	_ensure_initialized()

func configure(next_ability_id: String, next_tile_role: String, next_slot_index: int = -1) -> void:
	_ensure_initialized()
	ability_id = next_ability_id
	tile_role = next_tile_role
	slot_index = next_slot_index

func set_visual_state(icon: Texture2D, ability_name: String, cooldown_text: String, is_empty: bool) -> void:
	_ensure_initialized()
	icon_rect.texture = icon
	icon_rect.visible = icon != null
	name_label.text = ability_name
	cooldown_label.text = cooldown_text
	disabled = false
	modulate = Color(1, 1, 1, 1) if not is_empty else Color(0.9, 0.9, 0.9, 1)

func get_display_name() -> String:
	return "" if name_label == null else name_label.text

func get_display_cooldown() -> String:
	return "" if cooldown_label == null else cooldown_label.text

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

func _create_layout() -> void:
	if icon_rect != null:
		return
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)

	icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(52, 52)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon_rect)

	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(name_label)

	cooldown_label = Label.new()
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cooldown_label.clip_text = true
	cooldown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(cooldown_label)

func _ensure_initialized() -> void:
	text = ""
	clip_text = false
	_create_layout()
	var pressed_callable := Callable(self, "_on_pressed")
	if not is_connected("pressed", pressed_callable):
		pressed.connect(_on_pressed)
