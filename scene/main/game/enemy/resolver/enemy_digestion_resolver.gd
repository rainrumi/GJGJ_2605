class_name EnemyDigestionResolver
extends RefCounted

var _seed_effects: SeedEffectResolver # 種効果計算
var _seed_block_resolver: DreamSeedBlockAcidResolver # 種ブロック計算
var _acid_modifiers: EnemyAcidDamageModifiers # 消化補正
var _digestion_state: EnemyDigestionState # 消化状態


# 依存関係設定
func setup(
	seed_effects: SeedEffectResolver,
	seed_block_resolver: DreamSeedBlockAcidResolver,
	acid_modifiers: EnemyAcidDamageModifiers,
	digestion_state: EnemyDigestionState
) -> void:
	_seed_effects = seed_effects
	_seed_block_resolver = seed_block_resolver
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


# 消化結果作成
func create_results(input: EnemyDigestionInput) -> EnemyDigestionBatchResult:
	var batch := EnemyDigestionBatchResult.new() # 一括結果
	batch.turn_start_hp = _get_turn_start_hp(input.enemies)
	for enemy in input.enemies:
		var result := _create_enemy_result(enemy, input) # 対象結果
		if result == null:
			continue
		batch.results.append(result)
		batch.received_damage[enemy] = result.total_damage
	return batch


# 敵ダメージ収集
# 対象結果作成
func _create_enemy_result(enemy: Enemy, input: EnemyDigestionInput) -> EnemyDigestionResult:
	if not enemy.can_take_stomach_turn():
		return null
	var bottom_cell_count := input.stomach.get_bottom_row_cell_count(enemy) # 下端セル数
	if bottom_cell_count == 0:
		return null
	var damage := _get_final_damage(
		enemy,
		input.enemies,
		input.acid_damage_per_cell * bottom_cell_count
	) # 消化値
	damage = _acid_modifiers.resolve(enemy, damage)
	_digestion_state.set_last_damage(damage)
	_seed_effects.add_acid_damage_total(damage)
	var result := EnemyDigestionResult.new() # 対象結果
	result.enemy = enemy
	result.damage_values = [damage]
	result.total_damage = damage
	result.hp_before = enemy.data.hp.current
	return result


# 対象結果適用
func apply_result(result: EnemyDigestionResult, damage: int) -> void:
	if result == null or result.enemy == null or result.enemy.is_Acided():
		return
	result.total_damage = maxi(0, damage)
	result.damage_values = [result.total_damage]
	result.applied_damage = mini(result.hp_before, result.total_damage)
	result.overkill_damage = maxi(0, result.total_damage - result.hp_before)
	result.was_digested = result.enemy.take_acid_damage(result.total_damage, false)


# ダメージ要求作成
func request_damage(result: EnemyDigestionResult) -> EnemyDamageRequest:
	if result == null or result.enemy == null:
		return null
	return result.enemy.data.hp.request_damage(result.total_damage, result.enemy.data)


# 消化候補取得
func collect_digested(
	input: EnemyDigestionInput,
	batch: EnemyDigestionBatchResult
) -> Array[Enemy]:
	var digested_enemies: Array[Enemy] = [] # 消化候補一覧
	for result in batch.results:
		if result.was_digested:
			digested_enemies.append(result.enemy)
	for enemy in _digestion_state.consume():
		if not digested_enemies.has(enemy):
			digested_enemies.append(enemy)
	_sort_digested_enemies(
		input.enemies,
		digested_enemies,
		batch.received_damage,
		batch.turn_start_hp
	)
	return digested_enemies


# 種ブロック効果適用
func apply_seed_block_effects(
	input: EnemyDigestionInput,
	enemy: Enemy,
	batch: EnemyDigestionBatchResult,
	digested_enemies: Array[Enemy]
) -> void:
	_seed_block_resolver.append_Acided_by_seed_block_effects(
		enemy,
		input.enemies,
		input.stomach,
		input.minutes,
		batch.received_damage,
		digested_enemies,
		input.acid_damage_per_cell,
		input.elapsed_minutes
	)


# 効果なし消化解決
func resolve(input: EnemyDigestionInput) -> EnemyDigestionBatchResult:
	var batch := create_results(input) # 一括結果
	for result in batch.results:
		apply_result(result, result.total_damage)
	batch.digested_enemies = collect_digested(input, batch)
	return batch


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
