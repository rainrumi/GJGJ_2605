extends SceneTree

const EXPECTED_STAGE_AREAS: Array[StageInfo.StageArea] = [
	StageInfo.StageArea.IRIYU_CAVE,
	StageInfo.StageArea.ELMENA_UNIVERSITY,
	StageInfo.StageArea.RIRAN_TREE_GARRISON,
	StageInfo.StageArea.LUNOVA_OLD_CITY,
]

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scene/main/stage_select/stage_select.tscn") as PackedScene
	var current_stage := load("res://data/resources/area/area_lunova/area_lunova.tres") as StageInfo
	_expect(packed != null, "ステージ選択Sceneを読み込める")
	_expect(current_stage != null, "現在地用StageInfoを読み込める")
	if packed == null or current_stage == null:
		quit(_failures)
		return

	var stage_select := packed.instantiate()
	root.add_child(stage_select)
	await process_frame
	var run_state := RunState.new()
	run_state.current_hp = 90
	var unlocked_stage_ids: Array[int] = []
	stage_select.call("setup_stage_choices", current_stage, 1, unlocked_stage_ids, run_state)
	await process_frame

	var displayed_definitions: Array[StageInfo] = stage_select.get("_displayed_stage_definitions")
	var displayed_areas: Array[StageInfo.StageArea] = []
	for stage_definition in displayed_definitions:
		displayed_areas.append(stage_definition.stage_area)
	_expect(displayed_areas == EXPECTED_STAGE_AREAS, "現在地にかかわらずイリユ、エルメナ、リラン、ルノヴァの順で表示する")

	var choice_list := stage_select.get_node("UI/StageChoicesScroll/StageChoicesMargin/SelectContainer/StageChoicesListScroll/StageChoicesPadding/StageChoices")
	var rest_button := choice_list.get_node("TodayRestButton") as TodayRestButton
	_expect(rest_button.visible, "休める場合は休むボタンを表示する")
	_expect(rest_button.get_index() == 0, "休むボタンを一覧の一番上に表示する")
	var visible_stage_choices: Array[StageSelectChoice] = []
	for child in choice_list.get_children():
		if child is StageSelectChoice and child.visible:
			visible_stage_choices.append(child as StageSelectChoice)
	_expect(visible_stage_choices.size() == EXPECTED_STAGE_AREAS.size(), "4つのステージ選択ボタンを表示する")
	if visible_stage_choices.size() == EXPECTED_STAGE_AREAS.size():
		_expect(visible_stage_choices[1].location_label.text == "エルメナ大学", "2番目にエルメナ大学を表示する")
		_expect(visible_stage_choices[1].difficulty_label.text == "★★", "エルメナ大学の難易度を星2つで表示する")

	root.remove_child(stage_select)
	stage_select.free()
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("StageSelectChoiceOrderTest: %s" % message)
