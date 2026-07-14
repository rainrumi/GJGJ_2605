class_name EnemyEffect
extends Resource

enum EffectTarget {
	SELF,
	ADJACENT_OBJECTS,
	ADJACENT_ENEMIES,
	ALL_OBJECTS,
	ALL_ENEMIES,
	ACID_LINE_OBJECTS,
}

enum AdjacentSelection {
	ALL,
	EVEN_SPLIT,
	LOWEST_HP,
	RANDOM_ONE,
}

enum TargetSelection {
	ALL,
	RANDOM_ONE,
	LOWEST_HP,
}

enum SpawnArea {
	SAME_CELLS,
	EMPTY_STOMACH,
	EMPTY_ADJACENT,
	OUTSIDE_STOMACH,
}

enum ValueSource {
	FIXED,
	SELF_CURRENT_HP,
	SELF_MAX_HP,
	SELF_ATTACK,
	TAKEN_DAMAGE,
	OVERKILL_DAMAGE,
	DIGESTED_MINUTES,
	LOST_HP,
	INHERITED_VALUE,
}

enum Event {
	BATTLE_START,
	REFRESH,
	TURN_START,
	PROGRESS_TIME,
	BEFORE_ACID_DAMAGE,
	AFTER_ACID_DAMAGE,
	DIGESTED,
	ANY_DIGESTED,
	ADJACENT_ACID_DAMAGE,
	ADJACENT_DIGESTED,
}

# 適用順
@export var priority :int = 0
# 有効状態
@export var enabled :bool = true
var state := EnemyEffectState.new() # 個体効果状態
var _activation_data: EnemyEffectActivationData # 発動時値
var source: Enemy # 効果所有者
var enemies: Array[Enemy] = [] # 戦闘対象
var stomach: StomachBoard # 胃袋盤面
var player_health: PlayerHealth # プレイヤーHP
var spawn_queue: EnemySpawnQueue # 敵生成要求
var battle_clock: BattleClock # 戦闘時刻
var digestion_interval: DigestionInterval # 消化間隔
var acid_modifiers: EnemyAcidDamageModifiers # 全体消化補正
var digestion_state: EnemyDigestionState # 消化状態
var inheritance: EnemyEffectInheritance # 効果継承


# 依存関係設定
func bind_dependencies(
	owner: Enemy,
	enemy_list: Array[Enemy],
	stomach_board: StomachBoard,
	player_hp: PlayerHealth,
	enemy_spawns: EnemySpawnQueue,
	clock: BattleClock,
	interval: DigestionInterval,
	global_acid: EnemyAcidDamageModifiers,
	digestion: EnemyDigestionState,
	inherited_effects: EnemyEffectInheritance
) -> void:
	source = owner
	enemies = enemy_list
	stomach = stomach_board
	player_health = player_hp
	spawn_queue = enemy_spawns
	battle_clock = clock
	digestion_interval = interval
	acid_modifiers = global_acid
	digestion_state = digestion
	inheritance = inherited_effects


# 発動開始
func begin_activation(data: EnemyEffectActivationData) -> void:
	_activation_data = data


# 発動値取得
func get_activation_data() -> EnemyEffectActivationData:
	return _activation_data


# 発動終了
func end_activation() -> void:
	_activation_data = null


# 要求可能判定
func can_request(data: EnemyEffectActivationData) -> bool:
	return enabled and source != null and is_instance_valid(source) and data != null and data.is_valid()


# 接続解除
func unbind() -> void:
	_activation_data = null
	source = null
	enemies = []
	stomach = null
	player_health = null
	spawn_queue = null
	battle_clock = null
	digestion_interval = null
	acid_modifiers = null
	digestion_state = null
	inheritance = null
	state.clear()


# 効果適用
func apply() -> void:
	pass


# 戦闘開始判定
func is_battle_start_activation() -> bool:
	return _activation_data is BattleStartActivationData


# 更新判定
func is_refresh_activation() -> bool:
	return _activation_data is RefreshActivationData


# ターン開始判定
func is_turn_start_activation() -> bool:
	return _activation_data is TurnStartActivationData


# 時間進行判定
func is_progress_time_activation() -> bool:
	return _activation_data is ProgressTimeActivationData


# 消化前判定
func is_before_acid_damage_activation() -> bool:
	return _activation_data is BeforeAcidDamageActivationData


# 消化後判定
func is_after_acid_damage_activation() -> bool:
	return _activation_data is AfterAcidDamageActivationData


# 消化済み判定
func is_digested_activation() -> bool:
	return _activation_data is DigestedActivationData


# 全消化判定
func is_any_digested_activation() -> bool:
	return _activation_data is AnyDigestedActivationData


# 隣接被弾判定
func is_adjacent_acid_damage_activation() -> bool:
	return _activation_data is AdjacentAcidDamageActivationData


# 隣接消化判定
func is_adjacent_digested_activation() -> bool:
	return _activation_data is AdjacentDigestedActivationData


# 発動対象取得
func get_activation_target() -> Enemy:
	var damage_data := _activation_data as DamageActivationData # 被弾値
	if damage_data != null:
		return damage_data.target_enemy
	var digestion_data := _activation_data as DigestionActivationData # 消化値
	return digestion_data.target_enemy if digestion_data != null else null


# 発動ダメージ取得
func get_activation_damage() -> int:
	var damage_data := _activation_data as DamageActivationData # 被弾値
	if damage_data != null:
		return damage_data.amount
	var digestion_data := _activation_data as DigestionActivationData # 消化値
	return digestion_data.damage if digestion_data != null else 0


# 発動ダメージ設定
func set_activation_damage(value: int) -> void:
	var damage_data := _activation_data as DamageActivationData # 被弾値
	if damage_data != null:
		damage_data.set_amount(value)


# 超過ダメージ取得
func get_activation_overkill_damage() -> int:
	var damage_data := _activation_data as DamageActivationData # 被弾値
	if damage_data != null:
		return damage_data.overkill_amount
	var digestion_data := _activation_data as DigestionActivationData # 消化値
	return digestion_data.overkill_damage if digestion_data != null else 0


# 経過秒数取得
func get_activation_elapsed_seconds() -> int:
	var time_data := _activation_data as TimeActivationData # 時刻値
	return time_data.elapsed_seconds if time_data != null else 0


# 現在秒数取得
func get_activation_current_seconds() -> int:
	var time_data := _activation_data as TimeActivationData # 時刻値
	return time_data.current_seconds if time_data != null else 0


# 消化済み一覧取得
func get_activation_digested_enemies() -> Array[Enemy]:
	var digestion_data := _activation_data as DigestionActivationData # 消化値
	return digestion_data.digested_enemies if digestion_data != null else []


# 隣接モノ取得
func get_adjacent_objects() -> Array[Enemy]:
	return EnemyPlacementQuery.get_adjacent_enemies(source, enemies)


# 隣接悪夢取得
func get_adjacent_enemies() -> Array[Enemy]:
	var values: Array[Enemy] = [] # 隣接悪夢
	for enemy in get_adjacent_objects():
		if enemy.is_nightmare():
			values.append(enemy)
	return values


# 対象一覧取得
func get_targets(target_type: EffectTarget) -> Array[Enemy]:
	match target_type:
		EffectTarget.SELF:
			return [source]
		EffectTarget.ADJACENT_OBJECTS:
			return get_adjacent_objects()
		EffectTarget.ADJACENT_ENEMIES:
			return get_adjacent_enemies()
		EffectTarget.ALL_ENEMIES:
			return get_active_enemies()
		EffectTarget.ACID_LINE_OBJECTS:
			return get_acid_line_objects()
	return get_active_objects()


# activeモノ取得
func get_active_objects() -> Array[Enemy]:
	var values: Array[Enemy] = [] # 有効モノ
	for enemy in enemies:
		if enemy != null and enemy.is_active_in_stomach() and not enemy.is_Acided():
			values.append(enemy)
	return values


# active悪夢取得
func get_active_enemies() -> Array[Enemy]:
	var values: Array[Enemy] = [] # 有効悪夢
	for enemy in get_active_objects():
		if enemy.is_nightmare():
			values.append(enemy)
	return values


# 消化ライン対象取得
func get_acid_line_objects() -> Array[Enemy]:
	var values: Array[Enemy] = [] # ライン対象
	if stomach == null:
		return values
	for enemy in get_active_objects():
		if stomach.get_bottom_row_cell_count(enemy) > 0:
			values.append(enemy)
	return values


# ライン接触数取得
func get_acid_line_contact_count(enemy: Enemy = source) -> int:
	if stomach == null or enemy == null:
		return 0
	return stomach.get_bottom_row_cell_count(enemy)


# 胃袋端接触数取得
func get_stomach_edge_contact_count(enemy: Enemy = source) -> int:
	if stomach == null or enemy == null or not enemy.is_active_in_stomach():
		return 0
	var count := 0 # 接触数
	for cell in enemy.get_occupied_cells(enemy.stomach_cell):
		if cell.x == 0 or cell.x == stomach.columns - 1 or cell.y == 0 or cell.y == stomach.rows - 1:
			count += 1
	return count


# 空隣接数取得
func get_open_adjacent_count() -> int:
	if stomach == null:
		return 0
	return EnemyPlacementQuery.get_open_adjacent_cell_count(source, enemies, stomach.columns, stomach.rows)


# 空マス数取得
func get_empty_cell_count() -> int:
	if stomach == null:
		return 0
	return maxi(0, stomach.get_capacity() - stomach.get_current_fullness(enemies))


# 確率判定
func roll(chance: float, invert := false) -> bool:
	var chance_delta := source.data.defense_status.chance_delta if source != null else 0.0 # 確率差分
	var adjusted := clampf(chance + chance_delta, 0.0, 1.0) # 補正確率
	if invert:
		adjusted = 1.0 - adjusted
	return randf() <= adjusted


# 効果値取得
func scale_value(value: float) -> float:
	var multiplier := source.data.defense_status.effect_multiplier if source != null else 1.0 # 効果倍率
	return value * multiplier


# 攻撃差分追加
func add_attack_delta(enemy: Enemy, value: int) -> void:
	if enemy != null:
		enemy.data.attack.add_modifier_delta(roundi(scale_value(float(value))))


# 攻撃値固定
func set_attack(enemy: Enemy, value: int) -> void:
	if enemy != null:
		enemy.data.attack.set_modifier_override(roundi(scale_value(float(value))))


# 攻撃倍率追加
func multiply_attack(enemy: Enemy, value: float) -> void:
	if enemy != null:
		enemy.data.attack.multiply_modifier(scale_value(value))


# HP変更
func change_hp(enemy: Enemy, value: int) -> void:
	if enemy == null or value == 0:
		return
	var scaled := roundi(scale_value(float(value))) # 補正値
	if scaled > 0:
		enemy.heal(scaled)
	else:
		enemy.take_acid_damage(-scaled)


# 最大HP差分追加
func add_max_hp_delta(enemy: Enemy, value: int, follow_hp := false) -> void:
	if enemy != null:
		enemy.data.hp.add_modifier_delta(roundi(scale_value(float(value))), follow_hp)


# HP倍率追加
func multiply_hp(enemy: Enemy, value: float) -> void:
	if enemy != null:
		enemy.data.hp.multiply_modifier(scale_value(value))


# 消化差分追加
func add_acid_damage_delta(enemy: Enemy, value: int) -> void:
	if enemy != null:
		enemy.data.defense_status.add_acid_damage_delta(roundi(scale_value(float(value))))


# 消化倍率追加
func multiply_acid_damage(enemy: Enemy, value: float) -> void:
	if enemy != null:
		enemy.data.defense_status.multiply_acid_damage(scale_value(value))


# 全体消化差分
func add_global_acid_damage(value: int, multiplier := 1.0) -> void:
	if acid_modifiers != null:
		acid_modifiers.add_modifier(roundi(scale_value(float(value))), scale_value(multiplier))


# 消化間隔秒追加
func add_interval_seconds(value: int) -> void:
	if digestion_interval != null:
		digestion_interval.add_seconds(roundi(scale_value(float(value))))


# 消化間隔割合追加
func add_interval_rate(value: float) -> void:
	if digestion_interval != null:
		digestion_interval.add_rate(scale_value(value))


# 効果倍率追加
func multiply_effect(enemy: Enemy, value: float) -> void:
	if enemy != null:
		enemy.data.defense_status.multiply_effect(value)


# 確率差分追加
func add_chance_delta(enemy: Enemy, value: float) -> void:
	if enemy != null:
		enemy.data.defense_status.add_chance_delta(value)


# プレイヤー攻撃追加
func attack_player(value: int, count := 1) -> void:
	if player_health == null:
		return
	for _index in range(maxi(0, count)):
		player_health.request_damage(maxi(0, roundi(scale_value(float(value)))))


# 消化ダメージ付与
func deal_acid_damage(enemy: Enemy, value: int, hit_count := 1) -> void:
	if enemy == null or enemy.is_Acided() or value <= 0:
		return
	var digested := get_activation_digested_enemies() # 消化済み一覧
	for _index in range(maxi(1, hit_count)):
		if enemy.take_acid_damage(maxi(0, roundi(scale_value(float(value))))):
			if not digested.has(enemy):
				digested.append(enemy)
			if digestion_state != null:
				digestion_state.register(enemy)
			break


# 敵回復
func recover(enemy: Enemy, value: int, rate := 0.0) -> void:
	if enemy == null:
		return
	var amount := roundi(scale_value(float(value))) # 回復量
	amount += roundi(float(enemy.get_max_hp()) * scale_value(rate))
	enemy.heal(maxi(0, amount))


# 敵復活
func revive(enemy: Enemy, rate: float) -> void:
	if enemy != null and enemy.is_Acided():
		enemy.revive_with_hp_rate(clampf(scale_value(rate), 0.0, 1.0))


# 敵生成要求
func spawn_enemy(
	enemy_info: EnemyInfo,
	spawn_skill: EnemySkill,
	spawn_count: int,
	max_spawn_count: int,
	spawn_area: SpawnArea,
	hp_value: int,
	attack_value: int,
	inherit_skill := false
) -> void:
	if spawn_queue != null:
		spawn_queue.request(source, self, enemy_info, spawn_skill, spawn_count, max_spawn_count, spawn_area, hp_value, attack_value, inherit_skill)


# 状態整数取得
func get_state_int(key: String, default_value := 0) -> int:
	return int(state.get_value(key, default_value))


# 状態値設定
func set_state(key: String, value: Variant) -> void:
	state.set_value(key, value)


# 間隔発火数取得
func consume_interval(interval_seconds: int) -> int:
	if interval_seconds <= 0:
		return 0
	var accumulated := get_state_int("elapsed_seconds") + get_activation_elapsed_seconds() # 累積秒
	var count := int(accumulated / interval_seconds) # 発火数
	set_state("elapsed_seconds", accumulated % interval_seconds)
	return count


# 隣接数差分取得
func get_adjacent_count_delta() -> int:
	var previous := get_state_int("adjacent_count") # 直前数
	var current := get_adjacent_objects().size() # 現在数
	set_state("adjacent_count", current)
	return current - previous


# 新規隣接取得
func get_new_adjacent_objects() -> Array[Enemy]:
	var previous: Array = state.get_value("adjacent_ids", []) # 直前ID
	var current_ids: Array[int] = [] # 現在ID
	var values: Array[Enemy] = [] # 新規対象
	for enemy in get_adjacent_objects():
		var id := enemy.get_instance_id() # 対象ID
		current_ids.append(id)
		if not previous.has(id):
			values.append(enemy)
	set_state("adjacent_ids", current_ids)
	return values


# 発動可能隣接取得
func get_activatable_new_adjacent(max_activations: int) -> Array[Enemy]:
	var values: Array[Enemy] = [] # 発動対象
	for enemy in get_new_adjacent_objects():
		var key := "activation:%s" % enemy.get_instance_id() # 発動キー
		var count := get_state_int(key)
		if max_activations > 0 and count >= max_activations:
			continue
		set_state(key, count + 1)
		values.append(enemy)
	return values


# 参照値取得
func resolve_value(source_type: ValueSource, fixed_value := 0) -> int:
	match source_type:
		ValueSource.SELF_CURRENT_HP: return source.get_current_hp()
		ValueSource.SELF_MAX_HP: return source.get_max_hp()
		ValueSource.SELF_ATTACK: return source.data.attack.get_modified_value(source.get_damage())
		ValueSource.TAKEN_DAMAGE: return get_activation_damage()
		ValueSource.OVERKILL_DAMAGE: return get_activation_overkill_damage()
		ValueSource.DIGESTED_MINUTES: return source.stomach_elapsed_minutes if source != null else 0
		ValueSource.LOST_HP: return maxi(0, source.get_max_hp() - source.get_current_hp())
	return fixed_value


# 攻撃無効追加
func add_attack_guards(enemy: Enemy, value: int) -> void:
	if enemy != null:
		enemy.data.defense_status.add_attack_guards(value)


# 消化無効追加
func add_acid_guards(enemy: Enemy, value: int) -> void:
	if enemy != null:
		enemy.data.defense_status.add_acid_guards(value)


# 追加攻撃追加
func add_extra_attacks(enemy: Enemy, value: int) -> void:
	if enemy != null:
		enemy.data.defense_status.add_extra_attacks(value)


# 永続消化補正
func add_permanent_acid_modifier(enemy: Enemy, delta: int, multiplier: float) -> void:
	if enemy != null:
		enemy.data.defense_status.add_permanent_acid_modifier(delta, multiplier)


# 時刻差分追加
func add_time_delta(seconds: int) -> void:
	if battle_clock != null:
		battle_clock.request_change(seconds)


# 直近消化値取得
func get_last_acid_damage() -> int:
	return digestion_state.last_acid_damage if digestion_state != null else 0


# 効果継承
func inherit_effects(target: Enemy, owner: Enemy) -> void:
	if inheritance != null:
		inheritance.inherit(target, owner)


# 通常攻撃設定
func set_default_attack_disabled(enemy: Enemy, value: bool) -> void:
	if enemy != null and value:
		enemy.data.defense_status.disable_default_attack(true)
