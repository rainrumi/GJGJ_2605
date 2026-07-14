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
var _known_enemies: Dictionary = {} # 戦闘参加敵


# 状態初期化
func reset() -> void:
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
	_clear_refresh_modifiers()
	var activation := RefreshActivationData.new() # 更新発動値
	_request_effects(activation, enemies, stomach, true)
	_effect_stack.execute()
	_request_effects(activation, enemies, stomach, false)
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
	_request_effects(activation, enemies, stomach, false)
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


# 効果要求作成
func _request_effects(
	activation: EnemyEffectActivationData,
	enemies: Array[Enemy],
	stomach: StomachBoard,
	preprocess: bool
) -> void:
	for enemy in enemies:
		if not _can_apply(enemy, activation):
			continue
		for effect in _get_effects(enemy):
			var is_preprocessor := effect is EnemyEffectOnAdjacentObjectScaleEffect or effect is EnemyEffectOnAdjacentObjectChangeChance # 前処理判定
			if activation is RefreshActivationData and preprocess != is_preprocessor:
				continue
			if not activation is RefreshActivationData and preprocess:
				continue
			_bind_effect(effect, enemy, enemies, stomach)
			_effect_stack.request(effect, activation)


# 効果依存設定
func _bind_effect(effect: EnemyEffect, owner: Enemy, enemies: Array[Enemy], stomach: StomachBoard) -> void:
	effect.bind_dependencies(
		owner,
		enemies,
		stomach,
		_player_health,
		_spawn_queue,
		_battle_clock,
		_digestion_interval,
		_acid_modifiers,
		_digestion_state,
		_inheritance
	)


# 効果取得
func _get_effects(enemy: Enemy) -> Array[EnemyEffect]:
	var values := enemy.get_enemy_effects() # 効果一覧
	values.append_array(_inheritance.get_effects(enemy))
	values.sort_custom(func(a: EnemyEffect, b: EnemyEffect) -> bool: return a.priority < b.priority)
	return values


# 効果適用判定
func _can_apply(enemy: Enemy, activation: EnemyEffectActivationData) -> bool:
	if enemy == null or not enemy.should_apply_nightmare_skill() or _get_effects(enemy).is_empty():
		return false
	if not enemy.is_Acided():
		return true
	return activation is AfterAcidDamageActivationData \
		or activation is AdjacentAcidDamageActivationData \
		or activation is DigestionActivationData


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
