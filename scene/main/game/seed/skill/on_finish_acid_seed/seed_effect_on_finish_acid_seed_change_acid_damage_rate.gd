class_name SeedEffectOnFinishAcidSeedChangeAcidDamageRate
extends SeedEffect

@export var rate := 0.0 # 酸倍率


# 種消化完了
func on_finish_acid_seed(state: DreamSeedSkillState, _context: Dictionary) -> bool:
	state.next_acid_damage_bonus_rate += rate
	return true
