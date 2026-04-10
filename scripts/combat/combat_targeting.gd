class_name CombatTargeting
extends RefCounted

static func find_nearest_monster(hero: Node2D, monster_container: Node, max_distance: float) -> Node2D:
	if hero == null or monster_container == null:
		return null

	var nearest_monster: Node2D = null
	var nearest_distance := max_distance

	for child in monster_container.get_children():
		var monster := child as Node2D
		if monster == null or bool(monster.get("is_dead")):
			continue

		var distance = monster.global_position.distance_to(hero.global_position)
		if distance > nearest_distance:
			continue

		nearest_distance = distance
		nearest_monster = monster

	return nearest_monster
