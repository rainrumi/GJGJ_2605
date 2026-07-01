class_name SeedEffect
extends Resource

@export var priority := 0 # 優先度


# 初期化
func setup(_state: DreamSeedSkillState) -> void:
	pass


# 戦闘中
func on_battle(_state: DreamSeedSkillState, _context: Dictionary) -> void:
	pass


# 非戦闘中
func on_not_battle(_state: DreamSeedSkillState, _context: Dictionary) -> void:
	pass


# 時間経過
func on_progress_time(_state: DreamSeedSkillState, _context: Dictionary) -> void:
	pass


# 種消化完了
func on_finish_acid_seed(_state: DreamSeedSkillState, _context: Dictionary) -> bool:
	return false


# 種ブロック完了
func on_finish_acid_seed_block(_context: Dictionary) -> void:
	pass


# 敵消化中
func on_fire_acid_enemy(_state: DreamSeedSkillState, _context: Dictionary) -> void:
	pass


# 時刻までclear
func on_clear_until_clock(_state: DreamSeedSkillState, _context: Dictionary) -> void:
	pass


# 消化ダメージ率
func get_acid_damage_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return 0.0


# 時間短縮率
func get_time_reduction_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return 0.0


# 被ダメ倍率
func get_player_damage_multiplier_bonus(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return 0.0


# 反射消化率
func get_reflect_acid_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return 0.0


# 被撃消化加算
func get_taken_attack_flat_acid_bonus(_state: DreamSeedSkillState, _context: Dictionary) -> int:
	return 0


# 回復補正率
func get_heal_bonus_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return 0.0


# 休憩補正率
func get_rest_recovery_bonus_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return 0.0


# 与消化回復率
func get_acid_damage_heal_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return 0.0


# 悪夢消化回復
func get_acided_nightmare_heal_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return 0.0


# 悪夢消化最大HP
func get_acided_nightmare_max_hp_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return 0.0


# 最大HP補正
func get_max_hp_bonus_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return 0.0


# 時間HP回復
func get_time_hp_recovery_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return 0.0


# 時刻HP回復
func get_hour_hp_recovery_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return 0.0


# 敵攻撃倍率
func get_enemy_attack_multiplier_bonus(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return 0.0


# 敵攻撃差分
func get_enemy_attack_delta(_state: DreamSeedSkillState, _context: Dictionary) -> int:
	return 0


# 対象消化倍率
func get_acid_target_multiplier(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return 1.0


# 吐戻しダメ率
func get_remove_from_stomach_damage_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return -1.0


# 吐戻し消化率
func get_remove_from_stomach_acid_damage_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return 0.0


# 種ブロック率
func get_seed_block_acid_damage_rate(_context: Dictionary) -> float:
	return 0.0


# 種ブロック対象率
func get_seed_block_target_acid_multiplier(_context: Dictionary) -> float:
	return 1.0


# 胃袋列補正
func get_stomach_columns_delta() -> int:
	return 0


# 胃袋行補正
func get_stomach_rows_delta() -> int:
	return 0
