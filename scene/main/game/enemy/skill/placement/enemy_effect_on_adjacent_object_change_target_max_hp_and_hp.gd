class_name EnemyEffectOnAdjacentObjectChangeTargetMaxHpAndHp
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_REFRESH


# 依存種別取得
func get_dependency_mask() -> int:
	return DEPENDENCY_ENEMIES

# 最大HP差分
@export var max_hp_delta := 0
# 現在HP差分
@export var hp_delta := 0

# 効果適用
func apply() -> void:
	if not is_refresh_activation(): return
	for enemy in get_adjacent_objects(): add_max_hp_delta(enemy, max_hp_delta, false)
	for enemy in get_new_adjacent_objects(): change_hp(enemy, hp_delta)
