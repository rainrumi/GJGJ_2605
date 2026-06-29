class_name StageClearSeedChoiceList
extends VBoxContainer

signal choice_pressed(choice_index: int)
signal choice_hovered(choice_index: int)
signal choice_unhovered(choice_index: int)

var _seed_choices: Array[StageClearSeedChoice] = []


# 初期化
func _ready() -> void:
	_collect_seed_choices()


# 選択肢設定
func setup_choices(seed_options: Array[SeedInfo], is_active: bool, debug_numbers_visible: bool) -> void:
	if _seed_choices.is_empty():
		_collect_seed_choices()
	for i in range(_seed_choices.size()):
		var seed_choice := _seed_choices[i]
		var seed := _get_seed_option(seed_options, i)
		if seed == null:
			seed_choice.set_choice_disabled(true)
			continue
		seed_choice.setup_choice(seed)
		seed_choice.set_debug_numbers_visible(debug_numbers_visible)
		seed_choice.set_choice_disabled(not is_active)


# debug表示
func set_debug_numbers_visible(is_visible: bool) -> void:
	for seed_choice in _seed_choices:
		seed_choice.set_debug_numbers_visible(is_visible)


# 選択可否設定
func set_choices_active(is_active: bool) -> void:
	for seed_choice in _seed_choices:
		seed_choice.set_choice_disabled(not is_active)


# 選択数取得
func get_choice_count() -> int:
	if _seed_choices.is_empty():
		_collect_seed_choices()
	return _seed_choices.size()


# 選択肢収集
func _collect_seed_choices() -> void:
	_seed_choices.clear()
	for child in get_children():
		if child is StageClearSeedChoice:
			_add_seed_choice(child as StageClearSeedChoice)


# 選択肢追加
func _add_seed_choice(seed_choice: StageClearSeedChoice) -> void:
	var choice_index := _seed_choices.size()
	_seed_choices.append(seed_choice)
	seed_choice.pressed.connect(_on_seed_choice_pressed.bind(choice_index))
	seed_choice.mouse_entered.connect(_on_seed_choice_hovered.bind(choice_index))
	seed_choice.mouse_exited.connect(_on_seed_choice_unhovered.bind(choice_index))


# 種取得
func _get_seed_option(seed_options: Array[SeedInfo], seed_index: int) -> SeedInfo:
	if seed_index < 0 or seed_index >= seed_options.size():
		return null
	return seed_options[seed_index]


# 押下通知
func _on_seed_choice_pressed(choice_index: int) -> void:
	choice_pressed.emit(choice_index)


# hover通知
func _on_seed_choice_hovered(choice_index: int) -> void:
	if _is_choice_disabled(choice_index):
		return
	choice_hovered.emit(choice_index)


# hover解除通知
func _on_seed_choice_unhovered(choice_index: int) -> void:
	choice_unhovered.emit(choice_index)


# 無効判定
func _is_choice_disabled(choice_index: int) -> bool:
	if choice_index < 0 or choice_index >= _seed_choices.size():
		return true
	return _seed_choices[choice_index].disabled
