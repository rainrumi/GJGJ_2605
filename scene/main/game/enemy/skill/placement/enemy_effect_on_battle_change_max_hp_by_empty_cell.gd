class_name EnemyEffectOnBattleChangeMaxHpByEmptyCell
extends EnemyEffect

# マス毎最大HP
@export var max_hp_delta_per_cell := 0

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.REFRESH): runtime.add_max_hp_delta(runtime.source, max_hp_delta_per_cell * runtime.get_empty_cell_count(), false)
