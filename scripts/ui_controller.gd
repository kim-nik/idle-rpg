extends CanvasLayer

signal upgrade_clicked(upgrade_name: String)

const TAB_UPGRADES := "upgrades"
const TAB_ABILITIES := "abilities"
const TAB_MAP := "map"
const QUICK_TAP_MAX_DURATION_MS := 180
const SCROLL_START_DURATION_MS := 181
const QUICK_TAP_MAX_MOVEMENT := 18.0

@onready var top_wave_label: Label = $TopWaveBanner/TopWaveLabel
@onready var panel: Panel = $Panel
@onready var content_root: VBoxContainer = $Panel/MarginContainer/Content
@onready var stats_root: VBoxContainer = $Panel/MarginContainer/Content/StatsContainer
@onready var gold_label: Label = $Panel/MarginContainer/Content/StatsContainer/GoldLabel
@onready var wave_label: Label = $Panel/MarginContainer/Content/StatsContainer/WaveLabel
@onready var hero_stats_label: Label = $Panel/MarginContainer/Content/StatsContainer/HeroStatsLabel

@onready var tab_content_root: MarginContainer = $Panel/MarginContainer/Content/TabContentContainer
@onready var tab_viewport: Control = $Panel/MarginContainer/Content/TabContentContainer/TabViewport
@onready var upgrades_scroll: ScrollContainer = $Panel/MarginContainer/Content/TabContentContainer/TabViewport/UpgradesScroll
@onready var abilities_scroll: ScrollContainer = $Panel/MarginContainer/Content/TabContentContainer/TabViewport/AbilitiesScroll
@onready var map_scroll: ScrollContainer = $Panel/MarginContainer/Content/TabContentContainer/TabViewport/MapScroll

@onready var upgrades_tab_root: Control = upgrades_scroll.get_node("UpgradesTab")
@onready var abilities_tab_root: Control = abilities_scroll.get_node("AbilitiesTab")
@onready var map_tab_root: Control = map_scroll.get_node("MapTab")

@onready var tab_bar: HBoxContainer = $Panel/MarginContainer/Content/TabBar
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

var upgrade_system
var save_manager
var active_tab: String = TAB_UPGRADES
var button_touch_states := {}

func _ready() -> void:
	save_manager = get_node("/root/SaveManager")
	upgrade_system = get_node("/root/UpgradeSystem")

	_cache_upgrade_controls()
	_bind_upgrade_buttons()
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
	if scroll_container == null:
		return
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

func _update_ui() -> void:
	var wave = save_manager.save_data.wave
	var killed = save_manager.save_data.monsters_killed

	if gold_label:
		gold_label.text = "Gold: %d" % save_manager.save_data.gold
	if top_wave_label:
		top_wave_label.text = "Wave %d" % wave
	if wave_label:
		wave_label.text = "Monsters: %d/10" % killed

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

	if hero_stats_label:
		var hero = get_node_or_null("../CombatArea/Hero")
		if hero:
			hero_stats_label.text = "ATK: %d | SPD: %.1f | ARM: %d | REG: %.1f | HP: %d/%d" % [
				int(upgrade_system.get_damage()),
				upgrade_system.get_attack_speed(),
				int(upgrade_system.get_armor()),
				upgrade_system.get_health_regen(),
				int(hero.current_hp),
				int(upgrade_system.get_max_hp())
			]

func _update_upgrade_button(btn: Button, name: String, level: int, cost: int) -> void:
	if btn:
		btn.text = "%s Lv.%d Cost: %d" % [name, level, cost]
		btn.disabled = save_manager.save_data.gold < cost

func _update_upgrade_multiplier_buttons(upgrade_name: String, x10_btn: Button, x100_btn: Button) -> void:
	if x10_btn:
		x10_btn.disabled = not _can_purchase_upgrade_times(upgrade_name, 10)
	if x100_btn:
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
	_refresh_hero_stats(true)
	_update_ui()

func _refresh_hero_stats(restore_full_hp: bool = false) -> void:
	var hero = get_node_or_null("../CombatArea/Hero")
	if hero:
		if restore_full_hp:
			hero.current_hp = upgrade_system.get_max_hp()
		hero.update_stats()

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
