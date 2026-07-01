class_name SeedEffectOnFinishAcidSeedChangeTimeReductionRateAfterClock
extends SeedEffect

@export var rate := 0.0 # 短縮率
@export var start_minutes := -1 # 開始分


# 種消化完了
func on_finish_acid_seed(state: DreamSeedSkillState, context: Dictionary) -> bool:
	var minutes := int(context.get("minutes", 0)) # 経過分
	if start_minutes >= 0 and minutes < start_minutes:
		return false
	state.next_time_reduction_bonus_rate += rate
	return true
