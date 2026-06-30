class_name SeedEffectOnTargetChangeAcidDamage
extends SeedEffect

@export var multiplier := 1.0
@export var random_chance := 0
@export var random_multiplier := 1.0


# 対象消化倍率
func get_acid_target_multiplier(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	if random_chance > 0 and randi() % random_chance == 0:
		return random_multiplier
	return multiplier


# 種ブロック対象率
func get_seed_block_target_acid_multiplier(_context: Dictionary) -> float:
	if random_chance > 0 and randi() % random_chance == 0:
		return random_multiplier
	return multiplier
