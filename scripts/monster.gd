extends Node2D

signal monster_died(gold_reward: int)
signal monster_attacked(damage: float)

@onready var health_bar: ProgressBar = $HealthBar
@onready var sprite: Sprite2D = $Sprite2D

var monster_type: String = "slime"
var current_hp: float = 50.0
var max_hp: float = 50.0
var attack_power: float = 5.0
var gold_reward: int = 5
var move_speed: float = 30.0

var target_position: Vector2
var is_dead: bool = false
var death_timer: float = 0.0

const MONSTER_STATS := {
	"slime": {"hp": 50.0, "atk": 5.0, "gold": 5.0, "speed": 30.0, "color": Color.GREEN},
	"goblin": {"hp": 100.0, "atk": 10.0, "gold": 10.0, "speed": 40.0, "color": Color.BROWN},
	"orc": {"hp": 200.0, "atk": 20.0, "gold": 20.0, "speed": 35.0, "color": Color.RED},
	"demon": {"hp": 500.0, "atk": 50.0, "gold": 50.0, "speed": 45.0, "color": Color.PURPLE}
}

func _ready() -> void:
	target_position = global_position

func setup(type: String, wave_bonus: float = 1.0) -> void:
	monster_type = type
	var stats = MONSTER_STATS.get(type, MONSTER_STATS.slime)
	max_hp = stats.hp * wave_bonus
	current_hp = max_hp
	attack_power = stats.atk * wave_bonus
	gold_reward = int(stats.gold * wave_bonus)
	move_speed = stats.speed
	sprite.modulate = stats.color
	is_dead = false
	death_timer = 0.0
	visible = true
	modulate.a = 1.0

func _process(delta: float) -> void:
	if is_dead:
		death_timer += delta
		modulate.a = max(0, 1.0 - death_timer)
		if death_timer >= 0.3:
			queue_free()
		return
	
	if global_position.x > target_position.x:
		global_position.x -= move_speed * delta
	else:
		pass

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
	emit_signal("monster_died", gold_reward)

func attack_hero(hero_node: Node2D) -> void:
	if is_dead:
		return
	emit_signal("monster_attacked", attack_power)
	hero_node.take_damage(attack_power)