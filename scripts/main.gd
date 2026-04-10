extends Node

const CombatFeedbackControllerRef = preload("res://scripts/combat/combat_feedback_controller.gd")
const CombatTargetingRef = preload("res://scripts/combat/combat_targeting.gd")
const GameServicesRef = preload("res://scripts/core/game_services.gd")

const MAX_ACTIVE_FLOATING_TEXTS := CombatFeedbackControllerRef.MAX_ACTIVE_FLOATING_TEXTS
const DAMAGE_TEXT_OFFSET := CombatFeedbackControllerRef.DAMAGE_TEXT_OFFSET

@onready var hero: Node2D = $CombatArea/Hero
@onready var ability_effects: Node2D = $CombatArea/AbilityEffects
@onready var monster_container: Node = $CombatArea/Monsters
@onready var wave_manager: Node = $WaveManager
@onready var ui_controller: CanvasLayer = $UIArea

var ability_system: Node
var combat_feedback := CombatFeedbackControllerRef.new()

func _ready() -> void:
	ability_system = GameServicesRef.get_ability_system(self)
	combat_feedback.setup(self, ability_effects)

	if wave_manager and wave_manager.has_method("bind_runtime"):
		wave_manager.bind_runtime(hero, monster_container)
	if ui_controller and ui_controller.has_method("bind_runtime"):
		ui_controller.bind_runtime(hero, wave_manager, monster_container)

	hero.hero_died.connect(_on_hero_died)
	hero.attack_hit.connect(_on_hero_attack_hit)
	wave_manager.monster_spawned.connect(_on_monster_spawned)

	if ability_system:
		ability_system.load_from_save()
		if not ability_system.is_connected("ability_triggered", Callable(self, "_on_ability_triggered")):
			ability_system.ability_triggered.connect(_on_ability_triggered)
		ability_system.bind_runtime(self, hero, monster_container, wave_manager)

	for monster in monster_container.get_children():
		_on_monster_spawned(monster)

func _process(delta: float) -> void:
	hero.update_attack_cooldown(delta)
	if hero.is_attack_ready():
		_attack_nearest_monster()

func _attack_nearest_monster() -> void:
	var nearest_monster = CombatTargetingRef.find_nearest_monster(hero, monster_container, hero.attack_range)
	if nearest_monster:
		hero.start_attack(nearest_monster)

func _spawn_floating_text(text_value: String, world_position: Vector2, style_name: String) -> void:
	combat_feedback.show_combat_text(text_value, world_position, style_name)

func show_combat_text(text_value: String, world_position: Vector2, style_name: String) -> void:
	combat_feedback.show_combat_text(text_value, world_position, style_name)

func capture_debug_screenshot(file_name: String = "main_debug.png") -> String:
	var debug_dir = "user://debug"
	var absolute_debug_dir = ProjectSettings.globalize_path(debug_dir)
	DirAccess.make_dir_recursive_absolute(absolute_debug_dir)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var image: Image = null
	var display_name = DisplayServer.get_name()
	if display_name != "headless":
		var viewport_texture = get_viewport().get_texture()
		if viewport_texture:
			image = viewport_texture.get_image()
	if image == null:
		push_warning("Viewport capture is unavailable in this renderer. Saving a debug layout image instead.")
		image = _build_debug_layout_image()

	var screenshot_path = "%s/%s" % [debug_dir, file_name]
	var absolute_screenshot_path = ProjectSettings.globalize_path(screenshot_path)
	var error = image.save_png(absolute_screenshot_path)
	if error != OK:
		push_error("Failed to save screenshot: %s" % absolute_screenshot_path)
		return ""
	return absolute_screenshot_path

func _build_debug_layout_image() -> Image:
	var width = int(ProjectSettings.get_setting("display/window/size/viewport_width", 1080))
	var height = int(ProjectSettings.get_setting("display/window/size/viewport_height", 1920))
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)

	_fill_image_rect(image, Rect2i(0, 0, width, height / 2), Color(0.16, 0.18, 0.22, 1.0))
	_fill_image_rect(image, Rect2i(0, height / 2, width, 8), Color(0.95, 0.75, 0.32, 1.0))
	_fill_image_rect(image, Rect2i(0, height / 2 + 8, width, height / 2 - 8), Color(0.22, 0.22, 0.24, 1.0))

	_fill_image_rect(image, Rect2i(190, 440, 60, 80), Color(1.0, 0.75, 0.8, 1.0))
	_fill_image_rect(image, Rect2i(760, 24 + height / 2, 260, 60), Color(0.96, 0.84, 0.38, 1.0))
	_fill_image_rect(image, Rect2i(40, 180 + height / 2, 460, 300), Color(0.28, 0.30, 0.34, 1.0))

	var monsters = monster_container.get_children()
	if monsters.size() > 0:
		var monster = monsters[0] as Node2D
		if monster:
			var rect_position = Vector2i(int(monster.position.x) - 25, int(monster.position.y) - 30)
			_fill_image_rect(image, Rect2i(rect_position, Vector2i(50, 60)), Color(0.3, 1.0, 0.3, 1.0))

	return image

func _fill_image_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var x_end = min(rect.position.x + rect.size.x, image.get_width())
	var y_end = min(rect.position.y + rect.size.y, image.get_height())
	var x_start = max(rect.position.x, 0)
	var y_start = max(rect.position.y, 0)

	for y in range(y_start, y_end):
		for x in range(x_start, x_end):
			image.set_pixel(x, y, color)

func _on_hero_attack_hit(target_position: Vector2, damage: float, is_crit: bool) -> void:
	combat_feedback.show_hero_attack_damage(target_position, damage, is_crit)

func _on_monster_spawned(monster: Node2D) -> void:
	if monster and monster.has_method("assign_hero"):
		monster.assign_hero(hero)

	var attack_hit_callable := Callable(self, "_on_monster_attack_hit")
	if monster.has_signal("attack_hit") and not monster.is_connected("attack_hit", attack_hit_callable):
		monster.connect("attack_hit", attack_hit_callable)

func _on_monster_attack_hit(target_position: Vector2, damage: float) -> void:
	combat_feedback.show_hero_damage(target_position, damage)

func _on_hero_died() -> void:
	var save_manager = GameServicesRef.require_save_manager(self)
	if save_manager:
		save_manager.reset()
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

func _on_ability_triggered(ability_id: String, target: Node2D, text_value: String, style_name: String) -> void:
	if target == null or not is_instance_valid(target):
		return

	show_combat_text(text_value, target.global_position + DAMAGE_TEXT_OFFSET, style_name)
	var icon_texture = AbilityVisuals.get_icon(ability_id)
	if icon_texture:
		combat_feedback.show_ability_impact(icon_texture, _get_world_visual_bounds(target))

func _get_world_visual_bounds(target: Node2D) -> Rect2:
	if target.has_method("get_visual_bounds"):
		return target.get_visual_bounds()
	return Rect2(target.global_position - Vector2.ONE * 0.5, Vector2.ONE)
