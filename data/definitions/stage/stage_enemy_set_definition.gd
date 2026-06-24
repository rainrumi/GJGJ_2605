class_name StageEnemySetDefinition
extends Resource

@export var normal_enemy_presets: Array[NightmarePresetInfo] = []
@export var endless_enemy_presets: Array[NightmarePresetInfo] = []
@export var strengthened_enemy_presets: Array[NightmarePresetInfo] = []


func pick_normal_enemy_preset() -> NightmarePresetInfo:
	return _pick_random_preset(normal_enemy_presets)


func get_normal_enemy_preset(index: int) -> NightmarePresetInfo:
	if index < 0 or index >= normal_enemy_presets.size():
		return null
	return normal_enemy_presets[index]


func pick_endless_enemy_preset() -> NightmarePresetInfo:
	return _pick_random_preset(endless_enemy_presets)


func get_strengthened_enemy_preset(index: int) -> NightmarePresetInfo:
	if index < 0 or index >= strengthened_enemy_presets.size():
		return null
	return strengthened_enemy_presets[index]


func get_last_strengthened_enemy_preset() -> NightmarePresetInfo:
	for i in range(strengthened_enemy_presets.size() - 1, -1, -1):
		var preset := strengthened_enemy_presets[i]
		if preset != null and not preset.enemies.is_empty():
			return preset
	return null


func _pick_random_preset(presets: Array[NightmarePresetInfo]) -> NightmarePresetInfo:
	var candidates: Array[NightmarePresetInfo] = []
	for preset in presets:
		if preset != null and not preset.enemies.is_empty():
			candidates.append(preset)
	if candidates.is_empty():
		return null
	return candidates[randi() % candidates.size()]
