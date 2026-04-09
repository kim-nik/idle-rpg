extends Node

const FLOATING_TEXT_SCENE := preload("res://scenes/FloatingText.tscn")
const ABILITY_IMPACT_ICON_SCENE := preload("res://scenes/AbilityImpactIcon.tscn")
const MAX_ACTIVE_FLOATING_TEXTS := 12
const MAX_ACTIVE_ABILITY_ICONS := 8
const DAMAGE_TEXT_OFFSET := Vector2(-18, -72)
const HERO_DAMAGE_TEXT_OFFSET := Vector2(-18, -96)
const ABILITY_ICON_OFFSET := Vector2(0, -36)
const COMBAT_TEXT_STYLES := {
	"damage": {"color": Color(1.0, 0.95, 0.82, 1.0), "emphasized": false},
	"crit": {"color": Color(1.0, 0.82, 0.24, 1.0), "emphasized": true},
	"hero_damage": {"color": Color(1.0, 0.45, 0.45, 1.0), "emphasized": false},
	"ability": {"color": Color(0.48, 0.86, 1.0, 1.0), "emphasized": true},
	"heal": {"color": Color(0.45, 1.0, 0.55, 1.0), "emphasized": false},
	"dodge": {"color": Color(0.72, 0.92, 1.0, 1.0), "emphasized": true},
	"block": {"color": Color(0.7, 0.8, 1.0, 1.0), "emphasized": true},
	"resist": {"color": Color(0.82, 0.72, 1.0, 1.0), "emphasized": true}
}

@onready var hero: Node2D = $CombatArea/Hero
@onready var ability_effects: Node2D = $CombatArea/AbilityEffects
@onready var monster_container: Node = $CombatArea/Monsters
@onready var wave_manager: Node = $WaveManager
@onready var ability_system: Node = get_node("/root/AbilitySystem")

var floating_texts: Array[Label] = []
var ability_impact_icons: Array[Sprite2D] = []

func _ready() -> void:
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
	var nearest_monster: Node2D = null
	var min_distance: float = hero.attack_range

	for child in monster_container.get_children():
		var monster = child as Node2D
		if monster and not monster.is_dead:
			var distance = monster.global_position.distance_to(hero.global_position)
			if distance <= min_distance:
				min_distance = distance
				nearest_monster = monster

	if nearest_monster:
		hero.start_attack(nearest_monster)

func _spawn_floating_text(text_value: String, world_position: Vector2, style_name: String) -> void:
	var style = COMBAT_TEXT_STYLES.get(style_name, COMBAT_TEXT_STYLES.damage)
	var floating_text = _get_floating_text_node()
	if floating_text.get_parent() == null:
		add_child(floating_text)
	floating_text.show_value(text_value, world_position, style.color, style.emphasized)
	floating_text.move_to_front()

func show_combat_text(text_value: String, world_position: Vector2, style_name: String) -> void:
	_spawn_floating_text(text_value, world_position, style_name)

func _get_floating_text_node() -> Label:
	if floating_texts.size() < MAX_ACTIVE_FLOATING_TEXTS:
		var new_text = FLOATING_TEXT_SCENE.instantiate() as Label
		floating_texts.append(new_text)
		return new_text

	var recycled_text = floating_texts.pop_front()
	floating_texts.append(recycled_text)
	return recycled_text

func _get_ability_impact_icon_node() -> Sprite2D:
	if ability_impact_icons.size() < MAX_ACTIVE_ABILITY_ICONS:
		var new_icon = ABILITY_IMPACT_ICON_SCENE.instantiate() as Sprite2D
		ability_effects.add_child(new_icon)
		ability_impact_icons.append(new_icon)
		return new_icon

	var recycled_icon = ability_impact_icons.pop_front()
	ability_impact_icons.append(recycled_icon)
	return recycled_icon

func capture_debug_screenshot(file_name: String = "main_debug.png") -> String:
	var debug_dir = "user://debug"
	var absolute_debug_dir = ProjectSettings.globalize_path(debug_dir)
	DirAccess.make_dir_recursive_absolute(absolute_debug_dir)
	await get_tree().process_frame

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

	print("Debug screenshot saved to: %s" % absolute_screenshot_path)
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
	var damage_text = str(int(round(damage)))
	_spawn_floating_text(damage_text, target_position + DAMAGE_TEXT_OFFSET, "crit" if is_crit else "damage")

func _on_monster_spawned(monster: Node2D) -> void:
	var attack_hit_callable := Callable(self, "_on_monster_attack_hit")
	if monster.has_signal("attack_hit") and not monster.is_connected("attack_hit", attack_hit_callable):
		monster.connect("attack_hit", attack_hit_callable)

func _on_monster_attack_hit(target_position: Vector2, damage: float) -> void:
	var damage_text = str(int(round(damage)))
	_spawn_floating_text(damage_text, target_position + HERO_DAMAGE_TEXT_OFFSET, "hero_damage")

func _on_hero_died() -> void:
	var save_manager = get_node("/root/SaveManager")
	save_manager.reset()
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

func _on_ability_triggered(_ability_id: String, position: Vector2, text_value: String, style_name: String) -> void:
	show_combat_text(text_value, position + DAMAGE_TEXT_OFFSET, style_name)
	var icon_texture = AbilityVisuals.get_icon(_ability_id)
	if icon_texture:
		var impact_icon = _get_ability_impact_icon_node()
		impact_icon.show_impact(icon_texture, position + ABILITY_ICON_OFFSET)
