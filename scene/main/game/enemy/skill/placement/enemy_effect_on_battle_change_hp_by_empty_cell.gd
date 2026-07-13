class_name EnemyEffectOnBattleChangeHpByEmptyCell
extends EnemyEffect

# マス毎HP
@export var hp_delta_per_cell := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.REFRESH): context.change_hp(context.source, hp_delta_per_cell * (context.get_empty_cell_count() - context.get_state_int("empty_count"))); context.set_state("empty_count", context.get_empty_cell_count())
