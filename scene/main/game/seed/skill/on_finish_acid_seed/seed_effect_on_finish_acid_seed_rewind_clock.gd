class_name SeedEffectOnFinishAcidSeedRewindClock
extends SeedEffect

@export var rewind_minutes := 120

func on_finish_acid_seed(state: DreamSeedSkillState, _context: Dictionary) -> bool:
	state.pending_clock_rewind_minutes += maxi(0, rewind_minutes)
	return true
