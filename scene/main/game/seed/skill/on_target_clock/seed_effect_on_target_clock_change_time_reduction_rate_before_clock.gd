class_name SeedEffectOnTargetClockChangeTimeReductionRateBeforeClock
extends SeedEffect

@export var rate := 0.0 # 短縮率
@export var before_minutes := -1 # 境界分


# 時刻前判定
func get_time_reduction_rate(_state: DreamSeedSkillState, context: Dictionary) -> float:
	var minutes := int(context.get("minutes", 0)) # 経過分
	if before_minutes >= 0 and minutes >= before_minutes:
		return 0.0
	return maxf(rate, 0)
