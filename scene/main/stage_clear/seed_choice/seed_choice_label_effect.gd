class_name StageClearSeedChoiceLabelEffect
extends Label

enum EffectType {
	MAIN,
	SUB,
}

@export var effect_type: EffectType = EffectType.MAIN

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
	if effect_type == EffectType.SUB and not SeedDescription.has_sub_skill(current_seed):
		text = ""
		return
	text = _get_seed_effect_text(current_seed)


# 効果文取得
func _get_seed_effect_text(seed: SeedInfo) -> String:
	if effect_type == EffectType.MAIN:
		return "メインスキル\n%s" % SeedDescription.get_main_description(seed)
	return "サブスキル\n%s" % SeedDescription.get_sub_description(seed)
