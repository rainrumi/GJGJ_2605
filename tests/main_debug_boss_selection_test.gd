extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


# debugボスB-1選択試験
func _run() -> void:
	DebugState.set_debug_enabled(true)
	var packed := load("res://scene/main/main.tscn") as PackedScene
	_expect(packed != null, "Main Sceneを読み込める")
	if packed == null:
		quit(_failures)
		return

	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	var stage_select := main.get_node("StageSelect")
	var riran := stage_select.call("get_stage_definition_by_id", 5) as StageInfo
	_expect(riran != null, "リランのステージ定義を取得できる")
	if riran != null:
		var boss_stage := riran.create_high_difficulty_fallback()
		var progress_key := "%d:%d" % [boss_stage.stage_id, boss_stage.stage_area]
		main.run_state.current_day = 12
		main.run_state.normal_enemy_defeat_counts[progress_key] = 9
		main.run_state.strengthened_enemy_preset_indices[progress_key] = 2
		main.run_state.strengthened_enemy_defeat_counts[progress_key] = 2
		main.run_state.played_stage_novel_indices[progress_key] = 3

		stage_select.call(
			"setup_stage_choices",
			riran,
			main.run_state.current_day,
			[],
			main.run_state,
			main.run_state.current_minutes
		)
		var boss_button := stage_select.get_node("UI/BossButton") as Button
		boss_button.button_pressed = true
		var displayed_stages: Array = stage_select.get("_displayed_stage_definitions")
		var riran_choice_index := -1
		for index in range(displayed_stages.size()):
			var displayed_stage := displayed_stages[index] as StageInfo
			if displayed_stage != null and displayed_stage.stage_area == StageInfo.StageArea.RIRAN_TREE_GARRISON:
				boss_stage = displayed_stage
				riran_choice_index = index
				break
		_expect(riran_choice_index >= 0, "ボス一覧にリランを表示する")
		if riran_choice_index >= 0:
			stage_select.call("_on_stage_choice_pressed", riran_choice_index)
		var boss_presets := boss_stage.enemy_data.strengthened_enemy_presets
		_expect(main.get_node("Game").visible, "debugボス選択後に通常の戦闘画面へ遷移する")
		_expect(not boss_presets.is_empty(), "リランのB-1編成が存在する")
		if not boss_presets.is_empty():
			_expect(main.game.current_enemy_preset == boss_presets[0], "debugボス選択ではB-1編成を使用する")
		_expect(main.run_state.selected_stage == boss_stage, "通常ボスと同じ高難度ステージ定義を使用する")
		_expect(
			int(main.run_state.strengthened_enemy_preset_indices.get(progress_key, -1)) == 2,
			"debugボス選択で通常のボス進行番号を書き換えない"
		)
		_expect(
			int(main.run_state.strengthened_enemy_defeat_counts.get(progress_key, -1)) == 2,
			"debugボス選択で通常のボス撃破数を書き換えない"
		)

		main.game.cancel_battle()
		main.call("_on_stage_select_stage_selected", boss_stage)
		if boss_presets.size() >= 3:
			_expect(main.game.current_enemy_preset == boss_presets[2], "通常ボス選択は既存の進行位置を維持する")

	if main.get_node("Game").has_method("cancel_battle"):
		main.get_node("Game").cancel_battle()
	var bgm := main.get_node("BGM") as BeatConductor
	bgm.stop()
	bgm.audio_player.stream = null
	bgm.bgm_stream = null
	root.remove_child(main)
	main.free()
	DebugState.set_debug_enabled(false)
	await process_frame
	quit(_failures)


# 期待値確認
func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("MainDebugBossSelectionTest: %s" % message)
