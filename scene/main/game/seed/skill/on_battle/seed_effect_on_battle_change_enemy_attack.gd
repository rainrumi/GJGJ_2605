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
	var start_minutes := int(context.get("battle_start_minutes", 0)) # 開始分
	var step_minutes := int(context.get("base_step_minutes", 1)) # 間隔分
	if even_interval_attack_delta != 0 and _is_even_elapsed_step(minutes, start_minutes, step_minutes):
		return even_interval_attack_delta
	return 0


# 偶数step判定
func _is_even_elapsed_step(minutes: int, start_minutes: int, step_minutes: int) -> bool:
	var safe_step_minutes := maxi(1, step_minutes) # 安全間隔
	var elapsed_step := floori(float(maxi(0, minutes - start_minutes)) / float(safe_step_minutes)) # 経過step
	return elapsed_step % 2 == 0
