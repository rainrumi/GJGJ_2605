class_name EnemyTurnProcessor
extends RefCounted

var _seed_effects: SeedEffectResolver # 種効果計算
var _enemy_effects: EnemyEffectSystem # 敵効果窓口
var _digestion_interval: DigestionInterval # 消化間隔
var _battle_clock: BattleClock # 戦闘時刻
var _digestion_state: EnemyDigestionState # 消化状態
var _step_minutes := 30 # 基準進行分
var _battle_start_minutes := 0 # 戦闘開始分


# 依存関係設定
func setup(
	seed_effects: SeedEffectResolver,
	enemy_effects: EnemyEffectSystem,
	digestion_interval: DigestionInterval,
	battle_clock: BattleClock,
	digestion_state: EnemyDigestionState,
	step_minutes: int
) -> void:
	_seed_effects = seed_effects
	_enemy_effects = enemy_effects
	_digestion_interval = digestion_interval
	_battle_clock = battle_clock
	_digestion_state = digestion_state
	_step_minutes = maxi(1, step_minutes)


# 開始分設定
func set_battle_start_minutes(value: int) -> void:
	_battle_start_minutes = maxi(0, value)


# 基準分取得
func get_base_step_minutes() -> int:
	return _step_minutes


# 進行分取得
func get_step_minutes(enemies: Array[Enemy], minutes := 0) -> int:
	return int(get_step_minutes_breakdown(enemies, true, minutes)["total"])


# 進行内訳取得
func get_step_minutes_breakdown(
	_enemies: Array[Enemy],
	consume_pending_bonus := false,
	minutes := 0
) -> Dictionary:
	var nightmare_minutes := ceili(float(_digestion_interval.resolve(_step_minutes * 60)) / 60.0) # 悪夢補正分
	var seed_rate := -_seed_effects.get_time_reduction_rate(
		consume_pending_bonus,
		minutes,
		_battle_start_minutes,
		_step_minutes
	) # 種補正率
	var total_minutes := maxi(1, roundi(float(nightmare_minutes) * (1.0 + seed_rate))) # 最終進行分
	return {
		"total": total_minutes,
		"base": _step_minutes,
		"seed_buff": total_minutes - nightmare_minutes,
		"seed_rate": seed_rate,
		"nightmare_buff": nightmare_minutes - _step_minutes,
		"nightmare_rate": float(nightmare_minutes - _step_minutes) / float(_step_minutes),
	}


# ターン開始処理
func begin_turn(enemies: Array[Enemy], stomach: StomachBoard, minutes: int) -> void:
	_enemy_effects.refresh(enemies, stomach)
	_enemy_effects.prepare(enemies, stomach)
	_battle_clock.sync_time(_step_minutes * 60, minutes * 60)
	for enemy in enemies:
		if not enemy.is_Acided() and enemy.can_take_stomach_turn():
			enemy.data.stomach_status.add_elapsed_minutes(_step_minutes)


# 時間進行処理
func progress_time(
	previous_minutes: int,
	minutes: int,
	enemies: Array[Enemy],
	stomach: StomachBoard
) -> BattleTurnResultData:
	_seed_effects.apply_progress_time(previous_minutes, minutes)
	var elapsed_seconds := maxi(0, minutes - previous_minutes) * 60 # 経過秒数
	var current_seconds := minutes * 60 # 現在秒数
	_enemy_effects.prepare(enemies, stomach)
	_battle_clock.set_time(elapsed_seconds, current_seconds)
	_enemy_effects.execute()
	var digested_enemies := _digestion_state.consume() # 時間消化一覧
	var digested_data := _to_enemy_data(digested_enemies) # 消化データ一覧
	for enemy in digested_enemies:
		enemy.data.stomach_status.publish_digestion(0, 0, elapsed_seconds, current_seconds, digested_data)
		_enemy_effects.execute()
	_digestion_state.complete_batch(elapsed_seconds, current_seconds, digested_data)
	_enemy_effects.execute()
	_enemy_effects.refresh(enemies, stomach)
	var result := build_result(digested_enemies) # 時間効果結果
	result.player_damage_values = _enemy_effects.consume_player_damage()
	return result


# 敵データ変換
func _to_enemy_data(enemies: Array[Enemy]) -> Array[EnemyData]:
	var values: Array[EnemyData] = [] # 変換結果
	for enemy in enemies:
		if enemy != null:
			values.append(enemy.data)
	return values


# ターン結果構築
func build_result(digested_enemies: Array[Enemy]) -> BattleTurnResultData:
	var result := BattleTurnResultData.new() # ターン結果
	result.Acided_enemies = digested_enemies
	result.spawn_requests = _enemy_effects.consume_spawns()
	result.extra_elapsed_minutes = roundi(float(_enemy_effects.consume_time_delta_seconds()) / 60.0)
	return result


# 遅延敵有効化
func activate_deferred_enemies(enemies: Array[Enemy]) -> void:
	for enemy in enemies:
		enemy.data.stomach_status.activation_deferred = false


# 遅延重力解除
func unlock_deferred_gravity(enemies: Array[Enemy]) -> void:
	for enemy in enemies:
		if enemy.is_active_in_stomach() and enemy.is_activation_deferred():
			enemy.data.stomach_status.gravity_locked = false
