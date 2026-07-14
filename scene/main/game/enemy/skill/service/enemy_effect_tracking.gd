class_name EnemyEffectTracking
extends RefCounted


# 新規隣接取得
static func get_new_adjacent_objects(
	state: EnemyEffectState,
	source: Enemy,
	enemies: Array[Enemy]
) -> Array[Enemy]:
	var previous: Array = state.get_value("adjacent_ids", []) # 直前ID
	var current_ids: Array[int] = [] # 現在ID
	var values: Array[Enemy] = [] # 新規対象
	for enemy in EnemyEffectTargetQuery.get_adjacent_objects(source, enemies):
		var id := enemy.get_instance_id() # 対象ID
		current_ids.append(id)
		if not previous.has(id):
			values.append(enemy)
	state.set_value("adjacent_ids", current_ids)
	return values


# 発動可能隣接取得
static func get_activatable_new_adjacent(
	state: EnemyEffectState,
	source: Enemy,
	enemies: Array[Enemy],
	max_activations: int
) -> Array[Enemy]:
	var values: Array[Enemy] = [] # 発動対象
	for enemy in get_new_adjacent_objects(state, source, enemies):
		var key := "activation:%s" % enemy.get_instance_id() # 発動キー
		var count := int(state.get_value(key, 0)) # 発動回数
		if max_activations > 0 and count >= max_activations:
			continue
		state.set_value(key, count + 1)
		values.append(enemy)
	return values
