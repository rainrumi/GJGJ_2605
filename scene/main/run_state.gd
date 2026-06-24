class_name RunState
extends Resource

const DEFAULT_STOMACH_COLUMNS := 4
const DEFAULT_STOMACH_ROWS := 5
const HUWAHUWA_SCHOOL_STAGE_ID := 0
const HUWAHUWA_SCHOOL_UNLOCK_DAY_INTERVAL := 4
const MAX_HUWAHUWA_SCHOOL_STRENGTHENED_ENEMY_INDEX := 5
const STAGE_NOVEL_UNLOCK_DEFEAT_INTERVAL := 3
const MAX_STAGE_NOVEL_INDEX := 3

var current_day := 1
var current_hp := 100
var max_hp := 100
var stomach_columns := DEFAULT_STOMACH_COLUMNS
var stomach_rows := DEFAULT_STOMACH_ROWS
var selected_stage_id := 0
var selected_stage: StageInfo
var planted_flowers: Array[SeedInfo] = []
var last_time_over_recovery_percent := 0
var normal_enemy_preset_indices := {}
var strengthened_enemy_preset_indices := {}
var normal_enemy_defeat_counts := {}
var strengthened_enemy_defeat_counts := {}
var played_stage_novel_indices := {}


func reset() -> void:
	current_day = 1
	current_hp = max_hp
	stomach_columns = DEFAULT_STOMACH_COLUMNS
	stomach_rows = DEFAULT_STOMACH_ROWS
	selected_stage_id = 0
	selected_stage = null
	planted_flowers.clear()
	last_time_over_recovery_percent = 0
	normal_enemy_preset_indices.clear()
	strengthened_enemy_preset_indices.clear()
	normal_enemy_defeat_counts.clear()
	strengthened_enemy_defeat_counts.clear()
	played_stage_novel_indices.clear()


func pick_enemy_preset(stage: StageInfo) -> NightmarePresetInfo:
	if stage == null or stage.enemy_data == null:
		return null
	if stage.is_high_difficulty:
		return _pick_strengthened_enemy_preset(stage)
	return _pick_normal_enemy_preset(stage)


func _pick_normal_enemy_preset(stage: StageInfo) -> NightmarePresetInfo:
	var key := _get_stage_progress_key(stage)
	var index := int(normal_enemy_preset_indices.get(key, 0))
	var preset := stage.enemy_data.get_normal_enemy_preset(index)
	if preset != null:
		normal_enemy_preset_indices[key] = index + 1
		return preset
	return stage.enemy_data.pick_endless_enemy_preset()


func _pick_strengthened_enemy_preset(stage: StageInfo) -> NightmarePresetInfo:
	var key := _get_stage_progress_key(stage)
	var index := int(strengthened_enemy_preset_indices.get(key, 0))
	var unlocked_count := get_strengthened_enemy_unlock_count(stage)
	if unlocked_count <= 0:
		return null
	var max_index := unlocked_count - 1
	if index > max_index:
		index = max_index
	var preset := stage.enemy_data.get_strengthened_enemy_preset(index)
	if preset != null:
		strengthened_enemy_preset_indices[key] = index + 1
		return preset
	return stage.enemy_data.get_last_strengthened_enemy_preset()


func record_normal_stage_clear(stage: StageInfo) -> void:
	if stage == null or stage.is_high_difficulty:
		return
	var key := _get_stage_progress_key(stage)
	normal_enemy_defeat_counts[key] = int(normal_enemy_defeat_counts.get(key, 0)) + 1


func record_stage_clear(stage: StageInfo) -> void:
	if stage == null:
		return
	if stage.is_high_difficulty:
		record_strengthened_stage_clear(stage)
		return
	record_normal_stage_clear(stage)


func record_strengthened_stage_clear(stage: StageInfo) -> void:
	if stage == null or not stage.is_high_difficulty:
		return
	var key := _get_stage_progress_key(stage)
	strengthened_enemy_defeat_counts[key] = int(strengthened_enemy_defeat_counts.get(key, 0)) + 1


func get_stage_exploration_percent(stage: StageInfo) -> int:
	if stage == null or stage.enemy_data == null:
		return 0
	var normal_count := _get_exploration_normal_enemy_count(stage)
	var strengthened_count := stage.enemy_data.strengthened_enemy_presets.size()
	var total_weight := normal_count + strengthened_count * 2
	if total_weight <= 0:
		return 0
	var key := _get_stage_progress_key(stage)
	var cleared_normal_count := mini(int(normal_enemy_defeat_counts.get(key, 0)), normal_count)
	var cleared_strengthened_count := mini(int(strengthened_enemy_defeat_counts.get(key, 0)), strengthened_count)
	var cleared_weight := cleared_normal_count + cleared_strengthened_count * 2
	return clampi(roundi(float(cleared_weight) / float(total_weight) * 100.0), 0, 100)


func get_strengthened_enemy_unlock_count(stage: StageInfo) -> int:
	if stage != null and stage.stage_id == HUWAHUWA_SCHOOL_STAGE_ID:
		return mini(MAX_HUWAHUWA_SCHOOL_STRENGTHENED_ENEMY_INDEX, int(current_day / HUWAHUWA_SCHOOL_UNLOCK_DAY_INTERVAL))
	return get_stage_novel_unlock_count(stage)


func get_stage_novel_unlock_count(stage: StageInfo) -> int:
	if stage == null:
		return 0
	var defeat_count := int(normal_enemy_defeat_counts.get(_get_stage_progress_key(stage), 0))
	var available_novel_count := stage.stage_unlock_novel_texts.size()
	var max_novel_count := mini(MAX_STAGE_NOVEL_INDEX, available_novel_count)
	return mini(max_novel_count, int(defeat_count / STAGE_NOVEL_UNLOCK_DEFEAT_INTERVAL))


func get_unplayed_unlocked_stage_novel_indices(stage: StageInfo) -> Array[int]:
	var indices: Array[int] = []
	var unlocked_count := get_stage_novel_unlock_count(stage)
	var played_count := int(played_stage_novel_indices.get(_get_stage_progress_key(stage), 0))
	for scenario_index in range(played_count + 1, unlocked_count + 1):
		indices.append(scenario_index)
	return indices


func mark_stage_novel_played(stage: StageInfo, scenario_index: int) -> void:
	if stage == null:
		return
	var key := _get_stage_progress_key(stage)
	played_stage_novel_indices[key] = maxi(int(played_stage_novel_indices.get(key, 0)), scenario_index)


func _get_exploration_normal_enemy_count(stage: StageInfo) -> int:
	if not stage.has_normal_stage:
		return 0
	return mini(MAX_STAGE_NOVEL_INDEX, stage.stage_unlock_novel_texts.size()) * STAGE_NOVEL_UNLOCK_DEFEAT_INTERVAL


func _get_stage_progress_key(stage: StageInfo) -> String:
	return "%d:%d" % [stage.stage_id, stage.stage_area]
