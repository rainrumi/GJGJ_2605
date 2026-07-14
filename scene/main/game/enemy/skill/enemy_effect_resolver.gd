class_name EnemyEffectResolver
extends RefCounted

var _digestion_interval := DigestionInterval.new() # 消化間隔
var _global_acid_delta := 0 # 全体消化差分
var _global_acid_multiplier := 1.0 # 全体消化倍率
var _player_health := PlayerHealth.new() # プレイヤーHP
var _spawn_queue := EnemySpawnQueue.new() # 生成要求
var _inherited_effects: Dictionary = {} # 継承効果
var _battle_clock := BattleClock.new() # 戦闘時刻
var _last_acid_damage := 0 # 直近消化値
var _pending_digested: Array[Enemy] = [] # 直接消化済み
var _effect_stack := EnemyEffectStack.new() # 効果スタック
var _event_source := EnemyEffectEventSource.new() # イベント通知元
var _known_enemies: Dictionary = {} # 移行中の敵参照


# 通知接続
func _init() -> void:
	_event_source.occurred.connect(_on_effect_occurred)


# 状態初期化
func reset() -> void:
	_player_health.clear()
	_spawn_queue.clear()
	for enemy in _known_enemies.keys():
		if enemy != null and is_instance_valid(enemy):
			enemy.data.defense_status.reset()
			enemy.data.attack.reset_modifiers()
			enemy.data.hp.reset_modifiers()
	_known_enemies.clear()
	_inherited_effects.clear()
	_battle_clock.reset()
	_last_acid_damage = 0
	_pending_digested.clear()
	_effect_stack.clear()
	_clear_modifiers()


# 継続効果更新
func refresh(enemies: Array[Enemy], stomach: StomachBoard) -> void:
	_clear_modifiers()
	var event_data := _create_event_data(EnemyEffect.Event.REFRESH) # 更新イベント
	_event_source.notify(event_data, enemies, stomach, EnemyEffectEventSource.Phase.PREPROCESS)
	_effect_stack.execute()
	_event_source.notify(event_data, enemies, stomach, EnemyEffectEventSource.Phase.MAIN)
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
	var event_data := _create_event_data(
		event,
		target,
		damage,
		overkill_damage,
		elapsed_seconds,
		current_seconds,
		digested_enemies
	) # 発火イベント
	_event_source.notify(event_data, enemies, stomach)
	_effect_stack.execute()
	return event_data.damage


# 攻撃値取得
func get_attack(enemy: Enemy, base_value: int) -> int:
	return enemy.data.attack.get_modified_value(base_value) if enemy != null else maxi(0, base_value)


# 消化値取得
func get_acid_damage(enemy: Enemy, base_value: int) -> int:
	if consume_acid_guard(enemy):
		return 0
	if enemy == null:
		return maxi(0, base_value)
	var defense := enemy.data.defense_status # 防御状態
	var value := base_value + _global_acid_delta + defense.acid_damage_delta + defense.permanent_acid_delta # 補正前値
	value = roundi(float(value) * _global_acid_multiplier * defense.acid_damage_multiplier * defense.permanent_acid_multiplier)
	return maxi(0, value)


# 間隔秒取得
func get_interval_seconds(base_seconds: int) -> int:
	return _digestion_interval.resolve(base_seconds)


# 攻撃差分追加
func add_attack_delta(enemy: Enemy, value: int) -> void:
	if enemy != null:
		_register_enemy(enemy)
		enemy.data.attack.add_modifier_delta(value)


# 攻撃値固定
func set_attack_override(enemy: Enemy, value: int) -> void:
	if enemy != null:
		_register_enemy(enemy)
		enemy.data.attack.set_modifier_override(value)


# 攻撃倍率追加
func multiply_attack(enemy: Enemy, value: float) -> void:
	if enemy != null:
		_register_enemy(enemy)
		enemy.data.attack.multiply_modifier(value)


# 最大HP差分追加
func add_max_hp_delta(enemy: Enemy, value: int, follow_hp: bool) -> void:
	if enemy != null:
		_register_enemy(enemy)
		enemy.data.hp.add_modifier_delta(value, follow_hp)


# 最大HP倍率追加
func multiply_max_hp(enemy: Enemy, value: float) -> void:
	if enemy != null:
		_register_enemy(enemy)
		enemy.data.hp.multiply_modifier(value)


# 消化差分追加
func add_acid_damage_delta(enemy: Enemy, value: int) -> void:
	if enemy != null:
		_register_enemy(enemy)
		enemy.data.defense_status.add_acid_damage_delta(value)


# 消化倍率追加
func multiply_acid_damage(enemy: Enemy, value: float) -> void:
	if enemy != null:
		_register_enemy(enemy)
		enemy.data.defense_status.multiply_acid_damage(value)


# 全体消化追加
func add_global_acid_damage(delta: int, multiplier: float) -> void:
	_global_acid_delta += delta
	_global_acid_multiplier *= multiplier


# 間隔秒追加
func add_interval_seconds(value: int) -> void:
	_digestion_interval.add_seconds(value)


# 間隔割合追加
func add_interval_rate(value: float) -> void:
	_digestion_interval.add_rate(value)


# 効果倍率追加
func multiply_effect(enemy: Enemy, value: float) -> void:
	if enemy != null:
		_register_enemy(enemy)
		enemy.data.defense_status.multiply_effect(value)


# 効果倍率取得
func get_effect_multiplier(enemy: Enemy) -> float:
	return enemy.data.defense_status.effect_multiplier if enemy != null else 1.0


# 確率差分追加
func add_chance_delta(enemy: Enemy, value: float) -> void:
	if enemy != null:
		_register_enemy(enemy)
		enemy.data.defense_status.add_chance_delta(value)


# 確率差分取得
func get_chance_delta(enemy: Enemy) -> float:
	return enemy.data.defense_status.chance_delta if enemy != null else 0.0


# プレイヤーダメージ追加
func queue_player_damage(value: int) -> void:
	_player_health.request_damage(value)


# プレイヤーダメージ消費
func consume_player_damage() -> Array[int]:
	return _player_health.consume_damage()


# 直接消化ダメージ
func deal_acid_damage(enemy: Enemy, value: int, hit_count: int, digested_enemies: Array[Enemy]) -> void:
	if enemy == null or enemy.is_Acided() or value <= 0:
		return
	for _index in range(maxi(1, hit_count)):
		if enemy.take_acid_damage(value) and not digested_enemies.has(enemy):
			digested_enemies.append(enemy)
			if not _pending_digested.has(enemy): _pending_digested.append(enemy)
			break


# 直接消化済み消費
func consume_pending_digested() -> Array[Enemy]:
	var values: Array[Enemy] = _pending_digested.duplicate() # 消化済み一覧
	_pending_digested.clear()
	return values


# 生成要求追加
func queue_spawn(
	source: Enemy,
	effect: EnemyEffect,
	enemy_info: EnemyInfo,
	spawn_skill: EnemySkill,
	spawn_count: int,
	max_spawn_count: int,
	spawn_area: EnemyEffect.SpawnArea,
	hp_value: int,
	attack_value: int,
	inherit_skill: bool
) -> void:
	_spawn_queue.request(source, effect, enemy_info, spawn_skill, spawn_count, max_spawn_count, spawn_area, hp_value, attack_value, inherit_skill)


# 生成要求消費
func consume_spawns() -> Array[BattleSpawnEnemyData]:
	return _spawn_queue.consume()


# 追加攻撃付与
func add_extra_attacks(enemy: Enemy, value: int) -> void:
	if enemy != null:
		_register_enemy(enemy)
		enemy.data.defense_status.add_extra_attacks(value)


# 攻撃回数取得
func get_attack_count(enemy: Enemy) -> int:
	return maxi(0, 1 + enemy.data.defense_status.extra_attack_count) if enemy != null else 0


# 攻撃無効付与
func add_attack_guards(enemy: Enemy, value: int) -> void:
	if enemy != null:
		_register_enemy(enemy)
		enemy.data.defense_status.add_attack_guards(value)


# 攻撃無効消費
func consume_attack_guard(enemy: Enemy) -> bool:
	return enemy != null and enemy.data.defense_status.consume_attack_guard()


# 消化無効付与
func add_acid_guards(enemy: Enemy, value: int) -> void:
	if enemy != null:
		_register_enemy(enemy)
		enemy.data.defense_status.add_acid_guards(value)


# 消化無効消費
func consume_acid_guard(enemy: Enemy) -> bool:
	return enemy != null and enemy.data.defense_status.consume_acid_guard()


# 永続消化補正
func add_permanent_acid_modifier(enemy: Enemy, delta: int, multiplier: float) -> void:
	if enemy != null:
		_register_enemy(enemy)
		enemy.data.defense_status.add_permanent_acid_modifier(delta, multiplier)


# 時刻差分追加
func add_time_delta(seconds: int) -> void:
	_battle_clock.request_change(seconds)


# 時刻差分消費
func consume_time_delta_seconds() -> int:
	return _battle_clock.consume_change()


# 効果継承
func inherit_effects(target: Enemy, source: Enemy) -> void:
	var values: Array[EnemyEffect] = [] # 継承一覧
	if _inherited_effects.has(target): values.append_array(_inherited_effects[target])
	for effect in source.get_enemy_effects():
		values.append(effect.duplicate(true) as EnemyEffect)
	_inherited_effects[target] = values


# 通常攻撃設定
func set_default_attack_disabled(enemy: Enemy, value: bool) -> void:
	if enemy != null and value:
		_register_enemy(enemy)
		enemy.data.defense_status.disable_default_attack(true)


# 通常攻撃判定
func is_default_attack_disabled(enemy: Enemy) -> bool:
	return enemy != null and enemy.data.defense_status.default_attack_disabled


# 直近消化値設定
func set_last_acid_damage(value: int) -> void:
	_last_acid_damage = maxi(0, value)


# 直近消化値取得
func get_last_acid_damage() -> int:
	return _last_acid_damage


# 効果発動要求
func _request_effect(
	effect: EnemyEffect,
	source: Enemy,
	enemies: Array[Enemy],
	stomach: StomachBoard,
	event_data: EnemyEffectEventData
) -> void:
	if effect == null:
		return
	var runtime := EnemyEffectRuntime.new() # 実行時値
	runtime.setup(source, enemies, stomach, effect, self, event_data)
	_effect_stack.request(effect, EnemyEffectLegacyActivationData.new(runtime))


# イベント値作成
func _create_event_data(
	event: EnemyEffect.Event,
	target: Enemy = null,
	damage := 0,
	overkill_damage := 0,
	elapsed_seconds := 0,
	current_seconds := 0,
	digested_enemies: Array[Enemy] = []
) -> EnemyEffectEventData:
	var data := EnemyEffectEventData.new() # イベント値
	data.event = event
	data.target = target
	data.set_damage(damage)
	data.overkill_damage = overkill_damage
	data.clock.set_time(elapsed_seconds, current_seconds)
	data.digested_enemies = digested_enemies
	return data


# 効果イベント受付
func _on_effect_occurred(
	event_data: EnemyEffectEventData,
	enemies: Array[Enemy],
	stomach: StomachBoard,
	phase: EnemyEffectEventSource.Phase
) -> void:
	for enemy in enemies:
		if event_data.event == EnemyEffect.Event.REFRESH:
			if not _can_apply(enemy):
				continue
		elif not _can_apply_for_event(enemy, event_data.event):
			continue
		for effect in _get_effects(enemy):
			var is_preprocessor := effect is EnemyEffectOnAdjacentObjectScaleEffect or effect is EnemyEffectOnAdjacentObjectChangeChance # 前処理判定
			if phase == EnemyEffectEventSource.Phase.PREPROCESS and not is_preprocessor:
				continue
			if phase == EnemyEffectEventSource.Phase.MAIN and is_preprocessor:
				continue
			_request_effect(effect, enemy, enemies, stomach, event_data)


# 効果取得
func _get_effects(enemy: Enemy) -> Array[EnemyEffect]:
	var values := enemy.get_enemy_effects() # 効果一覧
	if _inherited_effects.has(enemy): values.append_array(_inherited_effects[enemy])
	values.sort_custom(func(a: EnemyEffect, b: EnemyEffect) -> bool: return a.priority < b.priority)
	return values


# 効果適用判定
func _can_apply(enemy: Enemy) -> bool:
	return enemy != null and not enemy.is_Acided() and enemy.should_apply_nightmare_skill() and not enemy.get_enemy_effects().is_empty()


# event適用判定
func _can_apply_for_event(enemy: Enemy, event: EnemyEffect.Event) -> bool:
	if enemy == null or not enemy.should_apply_nightmare_skill() or enemy.get_enemy_effects().is_empty():
		return false
	return not enemy.is_Acided() or event in [EnemyEffect.Event.AFTER_ACID_DAMAGE, EnemyEffect.Event.ADJACENT_ACID_DAMAGE, EnemyEffect.Event.DIGESTED, EnemyEffect.Event.ANY_DIGESTED, EnemyEffect.Event.ADJACENT_DIGESTED]


# modifier消去
func _clear_modifiers() -> void:
	for enemy in _known_enemies.keys():
		if enemy != null and is_instance_valid(enemy):
			enemy.data.defense_status.reset_refresh_modifiers()
			enemy.data.attack.reset_modifiers()
			enemy.data.hp.reset_modifiers()
	_digestion_interval.reset()
	_global_acid_delta = 0
	_global_acid_multiplier = 1.0


# 最大HP補正適用
func _apply_max_hp_modifiers(enemies: Array[Enemy]) -> void:
	for enemy in enemies:
		if enemy == null or enemy.is_Acided():
			continue
		enemy.data.hp.apply_modifiers()


# 敵参照登録
func _register_enemy(enemy: Enemy) -> void:
	_known_enemies[enemy] = true
