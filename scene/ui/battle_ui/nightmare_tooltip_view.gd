class_name NightmareTooltipView
extends LeftTooltipView

var _debug_number_text := ""


func show_enemy(enemy: Enemy, debug_number_text: String, debug_numbers_visible: bool) -> void:
	_debug_number_text = debug_number_text
	set_title("" if enemy.is_seed_stomach_block() else enemy.get_display_name())
	set_note("", false)
	set_entries(_get_enemy_entries(enemy, debug_numbers_visible))
	visible = true


func show_enemy_at(
	enemy: Enemy,
	debug_number_text: String,
	debug_numbers_visible: bool,
	anchor_global_position: Vector2
) -> void:
	show_enemy(enemy, debug_number_text, debug_numbers_visible)
	show_tooltip_at(anchor_global_position)


func hide_tooltip() -> void:
	visible = false


func set_debug_numbers_visible(is_visible: bool) -> void:
	if visible and is_visible and not _debug_number_text.is_empty():
		set_entries([
			{
				"explanation": "Debug",
				"value": _debug_number_text,
			},
		])


func _get_enemy_entries(enemy: Enemy, debug_numbers_visible: bool) -> Array:
	if enemy.is_seed_stomach_block():
		return _get_seed_block_entries(enemy, debug_numbers_visible)
	var entries: Array = []
	if debug_numbers_visible and not _debug_number_text.is_empty():
		entries.append({
			"explanation": "Debug",
			"value": _debug_number_text,
		})
	var main_effect_text := enemy.get_main_effect_text()
	entries.append({
		"value": "HP: %d/%d\n攻撃力: %d" % [enemy.current_hp, enemy.max_hp, enemy.get_display_damage()],
	})
	entries.append({
		"explanation": "メイン効果",
		"value": _get_effect_text(main_effect_text),
		"enabled": not main_effect_text.is_empty(),
	})
	return entries


func _get_effect_text(text: String) -> String:
	if text.is_empty():
		return "-"
	return text


func _get_seed_block_entries(enemy: Enemy, debug_numbers_visible: bool) -> Array:
	var entries: Array = []
	if debug_numbers_visible and not _debug_number_text.is_empty():
		entries.append({
			"explanation": "Debug",
			"value": _debug_number_text,
		})
	entries.append_array([
		{
			"explanation": "名称",
			"value": enemy.get_display_name(),
		},
		{
			"explanation": "HP",
			"value": "%d/%d" % [enemy.current_hp, enemy.max_hp],
		},
		{
			"explanation": "攻撃力",
			"value": "%d" % enemy.get_display_damage(),
		},
		{
			"explanation": "効果",
			"value": _get_seed_block_effect_text(enemy.seed_skill_info),
		},
	])
	return entries


func _get_seed_block_effect_text(seed_skill: SeedInfo) -> String:
	if seed_skill == null:
		return "-"
	return DreamSeedSkillDescriptionFormatter.get_sub_description(seed_skill)
