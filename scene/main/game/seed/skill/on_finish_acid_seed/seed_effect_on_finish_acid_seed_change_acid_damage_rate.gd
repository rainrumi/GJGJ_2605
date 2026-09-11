class_name SeedEffectOnFinishAcidSeedChangeAcidDamageRate
extends SeedEffect

@export var rate := 1.0 # 酸倍率


# 種消化完了
func on_finish_acid_seed(state: DreamSeedSkillState, _context: Dictionary) -> bool:
	state.persistent_acid_damage_bonus_rate += rate - 1.0
	return true
