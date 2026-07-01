class_name SeedEffectOnBattleElapsedAcidDamageRate
extends SeedEffect

@export var base_rate := 0.0 # 基礎倍率
@export var rate_per_minute := 0.0 # 分増加率
@export var start_minutes := -1 # 開始分
@export var max_rate := 999.0 # 上限率


# 消化率取得
func get_acid_damage_rate(_state: DreamSeedSkillState, context: Dictionary) -> float:
	var minutes := int(context.get("minutes", 0)) # 経過分
	var base_minutes := _get_base_minutes(minutes, context) # 基準分
	if start_minutes >= 0 and minutes < start_minutes:
		return 0.0
	var elapsed_minutes := maxi(0, minutes - base_minutes) # 経過分
	var value := base_rate + rate_per_minute * float(elapsed_minutes) # 適用値
	return clampf(value, -max_rate, max_rate)


# 基準分取得
func _get_base_minutes(minutes: int, context: Dictionary) -> int:
	if start_minutes >= 0:
		return start_minutes
	var context_start_minutes := int(context.get("battle_start_minutes", -1)) # 文脈開始
	if context_start_minutes >= 0:
		return context_start_minutes
	return minutes
