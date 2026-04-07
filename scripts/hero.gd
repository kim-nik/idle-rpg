extends Node2D

signal attack_hit(target_position: Vector2, damage: float, is_crit: bool)
signal hero_died()

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

func _process(_delta: float) -> void:
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
		_reset_attack_pose()
		emit_signal("hero_died")

func heal(amount: float) -> void:
	current_hp = min(current_hp + amount, max_hp)

func update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp

func get_attack_interval() -> float:
	return 1.0 / attack_speed

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

func get_damage_output() -> Dictionary:
	var damage = base_damage
	var is_crit = randf() * 100.0 < crit_chance
	if is_crit:
		damage *= crit_multiplier / 100.0
	return {"damage": damage, "is_crit": is_crit}

func _finish_attack_hit(target: Node2D, damage_output: Dictionary) -> void:
	if not is_instance_valid(target):
		return
	if target.get("is_dead"):
		return
	target.take_damage(damage_output["damage"])
	emit_signal("attack_hit", target.global_position, damage_output["damage"], damage_output["is_crit"])

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
