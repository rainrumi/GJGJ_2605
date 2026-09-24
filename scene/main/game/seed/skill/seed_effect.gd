class_name SeedEffect
extends Resource


func is_lethal_on_acid_damage() -> bool:
	return false


func get_adjacent_digestion_heal_rate() -> float:
	return 0.0


@export var priority := 0 # 優先度
@export var enabled := true # 有効状態
@export var non_stacking_key := "" # 同じ効果区分内で重複させない効果の識別子
@export_group("効果量・確率の対象変数")
@export var effect_amount_configured := false
@export var effect_amount_fields: PackedStringArray = []
@export var probability_configured := false
@export var probability_fields: PackedStringArray = []
@export_group("")


# 共有定義を変更せず、種ブロックの個体補正を適用した実行用効果を返す。
func adjusted_for_seed_block(seed_block: Enemy) -> SeedEffect:
	if seed_block == null:
		return self
	var amount_multiplier := seed_block.get_seed_effect_multiplier()
	var chance_multiplier := seed_block.get_seed_chance_multiplier()
	var fields := EffectFieldValues.numeric_fields(self)
	var adjusted: SeedEffect = self
	for field in effect_amount_fields:
		if effect_amount_configured and fields.has(field):
			if adjusted == self:
				adjusted = duplicate(true) as SeedEffect
			adjusted.set(field, EffectFieldValues.adjusted_value(get(field), amount_multiplier, false))
	for field in probability_fields:
		if probability_configured and fields.has(field):
			if adjusted == self:
				adjusted = duplicate(true) as SeedEffect
			adjusted.set(field, EffectFieldValues.adjusted_value(get(field), chance_multiplier, true))
	return adjusted


# Whether a newly hovered seed changes StatusPreview without a runtime condition.
func is_unconditional_status_change() -> bool:
	return false


# Whether a newly hovered seed can be evaluated from the StatusPreview context.
func is_status_preview_change() -> bool:
	return is_unconditional_status_change()


# 報酬選択中
func on_selecting_rewerd(_state: DreamSeedSkillState, _context: Dictionary) -> void:
	pass


# 報酬選択後
func on_selected_rewerd(_state: DreamSeedSkillState, _context: Dictionary) -> void:
	pass


# 初期化
func setup(_state: DreamSeedSkillState) -> void:
	pass


# 戦闘中
func on_battle(_state: DreamSeedSkillState, _context: Dictionary) -> void:
	pass


# 時間経過
func on_progress_time(_state: DreamSeedSkillState, _context: Dictionary) -> void:
	pass


# 種消化完了
func on_finish_acid_seed(_state: DreamSeedSkillState, _context: Dictionary) -> bool:
	return false


# 種消化後も戦闘中に効果計算へ参加するか
func persists_after_seed_digested() -> bool:
	return false


# 種ブロック完了
func on_finish_acid_seed_block(_context: Dictionary) -> void:
	pass


# 種ブロック由来の再評価時補正
func apply_seed_block_refresh_modifiers(_context: Dictionary) -> void:
	pass


# 敵消化中
func on_fire_acid_enemy(_state: DreamSeedSkillState, _context: Dictionary) -> void:
	pass


# 消化ダメージ率
func get_acid_damage_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return 1.0


# 消化buff倍率
func get_acid_damage_buff_multiplier(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return 1.0


# 時間短縮率
func get_time_reduction_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return 1.0


# 被ダメ倍率
func get_player_damage_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
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


# 蘇生回復補正率
func get_revive_recovery_bonus_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return 0.0


func get_revive_elapsed_minutes(_state: DreamSeedSkillState, _context: Dictionary) -> int:
	return -1


# 与消化回復率
func get_acid_damage_heal_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return 0.0


# 悪夢消化回復
func get_acided_enemy_heal_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	return 0.0


# 悪夢消化最大HP
func get_acided_enemy_max_hp_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
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


# 同じ種の装備数に応じた胃袋サイズ効果の発動可否
func is_stomach_size_active(_same_seed_count: int) -> bool:
	return true


# 消化行補正
func get_acid_line_rows_delta() -> int:
	return 0
