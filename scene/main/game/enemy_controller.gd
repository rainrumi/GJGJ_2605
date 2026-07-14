class_name EnemyController
extends RefCounted

const STEP_MINUTES := 30
const acid_DAMAGE := 300

var seed_effects := SeedEffectResolver.new()
var seed_block_resolver := DreamSeedBlockAcidResolver.new()
var enemy_effects := EnemyEffectSystem.new()
var _battle_start_minutes := 0 # 開始分


# setup処理
func setup(flowers: Array) -> void:
	seed_effects.setup(flowers)
	enemy_effects.reset()


# 敵effects更新
func refresh_enemy_effects(enemies: Array[Enemy], stomach: StomachBoard) -> void:
	enemy_effects.refresh(enemies, stomach)


# 種effect花設定
func set_seed_effect_flowers(flowers: Array) -> void:
	seed_effects.setup(flowers)


# 開始分設定
func set_battle_start_minutes(value: int) -> void:
	_battle_start_minutes = maxi(0, value)


# 敵effect初期化
func reset_enemy_effects() -> void:
	enemy_effects.reset()


# 消化ダメージbreakdown取得
func get_acid_damage_breakdown(
	enemies: Array[Enemy],
	minutes: int,
	consume_pending_bonus: bool = false,
	stomach: StomachBoard = null
) -> Dictionary:
	var stomach_columns := 0 # 胃袋列
	var stomach_rows := 0 # 胃袋行
	if stomach != null:
		stomach_columns = stomach.columns
		stomach_rows = stomach.rows
	var stomach_count := _get_active_stomach_count(enemies) # 胃内数
	return seed_effects.get_acid_damage_breakdown(
		acid_DAMAGE,
		_get_nightmare_acid_damage_rate(enemies, minutes) + _get_seed_block_acid_damage_rate(enemies, minutes),
		minutes,
		consume_pending_bonus,
		stomach_columns,
		stomach_rows,
		stomach_count
	)

# step分数取得
func get_step_minutes(enemies: Array[Enemy], minutes := 0) -> int:
	return int(get_step_minutes_breakdown(enemies, true, minutes)["total"])


# 基準step取得
func get_base_step_minutes() -> int:
	return STEP_MINUTES


# step分数breakdown取得
func get_step_minutes_breakdown(enemies: Array[Enemy], consume_pending_bonus := false, minutes := 0) -> Dictionary:
	# base分数
	var base_minutes := STEP_MINUTES
	# 悪夢分数
	var nightmare_minutes := base_minutes
	nightmare_minutes = ceili(float(enemy_effects.get_interval_seconds(nightmare_minutes * 60)) / 60.0)
	# 種率
	var seed_rate := -seed_effects.get_time_reduction_rate(
		consume_pending_bonus,
		minutes,
		_battle_start_minutes,
		base_minutes
	)
	# 合計分数
	var total_minutes := maxi(1, roundi(float(nightmare_minutes) * (1.0 + seed_rate)))
	return {
		"total": total_minutes,
		"base": base_minutes,
		"seed_buff": total_minutes - nightmare_minutes,
		"seed_rate": seed_rate,
		"nightmare_buff": nightmare_minutes - base_minutes,
		"nightmare_rate": float(nightmare_minutes - base_minutes) / float(base_minutes),
	}


# turnstarteffects適用
func apply_turn_start_effects(enemies: Array[Enemy], stomach: StomachBoard, minutes: int) -> void:
	enemy_effects.refresh(enemies, stomach)
	enemy_effects.dispatch(EnemyEffect.Event.TURN_START, enemies, stomach, null, 0, 0, STEP_MINUTES * 60, minutes * 60)
	for enemy in enemies:
		if enemy.is_Acided():
			continue
		if enemy.can_take_stomach_turn():
			enemy.stomach_elapsed_minutes += STEP_MINUTES


# 消化悪夢処理
func acid_nightmares(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	minutes: int,
	elapsed_minutes: int = STEP_MINUTES
) -> Array[Enemy]:
	# 消化済み敵
	var Acided_enemies: Array[Enemy] = []
	# ダメージdisplayvalues
	var damage_display_values: Dictionary = {}
	# received消化ダメージ
	var received_acid_damage: Dictionary = {}
	# turnstartHP
	var turn_start_hp := _get_turn_start_hp(enemies)
	# 消化ダメージperセル
	var acid_damage_per_cell := int(get_acid_damage_breakdown(enemies, minutes, true, stomach)["total"])
	for enemy in enemies:
		_acid_enemy(enemy, enemies, stomach, minutes, elapsed_minutes, acid_damage_per_cell, damage_display_values, received_acid_damage)
	_apply_enemy_damage_values(damage_display_values, Acided_enemies, enemies, stomach, minutes)
	for enemy in enemy_effects.consume_pending_digested():
		if not Acided_enemies.has(enemy): Acided_enemies.append(enemy)
	return _resolve_Acided_enemy_effects(enemies, stomach, minutes, elapsed_minutes, acid_damage_per_cell, Acided_enemies, received_acid_damage, turn_start_hp)


# 消化ダメージvalues適用
func apply_acid_damage_values(enemies: Array[Enemy], stomach: StomachBoard, minutes: int) -> Array[int]:
	# rawダメージvalues
	var raw_damage_values: Array[int] = []
	# 合計ダメージ
	var total_damage := 0
	for enemy in enemies:
		if enemy.should_deal_player_damage() and enemy.can_take_stomach_turn():
			if enemy_effects.is_default_attack_disabled(enemy):
				continue
			# ダメージ
			var damage := _get_enemy_attack_damage(enemy, enemies, stomach, minutes)
			if damage > 0:
				# attackvalues
				var attack_values: Array[int] = [] # 攻撃値一覧
				for _index in range(enemy_effects.get_attack_count(enemy)):
					attack_values.append_array(_get_enemy_attack_damage_values(enemy, damage))
				raw_damage_values.append_array(attack_values)
				total_damage += _sum_damage_values(attack_values)
	# finalダメージ
	var final_damage := seed_effects.apply_player_damage(total_damage, acid_DAMAGE)
	# ダメージvalues
	var damage_values := _split_damage_values(raw_damage_values, final_damage)
	damage_values.append_array(enemy_effects.consume_player_damage())
	return damage_values


# 敵状態display更新
func refresh_enemy_status_display(enemies: Array[Enemy], stomach: StomachBoard, minutes := 0) -> void:
	for enemy in enemies:
		if enemy == null or enemy.is_Acided():
			continue
		enemy.set_display_damage(_get_enemy_attack_damage(enemy, enemies, stomach, minutes))


# 休憩HP取得
func get_rest_hp(max_hp: int, rest_hp_rate: float) -> int:
	return seed_effects.get_rest_hp(max_hp, rest_hp_rate)


# 休憩回復補正率取得
func get_rest_recovery_bonus_rate() -> float:
	return seed_effects.get_rest_recovery_bonus_rate()


# nuisance敵処理
func activate_deferred_nuisance_enemies(enemies: Array[Enemy]) -> void:
	for enemy in enemies:
		enemy.activate_stomach_turn()


# nuisancegravity処理
func unlock_deferred_nuisance_gravity(enemies: Array[Enemy]) -> void:
	for enemy in enemies:
		if enemy.is_active_in_stomach() and enemy.is_activation_deferred():
			enemy.clear_gravity_lock()


# 種スキルID文言取得
func get_seed_id_text() -> String:
	return seed_effects.get_seed_id_text()


# directplayerダメージ適用
func apply_direct_player_damage(amount: int) -> int:
	return seed_effects.apply_player_damage(amount, acid_DAMAGE)


# 消化済み種effect追加
func add_Acided_seed_effect(seed: SeedInfo, minutes := 0, stomach: StomachBoard = null) -> bool:
	return seed_effects.add_Acided_seed_effect(seed, minutes, stomach)


# 時間経過適用
func apply_progress_time(previous_minutes: int, minutes: int, enemies: Array[Enemy], stomach: StomachBoard) -> BattleTurnResultData:
	seed_effects.apply_progress_time(previous_minutes, minutes)
	enemy_effects.dispatch(
		EnemyEffect.Event.PROGRESS_TIME,
		enemies,
		stomach,
		null,
		0,
		0,
		maxi(0, minutes - previous_minutes) * 60,
		minutes * 60
	)
	var Acided_enemies := enemy_effects.consume_pending_digested() # 時間消化済み
	for enemy in Acided_enemies:
		enemy_effects.dispatch(EnemyEffect.Event.DIGESTED, enemies, stomach, enemy, 0, 0, maxi(0, minutes - previous_minutes) * 60, minutes * 60, Acided_enemies)
		enemy_effects.dispatch(EnemyEffect.Event.ADJACENT_DIGESTED, enemies, stomach, enemy, 0, 0, maxi(0, minutes - previous_minutes) * 60, minutes * 60, Acided_enemies)
	enemy_effects.dispatch(EnemyEffect.Event.ANY_DIGESTED, enemies, stomach, null, 0, 0, maxi(0, minutes - previous_minutes) * 60, minutes * 60, Acided_enemies)
	enemy_effects.refresh(enemies, stomach)
	var result := BattleTurnResultData.new() # 時間効果結果
	result.Acided_enemies = Acided_enemies
	result.spawn_requests = enemy_effects.consume_spawns()
	result.player_damage_values = enemy_effects.consume_player_damage()
	result.extra_elapsed_minutes = roundi(float(enemy_effects.consume_time_delta_seconds()) / 60.0)
	return result


# 日数設定
func set_day(value: int) -> void:
	seed_effects.set_day(value)


# reviveイベント追加
func add_revive_event() -> void:
	seed_effects.add_revive_event()


# 回復イベント追加
func add_heal_event(amount: int) -> int:
	return seed_effects.add_heal_event(amount)


# 最大HP補正率取得
func get_max_hp_bonus_rate() -> float:
	return seed_effects.get_max_hp_bonus_rate()


# 最大HP補正率追加
func add_max_hp_bonus_rate(rate: float) -> void:
	seed_effects.add_max_hp_bonus_rate(rate)


# 消化率加算
func add_acid_damage_bonus_rate(rate: float) -> void:
	seed_effects.add_acid_damage_bonus_rate(rate)


# 時間HP回復率取得
func get_time_hp_recovery_rate(active_count: int) -> float:
	return seed_effects.get_time_hp_recovery_rate(active_count)


# 時HP回復率取得
func get_hour_hp_recovery_rate(current_minutes: int) -> float:
	return seed_effects.get_hour_hp_recovery_rate(current_minutes)


# 消化ダメージ回復量消費
func consume_acid_damage_heal_amount() -> int:
	return seed_effects.consume_acid_damage_heal_amount()


# 消化済み悪夢回復率取得
func get_Acided_nightmare_heal_rate() -> float:
	return seed_effects.get_Acided_nightmare_heal_rate()


# 消化済み悪夢最大HP率取得
func get_Acided_nightmare_max_hp_rate() -> float:
	return seed_effects.get_Acided_nightmare_max_hp_rate()


# 敵attack倍率取得
func get_enemy_attack_multiplier() -> float:
	return seed_effects.get_enemy_attack_multiplier()


# 敵attackdelta取得
func get_enemy_attack_delta(current_minutes: int) -> int:
	return seed_effects.get_enemy_attack_delta(current_minutes, _battle_start_minutes, STEP_MINUTES)


# removefrom胃袋ダメージ率取得
func get_remove_from_stomach_damage_rate(default_rate: float) -> float:
	return seed_effects.get_remove_from_stomach_damage_rate(default_rate)


# removefrom胃袋消化ダメージ取得
func get_remove_from_stomach_acid_damage_rate() -> float:
	return seed_effects.get_remove_from_stomach_acid_damage_rate()


# removefrom胃袋disabl判定
func is_remove_from_stomach_disabled() -> bool:
	return seed_effects.is_remove_from_stomach_disabled()


# buildturn結果処理
func build_turn_result(Acided_enemies: Array[Enemy]) -> BattleTurnResultData:
	# 結果
	var result := BattleTurnResultData.new()
	result.Acided_enemies = Acided_enemies
	result.spawn_requests = enemy_effects.consume_spawns()
	result.extra_elapsed_minutes = roundi(float(enemy_effects.consume_time_delta_seconds()) / 60.0)
	return result


# 消化敵処理
func _acid_enemy(
	enemy: Enemy,
	enemies: Array[Enemy],
	stomach: StomachBoard,
	minutes: int,
	elapsed_minutes: int,
	acid_damage_per_cell: int,
	damage_display_values: Dictionary,
	received_acid_damage: Dictionary
) -> void:
	if not enemy.can_take_stomach_turn():
		return
	# bottomセル数
	var bottom_cell_count := stomach.get_bottom_row_cell_count(enemy)
	if bottom_cell_count == 0:
		return
	# ダメージ
	var damage := _get_final_acid_damage(enemy, enemies, stomach, minutes, acid_damage_per_cell * bottom_cell_count)
	damage = enemy_effects.get_acid_damage(enemy, damage)
	damage = enemy_effects.dispatch(EnemyEffect.Event.BEFORE_ACID_DAMAGE, enemies, stomach, enemy, damage, 0, elapsed_minutes * 60, minutes * 60)
	enemy_effects.set_last_acid_damage(damage)
	received_acid_damage[enemy] = received_acid_damage.get(enemy, 0) + damage
	seed_effects.add_acid_damage_total(damage)
	_append_damage_value(damage_display_values, enemy, damage)


# resolve消化済み敵effect処理
func _resolve_Acided_enemy_effects(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	minutes: int,
	elapsed_minutes: int,
	acid_damage_per_cell: int,
	Acided_enemies: Array[Enemy],
	received_acid_damage: Dictionary,
	turn_start_hp: Dictionary
) -> Array[Enemy]:
	# final消化済み
	var final_Acided: Array[Enemy] = []
	_sort_Acided_enemies(enemies, Acided_enemies, received_acid_damage, turn_start_hp)
	for enemy in Acided_enemies:
		var overkill_damage := maxi(0, int(received_acid_damage.get(enemy, 0)) - int(turn_start_hp.get(enemy, 0))) # 超過ダメージ
		enemy_effects.dispatch(EnemyEffect.Event.DIGESTED, enemies, stomach, enemy, int(received_acid_damage.get(enemy, 0)), overkill_damage, elapsed_minutes * 60, minutes * 60, Acided_enemies)
		if not enemy.is_Acided():
			continue
		seed_block_resolver.append_Acided_by_seed_block_effects(
			enemy,
			enemies,
			stomach,
			minutes,
			received_acid_damage,
			Acided_enemies,
			acid_damage_per_cell,
			elapsed_minutes
		)
		final_Acided.append(enemy)
	enemy_effects.dispatch(EnemyEffect.Event.ANY_DIGESTED, enemies, stomach, null, 0, 0, elapsed_minutes * 60, minutes * 60, final_Acided)
	for Acided_enemy in final_Acided:
		enemy_effects.dispatch(EnemyEffect.Event.ADJACENT_DIGESTED, enemies, stomach, Acided_enemy, 0, 0, elapsed_minutes * 60, minutes * 60, final_Acided)
	return final_Acided


# sort消化済み敵処理
func _sort_Acided_enemies(
	enemies: Array[Enemy],
	Acided_enemies: Array[Enemy],
	received_acid_damage: Dictionary,
	turn_start_hp: Dictionary
) -> void:
	Acided_enemies.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		# asurplus
		var a_surplus := int(received_acid_damage.get(a, 0)) - int(turn_start_hp.get(a, 0))
		# bsurplus
		var b_surplus := int(received_acid_damage.get(b, 0)) - int(turn_start_hp.get(b, 0))
		if a_surplus == b_surplus:
			return enemies.find(a) < enemies.find(b)
		return a_surplus > b_surplus
	)


# 敵attackダメージ取得
func _get_enemy_attack_damage(enemy: Enemy, enemies: Array[Enemy], stomach: StomachBoard, minutes := 0) -> int:
	# ダメージ
	var damage_delta := seed_effects.get_enemy_attack_delta(minutes, _battle_start_minutes, STEP_MINUTES) # 差分
	var damage := maxi(0, roundi(float(enemy.get_damage()) * seed_effects.get_enemy_attack_multiplier()) + damage_delta)
	return enemy_effects.get_attack(enemy, damage)


# 敵attackダメージvalues取得
func _get_enemy_attack_damage_values(enemy: Enemy, damage: int) -> Array[int]:
	return [damage]


# final消化ダメージ取得
func _get_final_acid_damage(enemy: Enemy, enemies: Array[Enemy], stomach: StomachBoard, minutes: int, raw_damage: int) -> int:
	# ダメージ率
	var damage_rate := enemy.acid_damage_taken_multiplier
	damage_rate *= seed_effects.get_acid_target_multiplier()
	damage_rate *= seed_block_resolver.get_target_acid_damage_multiplier(enemy, enemies)
	return roundi(float(raw_damage) * damage_rate)


# 敵ダメージvalues適用
func _apply_enemy_damage_values(
	damage_display_values: Dictionary,
	Acided_enemies: Array[Enemy],
	enemies: Array[Enemy],
	stomach: StomachBoard,
	minutes: int
) -> void:
	for target in damage_display_values.keys():
		# 敵値
		var enemy := target as Enemy
		if enemy == null or enemy.is_Acided():
			continue
		# ダメージvalues
		var damage_values: Array = damage_display_values[target]
		# 合計ダメージ
		var total_damage := _sum_damage_values(damage_values)
		enemy.show_acid_damage_values(damage_values)
		if enemy.take_acid_damage(total_damage, false) and not Acided_enemies.has(enemy):
			Acided_enemies.append(enemy)
		enemy.pulse_damage()
		var overkill := maxi(0, total_damage - enemy.get_current_hp()) # 超過値
		enemy_effects.dispatch(EnemyEffect.Event.AFTER_ACID_DAMAGE, enemies, stomach, enemy, total_damage, overkill, STEP_MINUTES * 60, minutes * 60, Acided_enemies)
		enemy_effects.dispatch(EnemyEffect.Event.ADJACENT_ACID_DAMAGE, enemies, stomach, enemy, total_damage, overkill, STEP_MINUTES * 60, minutes * 60, Acided_enemies)


# turnstartHP取得
func _get_turn_start_hp(enemies: Array[Enemy]) -> Dictionary:
	# turnstartHP
	var turn_start_hp := {}
	for enemy in enemies:
		turn_start_hp[enemy] = enemy.get_current_hp()
	return turn_start_hp


# ダメージ値追加
func _append_damage_value(damage_values_by_enemy: Dictionary, enemy: Enemy, damage: int) -> void:
	if enemy == null or damage <= 0:
		return
	# ダメージvalues
	var damage_values: Array[int] = []
	if damage_values_by_enemy.has(enemy):
		damage_values.append_array(damage_values_by_enemy[enemy])
	damage_values.append(damage)
	damage_values_by_enemy[enemy] = damage_values


# sumダメージvalues処理
func _sum_damage_values(damage_values: Array) -> int:
	# 合計
	var total := 0
	for damage in damage_values:
		total += damage
	return total


# splitダメージvalues処理
func _split_damage_values(raw_damage_values: Array[int], final_damage: int) -> Array[int]:
	# ダメージvalues
	var damage_values: Array[int] = []
	if raw_damage_values.is_empty() or final_damage <= 0:
		return damage_values
	# raw合計
	var raw_total := 0
	for damage in raw_damage_values:
		raw_total += damage
	# assignedダメージ
	var assigned_damage := 0
	# cumulativerawダメージ
	var cumulative_raw_damage := 0
	for damage in raw_damage_values:
		cumulative_raw_damage += damage
		# cumulativeダメージ
		var cumulative_damage := roundi(float(cumulative_raw_damage) / float(raw_total) * float(final_damage))
		# splitダメージ
		var split_damage := maxi(0, cumulative_damage - assigned_damage)
		if split_damage > 0:
			damage_values.append(split_damage)
		assigned_damage = cumulative_damage
	return damage_values


# 胃内数取得
func _get_active_stomach_count(enemies: Array[Enemy]) -> int:
	var count := 0 # 数
	for enemy in enemies:
		if enemy != null and enemy.is_stomach_piece():
			count += 1
	return count

# 悪夢消化ダメージ率取得
func _get_nightmare_acid_damage_rate(enemies: Array[Enemy], _minutes: int) -> float:
	return _get_global_acid_damage_multiplier(enemies) - 1.0


# global消化ダメージ倍率取得
func _get_global_acid_damage_multiplier(enemies: Array[Enemy]) -> float:
	# 倍率
	var multiplier := 1.0
	for enemy in enemies:
		if enemy != null and enemy.is_active_in_stomach():
			multiplier *= enemy.acid_damage_global_multiplier
	return multiplier


# 種ブロック消化ダメージ率取得
func _get_seed_block_acid_damage_rate(enemies: Array[Enemy], minutes: int) -> float:
	return seed_block_resolver.get_acid_damage_rate(enemies, minutes)
