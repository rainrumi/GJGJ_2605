class_name EnemyEffectOnAdjacentEnemyAcidRecoverSelf
extends EnemyEffectOnAdjacentAcidDamage



# 隣接毎回復量
@export var recovery_per_adjacent := 0

# 効果適用
func apply() -> void:
	EnemyEffectBattleActions.recover(source, source, recovery_per_adjacent * EnemyEffectTargetQuery.get_adjacent_enemies(source, enemies).size())
