extends SceneTree

var _failures := 0


func _initialize() -> void:
	var state := RunState.new()
	state.current_hp = 10
	LaraReward.recover_hp(state, 50)
	_expect(state.current_hp == 60, "50%回復は最大HPの50%を加算する")
	LaraReward.recover_hp(state, 80)
	_expect(state.current_hp == 100, "回復は最大HPを超えない")
	var normal := SeedInfo.new()
	normal.skill_id = 1
	normal.display_name = "試験の種"
	var rare := SeedInfo.new()
	rare.skill_id = 2
	rare.rarity = SeedInfo.Rarity.RARE
	var pool := SeedPoolInfo.new()
	pool.common_skills = [normal]
	pool.rare_skills = [rare]
	var stage := StageInfo.new()
	stage.drop_seed_pool = pool
	var stages: Array[StageInfo] = [stage, stage]
	_expect(LaraReward.get_seed_candidates(stages, []).size() == 2,
		"複数エリアで出現する種も抽選候補は一つにする")
	_expect(LaraReward.get_seed_candidates(stages, [], SeedInfo.Rarity.RARE) == [rare],
		"勝利の候補はレアのみ")
	_expect(LaraReward.get_seed_candidates(stages, [], SeedInfo.Rarity.NORMAL) == [normal],
		"敗北の候補は通常のみ")
	_expect(LaraReward.grant_seed(state, normal) == "試験の種を1つ手に入れた。",
		"報酬メッセージに獲得名を含める")
	_expect(state.stored_seeds == [normal], "報酬を所持枠に追加する")
	state.current_area_stage = stage
	var next_stage := StageInfo.new()
	next_stage.stage_area = StageInfo.StageArea.COROTTA_STREET
	state.select_stage(next_stage)
	_expect(state.previous_area_stage == stage, "選択前のエリアを保持する")
	_expect(
		state.lara_area_novel_states[StageInfo.StageArea.COROTTA_STREET]
			== RunState.LaraAreaNovelState.NOT_VISITED,
		"プレイヤーのステージ選択ではラーラの訪問状態を変更しない"
	)
	state.lara_interaction_day = 5
	state.reset()
	_expect(state.previous_area_stage == null and state.lara_interaction_day == 0
		and state.get_visited_lara_area_novel_candidates().is_empty()
		and state.lara_area_novel_states[StageInfo.StageArea.COROTTA_STREET]
			== RunState.LaraAreaNovelState.NOT_VISITED
		and state.lara_area_visit_record_day == 1
		and state.lara_area_visit_record_minutes == RunState.BATTLE_START_MINUTES,
		"ニューゲームで交流履歴を未訪問へ初期化する")
	print("LaraRewardTest: %d failures" % _failures)
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)
