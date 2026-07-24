extends Node

const EXPECTED_DEBUG_AREA_COUNT := 11

var _failures := 0
var _selected_stage_areas: Array[int] = []


# 試験開始
func _ready() -> void:
	call_deferred("_run")


# debug時全エリア選択試験
func _run() -> void:
	DebugState.set_debug_enabled(false)
	var packed := load("res://scene/main/stage_select/stage_select.tscn") as PackedScene
	_expect(packed != null, "ステージ選択シーンを読み込める")
	if packed == null:
		get_tree().quit(_failures)
		return
	var stage_select := packed.instantiate()
	get_tree().root.add_child(stage_select)
	await get_tree().process_frame
	stage_select.connect("stage_selected", _on_stage_selected)

	var iriyu := load("res://data/resources/area/area_iriyu/area_iriyu.tres") as StageInfo
	stage_select.call("setup_stage_choices", iriyu, 1)
	_expect(_get_displayed_stages(stage_select).size() == 4, "通常時は既存の到達可能4エリアを表示する")
	_expect(
		stage_select.get_node_or_null("UI/DebugSeedPoolPanel") == null,
		"ステージデータのdebugパネルを構成しない"
	)

	var debug_button := stage_select.get_node_or_null("UI/DebugButton") as Button
	_expect(debug_button != null, "Debugボタンを構成する")
	if debug_button == null:
		get_tree().quit(_failures)
		return
	debug_button.pressed.emit()
	_check_all_areas(stage_select, "1日目")

	stage_select.call("setup_stage_choices", iriyu, 4)
	_check_all_areas(stage_select, "高難度日の4日目")

	stage_select.call("setup_stage_choices", iriyu, 1)
	debug_button.pressed.emit()
	_expect(_get_displayed_stages(stage_select).size() == 4, "debug解除時は通常の候補へ戻す")

	get_tree().root.remove_child(stage_select)
	stage_select.free()
	stage_select = null
	iriyu = null
	packed = null
	debug_button = null
	await get_tree().process_frame
	get_tree().quit(_failures)


# 全エリア確認
func _check_all_areas(stage_select: Node, context: String) -> void:
	var stage_definitions := _get_displayed_stages(stage_select)
	_expect(
		stage_definitions.size() == EXPECTED_DEBUG_AREA_COUNT,
		"%sのdebug時は11エリアを表示する（候補数: %d）" % [context, stage_definitions.size()]
	)
	var found_stage_areas: Array[int] = []
	for stage_definition in stage_definitions:
		if stage_definition != null:
			found_stage_areas.append(stage_definition.stage_area)
	for stage_area in range(1, EXPECTED_DEBUG_AREA_COUNT + 1):
		_expect(found_stage_areas.has(stage_area), "%sにエリア%dを含む" % [context, stage_area])

	_selected_stage_areas.clear()
	var choice_list := stage_select.get_node_or_null("UI/StageChoicesScroll/StageChoicesMargin/StageChoices")
	_expect(choice_list != null, "%sのステージ選択肢一覧を構成する" % context)
	if choice_list == null:
		return
	for child in choice_list.get_children():
		if child is StageSelectChoice and child.visible and not child.disabled:
			child.mouse_entered.emit()
			child.mouse_exited.emit()
			child.pressed.emit()
	_expect(
		_selected_stage_areas.size() == EXPECTED_DEBUG_AREA_COUNT,
		"%sの11エリアをすべて選択できる（選択数: %d）" % [context, _selected_stage_areas.size()]
	)
	for stage_area in range(1, EXPECTED_DEBUG_AREA_COUNT + 1):
		_expect(_selected_stage_areas.has(stage_area), "%sでエリア%dを選択できる" % [context, stage_area])


# ステージ選択通知
func _on_stage_selected(stage: StageInfo) -> void:
	if stage != null:
		_selected_stage_areas.append(stage.stage_area)


# 表示中ステージ取得
func _get_displayed_stages(stage_select: Node) -> Array[StageInfo]:
	var stages: Array[StageInfo] = []
	var raw_stages: Array = stage_select.get("_displayed_stage_definitions")
	for stage in raw_stages:
		if stage is StageInfo:
			stages.append(stage as StageInfo)
	return stages


# 期待値確認
func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("StageSelectDebugSelectionTest: %s" % message)
