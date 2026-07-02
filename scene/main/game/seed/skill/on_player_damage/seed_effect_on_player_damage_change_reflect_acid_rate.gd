class_name SeedEffectOnPlayerDamageChangeReflectAcidRate
extends SeedEffect

@export var reflect_acid_rate := 0.0 # 反射酸率


# 反射酸率
func get_reflect_acid_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return reflect_acid_rate
