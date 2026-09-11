class_name SeedEffectOnFinishAcidSeedChangeStomachRows
extends SeedEffect

@export var rows_delta := 0
@export var columns_delta := 0


func on_finish_acid_seed(state: DreamSeedSkillState, context: Dictionary) -> bool:
	var stomach := context.get("stomach") as StomachBoard
	if stomach == null or (rows_delta == 0 and columns_delta == 0):
		return false
	state.persistent_stomach_rows_bonus += rows_delta
	state.persistent_stomach_columns_bonus += columns_delta
	stomach.set_grid_size(stomach.columns + columns_delta, stomach.rows + rows_delta)
	return true
