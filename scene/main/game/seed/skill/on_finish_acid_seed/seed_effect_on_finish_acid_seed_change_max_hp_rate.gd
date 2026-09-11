class_name SeedEffectOnFinishAcidSeedChangeMaxHpRate
extends SeedEffect

@export var rate := 1.0 # 最大HP率


# 種消化完了
func on_finish_acid_seed(state: DreamSeedSkillState, _context: Dictionary) -> bool:
	state.max_hp_bonus_rate += rate - 1.0
	return true
