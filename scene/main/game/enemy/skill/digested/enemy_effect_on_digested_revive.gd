class_name EnemyEffectOnDigestedRevive
extends EnemyEffect

# 回復割合
@export_range(0.0, 1.0, 0.01) var recovery_rate := 1.0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.DIGESTED) and context.target == context.source: context.revive(context.source, recovery_rate)
