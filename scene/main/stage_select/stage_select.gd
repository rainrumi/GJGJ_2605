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


func _ready() -> void:
	for i in range(stage_choices.size()):
		stage_choices[i].pressed.connect(_on_stage_choice_pressed.bind(i))
	setup_stage_choices()


func setup_stage_choices() -> void:
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


func _get_random_stage_definitions() -> Array[StageDefinition]:
	var definitions: Array[StageDefinition] = []
	for stage_definition in _get_stage_definitions():
		if stage_definition != null:
			definitions.append(stage_definition)
	definitions.shuffle()
	if definitions.size() > stage_choices.size():
		definitions.resize(stage_choices.size())
	return definitions
