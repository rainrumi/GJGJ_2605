class_name SeedEffectOnBattleChangeAcidDamageRate
extends SeedEffect

@export var rate := 0.0 # 酸倍率
@export var max_rate := 999.0 # 上限率


# 消化率取得
func get_acid_damage_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return clampf(rate, -max_rate, max_rate)
