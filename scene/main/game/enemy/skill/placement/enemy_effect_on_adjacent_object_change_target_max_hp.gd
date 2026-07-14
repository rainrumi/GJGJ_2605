class_name EnemyEffectOnAdjacentObjectChangeTargetMaxHp
extends EnemyEffect

# 最大HP差分
@export var max_hp_delta := 0

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.REFRESH):
		for enemy in runtime.get_adjacent_objects(): runtime.add_max_hp_delta(enemy, max_hp_delta, false)
