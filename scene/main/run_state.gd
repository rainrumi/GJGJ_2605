class_name RunState
extends Resource

const DEFAULT_STOMACH_COLUMNS := 4
const DEFAULT_STOMACH_ROWS := 5

var current_day := 1
var current_hp := 100
var max_hp := 100
var stomach_columns := DEFAULT_STOMACH_COLUMNS
var stomach_rows := DEFAULT_STOMACH_ROWS
var selected_stage_id := 0
var selected_stage: StageDefinition
var planted_flowers: Array[FlowerDefinition] = []
var last_time_over_recovery_percent := 0
var normal_enemy_preset_indices := {}
var strengthened_enemy_preset_indices := {}


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


func pick_enemy_preset(stage: StageDefinition) -> EnemyPresetDefinition:
	if stage == null or stage.enemy_data == null:
		return null
	if stage.is_high_difficulty:
		return _pick_strengthened_enemy_preset(stage)
	return _pick_normal_enemy_preset(stage)


func _pick_normal_enemy_preset(stage: StageDefinition) -> EnemyPresetDefinition:
	var key := _get_stage_progress_key(stage)
	var index := int(normal_enemy_preset_indices.get(key, 0))
	var preset := stage.enemy_data.get_normal_enemy_preset(index)
	if preset != null:
		normal_enemy_preset_indices[key] = index + 1
		return preset
	return stage.enemy_data.pick_endless_enemy_preset()


func _pick_strengthened_enemy_preset(stage: StageDefinition) -> EnemyPresetDefinition:
	var key := _get_stage_progress_key(stage)
	var index := int(strengthened_enemy_preset_indices.get(key, 0))
	var preset := stage.enemy_data.get_strengthened_enemy_preset(index)
	if preset != null:
		strengthened_enemy_preset_indices[key] = index + 1
		return preset
	return stage.enemy_data.get_last_strengthened_enemy_preset()


func _get_stage_progress_key(stage: StageDefinition) -> String:
	return "%d:%d" % [stage.stage_id, stage.stage_area]
