class_name SeedEffectOnProgressTimeChangeAcidDamageRate
extends SeedEffect

@export var rate_per_minute := 0.0 # 分増加率
@export var start_minutes := -1 # 開始分
@export var max_rate := 999.0 # 上限率


# 時間経過
func on_progress_time(state: DreamSeedSkillState, context: Dictionary) -> void:
	var previous_minutes := int(context.get("previous_minutes", 0)) # 前時刻
	var minutes := int(context.get("minutes", previous_minutes)) # 現時刻
	var elapsed_minutes := _get_active_elapsed_minutes(previous_minutes, minutes) # 対象分
	if elapsed_minutes <= 0:
		return
	state.progress_acid_damage_bonus_rate = clampf(
		state.progress_acid_damage_bonus_rate + rate_per_minute * float(elapsed_minutes),
		-max_rate,
		max_rate
	)


# 対象分取得
func _get_active_elapsed_minutes(previous_minutes: int, minutes: int) -> int:
	if start_minutes < 0:
		return maxi(0, minutes - previous_minutes)
	if minutes <= start_minutes:
		return 0
	return maxi(0, minutes - maxi(previous_minutes, start_minutes))
