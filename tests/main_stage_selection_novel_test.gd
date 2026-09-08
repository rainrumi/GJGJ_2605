extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


# ハードステージ選択時ノベル試験
func _run() -> void:
	var packed := load("res://scene/main/main.tscn") as PackedScene
	_expect(packed != null, "Main Sceneを読み込める")
	if packed == null:
		quit(_failures)
		return

	var main := packed.instantiate()
	root.add_child(main)
	await process_frame

	var stage_select := main.get_node("StageSelect")
	var elmena := stage_select.call("get_stage_definition_by_id", 3) as StageInfo
	_expect(elmena != null, "エルメナ大学のステージ定義を取得できる")
	if elmena != null:
		var progress_key := "%d:%d" % [elmena.stage_id, elmena.stage_area]
		main.run_state.normal_enemy_defeat_counts[progress_key] = 9
		main.run_state.current_day = 4
		var hard_stage := elmena.create_high_difficulty_fallback()
		main.call("_on_stage_select_stage_selected", hard_stage)
		var opening_novel := main.get_node("OpeningNovel") as OpeningNovel
		var active_novel_text := opening_novel.get("_active_novel_text") as NovelTextInfo
		_expect(opening_novel.visible, "エルメナ大学のハードステージ選択後にノベルを表示する")
		_expect(not main.get_node("Game").visible, "ノベル終了まではゲーム画面を表示しない")
		_expect(
			active_novel_text != null
			and active_novel_text.script_path == "res://resource/novel/area/area_elmena/novel_area_elmena_event_001.txt",
			"novel_area_elmena_event_001を再生対象にする"
		)

		main.call("_on_opening_novel_finished")
		_expect(main.get_node("Game").visible, "1つ目のノベル終了後に続きのノベルを再生せずゲーム画面を表示する")
		_expect(main.run_state.selected_stage == hard_stage, "ノベル終了後も選択したハードステージを維持する")
		var replay_texts: Array = main.call("_collect_unplayed_selected_stage_unlock_novels", hard_stage)
		_expect(replay_texts.is_empty(), "再生済みのエリアノベルを同じ進行度で再生しない")

		main.run_state.strengthened_enemy_defeat_counts[progress_key] = 1
		var second_boss_texts: Array = main.call("_collect_unplayed_selected_stage_unlock_novels", hard_stage)
		_expect(second_boss_texts.size() == 1, "2つ目のボス前にはノベルを1つだけ選ぶ")
		_expect(
			second_boss_texts.size() == 1
			and (second_boss_texts[0] as NovelTextInfo).script_path
			== "res://resource/novel/area/area_elmena/novel_area_elmena_event_002.txt",
			"2つ目のボス前にはnovel_area_elmena_event_002だけを再生対象にする"
		)

		main.run_state.strengthened_enemy_defeat_counts[progress_key] = 2
		var third_boss_texts: Array = main.call("_collect_unplayed_selected_stage_unlock_novels", hard_stage)
		_expect(third_boss_texts.size() == 1, "3つ目のボス前にはノベルを1つだけ選ぶ")
		_expect(
			third_boss_texts.size() == 1
			and (third_boss_texts[0] as NovelTextInfo).script_path
			== "res://resource/novel/area/area_elmena/novel_area_elmena_event_003.txt",
			"3つ目のボス前にはnovel_area_elmena_event_003だけを再生対象にする"
		)

	if main.get_node("Game").has_method("cancel_battle"):
		main.get_node("Game").cancel_battle()
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
	push_error("MainStageSelectionNovelTest: %s" % message)
