extends Node

@onready var hero: Node2D = $CombatArea/Hero
@onready var monster_container: Node = $CombatArea/Monsters
@onready var wave_manager: Node = $WaveManager

var attack_cooldown: float = 0.0

func _ready() -> void:
	hero.hero_died.connect(_on_hero_died)

func _process(delta: float) -> void:
	attack_cooldown -= delta
	if attack_cooldown <= 0 and hero.try_attack():
		_attack_nearest_monster()
		attack_cooldown = hero.get_attack_interval()

func _attack_nearest_monster() -> void:
	var damage_output = hero.get_damage_output()
	var damage = damage_output.damage
	var is_crit = damage_output.is_crit
	
	var nearest_monster: Node2D = null
	var min_distance: float = 400.0
	
	for child in monster_container.get_children():
		var monster = child as Node2D
		if monster and not monster.is_dead:
			var distance = monster.global_position.distance_to(hero.global_position)
			if distance < min_distance:
				min_distance = distance
				nearest_monster = monster
	
	if nearest_monster:
		nearest_monster.take_damage(damage)
		if is_crit:
			_show_crit_effect(nearest_monster.global_position)

func _show_crit_effect(pos: Vector2) -> void:
	var crit_label = Label.new()
	crit_label.text = "CRIT!"
	crit_label.global_position = pos + Vector2(0, -50)
	crit_label.modulate = Color.YELLOW
	crit_label.add_theme_font_size_override("font_size", 32)
	add_child(crit_label)
	
	var tween = create_tween()
	tween.tween_property(crit_label, "position:y", pos.y - 100, 0.5)
	tween.tween_property(crit_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(crit_label.queue_free)

func _on_hero_died() -> void:
	var save_manager = get_node("/root/SaveManager")
	save_manager.reset()
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()