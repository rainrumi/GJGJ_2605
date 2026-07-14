class_name EnemyEffectOnAdjacentObjectChangeTargetHp
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_REFRESH


# 依存種別取得
func get_dependency_mask() -> int:
	return DEPENDENCY_ENEMIES

# HP差分
@export var hp_delta := 0
# 対象毎上限
@export_range(0, 64, 1) var max_activations_per_target := 0

# 効果適用
func apply() -> void:
	if not is_refresh_activation(): return
	for enemy in get_activatable_new_adjacent(max_activations_per_target): change_hp(enemy, hp_delta)
