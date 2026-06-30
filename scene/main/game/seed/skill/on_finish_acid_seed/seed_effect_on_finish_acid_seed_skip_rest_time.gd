class_name SeedEffectOnFinishAcidSeedSkipRestTime
extends SeedEffect

@export var skip_count := 1


# 種消化完了
func on_finish_acid_seed(_state: DreamSeedSkillState, _context: Dictionary) -> bool:
	return skip_count > 0
