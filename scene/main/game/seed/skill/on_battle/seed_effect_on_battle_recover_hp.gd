class_name SeedEffectOnBattleRecoverHp
extends SeedEffect

@export var acid_damage_heal_rate := 0.0 # 酸回復率
@export var acided_nightmare_heal_rate := 0.0 # 酸敵回復
@export var acided_nightmare_max_hp_rate := 0.0 # 酸敵最大
@export var time_active_count_heal_rate := 0.0 # 時間回復
@export var hour_heal_rate := 0.0 # 時報回復


# 与消化回復
func get_acid_damage_heal_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return acid_damage_heal_rate


# 悪夢消化回復
func get_acided_nightmare_heal_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return acided_nightmare_heal_rate


# 悪夢消化最大HP
func get_acided_nightmare_max_hp_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return acided_nightmare_max_hp_rate


# 時間HP回復
func get_time_hp_recovery_rate(_state: DreamSeedSkillState, context: Dictionary) -> float:
	return time_active_count_heal_rate * float(int(context.get("active_count", 0)))


# 時刻HP回復
func get_hour_hp_recovery_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return hour_heal_rate
