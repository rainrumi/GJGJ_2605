class_name SeedEffectOnFinishAcidSeedChangeAcidDamageRateBeforeClock
extends SeedEffect

@export var rate := 0.0 # 酸倍率
@export var before_minutes := -1 # 境界分


# 種消化完了
func on_finish_acid_seed(state: DreamSeedSkillState, context: Dictionary) -> bool:
	var minutes := int(context.get("minutes", 0)) # 経過分
	if before_minutes >= 0 and minutes >= before_minutes:
		return false
	state.next_acid_damage_bonus_rate += rate
	return true
