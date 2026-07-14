class_name EnemyEffectOnAdjacentObjectChangeTargetMaxHpAndHp
extends EnemyEffect

# 最大HP差分
@export var max_hp_delta := 0
# 現在HP差分
@export var hp_delta := 0

# 効果適用
func apply() -> void:
	if not runtime.is_event(Event.REFRESH): return
	for enemy in runtime.get_adjacent_objects(): runtime.add_max_hp_delta(enemy, max_hp_delta, false)
	for enemy in runtime.get_new_adjacent_objects(): runtime.change_hp(enemy, hp_delta)
