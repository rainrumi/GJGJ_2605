extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _check_stage_clear_returns_to_map()
	await _check_today_rest_button()
	await _check_unlock_and_time_carryover()
	quit(_failures)


func _check_stage_clear_returns_to_map() -> void:
	var packed := load("res://scene/main/stage_clear/stage_clear.tscn") as PackedScene
	_expect(packed != null, "ステージクリアSceneを読み込める")
	if packed == null:
		return
	var stage_clear := packed.instantiate()
	root.add_child(stage_clear)
	await process_frame
	stage_clear.set_continuous_play_enabled(true)
	stage_clear.setup_clear_result(20, 23 * 60)
	var continued := [false]
	stage_clear.continuation_requested.connect(func() -> void: continued[0] = true)
	stage_clear.call("_on_abandon_button_pressed")
	_expect(bool(continued[0]), "報酬選択後にマップへ戻る通知を行う")
	var hp_before_rest: int = stage_clear.get_current_hp()
	var recovery_rate: float = stage_clear.apply_time_recovery()
	_expect(recovery_rate > 0.0, "休む時刻に対応するHP回復率を取得する")
	_expect(stage_clear.get_current_hp() > hp_before_rest, "今日は休む選択時にHPを回復する")
	root.remove_child(stage_clear)
	stage_clear.free()


func _check_today_rest_button() -> void:
	var packed := load("res://scene/main/stage_select/stage_select.tscn") as PackedScene
	_expect(packed != null, "ステージ選択Sceneを読み込める")
	if packed == null:
		return
	var stage_select := packed.instantiate()
	root.add_child(stage_select)
	await process_frame
	var run_state := RunState.new()
	run_state.unlock_continuous_play()
	var unlocked_stage_ids: Array[int] = []
	stage_select.setup_stage_choices(null, 5, unlocked_stage_ids, run_state, 23 * 60)
	var choices := stage_select.get_node("UI/StageChoicesScroll/StageChoicesMargin/StageChoices")
	var rest_button := choices.get_node("TodayRestButton") as Button
	_expect(rest_button != null and not rest_button.visible, "当日未挑戦なら今日は休むボタンを表示しない")
	run_state.mark_area_challenged_today()
	var scroll := stage_select.get_node("UI/StageChoicesScroll") as ScrollContainer
	scroll.scroll_vertical = 50
	stage_select.setup_stage_choices(null, 5, unlocked_stage_ids, run_state, 23 * 60)
	await process_frame
	_expect(rest_button.visible, "連続プレイ解放後かつ当日挑戦済みなら今日は休むボタンを表示する")
	_expect(scroll.scroll_vertical == 0, "一覧更新時に今日は休むボタンを最上部へ表示する")
	_expect(choices.get_child(0) == rest_button, "今日は休むボタンをエリア選択の最上位に置く")
	_expect(rest_button.get_child_count() == 2, "専用ボタンはFrameとLocationLabelだけを保持する")
	var label := rest_button.get_node("LocationLabel") as Label
	_expect(label.text == "今日は休む", "LocationLabel設定で今日は休むと表示する")
	_expect(label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "今日は休むを中央揃えにする")
	run_state.reset_daily_challenge_state()
	stage_select.setup_stage_choices(null, 6, unlocked_stage_ids, run_state, 22 * 60)
	_expect(not rest_button.visible, "翌日は再挑戦するまで今日は休むボタンを非表示にする")
	root.remove_child(stage_select)
	stage_select.free()


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
