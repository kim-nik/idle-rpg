extends CanvasLayer

signal upgrade_clicked(upgrade_name: String)

@onready var gold_label: Label = $Panel/GoldLabel
@onready var wave_label: Label = $Panel/WaveLabel
@onready var hero_stats_label: Label = $Panel/HeroStatsLabel

@onready var damage_btn: Button = $Panel/UpgradeContainer/DamageButton
@onready var speed_btn: Button = $Panel/UpgradeContainer/SpeedButton
@onready var hp_btn: Button = $Panel/UpgradeContainer/HpButton
@onready var crit_chance_btn: Button = $Panel/UpgradeContainer/CritChanceButton
@onready var crit_dmg_btn: Button = $Panel/UpgradeContainer/CritDmgButton

var upgrade_system
var save_manager

func _ready() -> void:
	save_manager = get_node("/root/SaveManager")
	upgrade_system = get_node("/root/UpgradeSystem")
	
	damage_btn.pressed.connect(_on_damage_clicked)
	speed_btn.pressed.connect(_on_speed_clicked)
	hp_btn.pressed.connect(_on_hp_clicked)
	crit_chance_btn.pressed.connect(_on_crit_chance_clicked)
	crit_dmg_btn.pressed.connect(_on_crit_dmg_clicked)
	
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
	_update_upgrade_button(speed_btn, "Attack Speed", upgrades.attack_speed.level, upgrades.attack_speed.cost)
	_update_upgrade_button(hp_btn, "Max HP", upgrades.max_hp.level, upgrades.max_hp.cost)
	_update_upgrade_button(crit_chance_btn, "Crit Chance", upgrades.crit_chance.level, upgrades.crit_chance.cost)
	_update_upgrade_button(crit_dmg_btn, "Crit Damage", upgrades.crit_damage.level, upgrades.crit_damage.cost)
	
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

func _purchase_upgrade(upgrade_name: String) -> void:
	if upgrade_system.purchase_upgrade(upgrade_name):
		save_manager.save()
		var hero = get_node_or_null("../CombatArea/Hero")
		if hero:
			hero.update_stats()
		_update_ui()
