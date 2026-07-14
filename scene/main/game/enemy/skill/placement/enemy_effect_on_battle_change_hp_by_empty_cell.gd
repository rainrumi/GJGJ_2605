class_name EnemyEffectOnBattleChangeHpByEmptyCell
extends EnemyEffect

# マス毎HP
@export var hp_delta_per_cell := 0

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.REFRESH): runtime.change_hp(runtime.source, hp_delta_per_cell * (runtime.get_empty_cell_count() - runtime.get_state_int("empty_count"))); runtime.set_state("empty_count", runtime.get_empty_cell_count())
