class_name EnemyEffectOnAdjacentObjectChangeTargetMaxHp
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_REFRESH


# 依存種別取得
func get_dependency_mask() -> int:
	return DEPENDENCY_ENEMIES

# 最大HP差分
@export var max_hp_delta := 0

# 効果適用
func apply() -> void:
	if is_refresh_activation():
		for enemy in get_adjacent_objects(): add_max_hp_delta(enemy, max_hp_delta, false)
