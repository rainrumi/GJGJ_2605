class_name StageClearSeedChoiceLabelEffect
extends Label

var current_seed: SeedInfo


# 種表示
func setup_choice(seed: SeedInfo) -> void:
	current_seed = seed
	_refresh_text()


# 表示更新
func _refresh_text() -> void:
	if current_seed == null:
		text = ""
		return
	text = _get_seed_effect_text(current_seed)


# 効果文取得
func _get_seed_effect_text(seed: SeedInfo) -> String:
	var lines: Array[String] = [
		"メインスキル: %s" % SeedDescription.get_main_description(seed),
	]
	if SeedDescription.has_sub_skill(seed):
		lines.append("サブスキル: %s" % SeedDescription.get_sub_description(seed))
	return "\n".join(lines)
