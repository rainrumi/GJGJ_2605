class_name EnemyEffectSystem
extends RefCounted

var _digestion_interval := DigestionInterval.new() # 消化間隔
var _acid_modifiers := EnemyAcidDamageModifiers.new() # 全体消化補正
var _player_health := PlayerHealth.new() # プレイヤーHP
var _spawn_queue := EnemySpawnQueue.new() # 生成要求
var _battle_clock := BattleClock.new() # 戦闘時刻
var _digestion_state := EnemyDigestionState.new() # 消化状態
var _inheritance := EnemyEffectInheritance.new() # 継承効果
var _effect_stack := EnemyEffectStack.new() # 効果スタック
var _installer := EnemyEffectInstaller.new() # 効果配線
var _known_enemies: Dictionary = {} # 戦闘参加敵


# 効果系初期化
func _init() -> void:
	_installer.setup(
		_player_health,
		_spawn_queue,
		_battle_clock,
		_digestion_interval,
		_acid_modifiers,
		_digestion_state,
		_inheritance,
		_effect_stack
	)


# 状態初期化
func reset() -> void:
	_installer.reset()
	for enemy in _known_enemies.keys():
		if enemy != null and is_instance_valid(enemy):
			enemy.data.defense_status.reset()
			enemy.data.attack.reset_modifiers()
			enemy.data.hp.reset_modifiers()
	_known_enemies.clear()
	_player_health.clear()
	_spawn_queue.clear()
	_battle_clock.reset()
	_digestion_interval.reset()
	_acid_modifiers.reset()
	_digestion_state.reset()
	_inheritance.reset()
	_effect_stack.clear()


# 継続効果更新
func refresh(enemies: Array[Enemy], stomach: StomachBoard) -> void:
	_register_enemies(enemies)
	_installer.sync(enemies, stomach)
	_clear_refresh_modifiers()
	var activation := RefreshActivationData.new() # 更新発動値
	if stomach != null:
		stomach.request_effect_refresh_preprocess(activation)
	_effect_stack.execute()
	if stomach != null:
		stomach.request_effect_refresh(activation)
	_effect_stack.execute()
	_apply_max_hp_modifiers(enemies)


# 戦闘開始通知
func notify_battle_start(enemies: Array[Enemy], stomach: StomachBoard) -> void:
	_prepare_connections(enemies, stomach)
	_battle_clock.request_battle_effect(BattleStartActivationData.new())
	_effect_stack.execute()


# ターン開始通知
func notify_turn_start(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	elapsed_seconds: int,
	current_seconds: int
) -> void:
	_prepare_connections(enemies, stomach)
	_battle_clock.request_turn_effect(TurnStartActivationData.new(elapsed_seconds, current_seconds))
	_effect_stack.execute()


# 時間進行通知
func notify_progress_time(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	elapsed_seconds: int,
	current_seconds: int
) -> void:
	_prepare_connections(enemies, stomach)
	_battle_clock.request_progress_effect(ProgressTimeActivationData.new(elapsed_seconds, current_seconds))
	_effect_stack.execute()


# 消化前通知
func before_acid_damage(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	target: Enemy,
	damage: int,
	overkill_damage := 0
) -> int:
	if target == null:
		return maxi(0, damage)
	_prepare_connections(enemies, stomach)
	var activation := BeforeAcidDamageActivationData.new(damage, overkill_damage, target.data, target) # 被弾値
	target.data.hp.request_before_acid_damage(activation)
	_effect_stack.execute()
	return activation.amount


# 消化後通知
func notify_after_acid_damage(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	target: Enemy,
	damage: int,
	overkill_damage: int
) -> void:
	if target == null:
		return
	_prepare_connections(enemies, stomach)
	var activation := AfterAcidDamageActivationData.new(damage, overkill_damage, target.data, target) # 被弾値
	target.data.hp.request_after_acid_damage(activation)
	_effect_stack.execute()


# 隣接被弾通知
func notify_adjacent_acid_damage(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	target: Enemy,
	damage: int,
	overkill_damage: int
) -> void:
	if target == null:
		return
	_prepare_connections(enemies, stomach)
	var activation := AdjacentAcidDamageActivationData.new(damage, overkill_damage, target.data, target) # 被弾値
	target.data.hp.request_adjacent_acid_damage(activation)
	_effect_stack.execute()


# 消化済み通知
func notify_digested(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	target: Enemy,
	damage: int,
	overkill_damage: int,
	elapsed_seconds: int,
	current_seconds: int,
	digested_enemies: Array[Enemy]
) -> void:
	if target == null:
		return
	_prepare_connections(enemies, stomach)
	var activation := _create_digestion_activation(DigestedActivationData.new(), target, damage, overkill_damage, elapsed_seconds, current_seconds, digested_enemies) # 消化値
	target.data.stomach_status.request_digested_effect(activation)
	_effect_stack.execute()


# 全体消化通知
func notify_any_digested(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	elapsed_seconds: int,
	current_seconds: int,
	digested_enemies: Array[Enemy]
) -> void:
	_prepare_connections(enemies, stomach)
	var activation := _create_digestion_activation(AnyDigestedActivationData.new(), null, 0, 0, elapsed_seconds, current_seconds, digested_enemies) # 消化値
	_digestion_state.request_any_digested_effect(activation)
	_effect_stack.execute()


# 隣接消化通知
func notify_adjacent_digested(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	target: Enemy,
	elapsed_seconds: int,
	current_seconds: int,
	digested_enemies: Array[Enemy]
) -> void:
	if target == null:
		return
	_prepare_connections(enemies, stomach)
	var activation := _create_digestion_activation(AdjacentDigestedActivationData.new(), target, 0, 0, elapsed_seconds, current_seconds, digested_enemies) # 消化値
	target.data.stomach_status.request_adjacent_digested_effect(activation)
	_effect_stack.execute()


# 攻撃値取得
func get_attack(enemy: Enemy, base_value: int) -> int:
	return enemy.data.attack.get_modified_value(base_value) if enemy != null else maxi(0, base_value)


# 消化値取得
func get_acid_damage(enemy: Enemy, base_value: int) -> int:
	return _acid_modifiers.resolve(enemy, base_value)


# 間隔秒取得
func get_interval_seconds(base_seconds: int) -> int:
	return _digestion_interval.resolve(base_seconds)


# プレイヤーダメージ消費
func consume_player_damage() -> Array[int]:
	return _player_health.consume_damage()


# 生成要求消費
func consume_spawns() -> Array[BattleSpawnEnemyData]:
	return _spawn_queue.consume()


# 追加攻撃回数取得
func get_attack_count(enemy: Enemy) -> int:
	return maxi(0, 1 + enemy.data.defense_status.extra_attack_count) if enemy != null else 0


# 通常攻撃判定
func is_default_attack_disabled(enemy: Enemy) -> bool:
	return enemy != null and enemy.data.defense_status.default_attack_disabled


# 時刻差分消費
func consume_time_delta_seconds() -> int:
	return _battle_clock.consume_change()


# 消化済み消費
func consume_pending_digested() -> Array[Enemy]:
	return _digestion_state.consume()


# 直近消化値設定
func set_last_acid_damage(value: int) -> void:
	_digestion_state.set_last_damage(value)


# 効果配線準備
func _prepare_connections(enemies: Array[Enemy], stomach: StomachBoard) -> void:
	_register_enemies(enemies)
	_installer.sync(enemies, stomach)


# 消化発動値作成
func _create_digestion_activation(
	activation: DigestionActivationData,
	target: Enemy,
	damage: int,
	overkill_damage: int,
	elapsed_seconds: int,
	current_seconds: int,
	digested_enemies: Array[Enemy]
) -> DigestionActivationData:
	activation.setup(target, damage, overkill_damage, elapsed_seconds, current_seconds, digested_enemies)
	return activation


# 敵一覧登録
func _register_enemies(enemies: Array[Enemy]) -> void:
	for enemy in enemies:
		if enemy != null:
			_known_enemies[enemy] = true


# 一時補正初期化
func _clear_refresh_modifiers() -> void:
	for enemy in _known_enemies.keys():
		if enemy != null and is_instance_valid(enemy):
			enemy.data.defense_status.reset_refresh_modifiers()
			enemy.data.attack.reset_modifiers()
			enemy.data.hp.reset_modifiers()
	_digestion_interval.reset()
	_acid_modifiers.reset()


# 最大HP補正適用
func _apply_max_hp_modifiers(enemies: Array[Enemy]) -> void:
	for enemy in enemies:
		if enemy != null and not enemy.is_Acided():
			enemy.data.hp.apply_modifiers()
