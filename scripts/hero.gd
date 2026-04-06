extends Node2D

signal attack_hit(damage: float, is_crit: bool)
signal hero_died()

@onready var health_bar: ProgressBar = $HealthBar
@onready var body: Node2D = $Body

var current_hp: float = 100.0
var max_hp: float = 100.0
var base_damage: float = 10.0
var attack_speed: float = 1.0
var crit_chance: float = 5.0
var crit_multiplier: float = 150.0

var attack_timer: float = 0.0
var is_running: bool = true
var facing_right: bool = true

func _ready() -> void:
	update_stats()

func _process(delta: float) -> void:
	if is_running:
		body.scale.x = -1.0 if facing_right else 1.0
	update_health_bar()

func update_stats() -> void:
	var upgrade_system = get_node("/root/UpgradeSystem")
	max_hp = upgrade_system.get_max_hp()
	base_damage = upgrade_system.get_damage()
	attack_speed = upgrade_system.get_attack_speed()
	crit_chance = upgrade_system.get_crit_chance()
	crit_multiplier = upgrade_system.get_crit_damage()
	
	if current_hp > max_hp:
		current_hp = max_hp
	elif current_hp <= 0:
		current_hp = max_hp

func take_damage(amount: float) -> void:
	current_hp -= amount
	if current_hp <= 0:
		current_hp = 0
		emit_signal("hero_died")

func heal(amount: float) -> void:
	current_hp = min(current_hp + amount, max_hp)

func update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp

func get_attack_interval() -> float:
	return 1.0 / attack_speed

func try_attack() -> bool:
	attack_timer += get_process_delta_time()
	if attack_timer >= get_attack_interval():
		attack_timer = 0.0
		return true
	return false

func get_damage_output() -> Dictionary:
	var damage = base_damage
	var is_crit = randf() * 100.0 < crit_chance
	if is_crit:
		damage *= crit_multiplier / 100.0
	return {"damage": damage, "is_crit": is_crit}
