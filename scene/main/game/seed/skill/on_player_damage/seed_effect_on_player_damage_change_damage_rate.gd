class_name SeedEffectOnPlayerDamageChangeDamageRate
extends SeedEffect

@export var damage_rate := 0.0 # 被弾倍率


# 被ダメ倍率
func get_player_damage_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return damage_rate
