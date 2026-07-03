class_name SeedEffectOnAcidDamageChangeAcidDamageRateByStomachCount
extends SeedEffect

@export var rate := 0.5 # 変動率
@export var max_stomach_count := 3 # 胃内上限


# 消化率取得
func get_acid_damage_rate(_state: DreamSeedSkillState, context: Dictionary) -> float:
	var stomach_count := int(context.get("stomach_count", 0)) # 胃内数
	if stomach_count <= max_stomach_count:
		return rate
	return 0.0
