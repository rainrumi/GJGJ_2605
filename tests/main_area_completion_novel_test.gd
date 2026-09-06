extends SceneTree

const AREA_EXPECTATIONS := {
	1: ["lunova", "ルノヴァ旧市街"],
	2: ["eramia", "エラミア区"],
	3: ["elmena", "エルメナ大学"],
	4: ["gonsal", "ゴンサル地区"],
	5: ["riran", "大樹リラン駐屯地"],
	6: ["felis", "フェリス庭区"],
	7: ["nerix", "ネリクス魔法学校"],
	8: ["zaika", "ザイカ行政区"],
	9: ["mirune", "ミルネ街"],
	10: ["corotta", "コロッタ街"],
	11: ["iriyu", "イリユ洞窟"],
}

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

	for stage_id in AREA_EXPECTATIONS:
		var stage := main.stage_select.call("get_stage_definition_by_id", stage_id) as StageInfo
		var expectation: Array = AREA_EXPECTATIONS[stage_id]
		var area_slug := expectation[0] as String
		var area_name := expectation[1] as String
		_expect(stage != null, "%sのステージ定義を取得できる" % area_name)
		if stage == null:
			continue
		_expect(stage.completion_novel_text != null, "%sのクリア後ノベルが設定されている" % area_name)
		if stage.completion_novel_text != null:
			_expect(
				stage.completion_novel_text.script_path
				== "res://resource/novel/area/area_%s/novel_area_%s_event_003_001.txt"
				% [area_slug, area_slug],
				"%sのクリア後ノベルパスが正しい" % area_name
			)
			_expect(
				stage.completion_novel_text.get_script_text().contains("『%s』" % area_name),
				"%sの名称がクリア後ノベルに含まれる" % area_name
			)

	var elmena_source := main.stage_select.call("get_stage_definition_by_id", 3) as StageInfo
	var elmena_boss_stage := elmena_source.create_high_difficulty_fallback()
	main.run_state.select_stage(elmena_boss_stage)
	main.run_state.current_day = 7
	var progress_key := "%d:%d" % [elmena_boss_stage.stage_id, elmena_boss_stage.stage_area]
	main.run_state.normal_enemy_defeat_counts[progress_key] = 0
	main.run_state.strengthened_enemy_preset_indices[progress_key] = 0
	main.run_state.strengthened_enemy_defeat_counts[progress_key] = 1
	main.call("_queue_area_completion_novel_if_needed", elmena_boss_stage)
	_expect(
		main.get("pending_area_completion_novel_text") == null,
		"2つめのボスクリアではエリアクリアノベルを予約しない"
	)
	main.run_state.strengthened_enemy_defeat_counts[progress_key] = 2
	main.call("_queue_area_completion_novel_if_needed", elmena_boss_stage)
	main.call("_finish_current_day")
	var opening_novel := main.get_node("OpeningNovel") as OpeningNovel
	var active_novel_text := opening_novel.get("_active_novel_text") as NovelTextInfo
	_expect(opening_novel.visible, "3つめのボスクリア後にエリアクリアノベルを表示する")
	_expect(
		int(main.run_state.normal_enemy_defeat_counts.get(progress_key, -1)) == 0,
		"通常ステージのクリア数をエリアクリア判定に使用しない"
	)
	_expect(main.run_state.current_day == 7, "エリアクリアノベル終了までは当日を維持する")
	_expect(
		active_novel_text == elmena_boss_stage.completion_novel_text,
		"選択エリアのクリア後ノベルを再生する"
	)

	main.call("_on_opening_novel_finished")
	_expect(main.run_state.current_day == 8, "エリアクリアノベル終了後に翌日へ進む")

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
	push_error("MainAreaCompletionNovelTest: %s" % message)
