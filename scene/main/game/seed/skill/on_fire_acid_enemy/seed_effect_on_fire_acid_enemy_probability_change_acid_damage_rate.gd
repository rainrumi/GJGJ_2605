class_name SeedEffectOnFireAcidEnemyProbabilityChangeAcidDamageRate
extends SeedEffect

@export var probabirlity := 0.0 # 確率
@export var rate := 1.0 # 変動率


# 酸倍率抽選
func get_acid_target_multiplier(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	if probabirlity <= 0.0:
		return 1.0
	if randf() <= probabirlity:
		return rate
	return 1.0
