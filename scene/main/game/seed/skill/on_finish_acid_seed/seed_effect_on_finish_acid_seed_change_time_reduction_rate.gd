class_name SeedEffectOnFinishAcidSeedChangeTimeReductionRate
extends SeedEffect

@export var rate := 0.0 # 短縮率
@export var before_minutes := -1 # 境界分
@export var before_rate := 0.0 # 前率
@export var after_rate := 0.0 # 後率


# 種消化完了
func on_finish_acid_seed(state: DreamSeedSkillState, context: Dictionary) -> bool:
	var minutes := int(context.get("minutes", 0)) # 経過分
	var value := rate # 適用値
	if before_minutes >= 0:
		value += before_rate if minutes < before_minutes else after_rate
	state.next_time_reduction_bonus_rate += value
	return true
