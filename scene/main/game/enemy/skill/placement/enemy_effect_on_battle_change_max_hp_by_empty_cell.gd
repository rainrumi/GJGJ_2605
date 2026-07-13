class_name EnemyEffectOnBattleChangeMaxHpByEmptyCell
extends EnemyEffect

# マス毎最大HP
@export var max_hp_delta_per_cell := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.REFRESH): context.add_max_hp_delta(context.source, max_hp_delta_per_cell * context.get_empty_cell_count(), false)
