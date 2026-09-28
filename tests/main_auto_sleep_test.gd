extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(
		not RunState.has_reached_morning(RunState.MORNING_MINUTES - 1),
		"朝6:00の直前は時間切れと判定しない"
	)
	_expect(
		RunState.has_reached_morning(RunState.MORNING_MINUTES),
		"朝6:00ちょうどは戦闘の時間切れと同じ判定にする"
	)

	var packed := load("res://scene/main/main.tscn") as PackedScene
	_expect(packed != null, "Main Sceneを読み込める")
	if packed == null:
		quit(_failures)
		return

	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	main.bgm.stop()
	main.run_state.reset()
	main.run_state.current_day = 2
	main.run_state.current_minutes = RunState.MORNING_MINUTES - 1
	main.call("show_stage_select")
	_expect(main.active_novel_flow == main.NovelFlow.NONE, "朝6:00前には自動就寝ノベルを始めない")

	main.run_state.current_minutes = RunState.MORNING_MINUTES + 1
	main.call("show_stage_select")
	var opening_novel := main.get_node("OpeningNovel") as OpeningNovel
	var active_novel_text := opening_novel.get("_active_novel_text") as NovelTextInfo
	_expect(opening_novel.visible, "朝6:00を過ぎてステージ選択に入るとノベルを表示する")
	_expect(not main.stage_select.visible, "自動就寝ノベルの再生前にステージ選択を非表示にする")
	_expect(
		active_novel_text != null
		and active_novel_text.script_path == "res://resource/novel/event/novel_event_auto_sleep.txt",
		"自動就寝ノベルとしてnovel_event_auto_sleep.txtを再生する"
	)

	opening_novel.call("_finish")
	_expect(main.run_state.current_day == 3, "ノベル終了後に休む処理と同じ日付進行を行う")
	_expect(
		main.run_state.current_minutes == RunState.BATTLE_START_MINUTES,
		"自動就寝後は翌日の開始時刻へ戻す"
	)
	_expect(main.run_state.day_elapsed_minutes == 0, "自動就寝後に当日経過時間をリセットする")
	_expect(
		not bool(main.get("_day_change_time_recovery_pending")),
		"自動就寝で休息時の時間回復処理も完了する"
	)

	await create_timer(main.day_intro.DISPLAY_DURATION + 0.2).timeout
	main.call("_return_to_title")
	main.bgm.stop()
	main.bgm.audio_player.stream = null
	main.bgm.bgm_stream = null
	root.remove_child(main)
	main.free()
	await process_frame
	print("MainAutoSleepTest: %d failures" % _failures)
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("MainAutoSleepTest: %s" % message)
