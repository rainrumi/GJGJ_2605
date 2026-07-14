class_name EnemyEffectOnAdjacentObjectCountChangeSelfAttack
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_REFRESH


# 依存種別取得
func get_dependency_mask() -> int:
	return DEPENDENCY_ENEMIES

# 攻撃差分
@export var attack_delta := 0
# 必要隣接数
@export_range(1, 64, 1) var minimum_count := 1

# 効果適用
func apply() -> void:
	if not is_refresh_activation(): return
	var count := get_adjacent_objects().size() # 隣接数
	if count >= minimum_count: add_attack_delta(source, attack_delta * count)
