class_name EnemyEffectOnBattleChangeHpByEmptyCell
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_REFRESH


# 依存種別取得
func get_dependency_mask() -> int:
	return DEPENDENCY_ENEMIES | DEPENDENCY_STOMACH

# マス毎HP
@export var hp_delta_per_cell := 0

# 効果適用
func apply() -> void:
	if is_refresh_activation(): change_hp(source, hp_delta_per_cell * (get_empty_cell_count() - get_state_int("empty_count"))); set_state("empty_count", get_empty_cell_count())
