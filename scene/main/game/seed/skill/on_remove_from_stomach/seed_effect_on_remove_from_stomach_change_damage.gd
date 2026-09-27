class_name SeedEffectOnRemoveFromStomachChangeDamage
extends SeedEffect

@export var final_damage_multiplier := 1.0
@export var damage_rate := -1.0 # 戻し率
@export var acid_damage_rate := 0.0 # 酸戻し率
@export var disable_remove_from_stomach := false # 吐戻し無効
@export var disable_after_seed_acid := false # 種後無効


# 種消化完了
func on_finish_acid_seed(state: DreamSeedSkillState, _context: Dictionary) -> bool:
	if disable_after_seed_acid:
		state.remove_from_stomach_disabled = true
	if not is_equal_approx(final_damage_multiplier, 1.0):
		state.remove_damage_multiplier *= final_damage_multiplier
	return disable_after_seed_acid or not is_equal_approx(final_damage_multiplier, 1.0)


# 吐戻しダメ率
func get_remove_from_stomach_damage_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return damage_rate


# 吐戻し消化率
func get_remove_from_stomach_acid_damage_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return acid_damage_rate


func disables_remove_from_stomach() -> bool:
	return disable_remove_from_stomach
