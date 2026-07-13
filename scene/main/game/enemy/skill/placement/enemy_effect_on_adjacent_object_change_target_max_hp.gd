class_name EnemyEffectOnAdjacentObjectChangeTargetMaxHp
extends EnemyEffect

# 最大HP差分
@export var max_hp_delta := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.REFRESH):
		for enemy in context.get_adjacent_objects(): context.add_max_hp_delta(enemy, max_hp_delta, false)
