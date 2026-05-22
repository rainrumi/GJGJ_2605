extends Node2D

signal stage_selected(stage: StageDefinition)

@export var stage_catalog: StageCatalog
@export var stage_definitions: Array[StageDefinition] = []
@export var stage_choice_scene: PackedScene

@onready var stage_choice_list: VBoxContainer = $UI/StageChoicesScroll/StageChoicesMargin/StageChoices

var stage_choices: Array[BaseButton] = []
var _displayed_stage_definitions: Array[StageDefinition] = []
var _current_stage_definition: StageDefinition
var _current_day := 1


func _ready() -> void:
	_collect_stage_choices()
	setup_stage_choices()


func setup_stage_choices(current_stage_definition: StageDefinition = null, current_day: int = 1) -> void:
	if stage_choices.is_empty():
		_collect_stage_choices()
	_current_stage_definition = current_stage_definition
	_current_day = current_day
	_displayed_stage_definitions = _get_random_stage_definitions()
	_ensure_stage_choice_count(_displayed_stage_definitions.size())
	for i in range(stage_choices.size()):
		if i >= _displayed_stage_definitions.size():
			stage_choices[i].call("setup_choice", null)
			continue
		stage_choices[i].call("setup_choice", _displayed_stage_definitions[i])


func _on_stage_choice_pressed(choice_index: int) -> void:
	if choice_index >= _displayed_stage_definitions.size():
		return
	var stage_definition := _displayed_stage_definitions[choice_index]
	if stage_definition == null:
		return
	stage_selected.emit(stage_definition)


func _get_stage_definitions() -> Array[StageDefinition]:
	if stage_catalog != null:
		return stage_catalog.stages
	return stage_definitions


func get_stage_definition_by_id(stage_id: int) -> StageDefinition:
	for stage_definition in _get_stage_definitions():
		var found_stage := _find_stage_definition_by_id(stage_definition, stage_id)
		if found_stage != null:
			return found_stage
	return null


func _get_random_stage_definitions() -> Array[StageDefinition]:
	var definitions: Array[StageDefinition] = []
	if _is_high_difficulty_day():
		definitions = _get_high_difficulty_stage_definitions()
		definitions.shuffle()
		return definitions
	for stage_definition in _get_stage_definitions():
		if _can_reach_stage(stage_definition):
			definitions.append(stage_definition)
	definitions.shuffle()
	return definitions


func _collect_stage_choices() -> void:
	stage_choices.clear()
	for child in stage_choice_list.get_children():
		if child is BaseButton and child.has_method("setup_choice"):
			_add_stage_choice(child as BaseButton)


func _ensure_stage_choice_count(count: int) -> void:
	while stage_choices.size() < count:
		if stage_choice_scene == null:
			return
		var stage_choice := stage_choice_scene.instantiate()
		if not stage_choice is BaseButton or not stage_choice.has_method("setup_choice"):
			stage_choice.queue_free()
			return
		stage_choice_list.add_child(stage_choice)
		_add_stage_choice(stage_choice as BaseButton)


func _add_stage_choice(stage_choice: BaseButton) -> void:
	var choice_index := stage_choices.size()
	stage_choices.append(stage_choice)
	stage_choice.pressed.connect(_on_stage_choice_pressed.bind(choice_index))


func _can_reach_stage(stage_definition: StageDefinition) -> bool:
	if stage_definition == null:
		return false
	if stage_definition.is_high_difficulty:
		return false
	if _current_stage_definition == null:
		return true
	return _current_stage_definition.reachable_stage_areas.has(stage_definition.stage_area)


func _is_high_difficulty_day() -> bool:
	return _current_day > 0 and _current_day % 4 == 0


func _get_high_difficulty_stage_definitions() -> Array[StageDefinition]:
	var definitions: Array[StageDefinition] = []
	var source_stages := _get_high_difficulty_source_stages()
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


func _get_high_difficulty_source_stages() -> Array[StageDefinition]:
	var source_stages: Array[StageDefinition] = []
	if _current_stage_definition == null:
		for stage_definition in _get_stage_definitions():
			if stage_definition != null and not stage_definition.is_high_difficulty:
				source_stages.append(stage_definition)
		return source_stages
	source_stages.append(_current_stage_definition)
	return source_stages


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
