class_name EnemyEffectOnProgressTimeDisableDefaultAttack
extends EnemyEffect

# 通常攻撃停止
@export var disabled := true

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.REFRESH): context.resolver.set_default_attack_disabled(context.source, disabled)
