extends Node2D

signal stage_selected(stage_index: int)

@export var stage_definitions: Array[StageDefinition] = []

@onready var stage_choices: Array[StageSelectChoice] = [
	$UI/StageChoices/StageChoice1 as StageSelectChoice,
	$UI/StageChoices/StageChoice2 as StageSelectChoice,
	$UI/StageChoices/StageChoice3 as StageSelectChoice,
]


func _ready() -> void:
	_setup_stage_choices()


func _setup_stage_choices() -> void:
	for i in range(stage_choices.size()):
		if i >= stage_definitions.size():
			stage_choices[i].disabled = true
			continue
		stage_choices[i].setup_choice(stage_definitions[i])
		stage_choices[i].pressed.connect(_on_stage_choice_pressed.bind(i))


func _on_stage_choice_pressed(stage_index: int) -> void:
	stage_selected.emit(stage_index)
