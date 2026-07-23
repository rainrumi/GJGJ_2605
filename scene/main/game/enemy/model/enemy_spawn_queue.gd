class_name EnemySpawnQueue
extends RefCounted

signal requested(data: BattleSpawnEnemyData)

var _pending: Array[BattleSpawnEnemyData] = [] # 生成要求
var _spawn_counts: Dictionary = {} # 効果別生成数


# 生成要求追加
func request(
	source: Enemy,
	effect: EnemyEffect,
	enemy_info: EnemyInfo,
	spawn_main_skill: EnemySkill,
	spawn_count: int,
	max_spawn_count: int,
	spawn_area: EnemyEffect.SpawnArea,
	hp_value: int,
	attack_value: int,
	inherit_skill: bool
) -> void:
	if source == null or effect == null:
		return
	var key := "%s:%s" % [source.get_instance_id(), effect.get_instance_id()] # 生成キー
	var current_count := int(_spawn_counts.get(key, 0)) # 現在生成数
	var allowed_count := maxi(0, spawn_count) # 許可生成数
	if max_spawn_count > 0:
		allowed_count = mini(allowed_count, maxi(0, max_spawn_count - current_count))
	for _index in range(allowed_count):
		var data := BattleSpawnEnemyData.new() # 生成データ
		data.source_enemy = source
		data.enemy_info = enemy_info
		data.main_skill = source.get_enemy_skill() if inherit_skill else spawn_main_skill
		data.spawn_area = spawn_area
		data.max_hp = hp_value
		data.current_hp = hp_value
		data.damage = attack_value
		_pending.append(data)
		requested.emit(data)
	_spawn_counts[key] = current_count + allowed_count


# 生成要求消費
func consume() -> Array[BattleSpawnEnemyData]:
	var values: Array[BattleSpawnEnemyData] = _pending.duplicate() # 生成一覧
	_pending.clear()
	return values


# 生成状態初期化
func clear() -> void:
	_pending.clear()
	_spawn_counts.clear()
