extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _check_stage_clear_defers_time_recovery()
	await _check_stage_clear_returns_to_map()
	await _check_stage_clear_return_delay_after_unlock()
	await _check_high_difficulty_day_ends_after_one_battle()
	await _check_today_rest_button()
	await _check_day_change_applies_time_recovery()
	await _check_unlock_and_time_carryover()
	quit(_failures)


func _check_stage_clear_defers_time_recovery() -> void:
	var packed := load("res://scene/main/stage_clear/stage_clear.tscn") as PackedScene
	_expect(packed != null, "ステージクリアSceneを読み込める")
	if packed == null:
		return
	var stage_clear := packed.instantiate()
	root.add_child(stage_clear)
	await process_frame
	stage_clear.set_seed_inventory([], [])
	for continuous_play_enabled: bool in [false, true]:
		stage_clear.set_continuous_play_enabled(continuous_play_enabled)
		stage_clear.setup_clear_result(20, 23 * 60)
		var recovery_rate: float = stage_clear.call("_apply_selection_recovery", 0.0)
		_expect(is_zero_approx(recovery_rate), "種選択時は時間回復率を加算しない")
		_expect(stage_clear.get_current_hp() == 20, "種選択時は時間回復をHPへ適用しない")
	root.remove_child(stage_clear)
	stage_clear.free()


func _check_stage_clear_returns_to_map() -> void:
	var debug_state := root.get_node("DebugState")
	var original_debug_enabled: bool = debug_state.debug_enabled
	debug_state.set_debug_enabled(false)
	var packed := load("res://scene/main/stage_clear/stage_clear.tscn") as PackedScene
	_expect(packed != null, "ステージクリアSceneを読み込める")
	if packed == null:
		debug_state.set_debug_enabled(original_debug_enabled)
		return
	var stage_clear := packed.instantiate()
	root.add_child(stage_clear)
	await process_frame
	var debug_retry_button := stage_clear.get_node("UI/DebugRetryButton") as Button
	_expect(not debug_retry_button.visible, "Debug 無効時はステージクリアのリトライを隠す")
	var debug_retry_requested := [false]
	stage_clear.debug_retry_requested.connect(func() -> void: debug_retry_requested[0] = true)
	debug_state.set_debug_enabled(true)
	_expect(debug_retry_button.visible, "Debug 有効時はステージクリアのリトライを表示する")
	debug_retry_button.pressed.emit()
	_expect(bool(debug_retry_requested[0]), "ステージクリアのリトライ要求を通知する")
	stage_clear.set_continuous_play_enabled(true)
	stage_clear.setup_clear_result(20, 23 * 60)
	var continued := [false]
	stage_clear.continuation_requested.connect(func() -> void: continued[0] = true)
	stage_clear.call("_on_abandon_button_pressed")
	_expect(bool(continued[0]), "報酬選択後にマップへ戻る通知を行う")
	_expect(stage_clear.get_current_hp() == 30, "放棄時は追加回復だけを適用して時間回復は保留する")
	root.remove_child(stage_clear)
	stage_clear.free()
	debug_state.set_debug_enabled(original_debug_enabled)


func _check_stage_clear_return_delay_after_unlock() -> void:
	var packed := load("res://scene/main/main.tscn") as PackedScene
	_expect(packed != null, "Main Sceneを読み込める")
	if packed == null:
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	main.run_state.unlock_continuous_play()
	main.show_stage_clear()
	main.call("_on_stage_clear_continuation_requested")
	_expect(main.stage_clear.visible, "種選択直後はステージクリア画面を維持する")
	_expect(not main.stage_select.visible, "待機時間が終わるまでステージ選択画面へ遷移しない")
	await create_timer(main.STAGE_CLEAR_RETURN_DELAY + 0.1).timeout
	_expect(main.stage_select.visible, "待機時間後にステージ選択画面へ遷移する")
	var bgm := main.get_node("BGM") as BeatConductor
	bgm.stop()
	bgm.audio_player.stream = null
	bgm.bgm_stream = null
	root.remove_child(main)
	main.free()


func _check_high_difficulty_day_ends_after_one_battle() -> void:
	var packed := load("res://scene/main/main.tscn") as PackedScene
	_expect(packed != null, "Main Sceneを読み込める")
	if packed == null:
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	main.run_state.unlock_continuous_play()
	main.run_state.current_day = 8
	main.show_stage_clear()
	_expect(
		not bool(main.stage_clear.get("continuous_play_enabled")),
		"4日ごとの強化ステージ出現日は連続戦闘を無効にする"
	)
	main.stage_clear.call("_finish_reward_selection", 0.0)
	await create_timer(main.STAGE_CLEAR_RETURN_DELAY + 0.1).timeout
	_expect(main.run_state.current_day == 9, "強化ステージ出現日は1回の戦闘後に翌日へ進む")
	main.show_stage_clear()
	_expect(
		bool(main.stage_clear.get("continuous_play_enabled")),
		"強化ステージ出現日以外は連続戦闘を有効にする"
	)
	var bgm := main.get_node("BGM") as BeatConductor
	bgm.stop()
	bgm.audio_player.stream = null
	bgm.bgm_stream = null
	root.remove_child(main)
	main.free()


func _check_today_rest_button() -> void:
	var packed := load("res://scene/main/stage_select/stage_select.tscn") as PackedScene
	_expect(packed != null, "ステージ選択Sceneを読み込める")
	if packed == null:
		return
	var stage_select := packed.instantiate()
	root.add_child(stage_select)
	await process_frame
	var run_state := RunState.new()
	run_state.current_hp = 99
	var unlocked_stage_ids: Array[int] = []
	stage_select.setup_stage_choices(null, 1, unlocked_stage_ids, run_state, 22 * 60)
	var choices := stage_select.get_node("UI/StageChoicesScroll/StageChoicesMargin/SelectContainer/StageChoicesListScroll/StageChoicesPadding/StageChoices")
	var rest_button := choices.get_node("TodayRestButton") as Button
	_expect(rest_button.visible, "初日はHPが100未満なら今日は休むボタンを表示する")
	var initial_rest_requested := [false]
	stage_select.today_rest_requested.connect(func() -> void: initial_rest_requested[0] = true)
	rest_button.pressed.emit()
	_expect(bool(initial_rest_requested[0]), "初日に表示した今日は休むボタンから休息を要求できる")
	run_state.current_hp = 100
	stage_select.setup_stage_choices(null, 1, unlocked_stage_ids, run_state, 22 * 60)
	_expect(not rest_button.visible, "初日はHPが100以上なら今日は休むボタンを表示しない")

	run_state.unlock_continuous_play()
	stage_select.setup_stage_choices(null, 5, unlocked_stage_ids, run_state, 23 * 60)
	_expect(rest_button != null and not rest_button.visible, "当日未挑戦なら今日は休むボタンを表示しない")
	run_state.mark_area_challenged_today()
	var scroll := stage_select.get_node("UI/StageChoicesScroll/StageChoicesMargin/SelectContainer/StageChoicesListScroll") as ScrollContainer
	scroll.scroll_vertical = 50
	stage_select.setup_stage_choices(null, 5, unlocked_stage_ids, run_state, 23 * 60)
	await process_frame
	_expect(rest_button.visible, "連続プレイ解放後かつ当日挑戦済みなら今日は休むボタンを表示する")
	_expect(scroll.scroll_vertical == 0, "一覧更新時に今日は休むボタンを最上部へ表示する")
	_expect(choices.get_child(0) == rest_button, "今日は休むボタンをエリア選択の最上位に置く")
	_expect(rest_button.get_child_count() == 3, "専用ボタンはFrameと2つのLabelを保持する")
	var label := rest_button.get_node("LocationLabel") as Label
	_expect(label.text == "今日は休む", "LocationLabel設定で今日は休むと表示する")
	_expect(label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "今日は休むを中央揃えにする")
	var recovery_label := rest_button.get_node("RecoveryLabel") as Label
	_expect(recovery_label.text == "（HP90回復）", "23時の回復量を表示する")
	var no_flowers: Array[SeedInfo] = []
	(rest_button as TodayRestButton).set_recovery_info(22 * 60, 100, no_flowers)
	_expect(recovery_label.text == "（HP100回復）", "22時の回復量を表示する")
	(rest_button as TodayRestButton).set_recovery_info(24 * 60, 100, no_flowers)
	_expect(recovery_label.text == "（HP80回復）", "0時の回復量を表示する")
	(rest_button as TodayRestButton).set_recovery_info(25 * 60, 100, no_flowers)
	_expect(recovery_label.text == "（HP70回復）", "1時の回復量を表示する")
	(rest_button as TodayRestButton).set_recovery_info(26 * 60, 100, no_flowers)
	_expect(recovery_label.text == "（HP60回復）", "2時の回復量を表示する")
	(rest_button as TodayRestButton).set_recovery_info(27 * 60, 100, no_flowers)
	_expect(recovery_label.text == "（HP50回復）", "3時以降の回復量を表示する")
	_expect(recovery_label.position.y > label.position.y, "回復量をLocationLabelの下に表示する")
	_expect(label.position.y < 9.0, "LocationLabelを上へ移動する")
	run_state.reset_daily_challenge_state()
	stage_select.setup_stage_choices(null, 6, unlocked_stage_ids, run_state, 22 * 60)
	_expect(not rest_button.visible, "翌日は再挑戦するまで今日は休むボタンを非表示にする")
	root.remove_child(stage_select)
	stage_select.free()


func _check_day_change_applies_time_recovery() -> void:
	var packed := load("res://scene/main/main.tscn") as PackedScene
	_expect(packed != null, "Main Sceneを読み込める")
	if packed == null:
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	main.run_state.current_day = 5
	main.run_state.current_hp = 20
	main.run_state.current_minutes = 23 * 60
	main.run_state.planted_flowers.clear()
	main.call("_advance_to_next_day")
	_expect(main.run_state.current_day == 6, "日付更新時に翌日へ進む")
	_expect(main.run_state.current_hp == 20, "回復予約がない日付更新では時間回復を適用しない")
	main.run_state.current_hp = 20
	main.run_state.current_minutes = 23 * 60
	main.set("_day_change_time_recovery_pending", true)
	main.call("_advance_to_next_day")
	_expect(main.run_state.current_day == 7, "回復予約後の日付更新でも翌日へ進む")
	_expect(main.run_state.current_hp == 100, "日付更新時に23時の時間回復を一度適用する")
	var disable_effect := SeedEffectOnSelectedRewerdDisableClearRecovery.new()
	var disable_skill := SeedSkill.new()
	disable_skill.effects.assign([disable_effect])
	var disable_seed := SeedInfo.new()
	disable_seed.main_skill = disable_skill
	main.run_state.current_hp = 20
	main.run_state.current_minutes = 23 * 60
	main.run_state.planted_flowers.assign([disable_seed])
	main.set("_day_change_time_recovery_pending", true)
	main.call("_advance_to_next_day")
	_expect(main.run_state.current_hp == 20, "回復無効の種は日付更新時の時間回復も無効にする")
	main.call("_return_to_title")
	var bgm := main.get_node("BGM") as BeatConductor
	bgm.stop()
	bgm.audio_player.stream = null
	bgm.bgm_stream = null
	root.remove_child(main)
	main.free()


func _check_unlock_and_time_carryover() -> void:
	var packed := load("res://scene/main/main.tscn") as PackedScene
	_expect(packed != null, "Main Sceneを読み込める")
	if packed == null:
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	main.run_state.current_day = 4
	main.call("_finish_current_day")
	main.call("_on_opening_novel_finished")
	_expect(main.run_state.is_continuous_play_unlocked, "4日目終了ノベル後に連続プレイを解放する")
	main.run_state.current_minutes = 25 * 60 + 10
	var context := main.call("_create_battle_start_context", false) as BattleInfo
	_expect(context.starting_minutes == 25 * 60 + 10, "連続プレイ時刻を次の戦闘へ渡す")
	main.call("_advance_to_next_day")
	_expect(main.run_state.current_minutes == RunState.BATTLE_START_MINUTES, "休むと次の日の開始時刻へ戻す")
	var bgm := main.get_node("BGM") as BeatConductor
	bgm.stop()
	bgm.audio_player.stream = null
	bgm.bgm_stream = null
	root.remove_child(main)
	main.free()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("ContinuousPlayTest: %s" % message)
