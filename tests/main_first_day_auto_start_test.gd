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
	main.bgm.stop()

	main.run_state.reset()
	main.run_state.current_day = 1
	main.call("show_day_intro")
	await create_timer(main.day_intro.DISPLAY_DURATION + 0.2).timeout

	var selected_stage := main.run_state.selected_stage as StageInfo
	_expect(selected_stage != null, "1日目の自動選択でステージが設定される")
	_expect(
		selected_stage != null and selected_stage.stage_id == 11,
		"1日目はイリユ洞窟(stage_id=11)を自動選択する"
	)
	_expect(not main.stage_select.visible, "1日目の表示後にステージ選択画面を表示しない")
	_expect(main.game.visible, "1日目の表示後に戦闘画面を表示する")

	if main.game.has_method("cancel_battle"):
		main.game.cancel_battle()
	main.bgm.stop()
	main.bgm.audio_player.stream = null
	main.bgm.bgm_stream = null
	root.remove_child(main)
	main.free()
	await process_frame
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("MainFirstDayAutoStartTest: %s" % message)
