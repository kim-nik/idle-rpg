extends CanvasLayer

signal upgrade_clicked(upgrade_name: String)

const GameServicesRef = preload("res://scripts/core/game_services.gd")
const ScrollableButtonHandlerRef = preload("res://scripts/ui/scrollable_button_handler.gd")

const TAB_UPGRADES := "upgrades"
const TAB_ABILITIES := "abilities"
const TAB_MAP := "map"
const LIVE_REFRESH_INTERVAL := 0.1
const ABILITY_TILE_SCRIPT := preload("res://scripts/ui/ability_tile_button.gd")
const ABILITY_TILE_SIZE := Vector2(0, 144)
const ABILITY_TILE_EMPTY_TEXT := "Empty"
const ABILITY_NAME_MAX_CHARS := 12
const UPGRADE_BUTTON_CONFIGS := [
	{
		"upgrade_id": "damage",
		"display_name": "Damage",
		"row": "DamageRow",
		"primary_alias": "damage_btn",
		"primary_node": "DamageButton",
		"x10_alias": "damage_x10_btn",
		"x10_node": "DamageX10Button",
		"x100_alias": "damage_x100_btn",
		"x100_node": "DamageX100Button"
	},
	{
		"upgrade_id": "attack_speed",
		"display_name": "Attack Speed",
		"row": "SpeedRow",
		"primary_alias": "speed_btn",
		"primary_node": "SpeedButton",
		"x10_alias": "speed_x10_btn",
		"x10_node": "SpeedX10Button",
		"x100_alias": "speed_x100_btn",
		"x100_node": "SpeedX100Button"
	},
	{
		"upgrade_id": "max_hp",
		"display_name": "Max HP",
		"row": "HpRow",
		"primary_alias": "hp_btn",
		"primary_node": "HpButton",
		"x10_alias": "hp_x10_btn",
		"x10_node": "HpX10Button",
		"x100_alias": "hp_x100_btn",
		"x100_node": "HpX100Button"
	},
	{
		"upgrade_id": "armor",
		"display_name": "Armor",
		"row": "ArmorRow",
		"primary_alias": "armor_btn",
		"primary_node": "ArmorButton",
		"x10_alias": "armor_x10_btn",
		"x10_node": "ArmorX10Button",
		"x100_alias": "armor_x100_btn",
		"x100_node": "ArmorX100Button"
	},
	{
		"upgrade_id": "health_regen",
		"display_name": "HP Regen",
		"row": "RegenRow",
		"primary_alias": "regen_btn",
		"primary_node": "RegenButton",
		"x10_alias": "regen_x10_btn",
		"x10_node": "RegenX10Button",
		"x100_alias": "regen_x100_btn",
		"x100_node": "RegenX100Button"
	},
	{
		"upgrade_id": "crit_chance",
		"display_name": "Crit Chance",
		"row": "CritChanceRow",
		"primary_alias": "crit_chance_btn",
		"primary_node": "CritChanceButton",
		"x10_alias": "crit_chance_x10_btn",
		"x10_node": "CritChanceX10Button",
		"x100_alias": "crit_chance_x100_btn",
		"x100_node": "CritChanceX100Button"
	},
	{
		"upgrade_id": "crit_damage",
		"display_name": "Crit Damage",
		"row": "CritDmgRow",
		"primary_alias": "crit_dmg_btn",
		"primary_node": "CritDmgButton",
		"x10_alias": "crit_dmg_x10_btn",
		"x10_node": "CritDmgX10Button",
		"x100_alias": "crit_dmg_x100_btn",
		"x100_node": "CritDmgX100Button"
	}
]
const SPECIAL_BUTTON_CONFIGS := [
	{
		"action_id": "debug_gold",
		"row": "DebugGoldRow",
		"primary_alias": "debug_gold_btn",
		"primary_node": "DebugGoldButton",
		"x10_alias": "debug_gold_x10_btn",
		"x10_node": "DebugGoldX10Button",
		"x100_alias": "debug_gold_x100_btn",
		"x100_node": "DebugGoldX100Button"
	},
	{
		"action_id": "reset_progress",
		"row": "ResetProgressRow",
		"primary_alias": "reset_progress_btn",
		"primary_node": "ResetProgressButton",
		"x10_alias": "reset_progress_x10_btn",
		"x10_node": "ResetProgressX10Button",
		"x100_alias": "reset_progress_x100_btn",
		"x100_node": "ResetProgressX100Button"
	}
]

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
@onready var popup_overlay_root: ColorRect = $PopupOverlay

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

var upgrade_system: Node
var save_manager: Node
var ability_system: Node
var hero: Node2D
var wave_manager: Node
var monster_container: Node
var active_tab: String = TAB_UPGRADES
var selected_ability_id: String = ""
var selected_ability_source_role: String = "library"
var selected_ability_slot_index: int = -1

var _scroll_handler := ScrollableButtonHandlerRef.new()
var _refresh_requested := true
var _refresh_timer := 0.0

func _ready() -> void:
	add_to_group("ui_controller")
	save_manager = GameServicesRef.get_save_manager(self)
	upgrade_system = GameServicesRef.get_upgrade_system(self)
	ability_system = GameServicesRef.get_ability_system(self)

	_cache_upgrade_controls()
	_cache_ability_controls()
	_bind_upgrade_buttons()
	_bind_ability_buttons()
	_bind_tab_buttons()
	_connect_state_signals()
	bind_runtime(_resolve_hero(), _resolve_wave_manager(), _resolve_monster_container())
	set_active_tab(TAB_UPGRADES)
	_update_ui()

func bind_runtime(next_hero: Node2D, next_wave_manager: Node, next_monster_container: Node) -> void:
	hero = next_hero
	wave_manager = next_wave_manager
	monster_container = next_monster_container
	_connect_runtime_signals()
	_request_refresh()

func _process(delta: float) -> void:
	_refresh_timer += delta
	var should_live_refresh = hero != null and is_instance_valid(hero)
	if _refresh_requested or (should_live_refresh and _refresh_timer >= LIVE_REFRESH_INTERVAL):
		_update_ui()

func _cache_upgrade_controls() -> void:
	var upgrade_container = upgrades_tab_root.get_node("UpgradeContainer")
	for config in UPGRADE_BUTTON_CONFIGS:
		_cache_button_group(upgrade_container, config)
	for config in SPECIAL_BUTTON_CONFIGS:
		_cache_button_group(upgrade_container, config)

func _cache_button_group(root: Node, config: Dictionary) -> void:
	var row = root.get_node(String(config.get("row", "")))
	set(String(config.get("primary_alias", "")), row.get_node(String(config.get("primary_node", ""))))
	set(String(config.get("x10_alias", "")), row.get_node(String(config.get("x10_node", ""))))
	set(String(config.get("x100_alias", "")), row.get_node(String(config.get("x100_node", ""))))

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
	ability_popup_overlay = popup_overlay_root
	ability_popup_title_label = popup_overlay_root.get_node("PopupPanel/PopupMargin/PopupContent/PopupTitleLabel")
	ability_popup_description_label = popup_overlay_root.get_node("PopupPanel/PopupMargin/PopupContent/PopupDescriptionLabel")
	ability_popup_meta_label = popup_overlay_root.get_node("PopupPanel/PopupMargin/PopupContent/PopupMetaLabel")
	ability_popup_status_label = popup_overlay_root.get_node("PopupPanel/PopupMargin/PopupContent/PopupStatusLabel")
	ability_popup_close_button = popup_overlay_root.get_node("PopupPanel/PopupMargin/PopupContent/PopupButtons/PopupCloseButton")
	ability_popup_action_button = popup_overlay_root.get_node("PopupPanel/PopupMargin/PopupContent/PopupButtons/PopupActionButton")

func _bind_upgrade_buttons() -> void:
	for config in UPGRADE_BUTTON_CONFIGS:
		var upgrade_id = String(config.get("upgrade_id", ""))
		_register_scrollable_button(get(String(config.get("primary_alias", ""))), func() -> void:
			_purchase_upgrade(upgrade_id)
		)
		_register_scrollable_button(get(String(config.get("x10_alias", ""))), func() -> void:
			_purchase_upgrade_multiple(upgrade_id, 10)
		)
		_register_scrollable_button(get(String(config.get("x100_alias", ""))), func() -> void:
			_purchase_upgrade_multiple(upgrade_id, 100)
		)

	_register_scrollable_button(debug_gold_btn, _on_debug_gold_clicked)
	_register_scrollable_button(debug_gold_x10_btn, func() -> void:
		_add_debug_gold(10)
	)
	_register_scrollable_button(debug_gold_x100_btn, func() -> void:
		_add_debug_gold(100)
	)
	_register_scrollable_button(reset_progress_btn, _on_reset_progress_clicked)
	_register_scrollable_button(reset_progress_x10_btn, func() -> void:
		_reset_progress_multiple(10)
	)
	_register_scrollable_button(reset_progress_x100_btn, func() -> void:
		_reset_progress_multiple(100)
	)

func _bind_ability_buttons() -> void:
	ability_popup_close_button.pressed.connect(_close_ability_popup)
	ability_popup_action_button.pressed.connect(_on_popup_ability_action_pressed)
	_rebuild_ability_library()
	for index in range(ability_slot_buttons.size()):
		ability_slot_buttons[index].configure("", "slot", index)

func _bind_tab_buttons() -> void:
	upgrades_tab_button.pressed.connect(func() -> void:
		set_active_tab(TAB_UPGRADES)
	)
	abilities_tab_button.pressed.connect(func() -> void:
		set_active_tab(TAB_ABILITIES)
	)
	map_tab_button.pressed.connect(func() -> void:
		set_active_tab(TAB_MAP)
	)

func _connect_state_signals() -> void:
	_connect_signal_once(save_manager, "save_data_changed", Callable(self, "_on_external_state_changed"))
	_connect_signal_once(upgrade_system, "upgrades_changed", Callable(self, "_on_external_state_changed"))
	_connect_signal_once(ability_system, "loadout_changed", Callable(self, "_on_external_state_changed"))

func _connect_runtime_signals() -> void:
	_connect_signal_once(wave_manager, "wave_started", Callable(self, "_on_external_state_changed"))
	_connect_signal_once(wave_manager, "wave_completed", Callable(self, "_on_external_state_changed"))

func _connect_signal_once(emitter: Object, signal_name: String, callable: Callable) -> void:
	if emitter == null or not emitter.has_signal(signal_name):
		return
	if not emitter.is_connected(signal_name, callable):
		emitter.connect(signal_name, callable)

func _register_scrollable_button(button: Button, tap_action: Callable) -> void:
	_scroll_handler.register_button(button, tap_action)

func _clear_button_touch_state(button: Button) -> void:
	_scroll_handler.clear_state(button)

func _is_quick_tap(duration_ms: int, drag_distance: float) -> bool:
	return _scroll_handler.is_quick_tap(duration_ms, drag_distance)

func _should_start_scroll(duration_ms: int, drag_distance: float) -> bool:
	return _scroll_handler.should_start_scroll(duration_ms, drag_distance)

func set_active_tab(tab_name: String) -> void:
	active_tab = tab_name
	upgrades_scroll.visible = tab_name == TAB_UPGRADES
	abilities_scroll.visible = tab_name == TAB_ABILITIES
	map_scroll.visible = tab_name == TAB_MAP
	upgrades_tab_button.button_pressed = tab_name == TAB_UPGRADES
	abilities_tab_button.button_pressed = tab_name == TAB_ABILITIES
	map_tab_button.button_pressed = tab_name == TAB_MAP
	_request_refresh()

func on_ability_tile_pressed(tile: Button) -> void:
	if tile.ability_id.is_empty():
		return
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
	_request_refresh()
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
	_refresh_requested = false
	_refresh_timer = 0.0
	if save_manager == null or upgrade_system == null or ability_system == null:
		return

	if gold_label:
		gold_label.text = "Gold: %d" % int(save_manager.save_data.get("gold", 0))
	if top_wave_label:
		top_wave_label.text = "Wave %d" % int(save_manager.save_data.get("wave", 1))
	if wave_label:
		wave_label.text = "Monsters: %d/10" % int(save_manager.save_data.get("monsters_killed", 0))

	var upgrades = upgrade_system.get_all_upgrades()
	for config in UPGRADE_BUTTON_CONFIGS:
		var upgrade_id = String(config.get("upgrade_id", ""))
		var upgrade_state: Dictionary = upgrades.get(upgrade_id, {})
		_update_upgrade_button(
			get(String(config.get("primary_alias", ""))),
			String(upgrade_state.get("display_name", config.get("display_name", upgrade_id.capitalize()))),
			int(upgrade_state.get("level", 1)),
			int(upgrade_state.get("cost", 0))
		)
		_update_upgrade_multiplier_buttons(
			upgrade_id,
			get(String(config.get("x10_alias", ""))),
			get(String(config.get("x100_alias", "")))
		)

	_update_abilities_ui()
	_update_hero_stats_label()

func _update_hero_stats_label() -> void:
	var active_hero = hero if hero and is_instance_valid(hero) else _resolve_hero()
	if hero_stats_label and active_hero:
		hero_stats_label.text = "ATK: %d | SPD: %.1f | ARM: %d | REG: %.1f | HP: %d/%d" % [
			int(active_hero.base_damage),
			active_hero.attack_speed,
			int(active_hero.armor),
			active_hero.health_regen,
			int(active_hero.current_hp),
			int(active_hero.max_hp)
		]

func _update_abilities_ui() -> void:
	var equipped_slots = ability_system.get_equipped_ability_slots()
	for index in range(ability_slot_buttons.size()):
		var tile = ability_slot_buttons[index]
		var ability_id = equipped_slots[index]
		tile.configure(ability_id, "slot", index)
		_apply_ability_tile_visual(tile, ability_id, true)

	for definition in ability_system.get_all_definitions():
		var tile = ability_library_buttons.get(definition.ability_id)
		if tile:
			tile.configure(definition.ability_id, "library", -1)
			_apply_ability_tile_visual(tile, definition.ability_id, false)

	if ability_popup_overlay.visible and not selected_ability_id.is_empty():
		_update_ability_popup()

func _apply_ability_tile_visual(tile: Button, ability_id: String, use_runtime_cooldown: bool) -> void:
	if ability_id.is_empty():
		tile.set_visual_state(null, ABILITY_TILE_EMPTY_TEXT, "", true)
		return
	var definition = ability_system.get_definition(ability_id)
	if definition == null:
		tile.set_visual_state(null, ability_id, "", false)
		return
	var icon = AbilityVisuals.get_icon(ability_id)
	var cooldown_text = "CD %.1fs" % definition.cooldown_seconds
	if use_runtime_cooldown:
		var remaining = ability_system.get_cooldown_remaining(ability_id)
		cooldown_text = "Ready" if remaining <= 0.0 else "CD %.1fs" % remaining
	tile.set_visual_state(
		icon,
		_truncate_ability_name(definition.display_name),
		cooldown_text,
		false
	)

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
	_request_refresh()
	_update_ui()
	_close_ability_popup()

func _find_first_free_ability_slot() -> int:
	for slot_index in range(ability_slot_buttons.size()):
		if ability_system.get_ability_slot(slot_index).is_empty():
			return slot_index
	return -1

func _update_upgrade_button(btn: Button, name: String, level: int, cost: int) -> void:
	btn.text = "%s Lv.%d Cost: %d" % [name, level, cost]
	btn.disabled = int(save_manager.save_data.get("gold", 0)) < cost

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
	_request_refresh()
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
	_request_refresh()
	_update_ui()

func _add_debug_gold(times: int) -> void:
	save_manager.add_gold(100 * times, true)
	_request_refresh()
	_update_ui()

func _reset_progress_multiple(times: int) -> void:
	for _i in range(times):
		save_manager.reset()
	upgrade_system.load_from_save()
	ability_system.load_from_save()
	_refresh_hero_stats(true)
	_close_ability_popup()
	_request_refresh()
	_update_ui()

func _refresh_hero_stats(restore_full_hp: bool = false) -> void:
	var active_hero = hero if hero and is_instance_valid(hero) else _resolve_hero()
	if active_hero:
		active_hero.update_stats()
		if restore_full_hp:
			active_hero.current_hp = active_hero.max_hp

func _can_purchase_upgrade_times(upgrade_name: String, times: int) -> bool:
	var simulated_gold = int(save_manager.save_data.get("gold", 0))
	var simulated_level = upgrade_system.get_upgrade_level(upgrade_name)
	for _i in range(times):
		var cost = upgrade_system.get_upgrade_cost(upgrade_name, simulated_level)
		if simulated_gold < cost:
			return false
		simulated_gold -= cost
		simulated_level += 1
	return true

func _request_refresh() -> void:
	_refresh_requested = true

func _on_external_state_changed(_arg = null) -> void:
	_request_refresh()

func _resolve_hero() -> Node2D:
	var parent_node = get_parent()
	if parent_node == null:
		return null
	return parent_node.get_node_or_null("CombatArea/Hero") as Node2D

func _resolve_wave_manager() -> Node:
	var parent_node = get_parent()
	if parent_node == null:
		return null
	return parent_node.get_node_or_null("WaveManager")

func _resolve_monster_container() -> Node:
	var parent_node = get_parent()
	if parent_node == null:
		return null
	return parent_node.get_node_or_null("CombatArea/Monsters")
