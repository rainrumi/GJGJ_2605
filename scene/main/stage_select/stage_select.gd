extends Node2D

signal stage_selected(stage_index: int)

@onready var stage_choices: Array[StageSelectChoice] = [
	$UI/StageChoices/StageChoice1 as StageSelectChoice,
	$UI/StageChoices/StageChoice2 as StageSelectChoice,
	$UI/StageChoices/StageChoice3 as StageSelectChoice,
]


func _ready() -> void:
	_setup_stage_choices()


func _setup_stage_choices() -> void:
	for i in range(stage_choices.size()):
		var stage_number := i + 1
		stage_choices[i].setup_choice("夢の主 %d" % stage_number, "ステージ %d" % stage_number)
		stage_choices[i].pressed.connect(_on_stage_choice_pressed.bind(i))


func _on_stage_choice_pressed(stage_index: int) -> void:
	stage_selected.emit(stage_index)
