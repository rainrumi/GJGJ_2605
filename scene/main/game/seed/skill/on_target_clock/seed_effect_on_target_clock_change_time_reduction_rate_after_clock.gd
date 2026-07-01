class_name SeedEffectOnTargetClockChangeTimeReductionRateAfterClock
extends SeedEffect

@export var rate := 0.0 # 短縮率
@export var start_minutes := -1 # 開始分


# 時刻後判定
func get_time_reduction_rate(_state: DreamSeedSkillState, context: Dictionary) -> float:
	var minutes := int(context.get("minutes", 0)) # 経過分
	if start_minutes >= 0 and minutes < start_minutes:
		return 0.0
	return maxf(rate, 0)
