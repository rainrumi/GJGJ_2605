extends Node2D

signal stage_selected(stage: StageInfo)

@export var stage_catalog: StageCatalogInfo
@export var stage_definitions: Array[StageInfo] = []
@export var stage_choice_scene: PackedScene

@onready var map_view: StageSelectMapView = $CharacterArea/Map
@onready var stage_choice_list: StageSelectChoiceList = $UI/StageChoicesScroll/StageChoicesMargin/StageChoices
@onready var debug_seed_pool_panel: StageSelectDebugSeedPoolPanel = $UI/DebugSeedPoolPanel

var _displayed_stage_definitions: Array[StageInfo] = []
var _current_stage_definition: StageInfo
var _current_day := 1
var _unlocked_high_difficulty_stage_ids: Array[int] = []
var _run_state: RunState
var _hovered_stage_definition: StageInfo
var stage_selection_service := StageSelectionService.new()


# 初期化
func _ready() -> void:
	_connect_stage_choice_list()
	setup_stage_choices()


# ステージ選択肢設定
func setup_stage_choices(
	current_stage_definition: StageInfo = null,
	current_day: int = 1,
	unlocked_high_difficulty_stage_ids: Array[int] = [],
	run_state: RunState = null
) -> void:
	_current_stage_definition = current_stage_definition
	_current_day = current_day
	_unlocked_high_difficulty_stage_ids = unlocked_high_difficulty_stage_ids.duplicate()
	_run_state = run_state
	_hovered_stage_definition = null
	_displayed_stage_definitions = _get_random_stage_definitions()
	map_view.hide_hover()
	map_view.set_current_stage(_current_stage_definition)
	debug_seed_pool_panel.set_stage(null)
	stage_choice_list.setup_choices(
		_displayed_stage_definitions,
		_get_exploration_percents(_displayed_stage_definitions),
		stage_choice_scene
	)


# ステージ定義byID取得
func get_stage_definition_by_id(stage_id: int) -> StageInfo:
	return stage_selection_service.get_stage_definition_by_id(_get_stage_definitions(), stage_id)


# 進行用定義取得
func get_stage_definitions_for_progress() -> Array[StageInfo]:
	return _get_stage_definitions()


# 選択肢接続
func _connect_stage_choice_list() -> void:
	stage_choice_list.choice_pressed.connect(_on_stage_choice_pressed)
	stage_choice_list.choice_hovered.connect(_on_stage_choice_hovered)
	stage_choice_list.choice_unhovered.connect(_on_stage_choice_unhovered)


# 押下処理
func _on_stage_choice_pressed(choice_index: int) -> void:
	if choice_index >= _displayed_stage_definitions.size():
		return
	var stage_definition := _displayed_stage_definitions[choice_index]
	if stage_definition == null:
		return
	stage_selected.emit(stage_definition)


# ホバー処理
func _on_stage_choice_hovered(choice_index: int) -> void:
	if choice_index >= _displayed_stage_definitions.size():
		_show_stage_hover(null)
		return
	_show_stage_hover(_displayed_stage_definitions[choice_index])


# ホバー解除処理
func _on_stage_choice_unhovered(choice_index: int) -> void:
	if choice_index >= _displayed_stage_definitions.size():
		return
	if _hovered_stage_definition != _displayed_stage_definitions[choice_index]:
		return
	_show_stage_hover(null)


# ホバー表示
func _show_stage_hover(stage_definition: StageInfo) -> void:
	_hovered_stage_definition = stage_definition
	debug_seed_pool_panel.set_stage(stage_definition)
	if stage_definition == null:
		map_view.hide_hover()
		return
	map_view.show_stage_hover(stage_definition, _is_current_location(stage_definition))


# ステージ定義取得
func _get_stage_definitions() -> Array[StageInfo]:
	if stage_catalog != null:
		return stage_catalog.stages
	return stage_definitions


# ランダム定義取得
func _get_random_stage_definitions() -> Array[StageInfo]:
	var definitions := stage_selection_service.get_candidate_stages(
		_get_stage_definitions(),
		_current_stage_definition,
		_current_day,
		_unlocked_high_difficulty_stage_ids
	)
	definitions.shuffle()
	_move_current_location_to_front(definitions)
	return definitions


# 現在地を先頭へ
func _move_current_location_to_front(definitions: Array[StageInfo]) -> void:
	for i in range(definitions.size()):
		if not _is_current_location(definitions[i]):
			continue
		var current_location := definitions[i]
		definitions.remove_at(i)
		definitions.insert(0, current_location)
		return


# 現在地判定
func _is_current_location(stage_definition: StageInfo) -> bool:
	if _current_stage_definition == null or stage_definition == null:
		return false
	if stage_definition == _current_stage_definition:
		return true
	return stage_definition.map_position.distance_squared_to(_current_stage_definition.map_position) < 0.01


# 探索率一覧取得
func _get_exploration_percents(stage_definitions: Array[StageInfo]) -> Array[int]:
	var percents: Array[int] = []
	for stage_definition in stage_definitions:
		percents.append(_get_exploration_percent(stage_definition))
	return percents


# 探索率取得
func _get_exploration_percent(stage_definition: StageInfo) -> int:
	if _run_state == null:
		return 0
	return _run_state.get_stage_exploration_percent(stage_definition)
