class_name EnemyEffectOnAdjacentEnemyAcidRecoverVictim
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_ADJACENT_ACID_DAMAGE


# 依存種別取得
func get_dependency_mask() -> int:
	return DEPENDENCY_ENEMIES

# 隣接毎回復量
@export var recovery_per_adjacent := 0

# 効果適用
func apply() -> void:
	if is_adjacent_acid_damage_activation() and get_adjacent_enemies().has(get_activation_target()): recover(get_activation_target(), recovery_per_adjacent * get_adjacent_enemies().size())
