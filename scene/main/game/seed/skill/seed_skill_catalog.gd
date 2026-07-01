class_name SeedSkillCatalog
extends RefCounted


# main取得
static func get_main_skill(skill_id: int) -> SeedSkill:
	match skill_id:
		1001, 100101:
			return _skill([_acid_rate(0.10)])
		1003, 100103:
			return _skill([_time_rate(0.05)])
		2002, 100105:
			return _skill([_player_damage(0.30, 0.0, 0.30)])
		2004, 100107:
			return _skill([])
		2005, 100108:
			return _skill([_acid_rate(0.10)])
		2107, 100109:
			return _skill([_target_multiplier(1.20)])
		2108, 100110:
			return _skill([_target_multiplier(1.0, 20, 3.0)])
		2110, 100111:
			return _skill([_acid_rate(0.06)])
		2113, 100112:
			return _skill([_acid_rate(-0.20)])
		2118, 100115:
			return _skill([_stomach_size(1, 0)])
		2119, 100116:
			return _skill([_stomach_size(0, 1)])
		2121, 100117:
			return _skill([_recover_hp(0.0, 0.0, 0.0, 0.01, 0.0)])
		2123, 100118:
			return _skill([_recover_hp(0.02, 0.0, 0.0, 0.0, 0.0)])
		2124, 100119:
			return _skill([_recover_hp(0.0, 0.20, 0.0, 0.0, 0.0)])
		2126, 100120:
			return _skill([_recover_hp(0.0, 0.0, 0.05, 0.0, 0.0)])
		2129, 100121:
			return _skill([_heal_effect(0.0, 0.33, 0.0)])
		2132, 100122:
			return _skill([_time_rate(0.0, -1, 0.0, 0.0, 0.01)])
		2134, 100123:
			return _skill([_time_rate(0.0, 26 * 60, -0.50, 0.50)])
		2136, 100124:
			return _skill([_time_rate(0.02, -1, 0.0, 0.0, 0.0, 0.02, 0.40)])
		2137, 100125:
			return _skill([_return_damage(0.0, 0.0, false)])
		2138, 100126:
			return _skill([_return_damage(0.50, 0.33, false)])
	return null


# sub取得
static func get_sub_skill(skill_id: int) -> SeedSkill:
	match skill_id:
		1001, 100101:
			return _skill([_pending_acid(0.20)])
		1003, 100103:
			return _skill([_pending_time(0.15)])
		2002, 100105:
			return _skill([_adjacent_damage(0, 1.0, true)])
		2003, 100106:
			return _skill([_pending_time(0.50)])
		2004, 100107:
			return _skill([_pending_acid(2.0, 28 * 60)])
		2108, 100110:
			return _skill([_target_multiplier(2.0)])
		2113, 100112:
			return _skill([])
		2114, 100113:
			return _skill([_line_damage(1000, false)])
		2115, 100114:
			return _skill([_adjacent_damage(1000, 0.0, false)])
		2118, 100115:
			return _skill([_pending_time(0.10)])
		2119, 100116:
			return _skill([_pending_acid(0.10)])
		2123, 100118:
			return _skill([_target_multiplier(1.10)])
		2126, 100120:
			return _skill([_pending_max_hp(0.10)])
		2134, 100123:
			return _skill([_pending_time(0.0, -1, 26 * 60, 0.80, -0.80)])
		2136, 100124:
			return _skill([_pending_time(-0.04)])
		2137, 100125:
			return _skill([_return_adjacent()])
		2138, 100126:
			return _skill([_return_damage(-1.0, 0.0, true), _pending_acid(1.0)])
	return null


# skill作成
static func _skill(effects: Array) -> SeedSkill:
	var skill := SeedSkill.new() # スキル
	var typed_effects: Array[Resource] = [] # 効果配列
	for effect in effects:
		if effect is SeedEffect:
			typed_effects.append(effect as Resource)
	skill.effects = typed_effects
	return skill


# 消化率効果
static func _acid_rate(rate: float, start_minutes := -1) -> SeedEffect:
	var effect := SeedEffectOnBattleChangeAcidDamageRate.new() # 効果
	effect.rate = rate
	effect.start_minutes = start_minutes
	return effect


# pending消化率
static func _pending_acid(rate: float, start_minutes := -1) -> SeedEffect:
	var effect := SeedEffectOnFinishAcidSeedChangeAcidDamageRate.new() # 効果
	effect.rate = rate
	effect.start_minutes = start_minutes
	return effect


# 時間率効果
static func _time_rate(
	rate: float,
	before_minutes := -1,
	before_rate := 0.0,
	after_rate := 0.0,
	hp_loss_rate := 0.0,
	elapsed_step_rate := 0.0,
	max_abs_rate := 2.0
) -> SeedEffect:
	var effect := SeedEffectOnBattleChangeTimeReductionRate.new() # 効果
	effect.rate = rate
	effect.before_minutes = before_minutes
	effect.before_rate = before_rate
	effect.after_rate = after_rate
	effect.hp_loss_rate = hp_loss_rate
	effect.elapsed_step_rate = elapsed_step_rate
	effect.max_abs_rate = max_abs_rate
	return effect


# pending時間率
static func _pending_time(
	rate: float,
	_unused_start := -1,
	before_minutes := -1,
	before_rate := 0.0,
	after_rate := 0.0
) -> SeedEffect:
	var effect := SeedEffectOnFinishAcidSeedChangeTimeReductionRate.new() # 効果
	effect.rate = rate
	effect.before_minutes = before_minutes
	effect.before_rate = before_rate
	effect.after_rate = after_rate
	return effect


# 被ダメ効果
static func _player_damage(multiplier: float, reflect_rate: float, flat_rate: float) -> SeedEffect:
	var effect := SeedEffectOnPlayerDamageChangeDamage.new() # 効果
	effect.damage_multiplier_bonus = multiplier
	effect.reflect_acid_rate = reflect_rate
	effect.flat_acid_rate = flat_rate
	return effect


# 回復効果
static func _heal_effect(heal_bonus: float, heal_to_line: float, max_hp_from_recovery: float) -> SeedEffect:
	var effect := SeedEffectOnHealChangeEffect.new() # 効果
	effect.heal_bonus_rate = heal_bonus
	effect.heal_to_line_damage_rate = heal_to_line
	effect.max_hp_from_recovery_rate = max_hp_from_recovery
	return effect


# HP回復効果
static func _recover_hp(
	acid_heal: float,
	nightmare_heal: float,
	nightmare_max_hp: float,
	time_heal: float,
	hour_heal: float
) -> SeedEffect:
	var effect := SeedEffectOnBattleRecoverHp.new() # 効果
	effect.acid_damage_heal_rate = acid_heal
	effect.acided_nightmare_heal_rate = nightmare_heal
	effect.acided_nightmare_max_hp_rate = nightmare_max_hp
	effect.time_active_count_heal_rate = time_heal
	effect.hour_heal_rate = hour_heal
	return effect


# 対象倍率
static func _target_multiplier(multiplier: float, random_chance := 0, random_multiplier := 1.0) -> SeedEffect:
	var effect := SeedEffectOnTargetChangeAcidDamage.new() # 効果
	effect.multiplier = multiplier
	effect.random_chance = random_chance
	effect.random_multiplier = random_multiplier
	return effect


# 吐戻し効果
static func _return_damage(damage_rate: float, acid_damage_rate: float, disable_after_seed_acid: bool) -> SeedEffect:
	var effect := SeedEffectOnRemoveFromStomachChangeDamage.new() # 効果
	effect.damage_rate = damage_rate
	effect.acid_damage_rate = acid_damage_rate
	effect.disable_after_seed_acid = disable_after_seed_acid
	return effect


# 隣接ダメージ
static func _adjacent_damage(damage: int, received_rate: float, split: bool) -> SeedEffect:
	var effect := SeedEffectOnFinishAcidSeedBlockDamageAdjacent.new() # 効果
	effect.damage = damage
	effect.received_damage_rate = received_rate
	effect.split = split
	return effect


# 列ダメージ
static func _line_damage(damage: int, split: bool) -> SeedEffect:
	var effect := SeedEffectOnFinishAcidSeedBlockDamageLine.new() # 効果
	effect.damage = damage
	effect.split = split
	return effect


# 隣接返却
static func _return_adjacent() -> SeedEffect:
	return SeedEffectOnFinishAcidSeedBlockReturnAdjacent.new()


# 胃袋サイズ
static func _stomach_size(columns: int, rows: int) -> SeedEffect:
	var effect := SeedEffectOnBattleChangeStomachSize.new() # 効果
	effect.columns_delta = columns
	effect.rows_delta = rows
	return effect


# pending最大HP
static func _pending_max_hp(rate: float) -> SeedEffect:
	var effect := SeedEffectOnFinishAcidSeedChangeMaxHpRate.new() # 効果
	effect.rate = rate
	return effect
