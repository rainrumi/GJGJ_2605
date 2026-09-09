class_name SeedEffectOnFireAcidEnemyChangeAcidDamageRate
extends SeedEffect

@export var rate := 0.0 # 変動率


# 酸倍率取得
func get_acid_target_multiplier(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return 1.0 + rate
