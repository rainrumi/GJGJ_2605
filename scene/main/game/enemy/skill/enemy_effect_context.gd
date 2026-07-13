class_name EnemyEffectContext
extends RefCounted

var event: EnemyEffect.Event = EnemyEffect.Event.REFRESH # 発火種別
var source: Enemy # 効果所有者
var target: Enemy # 発火対象
var enemies: Array[Enemy] = [] # 敵一覧
var stomach: StomachBoard # 胃袋
var effect: EnemyEffect # 実行効果
var resolver: EnemyEffectResolver # 効果解決器
var elapsed_seconds := 0 # 経過秒数
var current_seconds := 0 # 現在秒数
var damage := 0 # 被ダメージ
var overkill_damage := 0 # 超過ダメージ
var digested_minutes := 0 # 消化経過分
var digested_enemies: Array[Enemy] = [] # 消化済み一覧


# event判定
func is_event(value: EnemyEffect.Event) -> bool:
	return event == value


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
func get_targets(target_type: EnemyEffect.EffectTarget) -> Array[Enemy]:
	match target_type:
		EnemyEffect.EffectTarget.SELF:
			return [source]
		EnemyEffect.EffectTarget.ADJACENT_OBJECTS:
			return get_adjacent_objects()
		EnemyEffect.EffectTarget.ADJACENT_ENEMIES:
			return get_adjacent_enemies()
		EnemyEffect.EffectTarget.ALL_ENEMIES:
			return get_active_enemies()
		EnemyEffect.EffectTarget.ACID_LINE_OBJECTS:
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
	var adjusted := clampf(chance + resolver.get_chance_delta(source), 0.0, 1.0) # 補正確率
	if invert:
		adjusted = 1.0 - adjusted
	return randf() <= adjusted


# 効果値取得
func scale_value(value: float) -> float:
	return value * resolver.get_effect_multiplier(source)


# 攻撃差分追加
func add_attack_delta(enemy: Enemy, value: int) -> void:
	resolver.add_attack_delta(enemy, roundi(scale_value(float(value))))


# 攻撃値固定
func set_attack(enemy: Enemy, value: int) -> void:
	resolver.set_attack_override(enemy, roundi(scale_value(float(value))))


# 攻撃倍率追加
func multiply_attack(enemy: Enemy, value: float) -> void:
	resolver.multiply_attack(enemy, scale_value(value))


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
	resolver.add_max_hp_delta(enemy, roundi(scale_value(float(value))), follow_hp)


# HP倍率追加
func multiply_hp(enemy: Enemy, value: float) -> void:
	resolver.multiply_max_hp(enemy, scale_value(value))


# 消化差分追加
func add_acid_damage_delta(enemy: Enemy, value: int) -> void:
	resolver.add_acid_damage_delta(enemy, roundi(scale_value(float(value))))


# 消化倍率追加
func multiply_acid_damage(enemy: Enemy, value: float) -> void:
	resolver.multiply_acid_damage(enemy, scale_value(value))


# 全体消化差分
func add_global_acid_damage(value: int, multiplier := 1.0) -> void:
	resolver.add_global_acid_damage(roundi(scale_value(float(value))), scale_value(multiplier))


# 消化間隔秒追加
func add_interval_seconds(value: int) -> void:
	resolver.add_interval_seconds(roundi(scale_value(float(value))))


# 消化間隔割合追加
func add_interval_rate(value: float) -> void:
	resolver.add_interval_rate(scale_value(value))


# 効果倍率追加
func multiply_effect(enemy: Enemy, value: float) -> void:
	resolver.multiply_effect(enemy, value)


# 確率差分追加
func add_chance_delta(enemy: Enemy, value: float) -> void:
	resolver.add_chance_delta(enemy, value)


# プレイヤー攻撃追加
func attack_player(value: int, count := 1) -> void:
	for _index in range(maxi(0, count)):
		resolver.queue_player_damage(maxi(0, roundi(scale_value(float(value)))))


# 消化ダメージ付与
func deal_acid_damage(enemy: Enemy, value: int, hit_count := 1) -> void:
	resolver.deal_acid_damage(enemy, maxi(0, roundi(scale_value(float(value)))), hit_count, digested_enemies)


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
	spawn_area: EnemyEffect.SpawnArea,
	hp_value: int,
	attack_value: int,
	inherit_skill := false
) -> void:
	resolver.queue_spawn(source, effect, enemy_info, spawn_skill, spawn_count, max_spawn_count, spawn_area, hp_value, attack_value, inherit_skill)


# 状態整数取得
func get_state_int(key: String, default_value := 0) -> int:
	return int(resolver.get_state(source, effect, key, default_value))


# 状態値設定
func set_state(key: String, value: Variant) -> void:
	resolver.set_state(source, effect, key, value)


# 間隔発火数取得
func consume_interval(interval_seconds: int) -> int:
	if interval_seconds <= 0:
		return 0
	var accumulated := get_state_int("elapsed_seconds") + elapsed_seconds # 累積秒
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
	var previous: Array = resolver.get_state(source, effect, "adjacent_ids", []) # 直前ID
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
func resolve_value(source_type: EnemyEffect.ValueSource, fixed_value := 0) -> int:
	match source_type:
		EnemyEffect.ValueSource.SELF_CURRENT_HP: return source.get_current_hp()
		EnemyEffect.ValueSource.SELF_MAX_HP: return source.get_max_hp()
		EnemyEffect.ValueSource.SELF_ATTACK: return resolver.get_attack(source, source.get_damage())
		EnemyEffect.ValueSource.TAKEN_DAMAGE: return damage
		EnemyEffect.ValueSource.OVERKILL_DAMAGE: return overkill_damage
		EnemyEffect.ValueSource.DIGESTED_MINUTES: return digested_minutes
		EnemyEffect.ValueSource.LOST_HP: return maxi(0, source.get_max_hp() - source.get_current_hp())
	return fixed_value
