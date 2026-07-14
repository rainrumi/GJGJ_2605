class_name EnemyEffectOnAdjacentObjectChangeTargetMaxHpAndHp
extends EnemyEffect

# 最大HP差分
@export var max_hp_delta := 0
# 現在HP差分
@export var hp_delta := 0

# 効果適用
func apply() -> void:
	if not is_refresh_activation(): return
	for enemy in get_adjacent_objects(): add_max_hp_delta(enemy, max_hp_delta, false)
	for enemy in get_new_adjacent_objects(): change_hp(enemy, hp_delta)
