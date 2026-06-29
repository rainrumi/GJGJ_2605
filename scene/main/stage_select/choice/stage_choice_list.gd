class_name StageSelectChoiceList
extends VBoxContainer

signal choice_pressed(choice_index: int)
signal choice_hovered(choice_index: int)
signal choice_unhovered(choice_index: int)

var _stage_choices: Array[StageSelectChoice] = []


# 初期化
func _ready() -> void:
	if _stage_choices.is_empty():
		_collect_stage_choices()


# 選択肢設定
func setup_choices(
	stage_definitions: Array[StageInfo],
	exploration_percents: Array[int],
	stage_choice_scene: PackedScene
) -> void:
	if _stage_choices.is_empty():
		_collect_stage_choices()
	_ensure_stage_choice_count(stage_definitions.size(), stage_choice_scene)
	for i in range(_stage_choices.size()):
		if i >= stage_definitions.size():
			_stage_choices[i].setup_choice(null)
			continue
		_stage_choices[i].setup_choice(stage_definitions[i], _get_exploration_percent(exploration_percents, i))


# 既存選択肢収集
func _collect_stage_choices() -> void:
	_stage_choices.clear()
	for child in get_children():
		if child is StageSelectChoice:
			_add_stage_choice(child as StageSelectChoice)


# 選択肢数保証
func _ensure_stage_choice_count(count: int, stage_choice_scene: PackedScene) -> void:
	while _stage_choices.size() < count:
		if stage_choice_scene == null:
			return
		var stage_choice := stage_choice_scene.instantiate()
		if not stage_choice is StageSelectChoice:
			stage_choice.queue_free()
			return
		add_child(stage_choice)
		_add_stage_choice(stage_choice as StageSelectChoice)


# 選択肢追加
func _add_stage_choice(stage_choice: StageSelectChoice) -> void:
	var choice_index := _stage_choices.size()
	_stage_choices.append(stage_choice)
	stage_choice.pressed.connect(_on_stage_choice_pressed.bind(choice_index))
	stage_choice.mouse_entered.connect(_on_stage_choice_hovered.bind(choice_index))
	stage_choice.mouse_exited.connect(_on_stage_choice_unhovered.bind(choice_index))
	stage_choice.focus_entered.connect(_on_stage_choice_hovered.bind(choice_index))
	stage_choice.focus_exited.connect(_on_stage_choice_unhovered.bind(choice_index))


# 探索率取得
func _get_exploration_percent(exploration_percents: Array[int], choice_index: int) -> int:
	if choice_index >= exploration_percents.size():
		return 0
	return exploration_percents[choice_index]


# 押下通知
func _on_stage_choice_pressed(choice_index: int) -> void:
	choice_pressed.emit(choice_index)


# ホバー通知
func _on_stage_choice_hovered(choice_index: int) -> void:
	choice_hovered.emit(choice_index)


# ホバー解除通知
func _on_stage_choice_unhovered(choice_index: int) -> void:
	choice_unhovered.emit(choice_index)
