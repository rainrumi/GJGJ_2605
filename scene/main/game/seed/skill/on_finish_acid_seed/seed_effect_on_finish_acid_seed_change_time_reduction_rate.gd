class_name SeedEffectOnFinishAcidSeedChangeTimeReductionRate
extends SeedEffect

@export var rate := 0.0 # 短縮率


# 種消化完了
func on_finish_acid_seed(state: DreamSeedSkillState, _context: Dictionary) -> bool:
	state.next_time_reduction_bonus_rate += rate
	return true
