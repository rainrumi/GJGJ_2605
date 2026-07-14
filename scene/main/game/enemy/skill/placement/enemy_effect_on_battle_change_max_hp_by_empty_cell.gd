class_name EnemyEffectOnBattleChangeMaxHpByEmptyCell
extends EnemyEffect

# マス毎最大HP
@export var max_hp_delta_per_cell := 0

# 効果適用
func apply() -> void:
	if is_refresh_activation(): add_max_hp_delta(source, max_hp_delta_per_cell * get_empty_cell_count(), false)
