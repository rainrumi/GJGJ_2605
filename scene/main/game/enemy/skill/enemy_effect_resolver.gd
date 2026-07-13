class_name EnemyEffectResolver
extends RefCounted

var _states: Dictionary = {} # 効果状態
var _attack_deltas: Dictionary = {} # 攻撃差分
var _attack_multipliers: Dictionary = {} # 攻撃倍率
var _attack_overrides: Dictionary = {} # 攻撃固定値
var _max_hp_deltas: Dictionary = {} # 最大HP差分
var _max_hp_multipliers: Dictionary = {} # 最大HP倍率
var _applied_max_hp_deltas: Dictionary = {} # 適用済み差分
var _acid_damage_deltas: Dictionary = {} # 消化差分
var _acid_damage_multipliers: Dictionary = {} # 消化倍率
var _effect_multipliers: Dictionary = {} # 効果倍率
var _chance_deltas: Dictionary = {} # 確率差分
var _interval_seconds_delta := 0 # 間隔秒差分
var _interval_rate := 0.0 # 間隔割合
var _global_acid_delta := 0 # 全体消化差分
var _global_acid_multiplier := 1.0 # 全体消化倍率
var _pending_player_damage: Array[int] = [] # プレイヤーダメージ
var _pending_spawns: Array[BattleSpawnEnemyData] = [] # 生成要求
var _spawn_counts: Dictionary = {} # 生成数
var _extra_attacks: Dictionary = {} # 追加攻撃
var _attack_guards: Dictionary = {} # 攻撃無効
var _acid_guards: Dictionary = {} # 消化無効
var _permanent_acid_deltas: Dictionary = {} # 永続消化差分
var _permanent_acid_multipliers: Dictionary = {} # 永続消化倍率
var _inherited_effects: Dictionary = {} # 継承効果
var _default_attack_disabled: Dictionary = {} # 通常攻撃停止
var _pending_time_delta_seconds := 0 # 時刻差分秒
var _last_acid_damage := 0 # 直近消化値
var _pending_digested: Array[Enemy] = [] # 直接消化済み


# 状態初期化
func reset() -> void:
	_states.clear()
	_applied_max_hp_deltas.clear()
	_pending_player_damage.clear()
	_pending_spawns.clear()
	_spawn_counts.clear()
	_extra_attacks.clear()
	_attack_guards.clear()
	_acid_guards.clear()
	_permanent_acid_deltas.clear()
	_permanent_acid_multipliers.clear()
	_inherited_effects.clear()
	_default_attack_disabled.clear()
	_pending_time_delta_seconds = 0
	_last_acid_damage = 0
	_pending_digested.clear()
	_clear_modifiers()


# 継続効果更新
func refresh(enemies: Array[Enemy], stomach: StomachBoard) -> void:
	_clear_modifiers()
	for enemy in enemies:
		if not _can_apply(enemy):
			continue
		for effect in _get_effects(enemy):
			if effect is EnemyEffectOnAdjacentObjectScaleEffect or effect is EnemyEffectOnAdjacentObjectChangeChance:
				_dispatch_effect(effect, EnemyEffect.Event.REFRESH, enemy, enemies, stomach)
	for enemy in enemies:
		if not _can_apply(enemy):
			continue
		for effect in _get_effects(enemy):
			if effect is EnemyEffectOnAdjacentObjectScaleEffect or effect is EnemyEffectOnAdjacentObjectChangeChance:
				continue
			_dispatch_effect(effect, EnemyEffect.Event.REFRESH, enemy, enemies, stomach)
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
	var current_damage := damage # 現在ダメージ
	for enemy in enemies:
		if not _can_apply_for_event(enemy, event):
			continue
		for effect in _get_effects(enemy):
			current_damage = _dispatch_effect(effect, event, enemy, enemies, stomach, target, current_damage, overkill_damage, elapsed_seconds, current_seconds, digested_enemies)
	return current_damage


# 攻撃値取得
func get_attack(enemy: Enemy, base_value: int) -> int:
	if _attack_overrides.has(enemy):
		return maxi(0, int(_attack_overrides[enemy]))
	return maxi(0, roundi(float(base_value + int(_attack_deltas.get(enemy, 0))) * float(_attack_multipliers.get(enemy, 1.0))))


# 消化値取得
func get_acid_damage(enemy: Enemy, base_value: int) -> int:
	if consume_acid_guard(enemy):
		return 0
	var value := base_value + _global_acid_delta + int(_acid_damage_deltas.get(enemy, 0)) + int(_permanent_acid_deltas.get(enemy, 0)) # 補正前値
	value = roundi(float(value) * _global_acid_multiplier * float(_acid_damage_multipliers.get(enemy, 1.0)) * float(_permanent_acid_multipliers.get(enemy, 1.0)))
	return maxi(0, value)


# 間隔秒取得
func get_interval_seconds(base_seconds: int) -> int:
	return maxi(1, roundi(float(base_seconds + _interval_seconds_delta) * (1.0 + _interval_rate)))


# 攻撃差分追加
func add_attack_delta(enemy: Enemy, value: int) -> void:
	_attack_deltas[enemy] = int(_attack_deltas.get(enemy, 0)) + value


# 攻撃値固定
func set_attack_override(enemy: Enemy, value: int) -> void:
	_attack_overrides[enemy] = value


# 攻撃倍率追加
func multiply_attack(enemy: Enemy, value: float) -> void:
	_attack_multipliers[enemy] = float(_attack_multipliers.get(enemy, 1.0)) * value


# 最大HP差分追加
func add_max_hp_delta(enemy: Enemy, value: int, follow_hp: bool) -> void:
	_max_hp_deltas[enemy] = int(_max_hp_deltas.get(enemy, 0)) + value
	if follow_hp:
		_states["follow_hp:%s" % enemy.get_instance_id()] = int(_states.get("follow_hp:%s" % enemy.get_instance_id(), 0)) + value


# 最大HP倍率追加
func multiply_max_hp(enemy: Enemy, value: float) -> void:
	_max_hp_multipliers[enemy] = float(_max_hp_multipliers.get(enemy, 1.0)) * value


# 消化差分追加
func add_acid_damage_delta(enemy: Enemy, value: int) -> void:
	_acid_damage_deltas[enemy] = int(_acid_damage_deltas.get(enemy, 0)) + value


# 消化倍率追加
func multiply_acid_damage(enemy: Enemy, value: float) -> void:
	_acid_damage_multipliers[enemy] = float(_acid_damage_multipliers.get(enemy, 1.0)) * value


# 全体消化追加
func add_global_acid_damage(delta: int, multiplier: float) -> void:
	_global_acid_delta += delta
	_global_acid_multiplier *= multiplier


# 間隔秒追加
func add_interval_seconds(value: int) -> void:
	_interval_seconds_delta += value


# 間隔割合追加
func add_interval_rate(value: float) -> void:
	_interval_rate += value


# 効果倍率追加
func multiply_effect(enemy: Enemy, value: float) -> void:
	_effect_multipliers[enemy] = float(_effect_multipliers.get(enemy, 1.0)) * value


# 効果倍率取得
func get_effect_multiplier(enemy: Enemy) -> float:
	return float(_effect_multipliers.get(enemy, 1.0))


# 確率差分追加
func add_chance_delta(enemy: Enemy, value: float) -> void:
	_chance_deltas[enemy] = float(_chance_deltas.get(enemy, 0.0)) + value


# 確率差分取得
func get_chance_delta(enemy: Enemy) -> float:
	return float(_chance_deltas.get(enemy, 0.0))


# プレイヤーダメージ追加
func queue_player_damage(value: int) -> void:
	if value > 0:
		_pending_player_damage.append(value)


# プレイヤーダメージ消費
func consume_player_damage() -> Array[int]:
	var values: Array[int] = _pending_player_damage.duplicate() # ダメージ一覧
	_pending_player_damage.clear()
	return values


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
	var key := "%s:%s" % [source.get_instance_id(), effect.get_instance_id()] # 生成キー
	var current_count := int(_spawn_counts.get(key, 0))
	var allowed_count := spawn_count
	if max_spawn_count > 0:
		allowed_count = mini(allowed_count, maxi(0, max_spawn_count - current_count))
	for _index in range(allowed_count):
		var request := BattleSpawnEnemyData.new() # 生成要求
		request.source_enemy = source
		request.enemy_info = enemy_info
		request.skill = source.get_enemy_skill() if inherit_skill else spawn_skill
		request.spawn_area = spawn_area
		request.max_hp = hp_value
		request.current_hp = hp_value
		request.damage = attack_value
		_pending_spawns.append(request)
	_spawn_counts[key] = current_count + allowed_count


# 生成要求消費
func consume_spawns() -> Array[BattleSpawnEnemyData]:
	var values: Array[BattleSpawnEnemyData] = _pending_spawns.duplicate() # 生成一覧
	_pending_spawns.clear()
	return values


# 追加攻撃付与
func add_extra_attacks(enemy: Enemy, value: int) -> void:
	_extra_attacks[enemy] = int(_extra_attacks.get(enemy, 0)) + value


# 攻撃回数取得
func get_attack_count(enemy: Enemy) -> int:
	return maxi(0, 1 + int(_extra_attacks.get(enemy, 0)))


# 攻撃無効付与
func add_attack_guards(enemy: Enemy, value: int) -> void:
	_attack_guards[enemy] = int(_attack_guards.get(enemy, 0)) + value


# 攻撃無効消費
func consume_attack_guard(enemy: Enemy) -> bool:
	var count := int(_attack_guards.get(enemy, 0))
	if count <= 0:
		return false
	_attack_guards[enemy] = count - 1
	return true


# 消化無効付与
func add_acid_guards(enemy: Enemy, value: int) -> void:
	_acid_guards[enemy] = int(_acid_guards.get(enemy, 0)) + value


# 消化無効消費
func consume_acid_guard(enemy: Enemy) -> bool:
	var count := int(_acid_guards.get(enemy, 0))
	if count <= 0:
		return false
	_acid_guards[enemy] = count - 1
	return true


# 永続消化補正
func add_permanent_acid_modifier(enemy: Enemy, delta: int, multiplier: float) -> void:
	_permanent_acid_deltas[enemy] = int(_permanent_acid_deltas.get(enemy, 0)) + delta
	_permanent_acid_multipliers[enemy] = float(_permanent_acid_multipliers.get(enemy, 1.0)) * multiplier


# 時刻差分追加
func add_time_delta(seconds: int) -> void:
	_pending_time_delta_seconds += seconds


# 時刻差分消費
func consume_time_delta_seconds() -> int:
	var value := _pending_time_delta_seconds # 時刻差分
	_pending_time_delta_seconds = 0
	return value


# 効果継承
func inherit_effects(target: Enemy, source: Enemy) -> void:
	var values: Array[EnemyEffect] = [] # 継承一覧
	if _inherited_effects.has(target): values.append_array(_inherited_effects[target])
	values.append_array(source.get_enemy_effects())
	_inherited_effects[target] = values


# 通常攻撃設定
func set_default_attack_disabled(enemy: Enemy, value: bool) -> void:
	if value:
		_default_attack_disabled[enemy] = true


# 通常攻撃判定
func is_default_attack_disabled(enemy: Enemy) -> bool:
	return bool(_default_attack_disabled.get(enemy, false))


# 直近消化値設定
func set_last_acid_damage(value: int) -> void:
	_last_acid_damage = maxi(0, value)


# 直近消化値取得
func get_last_acid_damage() -> int:
	return _last_acid_damage


# 状態取得
func get_state(enemy: Enemy, effect: EnemyEffect, key: String, default_value: Variant) -> Variant:
	return _states.get(_state_key(enemy, effect, key), default_value)


# 状態設定
func set_state(enemy: Enemy, effect: EnemyEffect, key: String, value: Variant) -> void:
	_states[_state_key(enemy, effect, key)] = value


# 効果dispatch
func _dispatch_effect(
	effect: EnemyEffect,
	event: EnemyEffect.Event,
	source: Enemy,
	enemies: Array[Enemy],
	stomach: StomachBoard,
	target: Enemy = null,
	damage := 0,
	overkill_damage := 0,
	elapsed_seconds := 0,
	current_seconds := 0,
	digested_enemies: Array[Enemy] = []
) -> int:
	var context := EnemyEffectContext.new() # 効果文脈
	context.event = event
	context.source = source
	context.target = target
	context.enemies = enemies
	context.stomach = stomach
	context.effect = effect
	context.resolver = self
	context.damage = damage
	context.overkill_damage = overkill_damage
	context.elapsed_seconds = elapsed_seconds
	context.current_seconds = current_seconds
	context.digested_minutes = source.stomach_elapsed_minutes
	context.digested_enemies = digested_enemies
	effect.apply(context)
	return context.damage


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
	_attack_deltas.clear()
	_attack_multipliers.clear()
	_attack_overrides.clear()
	_max_hp_deltas.clear()
	_max_hp_multipliers.clear()
	_acid_damage_deltas.clear()
	_acid_damage_multipliers.clear()
	_effect_multipliers.clear()
	_chance_deltas.clear()
	_default_attack_disabled.clear()
	_interval_seconds_delta = 0
	_interval_rate = 0.0
	_global_acid_delta = 0
	_global_acid_multiplier = 1.0


# 最大HP補正適用
func _apply_max_hp_modifiers(enemies: Array[Enemy]) -> void:
	for enemy in enemies:
		if enemy == null or enemy.is_Acided():
			continue
		var old_delta := int(_applied_max_hp_deltas.get(enemy, 0)) # 旧差分
		var base_max := maxi(1, enemy.get_max_hp() - old_delta) # 基準最大HP
		var next_max := maxi(1, roundi(float(base_max + int(_max_hp_deltas.get(enemy, 0))) * float(_max_hp_multipliers.get(enemy, 1.0))))
		var next_delta := next_max - base_max # 新差分
		var follow_key := "follow_hp:%s" % enemy.get_instance_id() # 追従キー
		var hp_delta := int(_states.get(follow_key, 0)) - old_delta
		enemy.set_hp_values(next_max, enemy.get_current_hp() + hp_delta)
		_states[follow_key] = 0
		_applied_max_hp_deltas[enemy] = next_delta


# 状態キー取得
func _state_key(enemy: Enemy, effect: EnemyEffect, key: String) -> String:
	return "%s:%s:%s" % [enemy.get_instance_id(), effect.get_instance_id(), key]
