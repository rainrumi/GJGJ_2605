class_name EnemyTooltip
extends LeftTooltip

var _debug_number_text := ""
var _debug_numbers_visible := false
var _enemy: Enemy


# 敵値表示
func show_enemy(enemy: Enemy, debug_number_text: String, debug_numbers_visible: bool) -> void:
	_disconnect_elapsed_changed()
	_enemy = enemy
	_debug_number_text = debug_number_text
	_debug_numbers_visible = debug_numbers_visible
	set_title(enemy.get_display_name())
	set_note("", false)
	set_entries(_get_enemy_entries(enemy, debug_numbers_visible))
	if enemy.data.definition != null and enemy.data.definition.skill_id == 17010003001:
		enemy.data.stomach_status.elapsed_changed.connect(_on_elapsed_changed)
	if enemy.data.definition != null and enemy.data.definition.lifetime_minutes > 0:
		enemy.data.age_changed.connect(_on_elapsed_changed)
	enemy.data.special_effects_changed.connect(_on_special_effects_changed)
	show_tooltip()


# 敵at表示
func show_enemy_at(
	enemy: Enemy,
	debug_number_text: String,
	debug_numbers_visible: bool,
	anchor_global_position: Vector2
) -> void:
	show_enemy(enemy, debug_number_text, debug_numbers_visible)
	show_tooltip_at(anchor_global_position)


# ツール非表示
func hide_tooltip() -> void:
	visible = false
	_disconnect_elapsed_changed()
	_enemy = null


func _disconnect_elapsed_changed() -> void:
	if _enemy != null and _enemy.data.stomach_status.elapsed_changed.is_connected(_on_elapsed_changed):
		_enemy.data.stomach_status.elapsed_changed.disconnect(_on_elapsed_changed)
	if _enemy != null and _enemy.data.age_changed.is_connected(_on_elapsed_changed):
		_enemy.data.age_changed.disconnect(_on_elapsed_changed)
	if _enemy != null and _enemy.data.special_effects_changed.is_connected(_on_special_effects_changed):
		_enemy.data.special_effects_changed.disconnect(_on_special_effects_changed)


func _on_elapsed_changed(_minutes: int) -> void:
	if visible and _enemy != null:
		set_entries(_get_enemy_entries(_enemy, _debug_numbers_visible))


func _on_special_effects_changed() -> void:
	if visible and _enemy != null:
		set_entries(_get_enemy_entries(_enemy, _debug_numbers_visible))


# デバッグ番号visible設定
func set_debug_numbers_visible(is_visible: bool) -> void:
	if visible and is_visible and not _debug_number_text.is_empty():
		set_entries([
			{
				"explanation": "Debug",
				"value": _debug_number_text,
			},
		])


# 敵項目取得
func _get_enemy_entries(enemy: Enemy, debug_numbers_visible: bool) -> Array:
	if enemy.is_seed_stomach_block():
		return _get_seed_block_entries(enemy, debug_numbers_visible)
	# 項目
	var entries: Array = []
	if debug_numbers_visible and not _debug_number_text.is_empty():
		entries.append({
			"explanation": "Debug",
			"value": _debug_number_text,
		})
	# maineffect文言
	var main_effect_text := enemy.get_main_effect_text()
	if enemy.data.definition != null and enemy.data.definition.skill_id == 17010003001 and not main_effect_text.is_empty():
		main_effect_text += " (経過時間:%.1f時間)" % (float(enemy.stomach_elapsed_minutes) / 60.0)
	if enemy.data.definition != null and enemy.data.definition.lifetime_minutes > 0 and not main_effect_text.is_empty():
		main_effect_text += "(経過時間:%.1f時間)" % (float(enemy.data.age_minutes) / 60)
	entries.append({
		"value": "HP: %d/%d\n攻撃力: %d" % [enemy.current_hp, enemy.max_hp, enemy.get_display_damage()],
	})
	entries.append({
		"explanation": "効果",
		"value": _get_effect_text(main_effect_text),
		"enabled": not main_effect_text.is_empty(),
	})
	_append_special_effects_entry(entries, enemy.data)
	return entries


# effect文言取得
func _get_effect_text(text: String) -> String:
	if text.is_empty():
		return "-"
	return text


# 種ブロック項目取得
func _get_seed_block_entries(enemy: Enemy, debug_numbers_visible: bool) -> Array:
	# 項目
	var entries: Array = []
	if debug_numbers_visible and not _debug_number_text.is_empty():
		entries.append({
			"explanation": "Debug",
			"value": _debug_number_text,
		})
	entries.append_array([
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
			"value": _get_seed_block_effect_text(enemy.seed_info),
		},
	])
	_append_special_effects_entry(entries, enemy.data)
	return entries


func _append_special_effects_entry(entries: Array, enemy_data: EnemyData) -> void:
	var effects: Array[String] = []
	for effect: int in enemy_data.special_effects:
		var amount := enemy_data.special_effects[effect]
		var name := EnemyData.get_special_effect_name(effect)
		if amount > 0 and not name.is_empty():
			effects.append("%s+%d" % [name, amount])
	if not effects.is_empty():
		entries.append({"explanation": "特殊効果", "value": ", ".join(effects)})


# 種ブロックeffect文言取得
func _get_seed_block_effect_text(seed: SeedInfo) -> String:
	if seed == null:
		return "-"
	return SeedDescription.get_sub_description(seed)
