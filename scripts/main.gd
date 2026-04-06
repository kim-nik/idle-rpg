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

func _on_hero_died() -> void:
	var save_manager = get_node("/root/SaveManager")
	save_manager.reset()
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
