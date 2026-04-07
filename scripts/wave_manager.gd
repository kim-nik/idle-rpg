extends Node

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal monster_spawned(monster: Node2D)

var current_wave: int = 1
var monsters_in_wave: int = 0
var total_monsters_in_wave: int = 10
var monsters_killed: int = 0

var spawn_timer: float = 0.0
var spawn_interval: float = 2.0
var wave_delay_timer: float = 0.0
var is_wave_active: bool = false
var is_between_waves: bool = true

var monster_container: Node

func _ready() -> void:
	monster_container = get_node("../CombatArea/Monsters")
	load_wave_from_save()
	start_next_wave()

func load_wave_from_save() -> void:
	var save_manager = get_node("/root/SaveManager")
	current_wave = save_manager.save_data.get("wave", 1)
	monsters_killed = save_manager.save_data.get("monsters_killed", 0)

func _process(delta: float) -> void:
	if is_between_waves:
		wave_delay_timer += delta
		if wave_delay_timer >= 3.0:
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
	if not monster_container:
		return
	
	var monster_scene = load("res://scenes/Monster.tscn")
	var monster = monster_scene.instantiate()
	
	var wave_bonus = 1.0 + (current_wave - 1) * 0.1
	var hero = get_node_or_null("../CombatArea/Hero")
	var spawn_y = 480.0
	if hero:
		spawn_y = hero.position.y
	monster.position = Vector2(900, spawn_y)
	monster_container.add_child(monster)

	var monster_type = get_monster_type_for_wave(current_wave)
	monster.setup(monster_type, wave_bonus)
	if hero:
		monster.configure_approach(hero.global_position.x)
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
	else:
		return "demon"

func _on_monster_died(gold_reward: int) -> void:
	var save_manager = get_node("/root/SaveManager")
	save_manager.save_data.gold += gold_reward
	save_manager.save_data.monsters_killed += 1
	monsters_killed += 1
	monsters_in_wave -= 1
	save_manager.save()
	
	if monsters_killed >= total_monsters_in_wave:
		complete_wave()

func complete_wave() -> void:
	is_wave_active = false
	is_between_waves = true
	wave_delay_timer = 0.0
	current_wave += 1
	
	var save_manager = get_node("/root/SaveManager")
	save_manager.save_data.wave = current_wave
	save_manager.save()
	
	emit_signal("wave_completed", current_wave - 1)
