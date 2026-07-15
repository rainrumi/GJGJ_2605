class_name EnemyEffectOnDigestedRevive
extends EnemyEffectOnSelfDigested


# 回復割合
@export_range(0.0, 1.0, 0.01) var recovery_rate := 1.0

# 効果適用
func apply() -> void:
	EnemyEffectBattleActions.revive(source, source, recovery_rate)
