class_name EnemyEffectOnProgressTimeDisableDefaultAttack
extends EnemyEffectOnRefresh


# 通常攻撃停止
@export var disabled := true

# 効果適用
func apply() -> void:
	EnemyEffectStatChanges.set_default_attack_disabled(source, disabled)
