class_name SeedEffectOnFinishAcidSeedChangeStomachRows
extends SeedEffect

@export var rows_delta := 0


func on_finish_acid_seed(state: DreamSeedSkillState, context: Dictionary) -> bool:
	var stomach := context.get("stomach") as StomachBoard
	if stomach == null or rows_delta == 0:
		return false
	state.persistent_stomach_rows_bonus += rows_delta
	stomach.set_grid_size(stomach.columns, stomach.rows + rows_delta)
	return true
