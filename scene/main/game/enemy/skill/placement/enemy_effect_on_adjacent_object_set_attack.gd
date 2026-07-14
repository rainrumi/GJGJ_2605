class_name EnemyEffectOnAdjacentObjectSetAttack
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_REFRESH


# 依存種別取得
func get_dependency_mask() -> int:
	return DEPENDENCY_ENEMIES

# 指定攻撃力
@export var attack := 0
# 必要隣接数
@export_range(1, 64, 1) var minimum_count := 1

# 効果適用
func apply() -> void:
	if is_refresh_activation() and get_adjacent_objects().size() >= minimum_count:
		set_attack(source, attack)
