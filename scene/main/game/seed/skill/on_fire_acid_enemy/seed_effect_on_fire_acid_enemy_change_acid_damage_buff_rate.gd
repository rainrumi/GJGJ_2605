class_name SeedEffectOnFireAcidEnemyChangeAcidDamageBuffRate
extends SeedEffect

@export var rate := 1.0 # buff倍率


# buff倍率取得
func get_acid_damage_buff_multiplier(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return rate
