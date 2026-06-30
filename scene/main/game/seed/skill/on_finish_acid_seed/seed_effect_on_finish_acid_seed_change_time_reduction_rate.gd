class_name SeedEffectOnFinishAcidSeedChangeTimeReductionRate
extends SeedEffect

@export var rate := 0.0
@export var before_minutes := -1
@export var before_rate := 0.0
@export var after_rate := 0.0


# 種消化完了
func on_finish_acid_seed(state: DreamSeedSkillState, context: Dictionary) -> bool:
	var minutes := int(context.get("minutes", 0))
	var value := rate
	if before_minutes >= 0:
		value += before_rate if minutes < before_minutes else after_rate
	state.next_time_reduction_bonus_rate += value
	return true
