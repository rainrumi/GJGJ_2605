class_name SeedEffectOnFinishAcidSeedChangeTimeReductionRate
extends SeedEffect

@export var rate := 1.0 # 短縮率


# 種消化完了
func on_finish_acid_seed(state: DreamSeedSkillState, _context: Dictionary) -> bool:
	state.persistent_time_reduction_bonus_rate += 1.0 - rate
	return true
