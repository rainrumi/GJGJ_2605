class_name EnemyEffectOnDigestedReviveIfOtherObject
extends EnemyEffect

# 回復割合
@export_range(0.0, 1.0, 0.01) var recovery_rate := 1.0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if not context.is_event(Event.DIGESTED) or context.target != context.source: return
	if context.get_active_objects().any(func(enemy: Enemy) -> bool: return enemy != context.source): context.revive(context.source, recovery_rate)
