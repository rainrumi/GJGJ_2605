class_name SeedEffectOnPlayerDamageChangeDamage
extends SeedEffect

@export var damage_multiplier_bonus := 0.0 # 被弾倍率
@export var reflect_acid_rate := 0.0 # 反射酸率
@export var flat_acid_rate := 0.0 # 固定酸率


# 被ダメ倍率
func get_player_damage_multiplier_bonus(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return damage_multiplier_bonus


# 反射消化率
func get_reflect_acid_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return reflect_acid_rate


# 被撃消化加算
func get_taken_attack_flat_acid_bonus(_state: DreamSeedSkillState, context: Dictionary) -> int:
	return floori(float(int(context.get("taken_damage", 0))) * flat_acid_rate)
