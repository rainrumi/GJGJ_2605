class_name SeedEffectOnFireAcidEnemyChangeAcidDamageRate
extends SeedEffect

@export var rate := 1.0 # 変動率


# 酸倍率取得
func get_acid_target_multiplier(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return rate
