class_name ScrollableButtonHandler
extends RefCounted

const QUICK_TAP_MAX_DURATION_MS := 180
const SCROLL_START_DURATION_MS := 181
const QUICK_TAP_MAX_MOVEMENT := 18.0

var _button_touch_states := {}

func register_button(button: Button, tap_action: Callable) -> void:
	if button == null:
		return
	button.gui_input.connect(func(event: InputEvent) -> void:
		_handle_input(button, event, tap_action)
	)

func clear_state(button: Button) -> void:
	if button == null:
		return
	_button_touch_states.erase(button.get_instance_id())

func is_quick_tap(duration_ms: int, drag_distance: float) -> bool:
	return duration_ms <= QUICK_TAP_MAX_DURATION_MS and drag_distance <= QUICK_TAP_MAX_MOVEMENT

func should_start_scroll(duration_ms: int, drag_distance: float) -> bool:
	return duration_ms >= SCROLL_START_DURATION_MS or drag_distance > QUICK_TAP_MAX_MOVEMENT

func _handle_input(button: Button, event: InputEvent, tap_action: Callable) -> void:
	if event is InputEventScreenTouch:
		_handle_touch_press(button, event, tap_action)
		return
	if event is InputEventScreenDrag:
		_handle_touch_drag(button, event)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_mouse_press(button, event, tap_action)
		return
	if event is InputEventMouseMotion:
		_handle_mouse_drag(button, event)

func _handle_touch_press(button: Button, event: InputEventScreenTouch, tap_action: Callable) -> void:
	var button_id = button.get_instance_id()
	if event.pressed:
		_button_touch_states[button_id] = {
			"pointer_id": event.index,
			"press_position": event.position,
			"last_position": event.position,
			"press_time_ms": Time.get_ticks_msec(),
			"scrolling": false,
			"tap_action": tap_action
		}
		return

	if not _button_touch_states.has(button_id):
		return
	var state: Dictionary = _button_touch_states[button_id]
	if state.pointer_id != event.index:
		return

	var duration_ms = Time.get_ticks_msec() - int(state.press_time_ms)
	var drag_distance = Vector2(state.press_position).distance_to(event.position)
	if is_quick_tap(duration_ms, drag_distance):
		tap_action.call()
	clear_state(button)

func _handle_touch_drag(button: Button, event: InputEventScreenDrag) -> void:
	var button_id = button.get_instance_id()
	if not _button_touch_states.has(button_id):
		return
	var state: Dictionary = _button_touch_states[button_id]
	if state.pointer_id != event.index:
		return

	var duration_ms = Time.get_ticks_msec() - int(state.press_time_ms)
	var drag_distance = Vector2(state.press_position).distance_to(event.position)
	if should_start_scroll(duration_ms, drag_distance):
		state.scrolling = true
		_scroll_button_parent(button, event.relative.y)
	state.last_position = event.position
	_button_touch_states[button_id] = state

func _handle_mouse_press(button: Button, event: InputEventMouseButton, tap_action: Callable) -> void:
	var button_id = button.get_instance_id()
	if event.pressed:
		_button_touch_states[button_id] = {
			"pointer_id": -1,
			"press_position": event.position,
			"last_position": event.position,
			"press_time_ms": Time.get_ticks_msec(),
			"scrolling": false,
			"tap_action": tap_action
		}
		return

	if not _button_touch_states.has(button_id):
		return
	var state: Dictionary = _button_touch_states[button_id]
	var duration_ms = Time.get_ticks_msec() - int(state.press_time_ms)
	var drag_distance = Vector2(state.press_position).distance_to(event.position)
	if is_quick_tap(duration_ms, drag_distance):
		tap_action.call()
	clear_state(button)

func _handle_mouse_drag(button: Button, event: InputEventMouseMotion) -> void:
	var button_id = button.get_instance_id()
	if not _button_touch_states.has(button_id):
		return
	if not (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		return

	var state: Dictionary = _button_touch_states[button_id]
	var duration_ms = Time.get_ticks_msec() - int(state.press_time_ms)
	var drag_distance = Vector2(state.press_position).distance_to(event.position)
	if should_start_scroll(duration_ms, drag_distance):
		state.scrolling = true
		_scroll_button_parent(button, event.relative.y)
	state.last_position = event.position
	_button_touch_states[button_id] = state

func _scroll_button_parent(button: Button, drag_delta_y: float) -> void:
	var scroll_container = _find_parent_scroll_container(button)
	if scroll_container:
		scroll_container.scroll_vertical = int(max(scroll_container.scroll_vertical - drag_delta_y, 0.0))

func _find_parent_scroll_container(control: Control) -> ScrollContainer:
	var parent = control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			return parent
		parent = parent.get_parent()
	return null
