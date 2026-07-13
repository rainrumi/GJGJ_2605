class_name EnemyEffectOnAdjacentObjectDigestedRevive
extends EnemyEffect

# 回復割合
@export_range(0.0, 1.0, 0.01) var recovery_rate := 1.0
# 復活対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ADJACENT_OBJECTS

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.ADJACENT_DIGESTED) and context.get_targets(target).has(context.target): context.revive(context.target, recovery_rate)
