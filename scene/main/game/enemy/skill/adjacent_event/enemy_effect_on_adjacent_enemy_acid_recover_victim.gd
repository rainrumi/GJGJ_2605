class_name EnemyEffectOnAdjacentEnemyAcidRecoverVictim
extends EnemyEffect

# 隣接毎回復量
@export var recovery_per_adjacent := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.ADJACENT_ACID_DAMAGE) and context.get_adjacent_enemies().has(context.target): context.recover(context.target, recovery_per_adjacent * context.get_adjacent_enemies().size())
