extends Node2D

signal attack_hit(target_position: Vector2, damage: float)
signal monster_died(gold_reward: int)

const CombatMathRef = preload("res://scripts/combat_math.gd")

const TARGET_REACH_DURATION: float = 1.0
const ATTACK_BACKSTEP_DISTANCE: float = 8.0
const ATTACK_LUNGE_DISTANCE: float = 16.0
const ATTACK_BACKSTEP_DURATION: float = 0.08
const ATTACK_LUNGE_DURATION: float = 0.1
const ATTACK_RECOVER_DURATION: float = 0.08
const QUEUE_SPACING: float = 72.0
const DEFAULT_VISUAL_SIZE := Vector2(50.0, 60.0)

@onready var health_bar: ProgressBar = $HealthBar
@onready var body: Node2D = $Body
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D

var monster_type: String = "slime"
var current_hp: float = 50.0
var max_hp: float = 50.0
var attack_power: float = 5.0
var attack_speed: float = 1.0
var armor: float = 0.0
var health_regen: float = 0.0
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
var hero: Node2D

const MONSTER_STATS := {
	"slime": {"hp": 50.0, "atk": 5.0, "gold": 5.0, "speed": 30.0, "attack_speed": 0.7, "armor": 0.0, "health_regen": 0.0, "color": Color.GREEN},
	"goblin": {"hp": 100.0, "atk": 10.0, "gold": 10.0, "speed": 40.0, "attack_speed": 0.75, "armor": 5.0, "health_regen": 0.5, "color": Color.BROWN},
	"orc": {"hp": 200.0, "atk": 20.0, "gold": 20.0, "speed": 35.0, "attack_speed": 0.8, "armor": 10.0, "health_regen": 1.0, "color": Color.RED},
	"demon": {"hp": 500.0, "atk": 50.0, "gold": 50.0, "speed": 45.0, "attack_speed": 0.9, "armor": 18.0, "health_regen": 2.0, "color": Color.PURPLE}
}

func _ready() -> void:
	target_position = global_position
	body_base_position = body.position

func assign_hero(next_hero: Node2D) -> void:
	hero = next_hero

func setup(type: String, wave_bonus: float = 1.0) -> void:
	monster_type = type
	var stats = MONSTER_STATS.get(type, MONSTER_STATS.slime)
	var combat_stats = CombatMathRef.build_monster_stats(stats, wave_bonus)
	max_hp = combat_stats.max_hp
	current_hp = max_hp
	attack_power = combat_stats.attack_damage
	attack_speed = combat_stats.attack_speed
	armor = combat_stats.armor
	health_regen = combat_stats.health_regen
	gold_reward = int(stats.gold * wave_bonus)
	base_move_speed = stats.speed
	move_speed = base_move_speed
	attack_interval = CombatMathRef.get_attack_interval(combat_stats)
	body.modulate = stats.color
	is_dead = false
	death_timer = 0.0
	is_attacking = false
	attack_timer = 0.0
	visible = true
	modulate.a = 1.0
	_reset_attack_pose()
	_update_health_bar()

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

	var active_hero = _resolve_hero()
	if active_hero == null:
		return

	apply_regeneration(delta)
	_update_health_bar()

	var queue_index = _get_queue_index()
	global_position.y = active_hero.global_position.y
	target_position = Vector2(
		active_hero.global_position.x + attack_range + queue_index * QUEUE_SPACING,
		active_hero.global_position.y
	)
	var horizontal_distance = global_position.x - active_hero.global_position.x

	if is_attacking:
		return

	if global_position.x > target_position.x:
		global_position.x = move_toward(global_position.x, target_position.x, move_speed * delta)
		return

	if queue_index > 0:
		return

	horizontal_distance = global_position.x - active_hero.global_position.x
	attack_timer += delta
	if horizontal_distance <= attack_range + 2.0 and attack_timer >= attack_interval:
		attack_timer = 0.0
		attack_hero(active_hero)

func take_damage(damage: float) -> bool:
	current_hp -= damage
	_update_health_bar()

	if current_hp <= 0:
		die()
		return true
	return false

func apply_regeneration(delta: float) -> void:
	current_hp = CombatMathRef.apply_regeneration(current_hp, max_hp, health_regen, delta)

func get_combat_stats() -> Dictionary:
	return CombatMathRef.create_stat_block({
		"max_hp": max_hp,
		"attack_damage": attack_power,
		"attack_speed": attack_speed,
		"armor": armor,
		"health_regen": health_regen,
		"crit_chance": 0.0,
		"crit_damage": 150.0
	})

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
	var resolved_attack = CombatMathRef.resolve_attack(get_combat_stats(), hero_node.get_combat_stats())
	hero_node.take_damage(resolved_attack.final_damage)
	emit_signal("attack_hit", hero_node.global_position, resolved_attack.final_damage)

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

func get_visual_bounds() -> Rect2:
	var polygon_body := _find_polygon_body()
	var polygon_bounds := _build_world_rect_from_points(
		polygon_body,
		polygon_body.polygon if polygon_body else PackedVector2Array()
	)
	if _has_visible_area(polygon_bounds):
		return polygon_bounds

	var collision_bounds := _get_collision_bounds()
	if _has_visible_area(collision_bounds):
		return collision_bounds

	var fallback_center = body.global_position if body else global_position
	return Rect2(fallback_center - DEFAULT_VISUAL_SIZE * 0.5, DEFAULT_VISUAL_SIZE)

func _find_polygon_body() -> Polygon2D:
	return _find_polygon_body_recursive(body)

func _find_polygon_body_recursive(node: Node) -> Polygon2D:
	if node == null:
		return null
	if node is Polygon2D:
		return node as Polygon2D

	for child in node.get_children():
		var polygon_body := _find_polygon_body_recursive(child)
		if polygon_body:
			return polygon_body
	return null

func _get_collision_bounds() -> Rect2:
	if collision_shape == null or collision_shape.shape == null:
		return Rect2()

	var local_points := PackedVector2Array()
	var rectangle_shape := collision_shape.shape as RectangleShape2D
	if rectangle_shape:
		var half_size := rectangle_shape.size * 0.5
		local_points = PackedVector2Array([
			Vector2(-half_size.x, -half_size.y),
			Vector2(half_size.x, -half_size.y),
			Vector2(half_size.x, half_size.y),
			Vector2(-half_size.x, half_size.y)
		])
	else:
		var circle_shape := collision_shape.shape as CircleShape2D
		if circle_shape:
			var radius := circle_shape.radius
			local_points = PackedVector2Array([
				Vector2(-radius, -radius),
				Vector2(radius, -radius),
				Vector2(radius, radius),
				Vector2(-radius, radius)
			])

	return _build_world_rect_from_points(collision_shape, local_points)

func _build_world_rect_from_points(node: Node2D, points: PackedVector2Array) -> Rect2:
	if node == null or points.is_empty():
		return Rect2()

	var first_point = node.to_global(points[0])
	var min_corner = first_point
	var max_corner = first_point

	for point in points:
		var world_point = node.to_global(point)
		min_corner.x = minf(min_corner.x, world_point.x)
		min_corner.y = minf(min_corner.y, world_point.y)
		max_corner.x = maxf(max_corner.x, world_point.x)
		max_corner.y = maxf(max_corner.y, world_point.y)

	return Rect2(min_corner, max_corner - min_corner)

func _has_visible_area(bounds: Rect2) -> bool:
	return bounds.size.x > 0.0 and bounds.size.y > 0.0

func _resolve_hero() -> Node2D:
	if hero and is_instance_valid(hero):
		return hero

	var parent_node = get_parent()
	if parent_node and parent_node.get_parent():
		hero = parent_node.get_parent().get_node_or_null("Hero") as Node2D
	return hero

func _update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
