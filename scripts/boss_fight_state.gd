class_name BossFightState
extends RefCounted

signal boss_defeated(gold_reward: int)

const BOSS_SPAWN_GAP_FROM_HERO := 40.0
const BOSS_APPROACH_DURATION := 0.2

var chapter_number: int = 1
var time_limit: float = 0.0
var time_remaining: float = 0.0
var boss_monster: Node2D
var _is_active: bool = false
var _monster_died_callable: Callable

func start(
	chapter: int,
	duration: float,
	monster_scene: PackedScene,
	monster_container: Node,
	hero: Node2D,
	default_spawn_x: float,
	default_spawn_y: float,
	boss_type: String,
	wave_bonus: float,
	stat_multipliers: Dictionary
) -> Node2D:
	clear()
	chapter_number = max(chapter, 1)
	time_limit = maxf(duration, 0.0)
	time_remaining = time_limit

	if monster_scene == null or monster_container == null:
		push_warning("BossFightState.start failed: monster scene or monster container is missing")
		return null

	var monster = monster_scene.instantiate()
	var spawn_y = hero.position.y if hero else default_spawn_y
	monster_container.add_child(monster)
	monster.setup(boss_type, wave_bonus, stat_multipliers)
	var spawn_x = default_spawn_x
	if hero:
		spawn_x = hero.position.x + monster.attack_range + BOSS_SPAWN_GAP_FROM_HERO
	monster.position = Vector2(spawn_x, spawn_y)
	if monster.has_method("assign_hero"):
		monster.assign_hero(hero)
	if hero and monster.has_method("configure_approach"):
		monster.configure_approach(hero.global_position.x, BOSS_APPROACH_DURATION)
	boss_monster = monster
	_is_active = true
	if boss_monster.has_signal("monster_died"):
		_monster_died_callable = Callable(self, "_on_boss_monster_died")
		if not boss_monster.is_connected("monster_died", _monster_died_callable):
			boss_monster.connect("monster_died", _monster_died_callable, CONNECT_ONE_SHOT)
	return boss_monster

func tick(delta: float) -> bool:
	if not _is_active:
		return false
	time_remaining = maxf(time_remaining - delta, 0.0)
	return time_remaining <= 0.0

func is_active() -> bool:
	return _is_active

func get_boss_monster() -> Node2D:
	return boss_monster

func clear() -> void:
	if boss_monster and is_instance_valid(boss_monster) and not _monster_died_callable.is_null():
		if boss_monster.has_signal("monster_died") and boss_monster.is_connected("monster_died", _monster_died_callable):
			boss_monster.disconnect("monster_died", _monster_died_callable)
	_is_active = false
	time_limit = 0.0
	time_remaining = 0.0
	chapter_number = 1
	boss_monster = null
	_monster_died_callable = Callable()

func _on_boss_monster_died(gold_reward: int) -> void:
	if not _is_active:
		return
	time_remaining = 0.0
	emit_signal("boss_defeated", gold_reward)
