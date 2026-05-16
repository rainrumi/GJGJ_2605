class_name NightmareTooltipView
extends LeftTooltipView

var _debug_number_text := ""


func show_enemy(enemy: Enemy, debug_number_text: String, debug_numbers_visible: bool) -> void:
	_debug_number_text = debug_number_text
	set_title(enemy.get_display_name())
	set_note("", false)
	set_entries(_get_enemy_entries(enemy, debug_numbers_visible))
	visible = true


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
	var entries: Array = []
	if debug_numbers_visible and not _debug_number_text.is_empty():
		entries.append({
			"explanation": "Debug",
			"value": _debug_number_text,
		})
	entries.append({
		"explanation": enemy.get_category_name(),
		"value": _get_effect_text(enemy.get_category_detail()),
	})
	entries.append({
		"explanation": "ステータス",
		"value": "HP: %d/%d\n攻撃力: %d" % [enemy.current_hp, enemy.max_hp, enemy.get_display_damage()],
	})
	entries.append({
		"explanation": "メイン効果",
		"value": _get_effect_text(enemy.get_main_effect_text()),
	})
	return entries


func _get_effect_text(text: String) -> String:
	if text.is_empty():
		return "-"
	return text
