extends Node2D

signal stage_selected(stage_id: int)

@export var stage_catalog: StageCatalog
@export var stage_definitions: Array[StageDefinition] = []

@onready var stage_choices: Array[StageSelectChoice] = [
	$UI/StageChoices/StageChoice1 as StageSelectChoice,
	$UI/StageChoices/StageChoice2 as StageSelectChoice,
	$UI/StageChoices/StageChoice3 as StageSelectChoice,
]

var _displayed_stage_definitions: Array[StageDefinition] = []
var _current_stage_definition: StageDefinition


func _ready() -> void:
	for i in range(stage_choices.size()):
		stage_choices[i].pressed.connect(_on_stage_choice_pressed.bind(i))
	setup_stage_choices()


func setup_stage_choices(current_stage_definition: StageDefinition = null) -> void:
	_current_stage_definition = current_stage_definition
	_displayed_stage_definitions = _get_random_stage_definitions()
	for i in range(stage_choices.size()):
		if i >= _displayed_stage_definitions.size():
			stage_choices[i].setup_choice(null)
			continue
		stage_choices[i].setup_choice(_displayed_stage_definitions[i])


func _on_stage_choice_pressed(choice_index: int) -> void:
	if choice_index >= _displayed_stage_definitions.size():
		return
	var stage_definition := _displayed_stage_definitions[choice_index]
	if stage_definition == null:
		return
	stage_selected.emit(stage_definition.stage_id)


func _get_stage_definitions() -> Array[StageDefinition]:
	if stage_catalog != null:
		return stage_catalog.stages
	return stage_definitions


func get_stage_definition_by_id(stage_id: int) -> StageDefinition:
	for stage_definition in _get_stage_definitions():
		if stage_definition != null and stage_definition.stage_id == stage_id:
			return stage_definition
	return null


func _get_random_stage_definitions() -> Array[StageDefinition]:
	var definitions: Array[StageDefinition] = []
	for stage_definition in _get_stage_definitions():
		if _can_reach_stage(stage_definition):
			definitions.append(stage_definition)
	definitions.shuffle()
	if definitions.size() > stage_choices.size():
		definitions.resize(stage_choices.size())
	return definitions


func _can_reach_stage(stage_definition: StageDefinition) -> bool:
	if stage_definition == null:
		return false
	if _current_stage_definition == null:
		return true
	return _current_stage_definition.reachable_stage_areas.has(stage_definition.stage_area)
