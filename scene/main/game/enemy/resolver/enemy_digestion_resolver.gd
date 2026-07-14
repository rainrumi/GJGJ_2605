class_name EnemyDigestionResolver
extends RefCounted

var _seed_effects: SeedEffectResolver # 種効果計算
var _seed_block_resolver: DreamSeedBlockAcidResolver # 種ブロック計算
var _enemy_effects: EnemyEffectSystem # 敵効果窓口
var _acid_modifiers: EnemyAcidDamageModifiers # 消化補正
var _digestion_state: EnemyDigestionState # 消化状態


# 依存関係設定
func setup(
	seed_effects: SeedEffectResolver,
	seed_block_resolver: DreamSeedBlockAcidResolver,
	enemy_effects: EnemyEffectSystem,
	acid_modifiers: EnemyAcidDamageModifiers,
	digestion_state: EnemyDigestionState
) -> void:
	_seed_effects = seed_effects
	_seed_block_resolver = seed_block_resolver
	_enemy_effects = enemy_effects
	_acid_modifiers = acid_modifiers
	_digestion_state = digestion_state


# 消化内訳取得
func get_damage_breakdown(
	enemies: Array[Enemy],
	minutes: int,
	base_damage: int,
	consume_pending_bonus := false,
	stomach: StomachBoard = null
) -> Dictionary:
	var columns := stomach.columns if stomach != null else 0 # 胃袋列数
	var rows := stomach.rows if stomach != null else 0 # 胃袋行数
	return _seed_effects.get_acid_damage_breakdown(
		base_damage,
		_get_nightmare_damage_rate(enemies) + _seed_block_resolver.get_acid_damage_rate(enemies, minutes),
		minutes,
		consume_pending_bonus,
		columns,
		rows,
		_get_active_stomach_count(enemies)
	)


# 消化処理解決
func resolve(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	minutes: int,
	elapsed_minutes: int,
	acid_damage_per_cell: int
) -> Array[Enemy]:
	var digested_enemies: Array[Enemy] = [] # 消化済み敵
	var damage_values: Dictionary = {} # 敵別ダメージ
	var received_damage: Dictionary = {} # 敵別受領値
	var turn_start_hp := _get_turn_start_hp(enemies) # 開始時HP
	for enemy in enemies:
		_collect_enemy_damage(enemy, enemies, stomach, minutes, acid_damage_per_cell, damage_values, received_damage)
	_apply_damage_values(damage_values, digested_enemies, enemies, stomach)
	for enemy in _digestion_state.consume():
		if not digested_enemies.has(enemy):
			digested_enemies.append(enemy)
	return _resolve_digested_effects(
		enemies,
		stomach,
		minutes,
		elapsed_minutes,
		acid_damage_per_cell,
		digested_enemies,
		received_damage,
		turn_start_hp
	)


# 敵ダメージ収集
func _collect_enemy_damage(
	enemy: Enemy,
	enemies: Array[Enemy],
	stomach: StomachBoard,
	minutes: int,
	acid_damage_per_cell: int,
	damage_values: Dictionary,
	received_damage: Dictionary
) -> void:
	if not enemy.can_take_stomach_turn():
		return
	var bottom_cell_count := stomach.get_bottom_row_cell_count(enemy) # 下端セル数
	if bottom_cell_count == 0:
		return
	var damage := _get_final_damage(enemy, enemies, acid_damage_per_cell * bottom_cell_count) # 消化値
	damage = _acid_modifiers.resolve(enemy, damage)
	damage = _prepare_acid_damage(enemies, stomach, enemy, damage)
	_digestion_state.set_last_damage(damage)
	received_damage[enemy] = received_damage.get(enemy, 0) + damage
	_seed_effects.add_acid_damage_total(damage)
	_append_damage_value(damage_values, enemy, damage)


# ダメージ一括適用
func _apply_damage_values(
	damage_values: Dictionary,
	digested_enemies: Array[Enemy],
	enemies: Array[Enemy],
	stomach: StomachBoard
) -> void:
	for target in damage_values.keys():
		var enemy := target as Enemy # 対象敵
		if enemy == null or enemy.is_Acided():
			continue
		var values: Array = damage_values[target] # 表示ダメージ
		var total_damage := _sum_damage_values(values) # 合計ダメージ
		var hp_before := enemy.data.hp.current # 適用前HP
		enemy.show_acid_damage_values(values)
		if enemy.take_acid_damage(total_damage, false) and not digested_enemies.has(enemy):
			digested_enemies.append(enemy)
		enemy.pulse_damage()
		var overkill := maxi(0, total_damage - hp_before) # 超過ダメージ
		_notify_acid_damage_applied(enemies, stomach, enemy, total_damage, overkill)
		_notify_adjacent_acid_damage(enemies, stomach, enemy, total_damage, overkill)


# 消化効果解決
func _resolve_digested_effects(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	minutes: int,
	elapsed_minutes: int,
	acid_damage_per_cell: int,
	digested_enemies: Array[Enemy],
	received_damage: Dictionary,
	turn_start_hp: Dictionary
) -> Array[Enemy]:
	var final_digested: Array[Enemy] = [] # 最終消化一覧
	_sort_digested_enemies(enemies, digested_enemies, received_damage, turn_start_hp)
	for enemy in digested_enemies:
		var damage := int(received_damage.get(enemy, 0)) # 受領ダメージ
		var overkill := maxi(0, damage - int(turn_start_hp.get(enemy, 0))) # 超過ダメージ
		_notify_digested(enemies, stomach, enemy, damage, overkill, elapsed_minutes * 60, minutes * 60, digested_enemies)
		if not enemy.is_Acided():
			continue
		_seed_block_resolver.append_Acided_by_seed_block_effects(
			enemy,
			enemies,
			stomach,
			minutes,
			received_damage,
			digested_enemies,
			acid_damage_per_cell,
			elapsed_minutes
		)
		final_digested.append(enemy)
	_notify_digestion_batch(enemies, stomach, elapsed_minutes * 60, minutes * 60, final_digested)
	for enemy in final_digested:
		_notify_adjacent_digested(enemies, stomach, enemy, elapsed_minutes * 60, minutes * 60, final_digested)
	return final_digested


# 消化前効果実行
func _prepare_acid_damage(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	target: Enemy,
	damage: int
) -> int:
	_enemy_effects.prepare(enemies, stomach)
	var activation := BeforeAcidDamageActivationData.new(damage, 0, target.data, target) # 消化前値
	target.data.hp.notify_acid_damage_preparing(activation)
	_enemy_effects.execute()
	return activation.amount


# 消化後効果実行
func _notify_acid_damage_applied(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	target: Enemy,
	damage: int,
	overkill: int
) -> void:
	_enemy_effects.prepare(enemies, stomach)
	var activation := AfterAcidDamageActivationData.new(damage, overkill, target.data, target) # 消化後値
	target.data.hp.notify_acid_damage_applied(activation)
	_enemy_effects.execute()


# 隣接被弾効果実行
func _notify_adjacent_acid_damage(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	target: Enemy,
	damage: int,
	overkill: int
) -> void:
	_enemy_effects.prepare(enemies, stomach)
	var activation := AdjacentAcidDamageActivationData.new(damage, overkill, target.data, target) # 隣接被弾値
	target.data.hp.notify_adjacent_acid_damage(activation)
	_enemy_effects.execute()


# 消化効果実行
func _notify_digested(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	target: Enemy,
	damage: int,
	overkill: int,
	elapsed_seconds: int,
	current_seconds: int,
	digested_enemies: Array[Enemy]
) -> void:
	_enemy_effects.prepare(enemies, stomach)
	var activation := DigestedActivationData.new() # 消化発動値
	activation.setup(target, damage, overkill, elapsed_seconds, current_seconds, digested_enemies)
	target.data.stomach_status.notify_digestion_resolved(activation)
	_enemy_effects.execute()


# 消化群効果実行
func _notify_digestion_batch(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	elapsed_seconds: int,
	current_seconds: int,
	digested_enemies: Array[Enemy]
) -> void:
	_enemy_effects.prepare(enemies, stomach)
	var activation := AnyDigestedActivationData.new() # 消化群値
	activation.setup(null, 0, 0, elapsed_seconds, current_seconds, digested_enemies)
	_digestion_state.notify_digestion_batch(activation)
	_enemy_effects.execute()


# 隣接消化効果実行
func _notify_adjacent_digested(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	target: Enemy,
	elapsed_seconds: int,
	current_seconds: int,
	digested_enemies: Array[Enemy]
) -> void:
	_enemy_effects.prepare(enemies, stomach)
	var activation := AdjacentDigestedActivationData.new() # 隣接消化値
	activation.setup(target, 0, 0, elapsed_seconds, current_seconds, digested_enemies)
	target.data.stomach_status.notify_adjacent_digestion(activation)
	_enemy_effects.execute()


# 消化順整列
func _sort_digested_enemies(
	enemies: Array[Enemy],
	digested_enemies: Array[Enemy],
	received_damage: Dictionary,
	turn_start_hp: Dictionary
) -> void:
	digested_enemies.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		var a_surplus := int(received_damage.get(a, 0)) - int(turn_start_hp.get(a, 0)) # A超過値
		var b_surplus := int(received_damage.get(b, 0)) - int(turn_start_hp.get(b, 0)) # B超過値
		if a_surplus == b_surplus:
			return enemies.find(a) < enemies.find(b)
		return a_surplus > b_surplus
	)


# 最終消化値取得
func _get_final_damage(enemy: Enemy, enemies: Array[Enemy], raw_damage: int) -> int:
	var damage_rate := enemy.acid_damage_taken_multiplier # 対象倍率
	damage_rate *= _seed_effects.get_acid_target_multiplier()
	damage_rate *= _seed_block_resolver.get_target_acid_damage_multiplier(enemy, enemies)
	return roundi(float(raw_damage) * damage_rate)


# 開始時HP取得
func _get_turn_start_hp(enemies: Array[Enemy]) -> Dictionary:
	var values := {} # HP一覧
	for enemy in enemies:
		values[enemy] = enemy.data.hp.current
	return values


# ダメージ値追加
func _append_damage_value(values_by_enemy: Dictionary, enemy: Enemy, damage: int) -> void:
	if enemy == null or damage <= 0:
		return
	var values: Array[int] = [] # 敵別値一覧
	if values_by_enemy.has(enemy):
		values.append_array(values_by_enemy[enemy])
	values.append(damage)
	values_by_enemy[enemy] = values


# ダメージ合計
func _sum_damage_values(values: Array) -> int:
	var total := 0 # 合計値
	for damage in values:
		total += int(damage)
	return total


# 胃内数取得
func _get_active_stomach_count(enemies: Array[Enemy]) -> int:
	var count := 0 # 胃内数
	for enemy in enemies:
		if enemy != null and enemy.is_stomach_piece():
			count += 1
	return count


# 悪夢消化率取得
func _get_nightmare_damage_rate(enemies: Array[Enemy]) -> float:
	var multiplier := 1.0 # 全体倍率
	for enemy in enemies:
		if enemy != null and enemy.is_active_in_stomach():
			multiplier *= enemy.acid_damage_global_multiplier
	return multiplier - 1.0
