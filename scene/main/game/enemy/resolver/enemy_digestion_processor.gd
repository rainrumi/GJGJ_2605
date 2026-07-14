class_name EnemyDigestionProcessor
extends RefCounted

var _resolver: EnemyDigestionResolver # 消化計算
var _enemy_effects: EnemyEffectSystem # 効果実行
var _presenter: EnemyPresenter # 結果表示


# 依存関係設定
func setup(
	resolver: EnemyDigestionResolver,
	enemy_effects: EnemyEffectSystem,
	presenter: EnemyPresenter
) -> void:
	_resolver = resolver
	_enemy_effects = enemy_effects
	_presenter = presenter


# 消化処理実行
func process(input: EnemyDigestionInput) -> EnemyDigestionBatchResult:
	var batch := _resolver.create_results(input) # 計算結果
	_enemy_effects.prepare(input.enemies, input.stomach)
	for result in batch.results:
		var damage := _enemy_effects.prepare_acid_damage(result.enemy, result.total_damage) # 補正後消化値
		_resolver.apply_result(result, damage)
		batch.received_damage[result.enemy] = result.total_damage
		_presenter.present_digestion_result(result)
		_enemy_effects.notify_acid_damage_applied(
			result.enemy,
			result.total_damage,
			result.overkill_damage
		)
		_enemy_effects.notify_adjacent_acid_damage(
			result.enemy,
			result.total_damage,
			result.overkill_damage
		)
	var candidates := _resolver.collect_digested(input, batch) # 消化候補
	var final_digested: Array[Enemy] = [] # 最終消化一覧
	for enemy in candidates:
		var result := batch.find_result(enemy) # 対象結果
		var damage := result.total_damage if result != null else int(batch.received_damage.get(enemy, 0)) # 受領値
		var overkill := result.overkill_damage if result != null else maxi(
			0,
			damage - int(batch.turn_start_hp.get(enemy, 0))
		) # 超過値
		_enemy_effects.notify_digested(
			enemy,
			damage,
			overkill,
			input.elapsed_minutes * 60,
			input.minutes * 60,
			candidates
		)
		if not enemy.is_Acided():
			if result != null:
				result.was_digested = false
			continue
		_resolver.apply_seed_block_effects(input, enemy, batch, candidates)
		final_digested.append(enemy)
	batch.digested_enemies = final_digested
	_enemy_effects.notify_digestion_batch(
		input.elapsed_minutes * 60,
		input.minutes * 60,
		final_digested
	)
	for enemy in final_digested:
		_enemy_effects.notify_adjacent_digested(
			enemy,
			input.elapsed_minutes * 60,
			input.minutes * 60,
			final_digested
		)
	return batch
