class_name StageClearCalculatorRecovery
extends RefCounted

# plant種判定
static func can_plant_seed(seed: SeedInfo, planted_flowers: Array[SeedInfo], max_flowers: int) -> bool:
	if seed == null:
		return false
	return count_planted_flowers(planted_flowers) < max_flowers


# 種入手可否
static func can_receive_seed(seed: SeedInfo, planted_flowers: Array[SeedInfo]) -> bool:
	if seed == null:
		return false
	for effect in _get_all_seed_effects(seed):
		if not effect.has_possession_limit():
			continue
		var current_count := _count_possession_limit_effects(effect, planted_flowers) # 所持数
		if not effect.can_add_possession(current_count):
			return false
	return true


# 数planted花処理
static func count_planted_flowers(planted_flowers: Array[SeedInfo]) -> int:
	# 数値
	var count := 0
	for flower in planted_flowers:
		if flower != null:
			count += 1
	return count


# planned回復率取得
static func get_planned_recovery_rate(
	planted_flowers: Array[SeedInfo],
	clear_minutes: int,
	recovery_applied: bool,
	start_hour: int,
	end_hour: int,
	base_rate: float,
	hourly_loss_rate: float
) -> float:
	if recovery_applied:
		return 0.0
	return get_clear_time_recovery_rate(planted_flowers, clear_minutes, start_hour, end_hour, base_rate, hourly_loss_rate) + get_seed_bonus_rate(planted_flowers, clear_minutes)


# clear時間回復率取得
static func get_clear_time_recovery_rate(
	planted_flowers: Array[SeedInfo],
	clear_minutes: int,
	start_hour: int,
	end_hour: int,
	base_rate: float,
	hourly_loss_rate: float
) -> float:
	if is_clear_time_recovery_disabled(planted_flowers, clear_minutes):
		return 0.0
	# clear時
	var clear_hour := int(clear_minutes / 60)
	if clear_hour < start_hour:
		return base_rate
	if clear_hour >= end_hour:
		return 0.0
	return maxf(0.0, base_rate - float(clear_hour - start_hour) * hourly_loss_rate)


# 種補正率取得
static func get_seed_bonus_rate(planted_flowers: Array[SeedInfo], clear_minutes := 0) -> float:
	return float(get_selecting_rewerd_context(planted_flowers, clear_minutes).get("hp_recovery_rate", 0.0))


# clear時間回復disabled判定
static func is_clear_time_recovery_disabled(planted_flowers: Array[SeedInfo], clear_minutes := 0) -> bool:
	return bool(get_selecting_rewerd_context(planted_flowers, clear_minutes).get("clear_time_recovery_disabled", false))


# grantsextra種選択肢処理
static func grants_extra_seed_choice(planted_flowers: Array[SeedInfo], clear_minutes: int) -> bool:
	return get_extra_seed_choice_count(planted_flowers, clear_minutes) > 0


# 追加選択数取得
static func get_extra_seed_choice_count(planted_flowers: Array[SeedInfo], clear_minutes: int) -> int:
	return int(get_selected_rewerd_context(planted_flowers, clear_minutes).get("extra_seed_choice_count", 0))


# 選択中効果取得
static func get_selecting_rewerd_context(planted_flowers: Array[SeedInfo], clear_minutes: int) -> Dictionary:
	var context := _create_rewerd_context(clear_minutes) # 文脈
	var state := DreamSeedSkillState.new() # 状態
	for effect in _get_main_effects(planted_flowers):
		effect.on_selecting_rewerd(state, context)
	return context


# 選択後効果取得
static func get_selected_rewerd_context(planted_flowers: Array[SeedInfo], clear_minutes: int) -> Dictionary:
	var context := _create_rewerd_context(clear_minutes) # 文脈
	var state := DreamSeedSkillState.new() # 状態
	for effect in _get_main_effects(planted_flowers):
		effect.on_selected_rewerd(state, context)
	return context


# 文脈作成
static func _create_rewerd_context(clear_minutes: int) -> Dictionary:
	return {
		"clear_minutes": clear_minutes,
		"hp_recovery_rate": 0.0,
		"extra_seed_choice_count": 0,
		"permanent_acid_rate": 0.0,
		"clear_time_recovery_disabled": false,
	}


# main効果取得
static func _get_main_effects(planted_flowers: Array[SeedInfo]) -> Array[SeedEffect]:
	var effects: Array[SeedEffect] = [] # 効果
	for flower in planted_flowers:
		if flower == null:
			continue
		effects.append_array(_get_seed_effects(flower.get_main_skill()))
	effects.sort_custom(func(a: SeedEffect, b: SeedEffect) -> bool:
		return a.priority < b.priority
	)
	return effects


# 種効果取得
static func _get_seed_effects(skill: SeedSkill) -> Array[SeedEffect]:
	var effects: Array[SeedEffect] = [] # 効果
	if skill == null:
		return effects
	effects.append_array(skill.get_effects())
	return effects


# 全効果取得
static func _get_all_seed_effects(seed: SeedInfo) -> Array[SeedEffect]:
	var effects: Array[SeedEffect] = [] # 効果
	if seed == null:
		return effects
	effects.append_array(_get_seed_effects(seed.get_main_skill()))
	effects.append_array(_get_seed_effects(seed.get_sub_skill()))
	return effects


# 上限効果数
static func _count_possession_limit_effects(
	target_effect: SeedEffect,
	planted_flowers: Array[SeedInfo]
) -> int:
	var count := 0 # 数値
	for flower in planted_flowers:
		if flower == null:
			continue
		for effect in _get_all_seed_effects(flower):
			if target_effect.matches_possession_limit_target(effect):
				count += 1
	return count
