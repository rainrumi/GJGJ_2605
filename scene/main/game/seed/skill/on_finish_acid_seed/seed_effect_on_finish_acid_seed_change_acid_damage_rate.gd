class_name SeedEffectOnFinishAcidSeedChangeAcidDamageRate
extends SeedEffect

@export var rate := 0.0
@export var start_minutes := -1


# 種消化完了
func on_finish_acid_seed(state: DreamSeedSkillState, context: Dictionary) -> bool:
	if start_minutes >= 0 and int(context.get("minutes", 0)) < start_minutes:
		return false
	state.next_acid_damage_bonus_rate += rate
	return true
