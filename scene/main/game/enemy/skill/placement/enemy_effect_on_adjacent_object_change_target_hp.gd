class_name EnemyEffectOnAdjacentObjectChangeTargetHp
extends EnemyEffect

# HP差分
@export var hp_delta := 0
# 対象毎上限
@export_range(0, 64, 1) var max_activations_per_target := 0

# 効果適用
func apply() -> void:
	if not runtime.is_event(Event.REFRESH): return
	for enemy in runtime.get_activatable_new_adjacent(max_activations_per_target): runtime.change_hp(enemy, hp_delta)
