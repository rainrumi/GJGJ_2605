class_name EnemyController
extends RefCounted

const STEP_MINUTES := 30
const acid_DAMAGE := 300
const SKILL_3_DAMAGE_REDUCTION_PER_OPEN_FACE := 0.1
const SKILL_7_HP_STEP_RATE := 0.2
const SKILL_7_MIN_HP_RATE := 0.2
const SKILL_7_MAX_HP_RATE := 2.0
const SKILL_11_REVIVE_START_RATE := 0.5
const SKILL_11_REVIVE_DECAY_RATE := 0.1
const SKILL_11_MIN_REVIVE_RATE := 0.1
const STRENGTH_RIRAN_REVIVE_START_RATE := 0.8
const TWO_OCLOCK_MINUTES := 26 * 60
const NIGHTMARE_SKILL_OPEN_CELL_ATTACK := 1
const NIGHTMARE_SKILL_DAMAGE_SHARE := 2
const NIGHTMARE_SKILL_OPEN_CELL_DEFENSE := 3
const NIGHTMARE_SKILL_BOTTOM_ATTACK := 4
const NIGHTMARE_SKILL_LATE_acid_WEAKEN := 5
const NIGHTMARE_SKILL_TIME_DELAY := 6
const NIGHTMARE_SKILL_RANDOM_HP := 7
const NIGHTMARE_SKILL_SPAWN_BLOCKS := 8
const NIGHTMARE_SKILL_CHAIN_GROWTH := 9
const NIGHTMARE_SKILL_ODD_ORDER_DAMAGE := 10
const NIGHTMARE_SKILL_EVEN_ORDER_REVIVE := 11
const NIGHTMARE_SKILL_SINGLE_acid_SPAWN := 12
const STRENGTH_ERAMIA_DAMAGE_TO_ATTACK := 20021
const STRENGTH_ERAMIA_COUNT_BUFF := 20022
const STRENGTH_ERAMIA_BIG_HIT_GUARD := 20023
const STRENGTH_ELMENA_LINE_ATTACK := 20031
const STRENGTH_ELMENA_HIT_COUNT_HEAL := 20032
const STRENGTH_ELMENA_THREE_OCLOCK_ATTACK := 20033
const STRENGTH_GONSAL_LOW_PARASITE := 20041
const STRENGTH_GONSAL_MID_PARASITE := 20042
const STRENGTH_GONSAL_HIGH_PARASITE := 20043
const STRENGTH_RIRAN_SINGLE_REVIVE := 20051
const STRENGTH_RIRAN_OVERHEAL := 20052
const STRENGTH_RIRAN_EXTRA_TIME := 20053
const STRENGTH_FELIS_SEVEN_ATTACK := 20061
const STRENGTH_FELIS_RANDOM_ATTACK := 20062
const STRENGTH_FELIS_FIVE_DAMAGE := 20063
const STRENGTH_NERIX_LOW_ATTACK_HP := 20071
const STRENGTH_NERIX_TOP_DAMAGE_ATTACK := 20072
const STRENGTH_NERIX_ABSORB_ALL := 20073
const STRENGTH_ZAIKA_LINE_ATTACK := 20081
const STRENGTH_ZAIKA_EDGE_HP := 20082
const STRENGTH_ZAIKA_LINE_HP_DOWN := 20083
const STRENGTH_MIRUNE_DELAYED_ATTACK := 20091
const STRENGTH_MIRUNE_MULTI_ATTACK := 20092
const STRENGTH_MIRUNE_FULL_DAMAGE_SHARE := 20093
const STRENGTH_COROTTA_TEN_TURNS := 20101
const STRENGTH_COROTTA_CHAIN_BUFF := 20102
const STRENGTH_COROTTA_SET_THREE_OCLOCK := 20103
const STRENGTH_IRIYU_KEEP_SEED := 20111
const STRENGTH_IRIYU_ADJACENT_WEAKEN := 20112
const STRENGTH_IRIYU_DAMAGE_TO_ATTACK := 20113
const THREE_OCLOCK_MINUTES := 27 * 60

var seed_effects := SeedEffectResolver.new()
var seed_block_resolver := DreamSeedBlockAcidResolver.new()
var acid_order := 0
# Side effects that can later move into AcidSideEffects / BattleTurnResultData.
var _pending_player_damage_values: Array[int] = []
var _pending_spawn_requests: Array[BattleSpawnEnemyData] = []
var _pending_extra_elapsed_minutes := 0
var _pending_time_override_minutes := -1
var _skill_7_base_hp: Dictionary = {}
var _skill_7_hp_rate: Dictionary = {}
var _strength_turn_counts: Dictionary = {}
var _strength_hit_counts: Dictionary = {}
var _strength_line_minutes: Dictionary = {}
var _strength_once_keys: Dictionary = {}
var _strength_base_max_hp: Dictionary = {}
var _strength_hp_modifiers: Dictionary = {}


# setup処理
func setup(flowers: Array) -> void:
	acid_order = 0
	_pending_player_damage_values.clear()
	_pending_spawn_requests.clear()
	_pending_extra_elapsed_minutes = 0
	_pending_time_override_minutes = -1
	_skill_7_base_hp.clear()
	_skill_7_hp_rate.clear()
	_strength_turn_counts.clear()
	_strength_hit_counts.clear()
	_strength_line_minutes.clear()
	_strength_once_keys.clear()
	_strength_base_max_hp.clear()
	_strength_hp_modifiers.clear()
	seed_effects.setup(flowers)


# 種effect花設定
func set_seed_effect_flowers(flowers: Array) -> void:
	seed_effects.setup(flowers)


# 消化order初期化
func reset_acid_order() -> void:
	acid_order = 0
	_skill_7_base_hp.clear()
	_skill_7_hp_rate.clear()
	_strength_turn_counts.clear()
	_strength_hit_counts.clear()
	_strength_line_minutes.clear()
	_strength_once_keys.clear()
	_strength_base_max_hp.clear()
	_strength_hp_modifiers.clear()


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


# step分数breakdown取得
func get_step_minutes_breakdown(enemies: Array[Enemy], consume_pending_bonus := false, minutes := 0) -> Dictionary:
	# base分数
	var base_minutes := STEP_MINUTES
	# 悪夢分数
	var nightmare_minutes := base_minutes
	for enemy in enemies:
		if _has_nightmare_effect(enemy, NIGHTMARE_SKILL_TIME_DELAY) and enemy.stomach_elapsed_minutes > 0 and enemy.stomach_elapsed_minutes % 60 == 0:
			nightmare_minutes += 30
	# 種率
	var seed_rate := -seed_effects.get_time_reduction_rate(consume_pending_bonus, minutes)
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
	for enemy in enemies:
		if enemy.is_Acided():
			continue
		if enemy.can_take_stomach_turn():
			enemy.stomach_elapsed_minutes += STEP_MINUTES
		if _has_nightmare_effect(enemy, NIGHTMARE_SKILL_RANDOM_HP) and not enemy.is_active_in_stomach():
			_apply_outside_stomach_hp_variation(enemy)
		_apply_strength_turn_start_effect(enemy, enemies, stomach, minutes)


# 消化悪夢処理
func acid_nightmares(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	minutes: int,
	elapsed_minutes: int = STEP_MINUTES
) -> Array[Enemy]:
	# 消化済み敵
	var Acided_enemies: Array[Enemy] = []
	# sharedダメージ
	var shared_damage: Dictionary = {}
	# ダメージdisplayvalues
	var damage_display_values: Dictionary = {}
	# received消化ダメージ
	var received_acid_damage: Dictionary = {}
	# 最大received消化ダメージ
	var max_received_acid_damage: Dictionary = {}
	# turnstartHP
	var turn_start_hp := _get_turn_start_hp(enemies)
	# 消化ダメージperセル
	var acid_damage_per_cell := int(get_acid_damage_breakdown(enemies, minutes, true, stomach)["total"])
	for enemy in enemies:
		_acid_enemy(enemy, enemies, stomach, minutes, elapsed_minutes, acid_damage_per_cell, shared_damage, damage_display_values, received_acid_damage, max_received_acid_damage)
	_apply_shared_damage(shared_damage, enemies, stomach, minutes, elapsed_minutes, damage_display_values, received_acid_damage, max_received_acid_damage)
	# forced消化済み
	var forced_Acided := _apply_strength_after_damage_reactions(enemies, received_acid_damage)
	_apply_enemy_damage_values(damage_display_values, Acided_enemies)
	for enemy in forced_Acided:
		if not Acided_enemies.has(enemy):
			Acided_enemies.append(enemy)
	return _resolve_Acided_enemy_effects(enemies, stomach, minutes, Acided_enemies, received_acid_damage, max_received_acid_damage, turn_start_hp)


# 消化ダメージvalues適用
func apply_acid_damage_values(enemies: Array[Enemy], stomach: StomachBoard, minutes: int) -> Array[int]:
	# rawダメージvalues
	var raw_damage_values: Array[int] = []
	# 合計ダメージ
	var total_damage := 0
	for enemy in enemies:
		if enemy.should_deal_player_damage() and enemy.can_take_stomach_turn():
			if _apply_strength_attack_timing_effect(enemy, minutes):
				continue
			# ダメージ
			var damage := _get_enemy_attack_damage(enemy, enemies, stomach, minutes)
			if damage > 0:
				# attackvalues
				var attack_values := _get_enemy_attack_damage_values(enemy, damage)
				raw_damage_values.append_array(attack_values)
				total_damage += _sum_damage_values(attack_values)
	# finalダメージ
	var final_damage := seed_effects.apply_player_damage(total_damage, acid_DAMAGE)
	# ダメージvalues
	var damage_values := _split_damage_values(raw_damage_values, final_damage)
	damage_values.append_array(consume_pending_player_damage_values())
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


# active悪夢effect判定
func has_active_nightmare_effect(enemies: Array[Enemy], skill_id: int) -> bool:
	for enemy in enemies:
		if _has_nightmare_effect(enemy, skill_id) and not enemy.is_Acided():
			return true
	return false


# 種スキルID文言取得
func get_seed_id_text() -> String:
	return seed_effects.get_seed_id_text()


# directplayerダメージ適用
func apply_direct_player_damage(amount: int) -> int:
	return seed_effects.apply_player_damage(amount, acid_DAMAGE)


# 消化済み種effect追加
func add_Acided_seed_effect(seed: SeedInfo, minutes := 0) -> bool:
	return seed_effects.add_Acided_seed_effect(seed, minutes)


# 時間経過適用
func apply_progress_time(previous_minutes: int, minutes: int) -> void:
	seed_effects.apply_progress_time(previous_minutes, minutes)


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
	return seed_effects.get_enemy_attack_delta(current_minutes)


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
	result.spawn_requests = consume_spawn_requests()
	result.extra_elapsed_minutes = _pending_extra_elapsed_minutes
	result.time_override_minutes = _pending_time_override_minutes
	_pending_extra_elapsed_minutes = 0
	_pending_time_override_minutes = -1
	return result


# ダメージvalues消費
func consume_pending_player_damage_values() -> Array[int]:
	# ダメージvalues
	var damage_values: Array[int] = []
	damage_values.append_array(_pending_player_damage_values)
	_pending_player_damage_values.clear()
	return damage_values


# 生成要求消費
func consume_spawn_requests() -> Array[BattleSpawnEnemyData]:
	# 要求
	var requests: Array[BattleSpawnEnemyData] = []
	requests.append_array(_pending_spawn_requests)
	_pending_spawn_requests.clear()
	return requests


# 消化敵処理
func _acid_enemy(
	enemy: Enemy,
	enemies: Array[Enemy],
	stomach: StomachBoard,
	minutes: int,
	elapsed_minutes: int,
	acid_damage_per_cell: int,
	shared_damage: Dictionary,
	damage_display_values: Dictionary,
	received_acid_damage: Dictionary,
	max_received_acid_damage: Dictionary
) -> void:
	if not enemy.can_take_stomach_turn():
		return
	if _is_seed_kept_by_iriyu(enemy, enemies):
		return
	# bottomセル数
	var bottom_cell_count := stomach.get_bottom_row_cell_count(enemy)
	if bottom_cell_count == 0:
		return
	# ダメージ
	var damage := _get_final_acid_damage(enemy, enemies, stomach, minutes, acid_damage_per_cell * bottom_cell_count)
	received_acid_damage[enemy] = received_acid_damage.get(enemy, 0) + damage
	seed_effects.add_acid_damage_total(damage)
	_record_max_acid_damage(max_received_acid_damage, enemy, damage)
	_apply_strength_damage_received_effects(enemy, enemies, damage, minutes, elapsed_minutes, stomach)
	_append_damage_value(damage_display_values, enemy, damage)
	_apply_acid_damage_share(enemy, enemies, damage, shared_damage)


# sharedダメージ適用
func _apply_shared_damage(
	shared_damage: Dictionary,
	enemies: Array[Enemy],
	stomach: StomachBoard,
	minutes: int,
	elapsed_minutes: int,
	damage_display_values: Dictionary,
	received_acid_damage: Dictionary,
	max_received_acid_damage: Dictionary
) -> void:
	for target in shared_damage.keys():
		# 対象敵
		var target_enemy := target as Enemy
		if target_enemy == null or target_enemy.is_Acided():
			continue
		# ダメージvalues
		var damage_values: Array = shared_damage[target]
		# 合計ダメージ
		var total_damage := _sum_damage_values(damage_values)
		total_damage = _get_final_acid_damage(target_enemy, enemies, stomach, minutes, total_damage)
		received_acid_damage[target_enemy] = received_acid_damage.get(target_enemy, 0) + total_damage
		seed_effects.add_acid_damage_total(total_damage)
		_record_max_acid_damage(max_received_acid_damage, target_enemy, total_damage)
		_apply_strength_damage_received_effects(target_enemy, enemies, total_damage, minutes, elapsed_minutes, stomach)
		_append_damage_value(damage_display_values, target_enemy, total_damage)


# resolve消化済み敵effect処理
func _resolve_Acided_enemy_effects(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	minutes: int,
	Acided_enemies: Array[Enemy],
	received_acid_damage: Dictionary,
	max_received_acid_damage: Dictionary,
	turn_start_hp: Dictionary
) -> Array[Enemy]:
	# final消化済み
	var final_Acided: Array[Enemy] = []
	_sort_Acided_enemies(enemies, Acided_enemies, received_acid_damage, turn_start_hp)
	for enemy in Acided_enemies:
		# order
		var current_order := -1
		if enemy.should_count_for_acid_order():
			acid_order += 1
			current_order = acid_order
		if _has_nightmare_effect(enemy, STRENGTH_RIRAN_SINGLE_REVIVE) and _get_Acided_nightmares(Acided_enemies).size() == 1:
			# riran率
			var riran_rate := STRENGTH_RIRAN_REVIVE_START_RATE - float(enemy.get_revive_count()) * SKILL_11_REVIVE_DECAY_RATE
			if riran_rate <= 0.0:
				final_Acided.append(enemy)
				continue
			enemy.revive_with_hp_rate(riran_rate)
			continue
		if current_order >= 0 and _has_nightmare_effect(enemy, NIGHTMARE_SKILL_ODD_ORDER_DAMAGE) and current_order % 2 == 1:
			# ダメージ
			var damage := seed_effects.apply_player_damage(enemy.get_damage() * 3, acid_DAMAGE)
			if damage > 0:
				_pending_player_damage_values.append(damage)
		if current_order >= 0 and _has_nightmare_effect(enemy, NIGHTMARE_SKILL_EVEN_ORDER_REVIVE) and current_order % 2 == 0:
			# revive率
			var revive_rate := maxf(
				SKILL_11_MIN_REVIVE_RATE,
				SKILL_11_REVIVE_START_RATE - float(enemy.get_revive_count()) * SKILL_11_REVIVE_DECAY_RATE
			)
			enemy.revive_with_hp_rate(revive_rate)
			continue
		seed_block_resolver.append_Acided_by_seed_block_effects(
			enemy,
			enemies,
			stomach,
			minutes,
			received_acid_damage,
			Acided_enemies
		)
		_apply_strength_Acided_effect(enemy, enemies, received_acid_damage, max_received_acid_damage)
		final_Acided.append(enemy)
	# 消化済み悪夢
	var Acided_nightmares := _get_Acided_nightmares(final_Acided)
	_apply_chain_reactions(enemies, Acided_nightmares)
	_apply_spawn_reactions(final_Acided, Acided_nightmares)
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


# chainreactions適用
func _apply_chain_reactions(enemies: Array[Enemy], Acided_enemies: Array[Enemy]) -> void:
	for watcher in enemies:
		if not _has_nightmare_effect(watcher, NIGHTMARE_SKILL_CHAIN_GROWTH) or watcher.is_Acided():
			if not _has_nightmare_effect(watcher, STRENGTH_COROTTA_CHAIN_BUFF) or watcher.is_Acided():
				continue
			for Acided_enemy in Acided_enemies:
				if watcher == Acided_enemy:
					continue
				watcher.add_max_hp(watcher.get_max_hp())
				watcher.add_damage(watcher.get_base_damage())
			continue
		for Acided_enemy in Acided_enemies:
			if watcher == Acided_enemy:
				continue
			watcher.change_max_hp(roundi(float(watcher.get_max_hp()) * 0.9))
			watcher.add_damage(roundi(float(watcher.get_base_damage()) * 0.5))


# 生成reactions適用
func _apply_spawn_reactions(
	Acided_enemies: Array[Enemy],
	Acided_nightmares: Array[Enemy]
) -> void:
	for enemy in Acided_enemies:
		if _has_nightmare_effect(enemy, NIGHTMARE_SKILL_SPAWN_BLOCKS):
			# nuisanceダメージ
			var nuisance_damage := roundi(float(enemy.get_base_damage()) * 0.5)
			for cell in enemy.get_occupied_cells(enemy.stomach_cell):
				_pending_spawn_requests.append(_create_spawn_request(enemy, cell, 0.5, nuisance_damage))
		if _has_nightmare_effect(enemy, NIGHTMARE_SKILL_SINGLE_acid_SPAWN) and Acided_nightmares.size() == 1:
			# 生成cells
			var spawn_cells := enemy.get_occupied_cells(enemy.stomach_cell)
			if not spawn_cells.is_empty():
				_pending_spawn_requests.append(_create_spawn_request(enemy, spawn_cells[0], 0.3, 0))


# 生成要求作成
func _create_spawn_request(
	source_enemy: Enemy,
	cell: Vector2i,
	hp_rate: float,
	damage: int,
	acid_damage_rate: float = 1.0,
	global_acid_damage_rate: float = 1.0
) -> BattleSpawnEnemyData:
	# 要求
	var request := BattleSpawnEnemyData.new()
	request.source_enemy = source_enemy
	request.cell = cell
	request.hp_rate = hp_rate
	request.damage = damage
	request.acid_damage_rate = acid_damage_rate
	request.global_acid_damage_rate = global_acid_damage_rate
	return request


# 消化済み悪夢取得
func _get_Acided_nightmares(Acided_enemies: Array[Enemy]) -> Array[Enemy]:
	# 悪夢
	var nightmares: Array[Enemy] = []
	for enemy in Acided_enemies:
		if enemy != null and enemy.should_trigger_nightmare_reactions():
			nightmares.append(enemy)
	return nightmares


# 敵attackダメージ取得
func _get_enemy_attack_damage(enemy: Enemy, enemies: Array[Enemy], stomach: StomachBoard, minutes := 0) -> int:
	# ダメージ
	var damage := maxi(0, roundi(float(enemy.get_damage()) * seed_effects.get_enemy_attack_multiplier()) + seed_effects.get_enemy_attack_delta(minutes))
	if _has_nightmare_effect(enemy, STRENGTH_MIRUNE_DELAYED_ATTACK):
		damage = 0
	if _has_nightmare_effect(enemy, NIGHTMARE_SKILL_OPEN_CELL_ATTACK):
		# open隣接cells
		var open_adjacent_cells := EnemyPlacementQuery.get_open_adjacent_cell_count(enemy, enemies, stomach.columns, stomach.rows)
		damage += roundi(float(enemy.get_base_damage()) * float(open_adjacent_cells))
	if _has_nightmare_effect(enemy, NIGHTMARE_SKILL_BOTTOM_ATTACK) and enemy.is_active_in_stomach():
		# bottomcells
		var bottom_cells := stomach.get_bottom_row_cell_count(enemy)
		# uppercells
		var upper_cells := maxi(0, enemy.get_size() - bottom_cells)
		damage += roundi(float(enemy.get_base_damage()) * float(bottom_cells - upper_cells) * 0.5)
	if _has_nightmare_effect(enemy, STRENGTH_ZAIKA_LINE_ATTACK) and stomach.get_bottom_row_cell_count(enemy) > 0:
		damage += enemy.get_base_damage()
	return damage


# 敵attackダメージvalues取得
func _get_enemy_attack_damage_values(enemy: Enemy, damage: int) -> Array[int]:
	if _has_nightmare_effect(enemy, STRENGTH_MIRUNE_MULTI_ATTACK):
		# values
		var values: Array[int] = []
		# splitダメージ
		var split_damage := maxi(1, roundi(float(damage) * 0.1))
		for i in range(10):
			values.append(split_damage)
		return values
	return [damage]


# 消化ダメージshare適用
func _apply_acid_damage_share(
	enemy: Enemy,
	enemies: Array[Enemy],
	damage: int,
	shared_damage: Dictionary
) -> void:
	if not _has_nightmare_effect(enemy, NIGHTMARE_SKILL_DAMAGE_SHARE):
		if not _has_nightmare_effect(enemy, STRENGTH_MIRUNE_FULL_DAMAGE_SHARE):
			return
	# 隣接敵
	var adjacent_enemies := EnemyPlacementQuery.get_adjacent_enemies(enemy, enemies)
	if adjacent_enemies.is_empty():
		return
	# share率
	var share_rate := 1.0 if _has_nightmare_effect(enemy, STRENGTH_MIRUNE_FULL_DAMAGE_SHARE) else 0.5
	# splitダメージ
	var split_damage := maxi(1, roundi(float(damage) * share_rate / float(adjacent_enemies.size())))
	for adjacent_enemy in adjacent_enemies:
		_append_damage_value(shared_damage, adjacent_enemy, split_damage)


# final消化ダメージ取得
func _get_final_acid_damage(enemy: Enemy, enemies: Array[Enemy], stomach: StomachBoard, minutes: int, raw_damage: int) -> int:
	# ダメージ率
	var damage_rate := enemy.acid_damage_taken_multiplier
	damage_rate *= seed_effects.get_acid_target_multiplier()
	damage_rate *= seed_block_resolver.get_target_acid_damage_multiplier(enemy, enemies)
	if _has_nightmare_effect(enemy, NIGHTMARE_SKILL_OPEN_CELL_DEFENSE):
		# open隣接cells
		var open_adjacent_cells := EnemyPlacementQuery.get_open_adjacent_cell_count(enemy, enemies, stomach.columns, stomach.rows)
		damage_rate *= maxf(
			0.0,
			1.0 - float(open_adjacent_cells) * SKILL_3_DAMAGE_REDUCTION_PER_OPEN_FACE
		)
	if _has_nightmare_effect(enemy, STRENGTH_ERAMIA_BIG_HIT_GUARD) and raw_damage >= ceili(float(enemy.get_max_hp()) * 0.33):
		damage_rate *= 0.1
	if _has_nightmare_effect(enemy, STRENGTH_FELIS_FIVE_DAMAGE) and _time_text_contains_digit(minutes, "5"):
		damage_rate *= 5.0
	return roundi(float(raw_damage) * damage_rate)


# outside胃袋HPvariati適用
func _apply_outside_stomach_hp_variation(enemy: Enemy) -> void:
	if not _skill_7_base_hp.has(enemy):
		_skill_7_base_hp[enemy] = enemy.get_max_hp()
		_skill_7_hp_rate[enemy] = 1.0
	# 率値
	var next_rate := float(_skill_7_hp_rate[enemy])
	if randi() % 2 == 0:
		next_rate += SKILL_7_HP_STEP_RATE
	else:
		next_rate -= SKILL_7_HP_STEP_RATE
	next_rate = clampf(next_rate, SKILL_7_MIN_HP_RATE, SKILL_7_MAX_HP_RATE)
	_skill_7_hp_rate[enemy] = next_rate
	# 最大HP
	var next_max_hp := maxi(1, roundi(float(int(_skill_7_base_hp[enemy])) * next_rate))
	# HPdelta
	var hp_delta := next_max_hp - enemy.get_max_hp()
	enemy.set_hp_values(next_max_hp, maxi(1, enemy.get_current_hp() + hp_delta))


# 敵ダメージvalues適用
func _apply_enemy_damage_values(damage_display_values: Dictionary, Acided_enemies: Array[Enemy]) -> void:
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
		elif _has_nightmare_effect(enemy, STRENGTH_RIRAN_OVERHEAL):
			enemy.heal_over_max(maxi(1, ceili(float(enemy.get_max_hp()) * 0.01)))
		enemy.pulse_damage()


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


# 最大消化ダメージ記録
func _record_max_acid_damage(max_damage_by_enemy: Dictionary, enemy: Enemy, damage: int) -> void:
	if enemy == null or damage <= 0:
		return
	max_damage_by_enemy[enemy] = maxi(int(max_damage_by_enemy.get(enemy, 0)), damage)


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


# starteffect適用
func _apply_strength_turn_start_effect(enemy: Enemy, enemies: Array[Enemy], stomach: StomachBoard, minutes: int) -> void:
	if not enemy.can_take_stomach_turn():
		return
	if _has_nightmare_effect(enemy, STRENGTH_ELMENA_LINE_ATTACK):
		# 列elapsed分数
		var line_elapsed_minutes := int(get_step_minutes_breakdown(enemies)["total"])
		_add_line_minutes(enemy, stomach, line_elapsed_minutes)
		if int(_strength_line_minutes.get(enemy, 0)) >= 60:
			_strength_line_minutes[enemy] = 0
			_pending_player_damage_values.append(seed_effects.apply_player_damage(enemy.get_base_damage() * 5, acid_DAMAGE))
	if _has_nightmare_effect(enemy, STRENGTH_ELMENA_HIT_COUNT_HEAL) and enemy.stomach_elapsed_minutes > 0 and enemy.stomach_elapsed_minutes % 60 == 0:
		# hit数
		var hit_count := int(_strength_hit_counts.get(enemy, 0))
		if hit_count > 0:
			enemy.heal(ceili(float(enemy.get_max_hp()) * 0.1 * float(hit_count)))
		_strength_hit_counts[enemy] = 0
	if _has_nightmare_effect(enemy, STRENGTH_FELIS_SEVEN_ATTACK) and _time_text_contains_digit(minutes, "7"):
		enemy.add_damage(enemy.get_base_damage())
	if _has_nightmare_effect(enemy, STRENGTH_FELIS_RANDOM_ATTACK):
		enemy.set_attack_multiplier(float(randi_range(10, 300)) / 100.0)
	if _has_nightmare_effect(enemy, STRENGTH_NERIX_LOW_ATTACK_HP):
		_apply_max_hp_modifier(enemy, "nerix_low_attack", 5.0, _has_lower_attack_than_other_nightmare(enemy, enemies))
	if _has_nightmare_effect(enemy, STRENGTH_ZAIKA_EDGE_HP):
		_apply_max_hp_modifier(enemy, "zaika_edge", 4.0, _is_adjacent_to_stomach_edge(enemy, stomach))
	if _has_nightmare_effect(enemy, STRENGTH_ZAIKA_LINE_HP_DOWN):
		_apply_max_hp_modifier(enemy, "zaika_line_down", 0.2, stomach.get_bottom_row_cell_count(enemy) >= 3)
	if _has_nightmare_effect(enemy, STRENGTH_MIRUNE_DELAYED_ATTACK):
		# 数値
		var count := _increment_strength_turn_count(enemy)
		if count % 3 == 0:
			_pending_player_damage_values.append(seed_effects.apply_player_damage(enemy.get_base_damage() * 5, acid_DAMAGE))
	if _has_nightmare_effect(enemy, STRENGTH_COROTTA_TEN_TURNS):
		# 数値
		var count := _increment_strength_turn_count(enemy)
		if count % 10 == 0:
			enemy.add_max_hp(enemy.get_max_hp() * 2)
			enemy.add_damage(enemy.get_base_damage())
	if _has_nightmare_effect(enemy, STRENGTH_IRIYU_ADJACENT_WEAKEN):
		_apply_iriyu_adjacent_weaken(enemy, enemies)


# timingeffect適用
func _apply_strength_attack_timing_effect(enemy: Enemy, minutes: int) -> bool:
	if (
		_has_nightmare_effect(enemy, STRENGTH_ELMENA_THREE_OCLOCK_ATTACK)
		and minutes >= TWO_OCLOCK_MINUTES
		and enemy.get_current_hp() >= ceili(float(enemy.get_max_hp()) * 0.5)
		and not _strength_once_keys.has("%s:elmena_two_oclock" % enemy.get_instance_id())
	):
		_strength_once_keys["%s:elmena_two_oclock" % enemy.get_instance_id()] = true
		# ダメージ
		var damage := seed_effects.apply_player_damage(enemy.get_base_damage() * 100, acid_DAMAGE)
		if damage > 0:
			_pending_player_damage_values.append(damage)
	return false


# receivedeffects適用
func _apply_strength_damage_received_effects(
	enemy: Enemy,
	enemies: Array[Enemy],
	damage: int,
	minutes: int,
	elapsed_minutes: int,
	_stomach: StomachBoard
) -> void:
	if damage <= 0:
		return
	if _has_nightmare_effect(enemy, STRENGTH_ERAMIA_DAMAGE_TO_ATTACK) and _has_even_time_part(minutes):
		enemy.add_damage(damage)
	if _has_nightmare_effect(enemy, STRENGTH_ERAMIA_COUNT_BUFF):
		# active数
		var active_count := _get_active_nightmare_count(enemies)
		enemy.add_max_hp(ceili(float(enemy.get_max_hp()) * 0.1 * float(active_count)))
		enemy.add_damage(ceili(float(enemy.get_base_damage()) * 0.1 * float(active_count)))
	if _has_nightmare_effect(enemy, STRENGTH_ELMENA_HIT_COUNT_HEAL):
		_strength_hit_counts[enemy] = int(_strength_hit_counts.get(enemy, 0)) + 1
	if _has_nightmare_effect(enemy, STRENGTH_RIRAN_EXTRA_TIME):
		_pending_extra_elapsed_minutes += elapsed_minutes
	if _has_nightmare_effect(enemy, STRENGTH_IRIYU_DAMAGE_TO_ATTACK):
		enemy.add_damage(floori(float(damage) * 0.1))


# ダメージreactions適用
func _apply_strength_after_damage_reactions(enemies: Array[Enemy], received_acid_damage: Dictionary) -> Array[Enemy]:
	# forced消化済み
	var forced_Acided: Array[Enemy] = []
	for enemy in enemies:
		if _has_nightmare_effect(enemy, STRENGTH_NERIX_TOP_DAMAGE_ATTACK) and _received_more_damage_than_others(enemy, enemies, received_acid_damage):
			enemy.add_damage(ceili(float(enemy.get_base_damage()) * 0.5))
		if not _has_nightmare_effect(enemy, STRENGTH_NERIX_ABSORB_ALL):
			continue
		if int(received_acid_damage.get(enemy, 0)) <= 0:
			continue
		# others
		var others := _get_other_active_nightmares(enemy, enemies)
		if others.is_empty():
			continue
		for other in others:
			enemy.add_max_hp(other.get_max_hp() * 2)
			enemy.add_damage(ceili(float(other.get_base_damage()) * 1.5))
			other.set_Acided(true)
			forced_Acided.append(other)
	return forced_Acided


# strength消化済みeffect適用
func _apply_strength_Acided_effect(
	enemy: Enemy,
	enemies: Array[Enemy],
	_received_acid_damage: Dictionary,
	max_received_acid_damage: Dictionary
) -> void:
	if _has_nightmare_effect(enemy, STRENGTH_GONSAL_LOW_PARASITE):
		for cell in enemy.get_occupied_cells(enemy.stomach_cell):
			_pending_spawn_requests.append(_create_spawn_request(enemy, cell, 0.5, 0))
	if _has_nightmare_effect(enemy, STRENGTH_GONSAL_MID_PARASITE):
		# ダメージ
		var damage := maxi(0, int(max_received_acid_damage.get(enemy, 0)))
		for cell in enemy.get_occupied_cells(enemy.stomach_cell):
			_pending_spawn_requests.append(_create_spawn_request(enemy, cell, 1.0, damage))
	if _has_nightmare_effect(enemy, STRENGTH_GONSAL_HIGH_PARASITE):
		for cell in enemy.get_occupied_cells(enemy.stomach_cell):
			_pending_spawn_requests.append(_create_spawn_request(enemy, cell, 1.0, 0, 1.0, 0.8))
	if _has_nightmare_effect(enemy, STRENGTH_COROTTA_SET_THREE_OCLOCK):
		_pending_time_override_minutes = THREE_OCLOCK_MINUTES


# 種keptbyiriyu判定
func _is_seed_kept_by_iriyu(enemy: Enemy, enemies: Array[Enemy]) -> bool:
	if not enemy.has_seed() or not enemy.is_active_in_stomach():
		return false
	for other in enemies:
		if _has_nightmare_effect(other, STRENGTH_IRIYU_KEEP_SEED) and EnemyPlacementQuery.are_enemies_adjacent(enemy, other):
			return true
	return false


# 列分数追加
func _add_line_minutes(enemy: Enemy, stomach: StomachBoard, elapsed_minutes: int) -> void:
	if stomach.get_bottom_row_cell_count(enemy) <= 0:
		_strength_line_minutes[enemy] = 0
		return
	_strength_line_minutes[enemy] = int(_strength_line_minutes.get(enemy, 0)) + elapsed_minutes


# turn数処理
func _increment_strength_turn_count(enemy: Enemy) -> int:
	# 数値
	var count := int(_strength_turn_counts.get(enemy, 0)) + 1
	_strength_turn_counts[enemy] = count
	return count


# 最大HPmodifier適用
func _apply_max_hp_modifier(enemy: Enemy, key: String, multiplier: float, enabled: bool) -> void:
	if not _strength_base_max_hp.has(enemy):
		_strength_base_max_hp[enemy] = enemy.get_max_hp()
	# modifiers
	var modifiers: Dictionary = {}
	if _strength_hp_modifiers.has(enemy):
		modifiers = _strength_hp_modifiers[enemy]
	if enabled:
		modifiers[key] = multiplier
	else:
		modifiers.erase(key)
	_strength_hp_modifiers[enemy] = modifiers
	# 倍率
	var next_multiplier := 1.0
	for modifier in modifiers.values():
		next_multiplier *= float(modifier)
	# 最大HP
	var current_max_hp := enemy.get_max_hp()
	# HP率
	var hp_rate := 1.0 if current_max_hp <= 0 else float(enemy.get_current_hp()) / float(current_max_hp)
	# 最大HP
	var next_max_hp := maxi(1, roundi(float(int(_strength_base_max_hp[enemy])) * next_multiplier))
	enemy.set_hp_values(next_max_hp, roundi(float(next_max_hp) * hp_rate))


# iriyu隣接weaken適用
func _apply_iriyu_adjacent_weaken(source: Enemy, enemies: Array[Enemy]) -> void:
	for adjacent in EnemyPlacementQuery.get_adjacent_enemies(source, enemies):
		if not adjacent.is_nightmare():
			continue
		# oncekey
		var once_key := "%s:%s" % [source.get_instance_id(), adjacent.get_instance_id()]
		if _strength_once_keys.has(once_key):
			continue
		_strength_once_keys[once_key] = true
		adjacent.add_damage(adjacent.get_base_damage() * 4)
		adjacent.set_hp_values(adjacent.get_max_hp(), maxi(1, ceili(float(adjacent.get_max_hp()) * 0.5)))


# active悪夢数取得
func _get_active_nightmare_count(enemies: Array[Enemy]) -> int:
	# 数値
	var count := 0
	for enemy in enemies:
		if enemy.is_active_in_stomach() and enemy.is_nightmare():
			count += 1
	return count


# 胃内数取得
func _get_active_stomach_count(enemies: Array[Enemy]) -> int:
	var count := 0 # 数
	for enemy in enemies:
		if enemy != null and enemy.is_stomach_piece():
			count += 1
	return count

# otheractive悪夢取得
func _get_other_active_nightmares(source: Enemy, enemies: Array[Enemy]) -> Array[Enemy]:
	# others
	var others: Array[Enemy] = []
	for enemy in enemies:
		if enemy != source and enemy.is_active_in_stomach() and enemy.is_nightmare():
			others.append(enemy)
	return others


# other悪夢判定
func _has_lower_attack_than_other_nightmare(enemy: Enemy, enemies: Array[Enemy]) -> bool:
	for other in enemies:
		if other != enemy and other.is_active_in_stomach() and other.is_nightmare() and enemy.get_damage() < other.get_damage():
			return true
	return false


# thanothers処理
func _received_more_damage_than_others(enemy: Enemy, enemies: Array[Enemy], received_acid_damage: Dictionary) -> bool:
	# ダメージ
	var damage := int(received_acid_damage.get(enemy, 0))
	if damage <= 0:
		return false
	for other in enemies:
		if other == enemy or not other.is_active_in_stomach() or not other.is_nightmare():
			continue
		if damage <= int(received_acid_damage.get(other, 0)):
			return false
	return true


# 隣接to胃袋edge判定
func _is_adjacent_to_stomach_edge(enemy: Enemy, stomach: StomachBoard) -> bool:
	for cell in enemy.get_occupied_cells(enemy.stomach_cell):
		if cell.x == 0 or cell.x == stomach.columns - 1 or cell.y == 0 or cell.y == stomach.rows - 1:
			return true
	return false


# even時間part判定
func _has_even_time_part(minutes: int) -> bool:
	return int(minutes / 60) % 2 == 0 or minutes % 60 % 2 == 0


# 時間文言containsdigit処理
func _time_text_contains_digit(minutes: int, digit: String) -> bool:
	# 時値
	var hour := int(minutes / 60) % 24
	# 分値
	var minute := minutes % 60
	return ("%02d%02d" % [hour, minute]).contains(digit)


# 悪夢消化ダメージ率取得
func _get_nightmare_acid_damage_rate(enemies: Array[Enemy], minutes: int) -> float:
	# ダメージ率
	var damage_rate := _get_global_acid_damage_multiplier(enemies) - 1.0
	if not has_active_nightmare_effect(enemies, NIGHTMARE_SKILL_LATE_acid_WEAKEN) or minutes < 25 * 60:
		return damage_rate
	# passedhours
	var passed_hours := maxi(0, floori(float(minutes - 25 * 60) / 60.0))
	return damage_rate - minf(0.9, 0.3 + float(passed_hours) * 0.05)


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


# 悪夢effect判定
func _has_nightmare_effect(enemy: Enemy, skill_id: int) -> bool:
	return (
		enemy.should_apply_nightmare_skill()
		and enemy.has_main_effect
		and enemy.has_nightmare_skill()
		and enemy.get_nightmare_skill().skill_id == skill_id
	)
