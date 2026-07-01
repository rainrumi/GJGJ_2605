class_name SeedEffectOnHealChangeEffect
extends SeedEffect

@export var heal_bonus_rate := 0.0 # 回復率
@export var heal_to_line_damage_rate := 0.0 # 回復酸化
@export var max_hp_from_recovery_rate := 0.0 # 累計HP率


# 回復補正
func get_heal_bonus_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return heal_bonus_rate


# 戦闘中
func on_battle(state: DreamSeedSkillState, context: Dictionary) -> void:
	var amount := int(context.get("amount", 0)) # 回復量
	state.next_acid_damage_flat_bonus += floori(float(amount) * heal_to_line_damage_rate)


# 最大HP補正
func get_max_hp_bonus_rate(state: DreamSeedSkillState, _context: Dictionary) -> float:
	return float(state.recovery_accumulated_for_max_hp) * max_hp_from_recovery_rate
