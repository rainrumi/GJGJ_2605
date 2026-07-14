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


# イベント通知
func dispatch(
	event: EnemyEffect.Event,
	enemies: Array[Enemy],
	stomach: StomachBoard,
	target: Enemy = null,
	damage := 0,
	overkill_damage := 0,
	elapsed_seconds := 0,
	current_seconds := 0,
	digested_enemies: Array[Enemy] = []
) -> int:
	_register_enemies(enemies)
	_installer.sync(enemies, stomach)
	var activation := _create_activation(
		event,
		target,
		damage,
		overkill_damage,
		elapsed_seconds,
		current_seconds,
		digested_enemies
	) # 発動時値
	if activation == null:
		return maxi(0, damage)
	_emit_activation(activation, target)
	_effect_stack.execute()
	var damage_data := activation as DamageActivationData # 被弾値
	return damage_data.amount if damage_data != null else maxi(0, damage)


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


# 発動信号通知
func _emit_activation(activation: EnemyEffectActivationData, target: Enemy) -> void:
	if activation is BattleStartActivationData:
		_battle_clock.request_battle_effect(activation)
	elif activation is TurnStartActivationData:
		_battle_clock.request_turn_effect(activation)
	elif activation is ProgressTimeActivationData:
		_battle_clock.request_progress_effect(activation)
	elif activation is BeforeAcidDamageActivationData and target != null:
		target.data.hp.request_before_acid_damage(activation)
	elif activation is AfterAcidDamageActivationData and target != null:
		target.data.hp.request_after_acid_damage(activation)
	elif activation is AdjacentAcidDamageActivationData and target != null:
		target.data.hp.request_adjacent_acid_damage(activation)
	elif activation is DigestedActivationData and target != null:
		target.data.stomach_status.request_digested_effect(activation)
	elif activation is AnyDigestedActivationData:
		_digestion_state.request_any_digested_effect(activation)
	elif activation is AdjacentDigestedActivationData and target != null:
		target.data.stomach_status.request_adjacent_digested_effect(activation)


# 発動値作成
func _create_activation(
	event: EnemyEffect.Event,
	target: Enemy,
	damage: int,
	overkill_damage: int,
	elapsed_seconds: int,
	current_seconds: int,
	digested_enemies: Array[Enemy]
) -> EnemyEffectActivationData:
	match event:
		EnemyEffect.Event.BATTLE_START:
			return BattleStartActivationData.new()
		EnemyEffect.Event.REFRESH:
			return RefreshActivationData.new()
		EnemyEffect.Event.TURN_START:
			return TurnStartActivationData.new(elapsed_seconds, current_seconds)
		EnemyEffect.Event.PROGRESS_TIME:
			return ProgressTimeActivationData.new(elapsed_seconds, current_seconds)
		EnemyEffect.Event.BEFORE_ACID_DAMAGE:
			return BeforeAcidDamageActivationData.new(damage, overkill_damage, target.data if target != null else null, target)
		EnemyEffect.Event.AFTER_ACID_DAMAGE:
			return AfterAcidDamageActivationData.new(damage, overkill_damage, target.data if target != null else null, target)
		EnemyEffect.Event.ADJACENT_ACID_DAMAGE:
			return AdjacentAcidDamageActivationData.new(damage, overkill_damage, target.data if target != null else null, target)
		EnemyEffect.Event.DIGESTED:
			return _create_digestion_activation(DigestedActivationData.new(), target, damage, overkill_damage, elapsed_seconds, current_seconds, digested_enemies)
		EnemyEffect.Event.ANY_DIGESTED:
			return _create_digestion_activation(AnyDigestedActivationData.new(), target, damage, overkill_damage, elapsed_seconds, current_seconds, digested_enemies)
		EnemyEffect.Event.ADJACENT_DIGESTED:
			return _create_digestion_activation(AdjacentDigestedActivationData.new(), target, damage, overkill_damage, elapsed_seconds, current_seconds, digested_enemies)
	return null


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
