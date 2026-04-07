extends Node2D

signal monster_died(gold_reward: int)

const TARGET_REACH_DURATION: float = 1.0
const ATTACK_BACKSTEP_DISTANCE: float = 8.0
const ATTACK_LUNGE_DISTANCE: float = 16.0
const ATTACK_BACKSTEP_DURATION: float = 0.08
const ATTACK_LUNGE_DURATION: float = 0.1
const ATTACK_RECOVER_DURATION: float = 0.08
const QUEUE_SPACING: float = 72.0

@onready var health_bar: ProgressBar = $HealthBar
@onready var body: Node2D = $Body

var monster_type: String = "slime"
var current_hp: float = 50.0
var max_hp: float = 50.0
var attack_power: float = 5.0
var gold_reward: int = 5
var move_speed: float = 30.0
var base_move_speed: float = 30.0
var attack_interval: float = 1.5
var attack_timer: float = 0.0
var attack_range: float = 120.0

var target_position: Vector2
var is_dead: bool = false
var death_timer: float = 0.0
var is_attacking: bool = false
var body_base_position: Vector2 = Vector2.ZERO
var attack_tween: Tween

const MONSTER_STATS := {
	"slime": {"hp": 50.0, "atk": 5.0, "gold": 5.0, "speed": 30.0, "color": Color.GREEN},
	"goblin": {"hp": 100.0, "atk": 10.0, "gold": 10.0, "speed": 40.0, "color": Color.BROWN},
	"orc": {"hp": 200.0, "atk": 20.0, "gold": 20.0, "speed": 35.0, "color": Color.RED},
	"demon": {"hp": 500.0, "atk": 50.0, "gold": 50.0, "speed": 45.0, "color": Color.PURPLE}
}

func _ready() -> void:
	target_position = global_position
	body_base_position = body.position

func setup(type: String, wave_bonus: float = 1.0) -> void:
	monster_type = type
	var stats = MONSTER_STATS.get(type, MONSTER_STATS.slime)
	max_hp = stats.hp * wave_bonus
	current_hp = max_hp
	attack_power = stats.atk * wave_bonus
	gold_reward = int(stats.gold * wave_bonus)
	base_move_speed = stats.speed
	move_speed = base_move_speed
	body.modulate = stats.color
	is_dead = false
	death_timer = 0.0
	is_attacking = false
	attack_timer = 0.0
	visible = true
	modulate.a = 1.0
	_reset_attack_pose()

func configure_approach(hero_x: float, duration: float = TARGET_REACH_DURATION) -> void:
	var desired_duration = max(duration, 0.01)
	var desired_x = hero_x + attack_range
	move_speed = max(base_move_speed, abs(global_position.x - desired_x) / desired_duration)

func _process(delta: float) -> void:
	if is_dead:
		death_timer += delta
		modulate.a = max(0, 1.0 - death_timer)
		if death_timer >= 0.3:
			queue_free()
		return

	var hero = get_node_or_null("../../Hero")
	if hero == null:
		return

	var queue_index = _get_queue_index()
	global_position.y = hero.global_position.y
	target_position = Vector2(
		hero.global_position.x + attack_range + queue_index * QUEUE_SPACING,
		hero.global_position.y
	)
	var horizontal_distance = global_position.x - hero.global_position.x

	if is_attacking:
		return

	if global_position.x > target_position.x:
		global_position.x = move_toward(global_position.x, target_position.x, move_speed * delta)
		return

	if queue_index > 0:
		return

	horizontal_distance = global_position.x - hero.global_position.x
	attack_timer += delta
	if horizontal_distance <= attack_range + 2.0 and attack_timer >= attack_interval:
		attack_timer = 0.0
		attack_hero(hero)

func take_damage(damage: float) -> bool:
	current_hp -= damage
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
	
	if current_hp <= 0:
		die()
		return true
	return false

func die() -> void:
	is_dead = true
	_reset_attack_pose()
	emit_signal("monster_died", gold_reward)

func attack_hero(hero_node: Node2D) -> void:
	if is_dead or is_attacking:
		return
	if not is_instance_valid(hero_node):
		return

	is_attacking = true
	_reset_attack_pose(false)
	attack_tween = create_tween()
	attack_tween.tween_property(
		body,
		"position:x",
		body_base_position.x + ATTACK_BACKSTEP_DISTANCE,
		ATTACK_BACKSTEP_DURATION
	)
	attack_tween.tween_property(
		body,
		"position:x",
		body_base_position.x - ATTACK_LUNGE_DISTANCE,
		ATTACK_LUNGE_DURATION
	)
	attack_tween.tween_callback(func() -> void:
		_finish_attack(hero_node)
	)
	attack_tween.tween_property(body, "position", body_base_position, ATTACK_RECOVER_DURATION)
	attack_tween.finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)

func _finish_attack(hero_node: Node2D) -> void:
	if is_dead:
		return
	if not is_instance_valid(hero_node):
		return
	hero_node.take_damage(attack_power)

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

func _get_queue_index() -> int:
	var monsters = []
	var container = get_parent()
	if container == null:
		return 0

	for child in container.get_children():
		if child is Node2D and not child.is_dead:
			monsters.append(child)

	monsters.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		if is_equal_approx(a.global_position.x, b.global_position.x):
			return a.get_instance_id() < b.get_instance_id()
		return a.global_position.x < b.global_position.x
	)
	return monsters.find(self)
