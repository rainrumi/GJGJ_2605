class_name EnemyEffectRefreshDefaultAttack
extends EnemyEffectOnRefresh

var disabled := false # 通常攻撃停止


# 効果適用
func apply() -> void:
	EnemyEffectStatChanges.set_default_attack_disabled(source, disabled)
