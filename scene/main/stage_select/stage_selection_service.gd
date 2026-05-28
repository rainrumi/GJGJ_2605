class_name StageSelectionService
extends RefCounted


func get_stage_definition_by_id(
	stage_definitions: Array[StageDefinition],
	stage_id: int
) -> StageDefinition:
	for stage_definition in stage_definitions:
		var found_stage := _find_stage_definition_by_id(stage_definition, stage_id)
		if found_stage != null:
			return found_stage
	return null


func get_candidate_stages(
	stage_definitions: Array[StageDefinition],
	current_stage_definition: StageDefinition,
	current_day: int,
	unlocked_high_difficulty_stage_ids: Array[int] = []
) -> Array[StageDefinition]:
	if _is_high_difficulty_day(current_day):
		return _get_high_difficulty_stage_definitions(stage_definitions, current_stage_definition, unlocked_high_difficulty_stage_ids)
	var definitions: Array[StageDefinition] = []
	for stage_definition in stage_definitions:
		if _can_reach_stage(stage_definition, current_stage_definition):
			definitions.append(stage_definition)
	return definitions


func _can_reach_stage(
	stage_definition: StageDefinition,
	current_stage_definition: StageDefinition
) -> bool:
	if stage_definition == null:
		return false
	if stage_definition.is_high_difficulty:
		return false
	if not stage_definition.has_normal_stage:
		return false
	if current_stage_definition == null:
		return true
	return current_stage_definition.reachable_stage_areas.has(stage_definition.stage_area)


func _is_high_difficulty_day(current_day: int) -> bool:
	return current_day > 0 and current_day % 4 == 0


func _get_high_difficulty_stage_definitions(
	stage_definitions: Array[StageDefinition],
	current_stage_definition: StageDefinition,
	unlocked_high_difficulty_stage_ids: Array[int]
) -> Array[StageDefinition]:
	var definitions: Array[StageDefinition] = []
	var source_stages := _get_high_difficulty_source_stages(stage_definitions, current_stage_definition, unlocked_high_difficulty_stage_ids)
	for source_stage in source_stages:
		if source_stage == null:
			continue
		if source_stage.high_difficulty_stages.is_empty():
			definitions.append(source_stage.create_high_difficulty_fallback())
			continue
		for high_stage in source_stage.high_difficulty_stages:
			if high_stage != null:
				definitions.append(high_stage)
	return definitions


func _get_high_difficulty_source_stages(
	stage_definitions: Array[StageDefinition],
	current_stage_definition: StageDefinition,
	unlocked_high_difficulty_stage_ids: Array[int]
) -> Array[StageDefinition]:
	var source_stages: Array[StageDefinition] = []
	if current_stage_definition == null:
		for stage_definition in stage_definitions:
			if _is_unlocked_high_difficulty_source_stage(stage_definition, unlocked_high_difficulty_stage_ids):
				source_stages.append(stage_definition)
		return source_stages
	if _is_unlocked_high_difficulty_source_stage(current_stage_definition, unlocked_high_difficulty_stage_ids):
		source_stages.append(current_stage_definition)
	for stage_definition in stage_definitions:
		if stage_definition == current_stage_definition:
			continue
		if _is_unlocked_high_difficulty_only_stage(stage_definition, unlocked_high_difficulty_stage_ids):
			source_stages.append(stage_definition)
	return source_stages


func _is_unlocked_high_difficulty_source_stage(
	stage_definition: StageDefinition,
	unlocked_high_difficulty_stage_ids: Array[int]
) -> bool:
	if stage_definition == null or stage_definition.is_high_difficulty:
		return false
	return unlocked_high_difficulty_stage_ids.has(stage_definition.stage_id)


func _is_unlocked_high_difficulty_only_stage(
	stage_definition: StageDefinition,
	unlocked_high_difficulty_stage_ids: Array[int]
) -> bool:
	if not _is_unlocked_high_difficulty_source_stage(stage_definition, unlocked_high_difficulty_stage_ids):
		return false
	return not stage_definition.has_normal_stage


func _find_stage_definition_by_id(stage_definition: StageDefinition, stage_id: int) -> StageDefinition:
	if stage_definition == null:
		return null
	if stage_definition.stage_id == stage_id:
		return stage_definition
	for high_stage in stage_definition.high_difficulty_stages:
		var found_stage := _find_stage_definition_by_id(high_stage, stage_id)
		if found_stage != null:
			return found_stage
	return null
