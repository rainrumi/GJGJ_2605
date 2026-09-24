class_name SeedEffectOnBattleChangeReviveElapsedTime
extends SeedEffect

@export var elapsed_minutes := 240


func get_revive_elapsed_minutes(_state: DreamSeedSkillState, _context: Dictionary) -> int:
	return elapsed_minutes
