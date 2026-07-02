class_name SeedEffectResolver
extends RefCounted

var _state := DreamSeedSkillState.new() # 状態
var _planted_flowers: Array[SeedInfo] = [] # 植付花


# setup処理
func setup(flowers: Array) -> void:
	_planted_flowers.clear()
	for flower in flowers:
		if flower is SeedInfo:
			_planted_flowers.append(flower as SeedInfo)
	_state.reset()
	for effect in _get_main_effects():
		effect.setup(_state)


# 消化ダメージbreakdown取得
func get_acid_damage_breakdown(
	base_damage: int,
	nightmare_rate: float,
	minutes: int,
	consume_pending_bonus: bool = false
) -> Dictionary:
	var context := {"minutes": minutes} # 文脈
	var seed_rate := _sum_float("get_acid_damage_rate", context) # 種倍率
	seed_rate += _state.progress_acid_damage_bonus_rate
	if _state.next_acid_damage_bonus_rate != 0.0:
		seed_rate += _state.next_acid_damage_bonus_rate
	if consume_pending_bonus:
		_state.next_acid_damage_bonus_rate = 0.0
	var buff_multiplier := _get_acid_damage_buff_multiplier(context) # buff倍率
	seed_rate *= buff_multiplier
	nightmare_rate *= buff_multiplier
	var seed_buff := roundi(float(base_damage) * seed_rate) # 種加算
	var damage_after_seed := base_damage + seed_buff + _state.next_acid_damage_flat_bonus # 種後ダメ
	if consume_pending_bonus:
		_state.next_acid_damage_flat_bonus = 0
	var total_damage := maxi(1, roundi(float(damage_after_seed) * (1.0 + nightmare_rate))) # 総ダメ
	return {
		"total": total_damage,
		"base": base_damage,
		"seed_buff": seed_buff,
		"seed_rate": seed_rate,
		"nightmare_buff": total_damage - damage_after_seed,
		"nightmare_rate": nightmare_rate,
	}


# playerダメージ適用
func apply_player_damage(amount: int, base_damage: int) -> int:
	if amount <= 0:
		return 0
	var context := {"amount": amount, "base_damage": base_damage} # 文脈
	var multiplier := 1.0 + _state.next_player_damage_rate # 被弾倍率
	multiplier += _sum_float("get_player_damage_rate", context)
	var final_damage := maxi(0, roundi(float(amount) * maxf(0.0, multiplier))) # 最終ダメ
	var damage_context := { # 被弾文脈
		"amount": amount,
		"base_damage": base_damage,
		"taken_damage": final_damage,
	}
	_state.next_acid_damage_bonus_rate += _sum_float("get_reflect_acid_rate", damage_context)
	_state.next_acid_damage_flat_bonus += _sum_int("get_taken_attack_flat_acid_bonus", damage_context)
	_state.next_player_damage_rate = 0.0
	_state.last_hp_loss = final_damage
	return final_damage


# 時間経過適用
func apply_progress_time(previous_minutes: int, minutes: int) -> void:
	var elapsed_minutes := maxi(0, minutes - previous_minutes) # 経過分
	var context := { # 文脈
		"previous_minutes": previous_minutes,
		"minutes": minutes,
		"elapsed_minutes": elapsed_minutes,
	}
	for effect in _get_main_effects():
		effect.on_progress_time(_state, context)


# 時間reduction率取得
func get_time_reduction_rate(consume_pending_bonus := false, minutes := 0) -> float:
	var rate := _sum_float("get_time_reduction_rate", {"minutes": minutes}) # 短縮率
	rate += _state.next_time_reduction_bonus_rate
	if consume_pending_bonus:
		_state.next_time_reduction_bonus_rate = 0.0
	return clampf(rate, -2.0, 0.9)


# 消化済み種effect追加
func add_Acided_seed_effect(seed: SeedInfo, minutes := 0) -> bool:
	if seed == null:
		return false
	var handled := false # 処理済み
	var context := {"seed": seed, "minutes": minutes} # 文脈
	for effect in _get_seed_effects(seed.get_sub_skill()):
		if effect.on_finish_acid_seed(_state, context):
			handled = true
	return handled


# 休憩HP取得
func get_rest_hp(max_hp: int, base_recovery_rate: float) -> int:
	var recovery_rate := base_recovery_rate + get_rest_recovery_bonus_rate() # 回復率
	return ceili(float(max_hp) * recovery_rate)


# 休憩回復補正率取得
func get_rest_recovery_bonus_rate() -> float:
	return _sum_float("get_rest_recovery_bonus_rate", {})


# 種スキルID文言取得
func get_seed_id_text() -> String:
	var seed_ids: Array[String] = [] # 種ID群
	for flower in _planted_flowers:
		if flower == null:
			continue
		seed_ids.append(str(flower.skill_id))
	if seed_ids.is_empty():
		return "-"
	return ",".join(seed_ids)


# 回復イベント追加
func add_heal_event(amount: int) -> int:
	if amount <= 0:
		return 0
	var context := {"amount": amount} # 文脈
	var bonus := ceili(float(amount) * _get_heal_bonus_rate(context)) # 回復加算
	_state.recovery_accumulated_for_max_hp += amount
	for effect in _get_main_effects():
		effect.on_battle(_state, context)
	return bonus


# reviveイベント追加
func add_revive_event() -> void:
	_state.revive_count += 1
	for effect in _get_main_effects():
		effect.on_battle(_state, {"event": "revive"})


# 消化ダメージ合計追加
func add_acid_damage_total(amount: int) -> void:
	_state.last_acid_damage_total += maxi(0, amount)


# 消化ダメージ回復量消費
func consume_acid_damage_heal_amount() -> int:
	var heal_amount := floori(float(_state.last_acid_damage_total) * _sum_float("get_acid_damage_heal_rate", {})) # 回復量
	_state.last_acid_damage_total = 0
	return heal_amount


# 消化済み悪夢回復率取得
func get_Acided_nightmare_heal_rate() -> float:
	return _sum_float("get_acided_nightmare_heal_rate", {})


# 消化済み悪夢最大HP率取得
func get_Acided_nightmare_max_hp_rate() -> float:
	return _sum_float("get_acided_nightmare_max_hp_rate", {})


# 最大HP補正率取得
func get_max_hp_bonus_rate() -> float:
	var context := {"recovery_accumulated": _state.recovery_accumulated_for_max_hp} # 文脈
	return maxf(0.0, _state.max_hp_bonus_rate + _sum_float("get_max_hp_bonus_rate", context))


# 時間HP回復率取得
func get_time_hp_recovery_rate(active_count: int) -> float:
	return _sum_float("get_time_hp_recovery_rate", {"active_count": active_count})


# 時HP回復率取得
func get_hour_hp_recovery_rate(minutes: int) -> float:
	if minutes % 60 != 0:
		return 0.0
	return _sum_float("get_hour_hp_recovery_rate", {"minutes": minutes})


# 敵attack倍率取得
func get_enemy_attack_multiplier() -> float:
	return maxf(0.0, 1.0 + _sum_float("get_enemy_attack_multiplier_bonus", {}))


# 敵attackdelta取得
func get_enemy_attack_delta(minutes: int) -> int:
	return _sum_int("get_enemy_attack_delta", {"minutes": minutes})


# 消化対象倍率取得
func get_acid_target_multiplier() -> float:
	var multiplier := 1.0 # 倍率
	for effect in _get_main_effects():
		multiplier *= effect.get_acid_target_multiplier(_state, {})
	return multiplier


# removefrom胃袋ダメージ率取得
func get_remove_from_stomach_damage_rate(default_rate: float) -> float:
	var rate := default_rate # 基準率
	for effect in _get_main_effects():
		var effect_rate := effect.get_remove_from_stomach_damage_rate(_state, {}) # 効果率
		if effect_rate >= 0.0:
			rate = effect_rate
	if _state.remove_from_stomach_disabled:
		return rate
	return rate


# removefrom胃袋消化ダメージ取得
func get_remove_from_stomach_acid_damage_rate() -> float:
	return _sum_float("get_remove_from_stomach_acid_damage_rate", {})


# removefrom胃袋disable判定
func is_remove_from_stomach_disabled() -> bool:
	return _state.remove_from_stomach_disabled


# 最大HP補正率追加
func add_max_hp_bonus_rate(rate: float) -> void:
	_state.max_hp_bonus_rate += rate


# 消化率加算
func add_acid_damage_bonus_rate(rate: float) -> void:
	_state.progress_acid_damage_bonus_rate += rate


# 消化buff倍率取得
func _get_acid_damage_buff_multiplier(context: Dictionary) -> float:
	var multiplier := 1.0 # 倍率
	for effect in _get_main_effects():
		multiplier *= maxf(0.0, effect.get_acid_damage_buff_multiplier(_state, context))
	return multiplier


# 日数設定
func set_day(value: int) -> void:
	_state.day = maxi(1, value)


# 回復補正率取得
func _get_heal_bonus_rate(context: Dictionary) -> float:
	var rate := _state.next_heal_bonus_rate + _sum_float("get_heal_bonus_rate", context) # 回復率
	_state.next_heal_bonus_rate = 0.0
	return rate


# main効果取得
func _get_main_effects() -> Array[SeedEffect]:
	var effects: Array[SeedEffect] = [] # 効果群
	for flower in _planted_flowers:
		if flower == null:
			continue
		effects.append_array(_get_seed_effects(flower.get_main_skill()))
	effects.sort_custom(func(a: SeedEffect, b: SeedEffect) -> bool:
		return a.priority < b.priority
	)
	return effects


# seed効果取得
func _get_seed_effects(skill: SeedSkill) -> Array[SeedEffect]:
	var effects: Array[SeedEffect] = [] # 効果群
	if skill == null:
		return effects
	effects.append_array(skill.get_effects())
	return effects


# float合計
func _sum_float(method_name: String, context: Dictionary) -> float:
	var total := 0.0 # 合計
	for effect in _get_main_effects():
		total += float(effect.call(method_name, _state, context))
	return total


# int合計
func _sum_int(method_name: String, context: Dictionary) -> int:
	var total := 0 # 合計
	for effect in _get_main_effects():
		total += int(effect.call(method_name, _state, context))
	return total
