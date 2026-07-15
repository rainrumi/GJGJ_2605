class_name EnemyDigestionProcessor
extends RefCounted

var _resolver: EnemyDigestionResolver # 消化計算
var _enemy_effects: EnemyEffectSystem # 効果実行
var _presenter: EnemyPresentationCoordinator # 結果表示
var _digestion_state: EnemyDigestionState # 消化一括Signal元


# 依存関係設定
func setup(
	resolver: EnemyDigestionResolver,
	enemy_effects: EnemyEffectSystem,
	presenter: EnemyPresentationCoordinator,
	digestion_state: EnemyDigestionState
) -> void:
	_resolver = resolver
	_enemy_effects = enemy_effects
	_presenter = presenter
	_digestion_state = digestion_state


# 消化処理実行
func process(input: EnemyDigestionInput) -> EnemyDigestionBatchResult:
	var batch := _resolver.create_results(input) # 計算結果
	_enemy_effects.prepare(input.enemies, input.stomach)
	_presenter.sync(input.enemies)
	for result in batch.results:
		var request := _resolver.request_damage(result) # 消化要求
		_enemy_effects.execute()
		_resolver.apply_result(result, request.amount if request != null else result.total_damage)
		_enemy_effects.execute()
		batch.received_damage[result.enemy] = result.total_damage
		_presenter.present_digestion_result(result)
	var candidates := _resolver.collect_digested(input, batch) # 消化候補
	var candidate_data := _to_enemy_data(candidates) # 消化候補データ
	var final_digested: Array[Enemy] = [] # 最終消化一覧
	for enemy in candidates:
		var result := batch.find_result(enemy) # 対象結果
		var damage := result.total_damage if result != null else int(batch.received_damage.get(enemy, 0)) # 受領値
		var overkill := result.overkill_damage if result != null else maxi(
			0,
			damage - int(batch.turn_start_hp.get(enemy, 0))
		) # 超過値
		enemy.data.stomach_status.publish_digestion(
			damage,
			overkill,
			input.elapsed_minutes * 60,
			input.minutes * 60,
			candidate_data
		)
		_enemy_effects.execute()
		if not enemy.is_Acided():
			if result != null:
				result.was_digested = false
			continue
		_resolver.apply_seed_block_effects(input, enemy, batch, candidates)
		final_digested.append(enemy)
	batch.digested_enemies = final_digested
	_digestion_state.complete_batch(
		input.elapsed_minutes * 60,
		input.minutes * 60,
		_to_enemy_data(final_digested)
	)
	_enemy_effects.execute()
	return batch


# 敵データ変換
func _to_enemy_data(enemies: Array[Enemy]) -> Array[EnemyData]:
	var values: Array[EnemyData] = [] # 変換結果
	for enemy in enemies:
		if enemy != null:
			values.append(enemy.data)
	return values
