extends SceneTree

var _failures := 0


# 試験開始
func _initialize() -> void:
	call_deferred("_run")


# ふわふわ学校挑戦後の現在地試験
func _run() -> void:
	var origin_stage := StageInfo.new()
	origin_stage.stage_id = 1
	origin_stage.stage_area = StageInfo.StageArea.LUNOVA_OLD_CITY
	origin_stage.reachable_stage_areas = [StageInfo.StageArea.ERAMIA_DISTRICT]

	var huwahuwa_school := StageInfo.new()
	huwahuwa_school.stage_id = RunState.HUWAHUWA_SCHOOL_STAGE_ID
	huwahuwa_school.stage_area = StageInfo.StageArea.huwahuwaSchool
	huwahuwa_school.has_normal_stage = false

	var reachable_stage := StageInfo.new()
	reachable_stage.stage_id = 2
	reachable_stage.stage_area = StageInfo.StageArea.ERAMIA_DISTRICT

	var run_state := RunState.new()
	run_state.select_stage(origin_stage)

	var stage_definitions: Array[StageInfo] = [origin_stage, huwahuwa_school, reachable_stage]
	var unlocked_stage_ids: Array[int] = [RunState.HUWAHUWA_SCHOOL_STAGE_ID]
	var stage_selection_service := StageSelectionService.new()
	var boss_candidates := stage_selection_service.get_candidate_stages(
		stage_definitions,
		run_state.current_area_stage,
		4,
		unlocked_stage_ids
	)
	_expect(boss_candidates.size() == 1, "4日目は解放済みのふわふわ学校を候補にする（候補数: %d）" % boss_candidates.size())
	if boss_candidates.is_empty():
		quit(_failures)
		return
	run_state.select_stage(boss_candidates[0])

	_expect(run_state.selected_stage.stage_area == StageInfo.StageArea.huwahuwaSchool, "戦闘対象にはふわふわ学校を保持する")
	_expect(run_state.current_area_stage == origin_stage, "現在地には挑戦前の通常エリアを保持する")

	var candidates := stage_selection_service.get_candidate_stages(
		stage_definitions,
		run_state.current_area_stage,
		5
	)
	_expect(candidates.size() == 1 and candidates[0] == reachable_stage, "元エリアの到達情報で翌日の候補を生成する")

	run_state.select_stage(reachable_stage)
	_expect(run_state.current_area_stage == reachable_stage, "通常エリア選択時は現在地を更新する")
	quit(_failures)


# 期待値確認
func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("HuwahuwaSchoolReturnAreaTest: %s" % message)
