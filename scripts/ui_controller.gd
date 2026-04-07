extends CanvasLayer

signal upgrade_clicked(upgrade_name: String)

@onready var gold_label: Label = $Panel/MarginContainer/Content/StatsContainer/GoldLabel
@onready var wave_label: Label = $Panel/MarginContainer/Content/StatsContainer/WaveLabel
@onready var hero_stats_label: Label = $Panel/MarginContainer/Content/StatsContainer/HeroStatsLabel

@onready var damage_btn: Button = $Panel/MarginContainer/Content/UpgradeContainer/DamageRow/DamageButton
@onready var damage_x10_btn: Button = $Panel/MarginContainer/Content/UpgradeContainer/DamageRow/DamageX10Button
@onready var damage_x100_btn: Button = $Panel/MarginContainer/Content/UpgradeContainer/DamageRow/DamageX100Button
@onready var speed_btn: Button = $Panel/MarginContainer/Content/UpgradeContainer/SpeedRow/SpeedButton
@onready var speed_x10_btn: Button = $Panel/MarginContainer/Content/UpgradeContainer/SpeedRow/SpeedX10Button
@onready var speed_x100_btn: Button = $Panel/MarginContainer/Content/UpgradeContainer/SpeedRow/SpeedX100Button
@onready var hp_btn: Button = $Panel/MarginContainer/Content/UpgradeContainer/HpRow/HpButton
@onready var hp_x10_btn: Button = $Panel/MarginContainer/Content/UpgradeContainer/HpRow/HpX10Button
@onready var hp_x100_btn: Button = $Panel/MarginContainer/Content/UpgradeContainer/HpRow/HpX100Button
@onready var crit_chance_btn: Button = $Panel/MarginContainer/Content/UpgradeContainer/CritChanceRow/CritChanceButton
@onready var crit_chance_x10_btn: Button = $Panel/MarginContainer/Content/UpgradeContainer/CritChanceRow/CritChanceX10Button
@onready var crit_chance_x100_btn: Button = $Panel/MarginContainer/Content/UpgradeContainer/CritChanceRow/CritChanceX100Button
@onready var crit_dmg_btn: Button = $Panel/MarginContainer/Content/UpgradeContainer/CritDmgRow/CritDmgButton
@onready var crit_dmg_x10_btn: Button = $Panel/MarginContainer/Content/UpgradeContainer/CritDmgRow/CritDmgX10Button
@onready var crit_dmg_x100_btn: Button = $Panel/MarginContainer/Content/UpgradeContainer/CritDmgRow/CritDmgX100Button
@onready var debug_gold_btn: Button = $Panel/MarginContainer/Content/UpgradeContainer/DebugGoldRow/DebugGoldButton
@onready var debug_gold_x10_btn: Button = $Panel/MarginContainer/Content/UpgradeContainer/DebugGoldRow/DebugGoldX10Button
@onready var debug_gold_x100_btn: Button = $Panel/MarginContainer/Content/UpgradeContainer/DebugGoldRow/DebugGoldX100Button
@onready var reset_progress_btn: Button = $Panel/MarginContainer/Content/UpgradeContainer/ResetProgressRow/ResetProgressButton
@onready var reset_progress_x10_btn: Button = $Panel/MarginContainer/Content/UpgradeContainer/ResetProgressRow/ResetProgressX10Button
@onready var reset_progress_x100_btn: Button = $Panel/MarginContainer/Content/UpgradeContainer/ResetProgressRow/ResetProgressX100Button

var upgrade_system
var save_manager

func _ready() -> void:
	save_manager = get_node("/root/SaveManager")
	upgrade_system = get_node("/root/UpgradeSystem")
	
	damage_btn.pressed.connect(_on_damage_clicked)
	damage_x10_btn.pressed.connect(func() -> void: _purchase_upgrade_multiple("damage", 10))
	damage_x100_btn.pressed.connect(func() -> void: _purchase_upgrade_multiple("damage", 100))
	speed_btn.pressed.connect(_on_speed_clicked)
	speed_x10_btn.pressed.connect(func() -> void: _purchase_upgrade_multiple("attack_speed", 10))
	speed_x100_btn.pressed.connect(func() -> void: _purchase_upgrade_multiple("attack_speed", 100))
	hp_btn.pressed.connect(_on_hp_clicked)
	hp_x10_btn.pressed.connect(func() -> void: _purchase_upgrade_multiple("max_hp", 10))
	hp_x100_btn.pressed.connect(func() -> void: _purchase_upgrade_multiple("max_hp", 100))
	crit_chance_btn.pressed.connect(_on_crit_chance_clicked)
	crit_chance_x10_btn.pressed.connect(func() -> void: _purchase_upgrade_multiple("crit_chance", 10))
	crit_chance_x100_btn.pressed.connect(func() -> void: _purchase_upgrade_multiple("crit_chance", 100))
	crit_dmg_btn.pressed.connect(_on_crit_dmg_clicked)
	crit_dmg_x10_btn.pressed.connect(func() -> void: _purchase_upgrade_multiple("crit_damage", 10))
	crit_dmg_x100_btn.pressed.connect(func() -> void: _purchase_upgrade_multiple("crit_damage", 100))
	debug_gold_btn.pressed.connect(_on_debug_gold_clicked)
	debug_gold_x10_btn.pressed.connect(func() -> void: _add_debug_gold(10))
	debug_gold_x100_btn.pressed.connect(func() -> void: _add_debug_gold(100))
	reset_progress_btn.pressed.connect(_on_reset_progress_clicked)
	reset_progress_x10_btn.pressed.connect(func() -> void: _reset_progress_multiple(10))
	reset_progress_x100_btn.pressed.connect(func() -> void: _reset_progress_multiple(100))
	
	_update_ui()

func _process(delta: float) -> void:
	_update_ui()

func _update_ui() -> void:
	if gold_label:
		gold_label.text = "Gold: %d" % save_manager.save_data.gold
	
	if wave_label:
		var wave = save_manager.save_data.wave
		var killed = save_manager.save_data.monsters_killed
		wave_label.text = "Wave: %d | Monsters: %d/10" % [wave, killed]
	
	var upgrades = upgrade_system.get_all_upgrades()
	_update_upgrade_button(damage_btn, "Damage", upgrades.damage.level, upgrades.damage.cost)
	_update_upgrade_multiplier_buttons("damage", damage_x10_btn, damage_x100_btn)
	_update_upgrade_button(speed_btn, "Attack Speed", upgrades.attack_speed.level, upgrades.attack_speed.cost)
	_update_upgrade_multiplier_buttons("attack_speed", speed_x10_btn, speed_x100_btn)
	_update_upgrade_button(hp_btn, "Max HP", upgrades.max_hp.level, upgrades.max_hp.cost)
	_update_upgrade_multiplier_buttons("max_hp", hp_x10_btn, hp_x100_btn)
	_update_upgrade_button(crit_chance_btn, "Crit Chance", upgrades.crit_chance.level, upgrades.crit_chance.cost)
	_update_upgrade_multiplier_buttons("crit_chance", crit_chance_x10_btn, crit_chance_x100_btn)
	_update_upgrade_button(crit_dmg_btn, "Crit Damage", upgrades.crit_damage.level, upgrades.crit_damage.cost)
	_update_upgrade_multiplier_buttons("crit_damage", crit_dmg_x10_btn, crit_dmg_x100_btn)
	
	if hero_stats_label:
		var hero = get_node_or_null("../CombatArea/Hero")
		if hero:
			hero_stats_label.text = "ATK: %d | SPD: %.1f | HP: %d/%d" % [
				int(upgrade_system.get_damage()),
				upgrade_system.get_attack_speed(),
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
