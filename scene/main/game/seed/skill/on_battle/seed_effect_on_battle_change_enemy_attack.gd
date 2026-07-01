class_name SeedEffectOnBattleChangeEnemyAttack
extends SeedEffect

@export var attack_multiplier_bonus := 0.0 # 攻撃倍率
@export var even_interval_attack_delta := 0 # 偶数攻撃


# 敵攻撃倍率
func get_enemy_attack_multiplier_bonus(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return attack_multiplier_bonus


# 敵攻撃差分
func get_enemy_attack_delta(_state: DreamSeedSkillState, context: Dictionary) -> int:
	var minutes := int(context.get("minutes", 0)) # 経過分
	if even_interval_attack_delta != 0 and int(minutes / 30) % 2 == 0:
		return even_interval_attack_delta
	return 0
