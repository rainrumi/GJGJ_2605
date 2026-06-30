class_name SeedEffectOnBattleChangeStomachSize
extends SeedEffect

@export var columns_delta := 0
@export var rows_delta := 0


# 胃袋列補正
func get_stomach_columns_delta() -> int:
	return columns_delta


# 胃袋行補正
func get_stomach_rows_delta() -> int:
	return rows_delta
