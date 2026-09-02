class_name SeedEffectOnBattleChangeStomachSize
extends SeedEffect


@export var columns_delta := 0 # 列差分
@export var rows_delta := 0 # 行差分
@export var unique_equipped_seed_only := false # 同じ種が1個だけ装備されている場合のみ有効


func is_unconditional_status_change() -> bool:
	return true


# 胃袋列補正
func get_stomach_columns_delta() -> int:
	return columns_delta


# 胃袋行補正
func get_stomach_rows_delta() -> int:
	return rows_delta


func is_stomach_size_active(same_seed_count: int) -> bool:
	return not unique_equipped_seed_only or same_seed_count == 1
