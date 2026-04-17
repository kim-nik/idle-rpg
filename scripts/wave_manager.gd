extends Node

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal monster_spawned(monster: Node2D)
signal boss_started(chapter_number: int)
signal chapter_completed(chapter_number: int)
signal campaign_state_changed()
signal defeat_triggered(defeat_reason: String)

const GameServicesRef = preload("res://scripts/core/game_services.gd")
const BossFightStateRef = preload("res://scripts/boss_fight_state.gd")
const CampaignProgressStateRef = preload("res://scripts/campaign/campaign_progress_state.gd")
const MONSTER_SCENE := preload("res://scenes/Monster.tscn")

const DEFAULT_MONSTER_SPAWN_X := 900.0
const DEFAULT_MONSTER_SPAWN_Y := 480.0
const BETWEEN_WAVE_DELAY := 3.0
const SPAWN_INTERVAL := 2.0

const WAVES_PER_CHAPTER := 10
const ENEMIES_PER_WAVE := 20
const MAX_ACTIVE_MONSTERS := 10
const WAVE_SCALE_STEP := 0.10
const CHAPTER_SCALE_STEP := 0.25

const BOSS_MONSTER_TYPE := "boss"
const BOSS_HP_MULTIPLIER := 3.0
const BOSS_DAMAGE_MULTIPLIER := 1.75
const BOSS_ARMOR_MULTIPLIER := 1.5
const BOSS_REGEN_MULTIPLIER := 1.5
const BOSS_FIGHT_DURATION := 30.0

var _progress: CampaignProgressState = CampaignProgressStateRef.new()

var current_chapter: int:
	get:
		return _progress.current_chapter
	set(value):
		_progress.current_chapter = value

var current_wave: int:
	get:
		return _progress.current_wave
	set(value):
		_progress.current_wave = value

var highest_unlocked_wave: int:
	get:
		return _progress.highest_unlocked_wave
	set(value):
		_progress.highest_unlocked_wave = value

var is_boss_unlocked: bool:
	get:
		return _progress.is_boss_unlocked
	set(value):
		_progress.is_boss_unlocked = value

var is_in_boss_fight: bool:
	get:
		return _progress.is_in_boss_fight
	set(value):
		_progress.is_in_boss_fight = value

var selected_wave: int:
	get:
		return _progress.selected_wave
	set(value):
		_progress.selected_wave = value

var selected_boss: bool:
	get:
		return _progress.selected_boss
	set(value):
		_progress.selected_boss = value

var monsters_in_wave: int = 0
var total_monsters_in_wave: int = ENEMIES_PER_WAVE
var monsters_killed: int = 0
var enemies_spawned_in_wave: int = 0
var boss_time_remaining: float = 0.0

var spawn_timer: float = 0.0
var spawn_interval: float = SPAWN_INTERVAL
var wave_delay_timer: float = 0.0
var is_wave_active: bool = false
var is_between_waves: bool = false

var _queued_wave: int = -1
var _queued_boss: bool = false

var _status_message: String:
	get:
		return _progress.status_message
	set(value):
		_progress.status_message = value

var hero: Node2D
var monster_container: Node
var boss_fight: BossFightState = BossFightStateRef.new()

func _ready() -> void:
	_connect_boss_fight_signals()
	_resolve_runtime_nodes()
	restart_from_save()

func bind_runtime(next_hero: Node2D, next_monster_container: Node) -> void:
	hero = next_hero
	monster_container = next_monster_container

func load_campaign_from_save() -> void:
	var save_manager = GameServicesRef.require_save_manager(self)
	if save_manager == null:
		return

	_progress.load_from_save(save_manager.save_data)
	total_monsters_in_wave = ENEMIES_PER_WAVE
	monsters_killed = 0
	enemies_spawned_in_wave = 0
	monsters_in_wave = 0
	boss_time_remaining = 0.0
	boss_fight.clear()
	is_wave_active = false
	is_between_waves = false
	_queued_wave = -1
	_queued_boss = false
	spawn_timer = 0.0
	wave_delay_timer = 0.0

func restart_from_save() -> void:
	_clear_active_monsters()
	load_campaign_from_save()
	_progress.clear_status()
	if is_in_boss_fight:
		_begin_boss_fight()
	else:
		_begin_regular_wave(current_wave)

func _process(delta: float) -> void:
	if is_between_waves:
		wave_delay_timer += delta
		if wave_delay_timer >= BETWEEN_WAVE_DELAY:
			_consume_queued_transition()
		return

	if not is_wave_active:
		return

	if _is_boss_stage_active():
		boss_time_remaining = boss_fight.time_remaining
		if boss_fight.tick(delta):
			boss_time_remaining = 0.0
			_handle_boss_timeout()
			return
		boss_time_remaining = boss_fight.time_remaining
		return
	elif is_in_boss_fight:
		push_warning("Boss stage flag was active without a live boss. Restoring boss-ready state.")
		_restore_boss_ready_state()
		return

	if enemies_spawned_in_wave >= total_monsters_in_wave or monsters_in_wave >= MAX_ACTIVE_MONSTERS:
		return

	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_regular_monster()

func get_monster_type_for_wave(wave: int) -> String:
	if wave <= 3:
		return "slime"
	elif wave <= 6:
		return "goblin"
	elif wave <= 9:
		return "orc"
	return "demon"

func get_campaign_snapshot() -> Dictionary:
	var boss_stage_active = _is_boss_stage_active()
	return _progress.create_snapshot(
		monsters_killed,
		total_monsters_in_wave,
		get_auto_next_wave(),
		get_auto_start_boss(),
		boss_stage_active,
		boss_fight.time_remaining if boss_stage_active else 0.0
	)

func get_auto_next_wave() -> bool:
	var save_manager = GameServicesRef.require_save_manager(self)
	if save_manager == null:
		return true
	return bool(save_manager.save_data.get("setting_auto_next_wave", true))

func get_auto_start_boss() -> bool:
	var save_manager = GameServicesRef.require_save_manager(self)
	if save_manager == null:
		return false
	return bool(save_manager.save_data.get("setting_auto_start_boss", false))

func set_auto_next_wave(enabled: bool) -> void:
	var save_manager = GameServicesRef.require_save_manager(self)
	if save_manager == null:
		return
	save_manager.save_data.setting_auto_next_wave = enabled
	save_manager.save()
	emit_signal("campaign_state_changed")

func set_auto_start_boss(enabled: bool) -> void:
	var save_manager = GameServicesRef.require_save_manager(self)
	if save_manager == null:
		return
	save_manager.save_data.setting_auto_start_boss = enabled
	save_manager.save()
	emit_signal("campaign_state_changed")

func select_wave(wave_number: int) -> bool:
	if not _progress.select_wave(wave_number):
		return false
	_persist_campaign_state("select_wave")
	return true

func select_boss() -> bool:
	if not _progress.select_boss():
		return false
	_persist_campaign_state("select_boss")
	return true

func start_selected_target() -> bool:
	_clear_active_monsters()
	_status_message = ""
	if selected_boss:
		if not is_boss_unlocked:
			return false
		return _begin_boss_fight()
	if selected_wave > highest_unlocked_wave:
		return false
	_begin_regular_wave(selected_wave)
	return true

func handle_hero_defeat(defeat_reason: String = "hero_defeat") -> void:
	_clear_active_monsters()
	boss_time_remaining = 0.0
	boss_fight.clear()
	_progress.apply_defeat(defeat_reason)
	is_wave_active = false
	is_between_waves = false
	_queued_wave = -1
	_queued_boss = false
	spawn_timer = 0.0
	wave_delay_timer = 0.0
	enemies_spawned_in_wave = 0
	monsters_killed = 0
	monsters_in_wave = 0
	_persist_campaign_state("defeat")

func _spawn_regular_monster() -> void:
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

	var wave_bonus = _get_regular_wave_bonus(current_wave)
	var monster_type = get_monster_type_for_wave(current_wave)
	monster.setup(monster_type, wave_bonus)
	if monster.has_method("assign_hero"):
		monster.assign_hero(active_hero)
	if active_hero:
		monster.configure_approach(active_hero.global_position.x)
	monster.connect("monster_died", Callable(self, "_on_regular_monster_died").bind(monster))
	enemies_spawned_in_wave += 1
	monsters_in_wave += 1
	emit_signal("monster_spawned", monster)

func _on_regular_monster_died(gold_reward: int, _monster: Node2D = null) -> void:
	var save_manager = GameServicesRef.require_save_manager(self)
	if save_manager == null:
		return

	save_manager.add_gold(gold_reward)
	monsters_in_wave = max(monsters_in_wave - 1, 0)

	if _is_boss_stage_active():
		push_warning("Ignoring regular monster death while boss stage is active")
		return

	monsters_killed += 1
	save_manager.save_data.monsters_killed = monsters_killed
	save_manager.save()

	if monsters_killed >= total_monsters_in_wave:
		_complete_regular_wave()

func _complete_regular_wave() -> void:
	var transition = _progress.complete_regular_wave(get_auto_next_wave(), get_auto_start_boss())
	var completed_wave = int(transition.get("completed_wave", current_wave))
	is_wave_active = false
	is_between_waves = true
	wave_delay_timer = 0.0
	_queued_wave = -1
	_queued_boss = false

	_queue_campaign_transition(transition)

	_persist_campaign_state("wave_complete")
	emit_signal("wave_completed", completed_wave)

func _complete_boss() -> void:
	var transition = _progress.complete_boss()
	var completed_chapter = int(transition.get("completed_chapter", current_chapter))
	is_wave_active = false
	is_between_waves = true
	boss_fight.clear()
	boss_time_remaining = 0.0
	wave_delay_timer = 0.0
	_queued_wave = -1
	_queued_boss = false
	monsters_killed = 0
	enemies_spawned_in_wave = 0
	monsters_in_wave = 0

	_queue_regular_wave(int(transition.get("queue_wave", 1)))
	_persist_campaign_state("chapter_complete")
	emit_signal("chapter_completed", completed_chapter)

func _begin_regular_wave(wave_number: int) -> void:
	_reset_hero_combat_state()
	_progress.begin_regular_wave(wave_number)
	boss_fight.clear()
	boss_time_remaining = 0.0
	is_wave_active = true
	is_between_waves = false
	spawn_timer = 0.0
	wave_delay_timer = 0.0
	_queued_wave = -1
	_queued_boss = false
	monsters_in_wave = 0
	monsters_killed = 0
	enemies_spawned_in_wave = 0
	total_monsters_in_wave = ENEMIES_PER_WAVE

	var save_manager = GameServicesRef.require_save_manager(self)
	if save_manager:
		save_manager.save_data.monsters_killed = 0

	_persist_campaign_state("wave_start")
	emit_signal("wave_started", current_wave)

func _begin_boss_fight() -> bool:
	_reset_hero_combat_state()
	_resolve_runtime_nodes()
	if monster_container == null:
		push_warning("Boss fight start failed: monster container is unavailable")
		_restore_boss_ready_state("Boss start failed")
		return false

	var active_hero = _get_hero()
	var boss_monster = boss_fight.start(
		current_chapter,
		BOSS_FIGHT_DURATION,
		MONSTER_SCENE,
		monster_container,
		active_hero,
		DEFAULT_MONSTER_SPAWN_X,
		DEFAULT_MONSTER_SPAWN_Y,
		BOSS_MONSTER_TYPE,
		_get_regular_wave_bonus(WAVES_PER_CHAPTER),
		{
			"max_hp": BOSS_HP_MULTIPLIER,
			"attack_damage": BOSS_DAMAGE_MULTIPLIER,
			"armor": BOSS_ARMOR_MULTIPLIER,
			"health_regen": BOSS_REGEN_MULTIPLIER
		}
	)
	if boss_monster == null:
		push_warning("Boss fight start failed: boss monster could not be instantiated")
		_restore_boss_ready_state("Boss start failed")
		return false

	_progress.begin_boss_fight()
	is_wave_active = true
	is_between_waves = false
	spawn_timer = 0.0
	wave_delay_timer = 0.0
	_queued_wave = -1
	_queued_boss = false
	monsters_in_wave = 0
	monsters_killed = 0
	enemies_spawned_in_wave = 0
	total_monsters_in_wave = 1
	boss_time_remaining = BOSS_FIGHT_DURATION

	var save_manager = GameServicesRef.require_save_manager(self)
	if save_manager:
		save_manager.save_data.monsters_killed = 0

	boss_time_remaining = boss_fight.time_remaining
	_persist_campaign_state("boss_start")
	emit_signal("boss_started", current_chapter)
	monsters_in_wave = 1
	enemies_spawned_in_wave = 1
	emit_signal("monster_spawned", boss_monster)
	return true

func _queue_regular_wave(wave_number: int) -> void:
	is_between_waves = true
	is_wave_active = false
	wave_delay_timer = 0.0
	_queued_wave = clampi(wave_number, 1, WAVES_PER_CHAPTER)
	_queued_boss = false

func _queue_boss_fight() -> void:
	is_between_waves = true
	is_wave_active = false
	wave_delay_timer = 0.0
	_queued_wave = -1
	_queued_boss = true

func _consume_queued_transition() -> void:
	is_between_waves = false
	wave_delay_timer = 0.0
	if _queued_boss:
		_queued_boss = false
		if not _begin_boss_fight():
			_begin_regular_wave(WAVES_PER_CHAPTER)
		return
	var queued_wave = _queued_wave
	_queued_wave = -1
	if queued_wave > 0:
		_begin_regular_wave(queued_wave)

func _persist_campaign_state(_change_reason: String) -> void:
	var save_manager = GameServicesRef.require_save_manager(self)
	if save_manager == null:
		return

	save_manager.save_data.monsters_killed = monsters_killed
	_progress.write_to_save(save_manager.save_data)
	save_manager.save_data.setting_auto_next_wave = get_auto_next_wave()
	save_manager.save_data.setting_auto_start_boss = get_auto_start_boss()
	save_manager.save()
	emit_signal("campaign_state_changed")

func _handle_boss_timeout() -> void:
	if not _is_boss_stage_active():
		return
	handle_hero_defeat("boss_timeout")
	emit_signal("defeat_triggered", "boss_timeout")

func _get_regular_wave_bonus(wave_number: int) -> float:
	return _get_chapter_multiplier(current_chapter) * _get_regular_wave_multiplier(wave_number)

func _get_chapter_multiplier(chapter_number: int) -> float:
	return 1.0 + max(chapter_number - 1, 0) * CHAPTER_SCALE_STEP

func _get_regular_wave_multiplier(wave_number: int) -> float:
	return 1.0 + max(wave_number - 1, 0) * WAVE_SCALE_STEP

func _queue_campaign_transition(transition: Dictionary) -> void:
	match String(transition.get("queue_kind", "regular_wave")):
		"boss_fight":
			_queue_boss_fight()
		_:
			_queue_regular_wave(int(transition.get("queue_wave", current_wave)))

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

func _clear_active_monsters() -> void:
	_resolve_runtime_nodes()
	boss_fight.clear()
	boss_time_remaining = 0.0
	_reset_hero_combat_state()
	if monster_container == null:
		return
	for child in monster_container.get_children():
		if child.has_signal("monster_died"):
			var death_callable := Callable(self, "_on_regular_monster_died").bind(child)
			if child.is_connected("monster_died", death_callable):
				child.disconnect("monster_died", death_callable)
		if child.has_method("set"):
			child.set("is_dead", true)
		if child.has_method("set_process"):
			child.set_process(false)
		if child is CanvasItem:
			child.visible = false
		child.queue_free()
	monsters_in_wave = 0

func _reset_hero_combat_state() -> void:
	_resolve_runtime_nodes()
	if hero and is_instance_valid(hero) and hero.has_method("cancel_attack"):
		hero.cancel_attack()

func _connect_boss_fight_signals() -> void:
	if boss_fight and boss_fight.has_signal("boss_defeated"):
		var boss_defeated_callable := Callable(self, "_on_boss_defeated")
		if not boss_fight.is_connected("boss_defeated", boss_defeated_callable):
			boss_fight.connect("boss_defeated", boss_defeated_callable)

func _on_boss_defeated(gold_reward: int) -> void:
	if not is_in_boss_fight:
		push_warning("Ignoring boss defeat callback because no active boss stage is running")
		return

	var save_manager = GameServicesRef.require_save_manager(self)
	if save_manager == null:
		return

	boss_fight.clear()
	boss_time_remaining = 0.0
	save_manager.add_gold(gold_reward)
	monsters_in_wave = 0
	monsters_killed = 1
	save_manager.save_data.monsters_killed = 1
	save_manager.save()
	_complete_boss()

func _is_boss_stage_active() -> bool:
	return is_in_boss_fight \
		and boss_fight.is_active() \
		and boss_fight.get_boss_monster() != null \
		and is_instance_valid(boss_fight.get_boss_monster())

func _restore_boss_ready_state(status_message: String = "Boss unlocked") -> void:
	is_wave_active = false
	is_between_waves = false
	spawn_timer = 0.0
	wave_delay_timer = 0.0
	_queued_wave = -1
	_queued_boss = false
	monsters_in_wave = 0
	monsters_killed = 0
	enemies_spawned_in_wave = 0
	total_monsters_in_wave = ENEMIES_PER_WAVE
	boss_time_remaining = 0.0
	boss_fight.clear()
	_progress.restore_boss_ready(status_message)
	_persist_campaign_state("boss_ready_restore")
