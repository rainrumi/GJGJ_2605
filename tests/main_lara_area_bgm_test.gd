extends Node

var _failures := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.time_scale = 20.0
	var packed := load("res://scene/main/main.tscn") as PackedScene
	_expect(packed != null, "Main scene loads")
	if packed == null:
		get_tree().quit(1)
		return
	var main := packed.instantiate()
	add_child(main)
	await get_tree().process_frame

	var bgm := main.get_node("BGM") as BeatConductor
	var novel := main.get_node("OpeningNovel") as OpeningNovel
	var game := main.get_node("Game") as CanvasItem
	var corotta := load("res://data/resources/area/area_corotta/area_corotta.tres") as StageInfo
	var eramia := load("res://data/resources/area/area_eramia/area_eramia.tres") as StageInfo
	_expect(bgm != null and novel != null and game != null, "Main scene exposes BGM, novel, and game nodes")
	_expect(corotta != null and eramia != null, "Area resources load")
	if bgm == null or novel == null or corotta == null or eramia == null:
		get_tree().quit(1)
		return

	bgm.play_bgm_immediately(BeatConductor.BGM_KIND.LUNOVA_0)
	main.run_state.reset()
	main.run_state.current_day = 5
	main.run_state.unlock_lara()
	main.run_state.lara_current_location = corotta
	main.run_state.lara_area_novel_states[StageInfo.StageArea.ERAMIA_DISTRICT] = RunState.LaraAreaNovelState.VISITED
	main.run_state.select_stage(eramia)
	main._on_stage_select_stage_selected(corotta)

	_expect(novel.visible, "Area conversation starts without waiting for the BGM fade")
	await bgm.bgm_changed
	_expect(bgm.bgm == BeatConductor.BGM_KIND.NORMAL_0, "Corotta uses the normal area BGM")
	_expect(novel.visible, "Area conversation remains visible while the BGM fades in")
	_expect(bgm._bgm_transition_factor < 1.0, "BGM fade in is still running after the conversation starts")

	for _frame in range(180):
		if is_equal_approx(bgm._bgm_transition_factor, 1.0):
			break
		await get_tree().process_frame
	_expect(is_equal_approx(bgm._bgm_transition_factor, 1.0), "BGM fade eventually completes")
	_expect(novel.visible, "Area conversation remains visible after the BGM fade completes")
	_expect(not game.visible, "Game scene remains hidden during the conversation")
	_expect(not main.get_node("Title").visible, "Title scene is hidden during the conversation")
	_expect(not main.get_node("DayIntro").visible, "Day intro scene is hidden during the conversation")
	_expect(not main.get_node("StageSelect").visible, "Stage select scene is hidden during the conversation")
	_expect(not main.get_node("Game/UI").visible, "Game UI is hidden during the conversation")
	_expect(not main.get_node("StageClear").visible, "Stage clear scene is hidden during the conversation")
	_expect(not main.get_node("SettingsScreen").visible, "Settings scene is hidden during the conversation")
	_expect(
		novel._active_novel_text.script_path.ends_with("novel_event_rara_eramia_001.txt"),
		"Conversation uses the visited area scenario",
	)

	# Revisit the same Lara area on the same day. The repeat novel must still request its area BGM.
	novel._script_request_id += 1
	novel.visible = false
	main.show_stage_select()
	main.run_state.lara_current_location = corotta
	bgm.play_bgm_immediately(BeatConductor.BGM_KIND.LUNOVA_0)
	main._on_stage_select_stage_selected(corotta)
	_expect(
		novel._active_novel_text.script_path.ends_with("novel_event_rara_false_001.txt"),
		"Same-day revisit uses the repeat conversation",
	)
	_expect(novel.visible, "Repeat conversation starts without waiting for the BGM fade")
	await bgm.bgm_changed
	_expect(bgm.bgm == BeatConductor.BGM_KIND.NORMAL_0, "Repeat conversation requests the area BGM")
	_expect(novel.visible, "Repeat conversation remains visible during the BGM fade")
	for _frame in range(180):
		if is_equal_approx(bgm._bgm_transition_factor, 1.0):
			break
		await get_tree().process_frame

	Engine.time_scale = 1.0
	novel._script_request_id += 1
	bgm.stop()
	bgm.audio_player.stream = null
	bgm.bgm_stream = null
	main.queue_free()
	await get_tree().process_frame
	print("MainLaraAreaBgmTest: %d failures" % _failures)
	get_tree().quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("MainLaraAreaBgmTest: %s" % message)
