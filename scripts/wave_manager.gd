extends Node

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal monster_spawned(monster: Node2D)

const GameServicesRef = preload("res://scripts/core/game_services.gd")
const MONSTER_SCENE := preload("res://scenes/Monster.tscn")
const DEFAULT_MONSTER_SPAWN_X := 900.0
const DEFAULT_MONSTER_SPAWN_Y := 480.0
const BETWEEN_WAVE_DELAY := 3.0

var current_wave: int = 1
var monsters_in_wave: int = 0
var total_monsters_in_wave: int = 10
var monsters_killed: int = 0

var spawn_timer: float = 0.0
var spawn_interval: float = 2.0
var wave_delay_timer: float = 0.0
var is_wave_active: bool = false
var is_between_waves: bool = true

var hero: Node2D
var monster_container: Node

func _ready() -> void:
	_resolve_runtime_nodes()
	load_wave_from_save()
	start_next_wave()

func bind_runtime(next_hero: Node2D, next_monster_container: Node) -> void:
	hero = next_hero
	monster_container = next_monster_container

func load_wave_from_save() -> void:
	var save_manager = GameServicesRef.require_save_manager(self)
	if save_manager == null:
		return
	current_wave = int(save_manager.save_data.get("wave", 1))
	monsters_killed = int(save_manager.save_data.get("monsters_killed", 0))

func _process(delta: float) -> void:
	if is_between_waves:
		wave_delay_timer += delta
		if wave_delay_timer >= BETWEEN_WAVE_DELAY:
			start_next_wave()
		return

	if is_wave_active and monsters_in_wave < total_monsters_in_wave:
		spawn_timer += delta
		if spawn_timer >= spawn_interval:
			spawn_timer = 0.0
			spawn_monster()

func start_next_wave() -> void:
	is_between_waves = false
	is_wave_active = true
	monsters_in_wave = 0
	monsters_killed = 0
	spawn_timer = 0.0
	emit_signal("wave_started", current_wave)

func spawn_monster() -> void:
	_resolve_runtime_nodes()
	if monster_container == null:
		return

	var monster = MONSTER_SCENE.instantiate()
	var active_hero = _get_hero()
	var spawn_y = DEFAULT_MONSTER_SPAWN_Y
	if active_hero:
		spawn_y = active_hero.position.y
	monster.position = Vector2(DEFAULT_MONSTER_SPAWN_X, spawn_y)
	monster_container.add_child(monster)

	var wave_bonus = 1.0 + (current_wave - 1) * 0.1
	var monster_type = get_monster_type_for_wave(current_wave)
	monster.setup(monster_type, wave_bonus)
	if monster.has_method("assign_hero"):
		monster.assign_hero(active_hero)
	if active_hero:
		monster.configure_approach(active_hero.global_position.x)
	monster.connect("monster_died", _on_monster_died)
	monsters_in_wave += 1
	emit_signal("monster_spawned", monster)

func get_monster_type_for_wave(wave: int) -> String:
	if wave <= 3:
		return "slime"
	elif wave <= 6:
		return "goblin"
	elif wave <= 9:
		return "orc"
	return "demon"

func _on_monster_died(gold_reward: int) -> void:
	var save_manager = GameServicesRef.require_save_manager(self)
	if save_manager == null:
		return

	save_manager.add_gold(gold_reward)
	save_manager.add_monsters_killed(1)
	monsters_killed += 1
	monsters_in_wave = max(monsters_in_wave - 1, 0)
	save_manager.save()

	if monsters_killed >= total_monsters_in_wave:
		complete_wave()

func complete_wave() -> void:
	is_wave_active = false
	is_between_waves = true
	wave_delay_timer = 0.0
	current_wave += 1

	var save_manager = GameServicesRef.require_save_manager(self)
	if save_manager == null:
		return

	save_manager.set_save_field("wave", current_wave)
	save_manager.save()
	emit_signal("wave_completed", current_wave - 1)

func _get_hero() -> Node2D:
	_resolve_runtime_nodes()
	return hero

func _resolve_runtime_nodes() -> void:
	var main_scene = get_parent()
	if main_scene == null:
		return
	var combat_area = main_scene.get_node_or_null("CombatArea")
	if combat_area == null:
		return

	if hero == null or not is_instance_valid(hero):
		hero = combat_area.get_node_or_null("Hero") as Node2D
	if monster_container == null or not is_instance_valid(monster_container):
		monster_container = combat_area.get_node_or_null("Monsters")
