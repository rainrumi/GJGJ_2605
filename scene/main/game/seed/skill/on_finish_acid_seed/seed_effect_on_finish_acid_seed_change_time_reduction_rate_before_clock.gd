class_name SeedEffectOnFinishAcidSeedChangeTimeReductionRateBeforeClock
extends SeedEffect

@export var rate := 0.0 # 短縮率
@export var before_minutes := -1 # 境界分


# 種消化完了
func on_finish_acid_seed(state: DreamSeedSkillState, context: Dictionary) -> bool:
	var minutes := int(context.get("minutes", 0)) # 経過分
	if before_minutes >= 0 and minutes >= before_minutes:
		return false
	state.persistent_time_reduction_bonus_rate += rate
	return true
