class_name GameServices
extends RefCounted

const SAVE_MANAGER_PATH := "/root/SaveManager"
const UPGRADE_SYSTEM_PATH := "/root/UpgradeSystem"
const ABILITY_SYSTEM_PATH := "/root/AbilitySystem"

static func get_save_manager(context: Node) -> Node:
	if context == null:
		return null
	return context.get_node_or_null(SAVE_MANAGER_PATH)

static func get_upgrade_system(context: Node) -> Node:
	if context == null:
		return null
	return context.get_node_or_null(UPGRADE_SYSTEM_PATH)

static func get_ability_system(context: Node) -> Node:
	if context == null:
		return null
	return context.get_node_or_null(ABILITY_SYSTEM_PATH)

static func require_save_manager(context: Node) -> Node:
	var save_manager = get_save_manager(context)
	if save_manager == null and context:
		context.push_error("SaveManager autoload is unavailable.")
	return save_manager

static func require_upgrade_system(context: Node) -> Node:
	var upgrade_system = get_upgrade_system(context)
	if upgrade_system == null and context:
		context.push_error("UpgradeSystem autoload is unavailable.")
	return upgrade_system

static func require_ability_system(context: Node) -> Node:
	var ability_system = get_ability_system(context)
	if ability_system == null and context:
		context.push_error("AbilitySystem autoload is unavailable.")
	return ability_system
