extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var current_stage := _create_stage(1, StageInfo.StageArea.LUNOVA_OLD_CITY)
	var remote_pending_stage := _create_stage(2, StageInfo.StageArea.ERAMIA_DISTRICT)
	var completed_stage := _create_stage(3, StageInfo.StageArea.ELMENA_UNIVERSITY)
	var locked_stage := _create_stage(4, StageInfo.StageArea.GONSAL_DISTRICT)
	var huwahuwa_school := _create_stage(RunState.HUWAHUWA_SCHOOL_STAGE_ID, StageInfo.StageArea.huwahuwaSchool)
	huwahuwa_school.has_normal_stage = false

	var run_state := RunState.new()
	run_state.current_day = 4
	_set_defeat_counts(run_state, current_stage, 3, 1)
	_set_defeat_counts(run_state, remote_pending_stage, 6, 1)
	_set_defeat_counts(run_state, completed_stage, 9, 3)
	_set_defeat_counts(run_state, locked_stage, 2, 0)

	var stages: Array[StageInfo] = [current_stage, remote_pending_stage, completed_stage, locked_stage, huwahuwa_school]
	var available_ids: Array[int] = []
	for stage in stages:
		if run_state.has_pending_strengthened_enemy(stage):
			available_ids.append(stage.stage_id)

	var candidates := StageSelectionService.new().get_candidate_stages(stages, current_stage, 4, available_ids)
	_expect(_has_area(candidates, StageInfo.StageArea.ERAMIA_DISTRICT), "現在地でない未クリアの第2ボスを表示する")
	_expect(_has_area(candidates, StageInfo.StageArea.huwahuwaSchool), "ふわふわ学校を表示する")
	_expect(not _has_area(candidates, StageInfo.StageArea.LUNOVA_OLD_CITY), "クリア済みの第1ボスを表示しない")
	_expect(not _has_area(candidates, StageInfo.StageArea.ELMENA_UNIVERSITY), "解放済みボスをすべてクリアしたエリアを表示しない")
	_expect(not _has_area(candidates, StageInfo.StageArea.GONSAL_DISTRICT), "通常戦3勝未満のエリアを表示しない")
	_expect(candidates.size() == 2, "条件を満たす全エリアとふわふわ学校だけを表示する")
	quit(_failures)


func _create_stage(stage_id: int, stage_area: StageInfo.StageArea) -> StageInfo:
	var stage := StageInfo.new()
	stage.stage_id = stage_id
	stage.stage_area = stage_area
	stage.stage_unlock_novel_texts.assign([NovelTextInfo.new(), NovelTextInfo.new(), NovelTextInfo.new()])
	return stage


func _set_defeat_counts(run_state: RunState, stage: StageInfo, normal_count: int, boss_count: int) -> void:
	var key := "%d:%d" % [stage.stage_id, stage.stage_area]
	run_state.normal_enemy_defeat_counts[key] = normal_count
	run_state.strengthened_enemy_defeat_counts[key] = boss_count


func _has_area(candidates: Array[StageInfo], stage_area: StageInfo.StageArea) -> bool:
	for candidate in candidates:
		if candidate.stage_area == stage_area:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("BossStageCandidateTest: %s" % message)
