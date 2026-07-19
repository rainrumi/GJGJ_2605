class_name StageEnemyInfo
extends Resource

@export var normal_enemy_presets: Array[EnemyPresetInfo] = []
@export var endless_enemy_presets: Array[EnemyPresetInfo] = []
@export var strengthened_enemy_presets: Array[EnemyPresetInfo] = []


# ステージ名取得
func get_stage_name(enemy_preset: EnemyPresetInfo) -> String:
	if enemy_preset == null:
		return ""
	# 通常番号
	var normal_index := normal_enemy_presets.find(enemy_preset)
	if normal_index >= 0:
		return "ST-N-%d" % (normal_index + 1)
	# boss番号
	var boss_index := strengthened_enemy_presets.find(enemy_preset)
	if boss_index >= 0:
		return "ST-B-%d" % (boss_index + 1)
	if endless_enemy_presets.has(enemy_preset):
		return "ST-E"
	return ""


# 通常敵編成選択
func pick_normal_enemy_preset() -> EnemyPresetInfo:
	return _pick_random_preset(normal_enemy_presets)


# 通常敵編成取得
func get_normal_enemy_preset(index: int) -> EnemyPresetInfo:
	if index < 0 or index >= normal_enemy_presets.size():
		return null
	return normal_enemy_presets[index]


# endless敵編成選択
func pick_endless_enemy_preset() -> EnemyPresetInfo:
	return _pick_random_preset(endless_enemy_presets)


# 強化敵編成取得
func get_strengthened_enemy_preset(index: int) -> EnemyPresetInfo:
	if index < 0 or index >= strengthened_enemy_presets.size():
		return null
	return strengthened_enemy_presets[index]


# 強化敵編成取得
func get_last_strengthened_enemy_preset() -> EnemyPresetInfo:
	for i in range(strengthened_enemy_presets.size() - 1, -1, -1):
		# 編成
		var preset := strengthened_enemy_presets[i]
		if preset != null and not preset.enemies.is_empty():
			return preset
	return null


# random編成選択
func _pick_random_preset(presets: Array[EnemyPresetInfo]) -> EnemyPresetInfo:
	# 候補
	var candidates: Array[EnemyPresetInfo] = []
	for preset in presets:
		if preset != null and not preset.enemies.is_empty():
			candidates.append(preset)
	if candidates.is_empty():
		return null
	return candidates[randi() % candidates.size()]
