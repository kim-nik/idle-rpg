extends Node2D

signal attack_hit(target_position: Vector2, damage: float, is_crit: bool)
signal hero_died()

const CombatMathRef = preload("res://scripts/combat_math.gd")

const ATTACK_BACKSTEP_DISTANCE: float = 10.0
const ATTACK_LUNGE_DISTANCE: float = 18.0
const ATTACK_BACKSTEP_DURATION: float = 0.08
const ATTACK_LUNGE_DURATION: float = 0.1
const ATTACK_RECOVER_DURATION: float = 0.08

@onready var health_bar: ProgressBar = $HealthBar
@onready var body: Node2D = $Body

var current_hp: float = 100.0
var max_hp: float = 100.0
var base_damage: float = 10.0
var attack_speed: float = 1.0
var crit_chance: float = 5.0
var crit_multiplier: float = 150.0
var armor: float = 0.0
var health_regen: float = 0.0
var attack_range: float = 140.0

var attack_timer: float = 0.0
var is_running: bool = true
var facing_right: bool = true
var is_attacking: bool = false
var body_base_position: Vector2 = Vector2.ZERO
var attack_tween: Tween

func _ready() -> void:
	body_base_position = body.position
	update_stats()

func _process(delta: float) -> void:
	if is_running:
		body.scale.x = -1.0 if facing_right else 1.0
	apply_regeneration(delta)
	update_health_bar()

func update_stats() -> void:
	var upgrade_system = get_node("/root/UpgradeSystem")
	var stats = CombatMathRef.build_hero_stats(upgrade_system)
	max_hp = stats.max_hp
	base_damage = stats.attack_damage
	attack_speed = stats.attack_speed
	crit_chance = stats.crit_chance
	crit_multiplier = stats.crit_damage
	armor = stats.armor
	health_regen = stats.health_regen

	if current_hp > max_hp:
		current_hp = max_hp
	elif current_hp <= 0 and max_hp > 0:
		current_hp = max_hp

func take_damage(amount: float) -> void:
	current_hp -= amount
	if current_hp <= 0:
		current_hp = 0
		_reset_attack_pose()
		emit_signal("hero_died")

func heal(amount: float) -> void:
	current_hp = min(current_hp + amount, max_hp)

func apply_regeneration(delta: float) -> void:
	current_hp = CombatMathRef.apply_regeneration(current_hp, max_hp, health_regen, delta)

func update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp

func get_attack_interval() -> float:
	return CombatMathRef.get_attack_interval(get_combat_stats())

func update_attack_cooldown(delta: float) -> void:
	if is_attacking:
		return
	attack_timer = min(attack_timer + delta, get_attack_interval())

func is_attack_ready() -> bool:
	return not is_attacking and attack_timer >= get_attack_interval()

func can_attack_target(target: Node2D) -> bool:
	if not is_instance_valid(target):
		return false
	if target.get("is_dead"):
		return false
	return global_position.distance_to(target.global_position) <= attack_range

func start_attack(target: Node2D) -> bool:
	if not can_attack_target(target):
		return false
	if not is_attack_ready():
		return false

	attack_timer = 0.0
	is_attacking = true
	var damage_output = get_damage_output()
	var attack_direction = 1.0 if facing_right else -1.0

	_reset_attack_pose(false)
	attack_tween = create_tween()
	attack_tween.tween_property(
		body,
		"position:x",
		body_base_position.x - attack_direction * ATTACK_BACKSTEP_DISTANCE,
		ATTACK_BACKSTEP_DURATION
	)
	attack_tween.tween_property(
		body,
		"position:x",
		body_base_position.x + attack_direction * ATTACK_LUNGE_DISTANCE,
		ATTACK_LUNGE_DURATION
	)
	attack_tween.tween_callback(func() -> void:
		_finish_attack_hit(target, damage_output)
	)
	attack_tween.tween_property(body, "position", body_base_position, ATTACK_RECOVER_DURATION)
	attack_tween.finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)
	return true

func try_attack() -> bool:
	if is_attack_ready():
		attack_timer = 0.0
		return true
	return false

func get_damage_output(defender_stats: Dictionary = {}) -> Dictionary:
	if defender_stats.is_empty():
		return CombatMathRef.roll_attack(get_combat_stats())
	return CombatMathRef.resolve_attack(get_combat_stats(), defender_stats)

func get_combat_stats() -> Dictionary:
	return CombatMathRef.create_stat_block({
		"max_hp": max_hp,
		"attack_damage": base_damage,
		"attack_speed": attack_speed,
		"crit_chance": crit_chance,
		"crit_damage": crit_multiplier,
		"armor": armor,
		"health_regen": health_regen
	})

func _finish_attack_hit(target: Node2D, damage_output: Dictionary) -> void:
	if not is_instance_valid(target):
		return
	if target.get("is_dead"):
		return
	var resolved_attack = damage_output
	if target.has_method("get_combat_stats"):
		resolved_attack = get_damage_output(target.get_combat_stats())
	target.take_damage(resolved_attack.final_damage)
	emit_signal("attack_hit", target.global_position, resolved_attack.final_damage, resolved_attack.is_crit)

func _on_attack_finished() -> void:
	is_attacking = false
	body.position = body_base_position

func _reset_attack_pose(clear_attack_state: bool = true) -> void:
	if is_instance_valid(attack_tween):
		attack_tween.kill()
	attack_tween = null
	if clear_attack_state:
		is_attacking = false
	if body:
		body.position = body_base_position
