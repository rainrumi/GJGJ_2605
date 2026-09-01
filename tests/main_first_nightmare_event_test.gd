extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scene/main/main.tscn") as PackedScene
	_expect(packed != null, "Main Sceneを読み込める")
	if packed == null:
		quit(_failures)
		return

	var main := packed.instantiate()
	root.add_child(main)
	await process_frame

	main.run_state.current_day = 4
	main.call("_finish_current_day")

	var opening_novel := main.get_node("OpeningNovel") as OpeningNovel
	var event_text := main.get("first_nightmare_event_novel_text") as NovelTextInfo
	_expect(event_text != null, "4日目終了後ノベルのResourceが設定されている")
	_expect(
		event_text != null
		and event_text.script_path == "res://resource/novel/novel_event_100.txt",
		"novel_event_100.txtを再生対象にする"
	)
	_expect(opening_novel.visible, "4日目終了後にノベル画面を表示する")
	_expect(main.run_state.current_day == 4, "ノベル終了までは4日目を維持する")

	main.call("_on_opening_novel_finished")
	_expect(main.run_state.current_day == 5, "ノベル終了後に5日目へ進む")
	_expect(main.run_state.is_lara_unlocked, "ノベル終了時にラーラを解放する")
	_expect(main.run_state.lara_current_location != null, "5日目のラーラの現在地を抽選する")
	if main.run_state.lara_current_location != null:
		_expect(
			main.run_state.lara_current_location.stage_area != StageInfo.StageArea.LUNOVA_OLD_CITY,
			"ラーラの現在地に旧市街を選ばない"
		)
	main.call("_advance_to_next_day")
	_expect(main.run_state.current_day == 6, "次の日付更新で6日目へ進む")
	_expect(
		main.run_state.lara_current_location in main.lara_location_catalog.stages,
		"日付更新ごとにラーラの現在地を10箇所から再抽選する"
	)

	var bgm := main.get_node("BGM") as BeatConductor
	bgm.stop()
	bgm.audio_player.stream = null
	bgm.bgm_stream = null
	root.remove_child(main)
	main.free()
	await process_frame
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("MainFirstNightmareEventTest: %s" % message)
