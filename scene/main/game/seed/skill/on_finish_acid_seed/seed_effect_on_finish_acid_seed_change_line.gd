class_name SeedEffectOnFinishAcidSeedChangeLine
extends SeedEffect

@export var line_delta := 0


# 種消化完了
func on_finish_acid_seed(_state: DreamSeedSkillState, _context: Dictionary) -> bool:
	return true
