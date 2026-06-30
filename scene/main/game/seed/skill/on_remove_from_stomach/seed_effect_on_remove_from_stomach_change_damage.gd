class_name SeedEffectOnRemoveFromStomachChangeDamage
extends SeedEffect

@export var damage_rate := -1.0
@export var acid_damage_rate := 0.0
@export var disable_after_seed_acid := false


# 種消化完了
func on_finish_acid_seed(state: DreamSeedSkillState, _context: Dictionary) -> bool:
	if disable_after_seed_acid:
		state.remove_from_stomach_disabled = true
		return true
	return false


# 吐戻しダメ率
func get_remove_from_stomach_damage_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return damage_rate


# 吐戻し消化率
func get_remove_from_stomach_acid_damage_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return acid_damage_rate
