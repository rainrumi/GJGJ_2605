extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scene/main/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	var selection := main.get_node("StageSelect")
	var corotta := load("res://data/resources/area/area_corotta/area_corotta.tres") as StageInfo
	var destination := selection.get_stage_definition_by_id(3) as StageInfo
	main.run_state.lara_area_visit_record_day = 6
	main.run_state.lara_area_visit_record_minutes = 2 * 60
	main.run_state.current_day = 7
	main.run_state.current_minutes = 22 * 60
	main.show_stage_select()
	_expect(
		main.run_state.lara_area_novel_states[StageInfo.StageArea.ZAIKA_ADMIN_DISTRICT]
			== RunState.LaraAreaNovelState.VISITED,
		"ステージ選択画面に入った時、休息中のラーラ訪問も遡って記録する"
	)
	main.run_state.reset()
	main.run_state.current_day = 5
	main.run_state.unlock_lara()
	main.run_state.lara_current_location = destination
	main.run_state.lara_area_novel_states[StageInfo.StageArea.COROTTA_STREET] \
		= RunState.LaraAreaNovelState.VISITED
	main.run_state.select_stage(corotta)
	main.should_reset_player_state = false
	main.run_state.current_hp = 10
	main._on_stage_select_stage_selected(destination)
	var novel := main.get_node("OpeningNovel") as OpeningNovel
	_expect(novel.visible and not main.get_node("Game").visible,
		"ラーラとの交流が戦闘開始を待たせる")
	_expect(novel._active_novel_text.script_path.ends_with("novel_event_rara_corotta_001"),
		"訪問済みエリアの初回シナリオを優先する")
	_expect(
		main.run_state.lara_area_novel_states[StageInfo.StageArea.COROTTA_STREET]
			== RunState.LaraAreaNovelState.PLAYED,
		"専用会話を選んだエリアを再生済みにする"
	)
	var before_seed_count: int = main.run_state.stored_seeds.size()
	main._on_opening_novel_finished()
	_expect(main.run_state.current_hp > 10 or main.run_state.stored_seeds.size() == before_seed_count + 1,
		"初回ノベル終了時に回復または種を得る")
	_expect(not main.get_node("Game").visible, "報酬メッセージを閉じるまで戦闘を開始しない")
	main._on_opening_novel_finished()
	_expect(main.get_node("Game").visible, "報酬表示の後に戦闘を開始する")
	main.get_node("Game").cancel_battle()
	main._on_stage_select_stage_selected(destination)
	_expect(novel._active_novel_text.script_path.ends_with("novel_event_rara_false_001"),
		"同日2回目はfalseシナリオ")
	var hp_before: int = main.run_state.current_hp
	before_seed_count = main.run_state.stored_seeds.size()
	main._on_opening_novel_finished()
	_expect(main.run_state.current_hp == hp_before and main.run_state.stored_seeds.size() == before_seed_count,
		"2回目は報酬を付与しない")
	main.get_node("Game").cancel_battle()
	main.run_state.current_day = 6
	main._on_stage_select_stage_selected(destination)
	_expect(novel._active_novel_text.script_path.contains("/common/"),
		"別の日も既読エリアシナリオは再生せずcommonを選ぶ")
	main.run_state.current_day = 7
	var eramia := load("res://data/resources/area/area_eramia/area_eramia.tres") as StageInfo
	main.run_state.lara_area_novel_states[StageInfo.StageArea.ERAMIA_DISTRICT] \
		= RunState.LaraAreaNovelState.VISITED
	main.run_state.select_stage(eramia)
	main.run_state.select_stage(corotta)
	main._on_stage_select_stage_selected(destination)
	_expect(novel._active_novel_text.script_path.ends_with("novel_event_rara_eramia_001"),
		"未再生の訪問済みエリアがあれば直前エリアでなくても専用交流を再生する")
	main.run_state.current_day = 8
	var felis := load("res://data/resources/area/area_felis/area_felis.tres") as StageInfo
	var gonsal := load("res://data/resources/area/area_gonsal/area_gonsal.tres") as StageInfo
	main.run_state.lara_area_novel_states[StageInfo.StageArea.FELIS_GARDEN_DISTRICT] \
		= RunState.LaraAreaNovelState.VISITED
	main.run_state.lara_area_novel_states[StageInfo.StageArea.GONSAL_DISTRICT] \
		= RunState.LaraAreaNovelState.VISITED
	main.run_state.select_stage(felis)
	main.run_state.select_stage(gonsal)
	main._on_stage_select_stage_selected(destination)
	var selected_multiple_area := (
		novel._active_novel_text.script_path.ends_with("novel_event_rara_felis_001")
		or novel._active_novel_text.script_path.ends_with("novel_event_rara_gonsal_001")
	)
	_expect(selected_multiple_area, "複数の訪問済みエリアから専用交流をランダムに選ぶ")
	var played_count := 0
	for area in [StageInfo.StageArea.FELIS_GARDEN_DISTRICT, StageInfo.StageArea.GONSAL_DISTRICT]:
		if main.run_state.lara_area_novel_states[area] == RunState.LaraAreaNovelState.PLAYED:
			played_count += 1
	_expect(played_count == 1, "ランダム選択した1エリアだけを再生済みにする")
	main._return_to_title()
	novel._script_request_id += 1
	novel.click_wait_completed.emit()
	await create_timer(0.15).timeout
	var bgm := main.get_node("BGM") as BeatConductor
	bgm.stop()
	bgm.audio_player.stream = null
	bgm.bgm_stream = null
	main.queue_free()
	await process_frame
	print("MainLaraInteractionTest: %d failures" % _failures)
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)
