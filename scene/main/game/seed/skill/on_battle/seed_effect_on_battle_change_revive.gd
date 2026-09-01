class_name SeedEffectOnBattleChangeRevive
extends SeedEffect

@export var recovery_bonus_rate := 0.0 # 蘇生回復率


# 蘇生回復補正率
func get_revive_recovery_bonus_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return recovery_bonus_rate
