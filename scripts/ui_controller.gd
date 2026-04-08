extends CanvasLayer

signal upgrade_clicked(upgrade_name: String)

const TAB_UPGRADES := "upgrades"
const TAB_ABILITIES := "abilities"
const TAB_MAP := "map"
const QUICK_TAP_MAX_DURATION_MS := 180
const SCROLL_START_DURATION_MS := 181
const QUICK_TAP_MAX_MOVEMENT := 18.0
const ABILITY_TILE_SCRIPT := preload("res://scripts/ui/ability_tile_button.gd")
const ABILITY_TILE_SIZE := Vector2(0, 144)
const ABILITY_TILE_EMPTY_TEXT := "Empty"
const ABILITY_NAME_MAX_CHARS := 12

@onready var top_wave_label: Label = $TopWaveBanner/TopWaveLabel
@onready var gold_label: Label = $Panel/MarginContainer/Content/StatsContainer/GoldLabel
@onready var wave_label: Label = $Panel/MarginContainer/Content/StatsContainer/WaveLabel
@onready var hero_stats_label: Label = $Panel/MarginContainer/Content/StatsContainer/HeroStatsLabel

@onready var upgrades_scroll: ScrollContainer = $Panel/MarginContainer/Content/TabContentContainer/TabViewport/UpgradesScroll
@onready var abilities_scroll: ScrollContainer = $Panel/MarginContainer/Content/TabContentContainer/TabViewport/AbilitiesScroll
@onready var map_scroll: ScrollContainer = $Panel/MarginContainer/Content/TabContentContainer/TabViewport/MapScroll

@onready var upgrades_tab_root: Control = upgrades_scroll.get_node("UpgradesTab")
@onready var abilities_tab_root: Control = abilities_scroll.get_node("AbilitiesTab")

@onready var upgrades_tab_button: Button = $Panel/MarginContainer/Content/TabBar/UpgradesTabButton
@onready var abilities_tab_button: Button = $Panel/MarginContainer/Content/TabBar/AbilitiesTabButton
@onready var map_tab_button: Button = $Panel/MarginContainer/Content/TabBar/MapTabButton

var damage_btn: Button
var damage_x10_btn: Button
var damage_x100_btn: Button
var speed_btn: Button
var speed_x10_btn: Button
var speed_x100_btn: Button
var hp_btn: Button
var hp_x10_btn: Button
var hp_x100_btn: Button
var armor_btn: Button
var armor_x10_btn: Button
var armor_x100_btn: Button
var regen_btn: Button
var regen_x10_btn: Button
var regen_x100_btn: Button
var crit_chance_btn: Button
var crit_chance_x10_btn: Button
var crit_chance_x100_btn: Button
var crit_dmg_btn: Button
var crit_dmg_x10_btn: Button
var crit_dmg_x100_btn: Button
var debug_gold_btn: Button
var debug_gold_x10_btn: Button
var debug_gold_x100_btn: Button
var reset_progress_btn: Button
var reset_progress_x10_btn: Button
var reset_progress_x100_btn: Button

var ability_slot_buttons: Array[Button] = []
var ability_library_buttons: Dictionary = {}
var ability_library_grid: GridContainer
var ability_popup_overlay: ColorRect
var ability_popup_title_label: Label
var ability_popup_description_label: Label
var ability_popup_meta_label: Label
var ability_popup_status_label: Label
var ability_popup_close_button: Button
var ability_popup_action_button: Button

var upgrade_system
var save_manager
var ability_system
var active_tab: String = TAB_UPGRADES
var button_touch_states := {}
var selected_ability_id: String = ""
var selected_ability_source_role: String = "library"
var selected_ability_slot_index: int = -1

func _ready() -> void:
	add_to_group("ui_controller")
	save_manager = get_node("/root/SaveManager")
	upgrade_system = get_node("/root/UpgradeSystem")
	ability_system = get_node("/root/AbilitySystem")

	_cache_upgrade_controls()
	_cache_ability_controls()
	_bind_upgrade_buttons()
	_bind_ability_buttons()
	_bind_tab_buttons()
	set_active_tab(TAB_UPGRADES)
	_update_ui()

func _process(_delta: float) -> void:
	_update_ui()

func _cache_upgrade_controls() -> void:
	var upgrade_container = upgrades_tab_root.get_node("UpgradeContainer")
	damage_btn = upgrade_container.get_node("DamageRow/DamageButton")
	damage_x10_btn = upgrade_container.get_node("DamageRow/DamageX10Button")
	damage_x100_btn = upgrade_container.get_node("DamageRow/DamageX100Button")
	speed_btn = upgrade_container.get_node("SpeedRow/SpeedButton")
	speed_x10_btn = upgrade_container.get_node("SpeedRow/SpeedX10Button")
	speed_x100_btn = upgrade_container.get_node("SpeedRow/SpeedX100Button")
	hp_btn = upgrade_container.get_node("HpRow/HpButton")
	hp_x10_btn = upgrade_container.get_node("HpRow/HpX10Button")
	hp_x100_btn = upgrade_container.get_node("HpRow/HpX100Button")
	armor_btn = upgrade_container.get_node("ArmorRow/ArmorButton")
	armor_x10_btn = upgrade_container.get_node("ArmorRow/ArmorX10Button")
	armor_x100_btn = upgrade_container.get_node("ArmorRow/ArmorX100Button")
	regen_btn = upgrade_container.get_node("RegenRow/RegenButton")
	regen_x10_btn = upgrade_container.get_node("RegenRow/RegenX10Button")
	regen_x100_btn = upgrade_container.get_node("RegenRow/RegenX100Button")
	crit_chance_btn = upgrade_container.get_node("CritChanceRow/CritChanceButton")
	crit_chance_x10_btn = upgrade_container.get_node("CritChanceRow/CritChanceX10Button")
	crit_chance_x100_btn = upgrade_container.get_node("CritChanceRow/CritChanceX100Button")
	crit_dmg_btn = upgrade_container.get_node("CritDmgRow/CritDmgButton")
	crit_dmg_x10_btn = upgrade_container.get_node("CritDmgRow/CritDmgX10Button")
	crit_dmg_x100_btn = upgrade_container.get_node("CritDmgRow/CritDmgX100Button")
	debug_gold_btn = upgrade_container.get_node("DebugGoldRow/DebugGoldButton")
	debug_gold_x10_btn = upgrade_container.get_node("DebugGoldRow/DebugGoldX10Button")
	debug_gold_x100_btn = upgrade_container.get_node("DebugGoldRow/DebugGoldX100Button")
	reset_progress_btn = upgrade_container.get_node("ResetProgressRow/ResetProgressButton")
	reset_progress_x10_btn = upgrade_container.get_node("ResetProgressRow/ResetProgressX10Button")
	reset_progress_x100_btn = upgrade_container.get_node("ResetProgressRow/ResetProgressX100Button")

func _cache_ability_controls() -> void:
	var slot_grid = abilities_tab_root.get_node("SlotGrid")
	for child in slot_grid.get_children():
		var tile = child as Button
		if tile:
			tile.set_script(ABILITY_TILE_SCRIPT)
			tile.custom_minimum_size = ABILITY_TILE_SIZE
			tile.clip_text = true
			tile.alignment = HORIZONTAL_ALIGNMENT_CENTER
			ability_slot_buttons.append(tile)

	ability_library_grid = abilities_tab_root.get_node("LibraryGrid")
	ability_popup_overlay = abilities_tab_root.get_node("PopupOverlay")
	ability_popup_title_label = abilities_tab_root.get_node("PopupOverlay/PopupPanel/PopupMargin/PopupContent/PopupTitleLabel")
	ability_popup_description_label = abilities_tab_root.get_node("PopupOverlay/PopupPanel/PopupMargin/PopupContent/PopupDescriptionLabel")
	ability_popup_meta_label = abilities_tab_root.get_node("PopupOverlay/PopupPanel/PopupMargin/PopupContent/PopupMetaLabel")
	ability_popup_status_label = abilities_tab_root.get_node("PopupOverlay/PopupPanel/PopupMargin/PopupContent/PopupStatusLabel")
	ability_popup_close_button = abilities_tab_root.get_node("PopupOverlay/PopupPanel/PopupMargin/PopupContent/PopupButtons/PopupCloseButton")
	ability_popup_action_button = abilities_tab_root.get_node("PopupOverlay/PopupPanel/PopupMargin/PopupContent/PopupButtons/PopupActionButton")

func _bind_upgrade_buttons() -> void:
	_register_scrollable_button(damage_btn, _on_damage_clicked)
	_register_scrollable_button(damage_x10_btn, func() -> void: _purchase_upgrade_multiple("damage", 10))
	_register_scrollable_button(damage_x100_btn, func() -> void: _purchase_upgrade_multiple("damage", 100))
	_register_scrollable_button(speed_btn, _on_speed_clicked)
	_register_scrollable_button(speed_x10_btn, func() -> void: _purchase_upgrade_multiple("attack_speed", 10))
	_register_scrollable_button(speed_x100_btn, func() -> void: _purchase_upgrade_multiple("attack_speed", 100))
	_register_scrollable_button(hp_btn, _on_hp_clicked)
	_register_scrollable_button(hp_x10_btn, func() -> void: _purchase_upgrade_multiple("max_hp", 10))
	_register_scrollable_button(hp_x100_btn, func() -> void: _purchase_upgrade_multiple("max_hp", 100))
	_register_scrollable_button(armor_btn, _on_armor_clicked)
	_register_scrollable_button(armor_x10_btn, func() -> void: _purchase_upgrade_multiple("armor", 10))
	_register_scrollable_button(armor_x100_btn, func() -> void: _purchase_upgrade_multiple("armor", 100))
	_register_scrollable_button(regen_btn, _on_regen_clicked)
	_register_scrollable_button(regen_x10_btn, func() -> void: _purchase_upgrade_multiple("health_regen", 10))
	_register_scrollable_button(regen_x100_btn, func() -> void: _purchase_upgrade_multiple("health_regen", 100))
	_register_scrollable_button(crit_chance_btn, _on_crit_chance_clicked)
	_register_scrollable_button(crit_chance_x10_btn, func() -> void: _purchase_upgrade_multiple("crit_chance", 10))
	_register_scrollable_button(crit_chance_x100_btn, func() -> void: _purchase_upgrade_multiple("crit_chance", 100))
	_register_scrollable_button(crit_dmg_btn, _on_crit_dmg_clicked)
	_register_scrollable_button(crit_dmg_x10_btn, func() -> void: _purchase_upgrade_multiple("crit_damage", 10))
	_register_scrollable_button(crit_dmg_x100_btn, func() -> void: _purchase_upgrade_multiple("crit_damage", 100))
	_register_scrollable_button(debug_gold_btn, _on_debug_gold_clicked)
	_register_scrollable_button(debug_gold_x10_btn, func() -> void: _add_debug_gold(10))
	_register_scrollable_button(debug_gold_x100_btn, func() -> void: _add_debug_gold(100))
	_register_scrollable_button(reset_progress_btn, _on_reset_progress_clicked)
	_register_scrollable_button(reset_progress_x10_btn, func() -> void: _reset_progress_multiple(10))
	_register_scrollable_button(reset_progress_x100_btn, func() -> void: _reset_progress_multiple(100))

func _bind_ability_buttons() -> void:
	_register_scrollable_button(ability_popup_close_button, _close_ability_popup)
	_register_scrollable_button(ability_popup_action_button, _on_popup_ability_action_pressed)
	_rebuild_ability_library()
	for index in range(ability_slot_buttons.size()):
		ability_slot_buttons[index].configure("", "slot", index)

func _bind_tab_buttons() -> void:
	upgrades_tab_button.pressed.connect(func() -> void: set_active_tab(TAB_UPGRADES))
	abilities_tab_button.pressed.connect(func() -> void: set_active_tab(TAB_ABILITIES))
	map_tab_button.pressed.connect(func() -> void: set_active_tab(TAB_MAP))

func _register_scrollable_button(button: Button, tap_action: Callable) -> void:
	button.gui_input.connect(func(event: InputEvent) -> void:
		_handle_scrollable_button_input(button, event, tap_action)
	)

func _handle_scrollable_button_input(button: Button, event: InputEvent, tap_action: Callable) -> void:
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
		button_touch_states[button_id] = {
			"pointer_id": event.index,
			"press_position": event.position,
			"last_position": event.position,
			"press_time_ms": Time.get_ticks_msec(),
			"scrolling": false,
			"tap_action": tap_action
		}
		return

	if not button_touch_states.has(button_id):
		return
	var state: Dictionary = button_touch_states[button_id]
	if state.pointer_id != event.index:
		return
	var duration_ms = Time.get_ticks_msec() - int(state.press_time_ms)
	var drag_distance = Vector2(state.press_position).distance_to(event.position)
	if _is_quick_tap(duration_ms, drag_distance):
		tap_action.call()
	_clear_button_touch_state(button)

func _handle_touch_drag(button: Button, event: InputEventScreenDrag) -> void:
	var button_id = button.get_instance_id()
	if not button_touch_states.has(button_id):
		return
	var state: Dictionary = button_touch_states[button_id]
	if state.pointer_id != event.index:
		return
	var duration_ms = Time.get_ticks_msec() - int(state.press_time_ms)
	var drag_distance = Vector2(state.press_position).distance_to(event.position)
	if _should_start_scroll(duration_ms, drag_distance):
		state.scrolling = true
		_scroll_button_parent(button, event.relative.y)
	state.last_position = event.position
	button_touch_states[button_id] = state

func _handle_mouse_press(button: Button, event: InputEventMouseButton, tap_action: Callable) -> void:
	var button_id = button.get_instance_id()
	if event.pressed:
		button_touch_states[button_id] = {
			"pointer_id": -1,
			"press_position": event.position,
			"last_position": event.position,
			"press_time_ms": Time.get_ticks_msec(),
			"scrolling": false,
			"tap_action": tap_action
		}
		return

	if not button_touch_states.has(button_id):
		return
	var state: Dictionary = button_touch_states[button_id]
	var duration_ms = Time.get_ticks_msec() - int(state.press_time_ms)
	var drag_distance = Vector2(state.press_position).distance_to(event.position)
	if _is_quick_tap(duration_ms, drag_distance):
		tap_action.call()
	_clear_button_touch_state(button)

func _handle_mouse_drag(button: Button, event: InputEventMouseMotion) -> void:
	var button_id = button.get_instance_id()
	if not button_touch_states.has(button_id):
		return
	if not (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		return
	var state: Dictionary = button_touch_states[button_id]
	var duration_ms = Time.get_ticks_msec() - int(state.press_time_ms)
	var drag_distance = Vector2(state.press_position).distance_to(event.position)
	if _should_start_scroll(duration_ms, drag_distance):
		state.scrolling = true
		_scroll_button_parent(button, event.relative.y)
	state.last_position = event.position
	button_touch_states[button_id] = state

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

func _clear_button_touch_state(button: Button) -> void:
	button_touch_states.erase(button.get_instance_id())

func _is_quick_tap(duration_ms: int, drag_distance: float) -> bool:
	return duration_ms <= QUICK_TAP_MAX_DURATION_MS and drag_distance <= QUICK_TAP_MAX_MOVEMENT

func _should_start_scroll(duration_ms: int, drag_distance: float) -> bool:
	return duration_ms >= SCROLL_START_DURATION_MS or drag_distance > QUICK_TAP_MAX_MOVEMENT

func set_active_tab(tab_name: String) -> void:
	active_tab = tab_name
	upgrades_scroll.visible = tab_name == TAB_UPGRADES
	abilities_scroll.visible = tab_name == TAB_ABILITIES
	map_scroll.visible = tab_name == TAB_MAP
	upgrades_tab_button.button_pressed = tab_name == TAB_UPGRADES
	abilities_tab_button.button_pressed = tab_name == TAB_ABILITIES
	map_tab_button.button_pressed = tab_name == TAB_MAP

func on_ability_tile_pressed(tile: Button) -> void:
	selected_ability_id = tile.ability_id
	selected_ability_source_role = tile.tile_role
	selected_ability_slot_index = tile.slot_index
	ability_popup_overlay.visible = true
	_update_ability_popup()

func get_ability_drag_preview_text(ability_id: String) -> String:
	var definition = ability_system.get_definition(ability_id)
	return definition.display_name if definition else ability_id

func can_drop_ability_tile(target_tile: Button, data) -> bool:
	if not (data is Dictionary) or target_tile.tile_role != "slot":
		return false
	var ability_id = String(data.get("ability_id", ""))
	if ability_id.is_empty():
		return false
	var existing_slot = ability_system.get_equipped_slot_for_ability(ability_id)
	return existing_slot == -1 or existing_slot == target_tile.slot_index

func drop_ability_tile(target_tile: Button, data) -> void:
	if not can_drop_ability_tile(target_tile, data):
		return
	var ability_id = String(data.get("ability_id", ""))
	if ability_system.equip_ability(target_tile.slot_index, ability_id):
		_refresh_hero_stats()
	_update_ui()

func _rebuild_ability_library() -> void:
	for child in ability_library_grid.get_children():
		child.queue_free()
	ability_library_buttons.clear()
	for definition in ability_system.get_all_definitions():
		var tile := Button.new()
		tile.set_script(ABILITY_TILE_SCRIPT)
		tile.custom_minimum_size = ABILITY_TILE_SIZE
		tile.clip_text = true
		tile.alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ability_library_grid.add_child(tile)
		tile.configure(definition.ability_id, "library", -1)
		ability_library_buttons[definition.ability_id] = tile

func _update_ui() -> void:
	if gold_label:
		gold_label.text = "Gold: %d" % save_manager.save_data.gold
	if top_wave_label:
		top_wave_label.text = "Wave %d" % save_manager.save_data.wave
	if wave_label:
		wave_label.text = "Monsters: %d/10" % save_manager.save_data.monsters_killed

	var upgrades = upgrade_system.get_all_upgrades()
	_update_upgrade_button(damage_btn, "Damage", upgrades.damage.level, upgrades.damage.cost)
	_update_upgrade_multiplier_buttons("damage", damage_x10_btn, damage_x100_btn)
	_update_upgrade_button(speed_btn, "Attack Speed", upgrades.attack_speed.level, upgrades.attack_speed.cost)
	_update_upgrade_multiplier_buttons("attack_speed", speed_x10_btn, speed_x100_btn)
	_update_upgrade_button(hp_btn, "Max HP", upgrades.max_hp.level, upgrades.max_hp.cost)
	_update_upgrade_multiplier_buttons("max_hp", hp_x10_btn, hp_x100_btn)
	_update_upgrade_button(armor_btn, "Armor", upgrades.armor.level, upgrades.armor.cost)
	_update_upgrade_multiplier_buttons("armor", armor_x10_btn, armor_x100_btn)
	_update_upgrade_button(regen_btn, "HP Regen", upgrades.health_regen.level, upgrades.health_regen.cost)
	_update_upgrade_multiplier_buttons("health_regen", regen_x10_btn, regen_x100_btn)
	_update_upgrade_button(crit_chance_btn, "Crit Chance", upgrades.crit_chance.level, upgrades.crit_chance.cost)
	_update_upgrade_multiplier_buttons("crit_chance", crit_chance_x10_btn, crit_chance_x100_btn)
	_update_upgrade_button(crit_dmg_btn, "Crit Damage", upgrades.crit_damage.level, upgrades.crit_damage.cost)
	_update_upgrade_multiplier_buttons("crit_damage", crit_dmg_x10_btn, crit_dmg_x100_btn)
	_update_abilities_ui()

	var hero = get_node_or_null("../CombatArea/Hero")
	if hero_stats_label and hero:
		hero_stats_label.text = "ATK: %d | SPD: %.1f | ARM: %d | REG: %.1f | HP: %d/%d" % [
			int(hero.base_damage),
			hero.attack_speed,
			int(hero.armor),
			hero.health_regen,
			int(hero.current_hp),
			int(hero.max_hp)
		]

func _update_abilities_ui() -> void:
	var equipped_slots = ability_system.get_equipped_ability_slots()
	for index in range(ability_slot_buttons.size()):
		var tile = ability_slot_buttons[index]
		var ability_id = equipped_slots[index]
		tile.configure(ability_id, "slot", index)
		tile.text = _build_ability_tile_text(ability_id)

	for definition in ability_system.get_all_definitions():
		var tile = ability_library_buttons.get(definition.ability_id)
		if tile:
			tile.configure(definition.ability_id, "library", -1)
			tile.text = _build_ability_tile_text(definition.ability_id)

	if ability_popup_overlay.visible and not selected_ability_id.is_empty():
		_update_ability_popup()

func _build_ability_tile_text(ability_id: String) -> String:
	if ability_id.is_empty():
		return ABILITY_TILE_EMPTY_TEXT
	var definition = ability_system.get_definition(ability_id)
	if definition == null:
		return ability_id
	return "%s\nCD %.1fs" % [_truncate_ability_name(definition.display_name), definition.cooldown_seconds]

func _truncate_ability_name(display_name: String) -> String:
	if display_name.length() <= ABILITY_NAME_MAX_CHARS:
		return display_name
	return "%s..." % display_name.substr(0, ABILITY_NAME_MAX_CHARS - 3)

func _update_ability_popup() -> void:
	var definition = ability_system.get_definition(selected_ability_id)
	if definition == null:
		return
	ability_popup_title_label.text = definition.display_name
	ability_popup_description_label.text = definition.description
	ability_popup_meta_label.text = definition.get_meta_summary()
	var equipped_slot = ability_system.get_equipped_slot_for_ability(definition.ability_id)
	if equipped_slot >= 0:
		ability_popup_status_label.text = "Active in slot %d" % (equipped_slot + 1)
		ability_popup_action_button.text = "Remove"
		ability_popup_action_button.disabled = false
	else:
		var free_slot = _find_first_free_ability_slot()
		ability_popup_status_label.text = "Not active" if free_slot >= 0 else "No free active slots"
		ability_popup_action_button.text = "Add"
		ability_popup_action_button.disabled = free_slot < 0

func _close_ability_popup() -> void:
	ability_popup_overlay.visible = false

func _on_popup_ability_action_pressed() -> void:
	var definition = ability_system.get_definition(selected_ability_id)
	if definition == null:
		return
	var equipped_slot = ability_system.get_equipped_slot_for_ability(definition.ability_id)
	if equipped_slot >= 0:
		if ability_system.clear_slot(equipped_slot):
			_refresh_hero_stats()
	else:
		var free_slot = _find_first_free_ability_slot()
		if free_slot >= 0 and ability_system.equip_ability(free_slot, definition.ability_id):
			_refresh_hero_stats()
	_update_ui()
	_close_ability_popup()

func _find_first_free_ability_slot() -> int:
	for slot_index in range(ability_slot_buttons.size()):
		if ability_system.get_ability_slot(slot_index).is_empty():
			return slot_index
	return -1

func _update_upgrade_button(btn: Button, name: String, level: int, cost: int) -> void:
	btn.text = "%s Lv.%d Cost: %d" % [name, level, cost]
	btn.disabled = save_manager.save_data.gold < cost

func _update_upgrade_multiplier_buttons(upgrade_name: String, x10_btn: Button, x100_btn: Button) -> void:
	x10_btn.disabled = not _can_purchase_upgrade_times(upgrade_name, 10)
	x100_btn.disabled = not _can_purchase_upgrade_times(upgrade_name, 100)

func _on_damage_clicked() -> void:
	_purchase_upgrade("damage")

func _on_speed_clicked() -> void:
	_purchase_upgrade("attack_speed")

func _on_hp_clicked() -> void:
	_purchase_upgrade("max_hp")

func _on_armor_clicked() -> void:
	_purchase_upgrade("armor")

func _on_regen_clicked() -> void:
	_purchase_upgrade("health_regen")

func _on_crit_chance_clicked() -> void:
	_purchase_upgrade("crit_chance")

func _on_crit_dmg_clicked() -> void:
	_purchase_upgrade("crit_damage")

func _on_debug_gold_clicked() -> void:
	_add_debug_gold(1)

func _on_reset_progress_clicked() -> void:
	_reset_progress_multiple(1)

func _purchase_upgrade(upgrade_name: String) -> void:
	if upgrade_system.purchase_upgrade(upgrade_name):
		save_manager.save()
		_refresh_hero_stats()
		_update_ui()

func _purchase_upgrade_multiple(upgrade_name: String, times: int) -> void:
	var purchase_count = 0
	for _i in range(times):
		if not upgrade_system.purchase_upgrade(upgrade_name):
			break
		purchase_count += 1
	if purchase_count > 0:
		save_manager.save()
		_refresh_hero_stats()
	_update_ui()

func _add_debug_gold(times: int) -> void:
	save_manager.save_data.gold += 100 * times
	save_manager.save()
	_update_ui()

func _reset_progress_multiple(times: int) -> void:
	for _i in range(times):
		save_manager.reset()
	upgrade_system.load_from_save()
	ability_system.load_from_save()
	_refresh_hero_stats(true)
	_close_ability_popup()
	_update_ui()

func _refresh_hero_stats(restore_full_hp: bool = false) -> void:
	var hero = get_node_or_null("../CombatArea/Hero")
	if hero:
		hero.update_stats()
		if restore_full_hp:
			hero.current_hp = hero.max_hp

func _can_purchase_upgrade_times(upgrade_name: String, times: int) -> bool:
	var simulated_gold = save_manager.save_data.gold
	var simulated_level = upgrade_system.get_upgrade_level(upgrade_name)
	for _i in range(times):
		var cost = upgrade_system.get_upgrade_cost(upgrade_name, simulated_level)
		if simulated_gold < cost:
			return false
		simulated_gold -= cost
		simulated_level += 1
	return true
