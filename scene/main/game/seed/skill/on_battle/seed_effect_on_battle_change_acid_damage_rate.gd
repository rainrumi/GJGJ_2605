class_name SeedEffectOnBattleChangeAcidDamageRate
extends SeedEffect

@export var rate := 0.0
@export var start_minutes := -1
@export var elapsed_step_rate := 0.0
@export var revive_rate := 0.0
@export var max_rate := 999.0


# 消化率取得
func get_acid_damage_rate(state: DreamSeedSkillState, context: Dictionary) -> float:
	var minutes := int(context.get("minutes", 0))
	if start_minutes >= 0 and minutes < start_minutes:
		return 0.0
	var value := rate
	value += elapsed_step_rate * _get_elapsed_step_count(minutes)
	value += revive_rate * float(state.revive_count)
	return clampf(value, -max_rate, max_rate)


# elapsed数
func _get_elapsed_step_count(minutes: int) -> float:
	return maxf(0.0, float(minutes - 22 * 60) / 30.0)
