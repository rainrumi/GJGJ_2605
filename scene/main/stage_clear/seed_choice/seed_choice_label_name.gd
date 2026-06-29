class_name StageClearSeedChoiceLabelName
extends Label

var current_seed: SeedInfo
var debug_numbers_visible := false


# 種表示
func setup_choice(seed: SeedInfo) -> void:
	current_seed = seed
	_refresh_text()


# debug表示
func set_debug_numbers_visible(is_visible: bool) -> void:
	debug_numbers_visible = is_visible
	_refresh_text()


# 表示更新
func _refresh_text() -> void:
	if current_seed == null:
		text = ""
		return
	text = _get_seed_name_text(current_seed)


# 名前取得
func _get_seed_name_text(seed: SeedInfo) -> String:
	if not debug_numbers_visible:
		return seed.display_name
	return "%s ID:%d" % [seed.display_name, seed.skill_id]
