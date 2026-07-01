class_name SeedEffectOnBattleChangeAcidDamageRate
extends SeedEffect

@export var rate := 0.0 # 酸倍率


# 消化率取得
func get_acid_damage_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return rate
