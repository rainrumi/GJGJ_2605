class_name EnemyEffectOnAdjacentEnemyAcidRecoverSelf
extends EnemyEffect

# 隣接毎回復量
@export var recovery_per_adjacent := 0

# 効果適用
func apply() -> void:
	if is_adjacent_acid_damage_activation() and get_adjacent_enemies().has(get_activation_target()): recover(source, recovery_per_adjacent * get_adjacent_enemies().size())
