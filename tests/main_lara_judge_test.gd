extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scene/main/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	var novel := main.get_node("OpeningNovel") as OpeningNovel
	var source := main.stage_select.get_stage_definition_by_id(3) as StageInfo
	var boss := source.create_high_difficulty_fallback()
	for difference in [1, 0, -1]:
		main.run_state.reset()
		main.run_state.current_day = 8
		main.run_state.current_minutes = 1800
		main.run_state.unlock_lara()
		main.run_state.select_stage(boss)
		main._sync_lara_progress()
		main.run_state.normal_enemy_defeat_counts["3:3"] = main.run_state.lara_digestion_count + difference - 1
		main.game.minutes = 1800
		main.game.hp = 50
		main._on_game_battle_finished(true)
		_expect(main.stage_clear.visible and main._lara_judge_pending, "ボス勝利直後は通常報酬を先に表示する")
		main._on_stage_clear_selection_finished(0.0)
		await create_timer(1.1).timeout
		_expect(novel._active_novel_text.script_path.ends_with("judge_setup_001"), "報酬選択後に勝負setupを表示")
		main._on_opening_novel_finished()
		var outcome := "win" if difference > 0 else ("lose" if difference < 0 else "draw")
		_expect(novel._active_novel_text.script_path.contains("judge_%s_" % outcome), "消化数比較に応じた結果を表示")
		main._on_opening_novel_finished()
		_expect(novel._images.has(1), "勝敗結果後の報酬文中にラーラを表示")
		_expect(main.run_state.stored_seeds.size() == 1, "結果後に種を1つ付与する")
		var seed := main.run_state.stored_seeds[0] as SeedInfo
		if difference != 0:
			_expect(seed.rarity == (SeedInfo.Rarity.RARE if difference > 0 else SeedInfo.Rarity.NORMAL), "結果のレアリティ制限に従う")
		_expect(main.run_state.current_hp == 100, "結果に関係なくHPを全回復")
		_expect(novel._active_novel_text.text.ends_with((
			"%sを1つ手に入れた。更にHPが全回復した。"
			+ "\n@lcm\n@name \"ラーラ\"\n次は12日目が終わったときよ！\n@lcm"
			) % seed.display_name),
			"ノベルのメッセージボックスに獲得名と回復を表示")
		_expect(main.run_state.current_day == 8, "報酬メッセージ中は翌日へ進めない")
		main._on_opening_novel_finished()
		_expect(main.run_state.current_day == 9, "報酬メッセージ後に翌日へ進む")
		main._return_to_title()

	main.run_state.reset()
	main.run_state.current_day = 20
	main.run_state.current_hp = 50
	main._lara_judge_result = 0
	main._show_lara_judge_result()
	main._on_opening_novel_finished()
	_expect(novel._images.has(1), "20日目も勝敗結果後のメッセージ中にラーラを表示")
	_expect(main.run_state.stored_seeds.is_empty(), "20日目の勝負後はアイテムを付与しない")
	_expect(main.run_state.current_hp == 50, "20日目の勝負後は報酬によるHP回復を行わない")
	_expect(novel._active_novel_text.text.ends_with(
		"@name \"ラーラ\"\n"
		+ "……今日が最後ね。あとは合格を祈りましょう……。\n@lcm"
		), "20日目は最終日の専用メッセージを表示する")
	_expect(not novel._active_novel_text.text.contains("次は24日目"), "20日目に次回判定日を表示しない")
	main._return_to_title()

	main.run_state.reset()
	main.run_state.current_day = 4
	main.run_state.current_minutes = 1800
	main.run_state.select_stage(boss)
	main.run_state.strengthened_enemy_defeat_counts["3:3"] = 2
	main._on_game_battle_finished(true)
	main._on_stage_clear_selection_finished(0.0)
	await create_timer(1.1).timeout
	_expect(novel._active_novel_text == boss.completion_novel_text, "3回目ボスのエリアノベルを勝負より先に再生")
	main._on_opening_novel_finished()
	_expect(novel._active_novel_text == main.first_nightmare_event_novel_text, "4日目に初登場イベントを再生")
	main._on_opening_novel_finished()
	_expect(main.run_state.current_day == 5, "4日目は消化数を比較せず初登場イベント後に翌日へ進む")
	_expect(not main._lara_judge_pending, "4日目は消化数比較を予約しない")
	main._return_to_title()

	main.run_state.reset()
	_expect(main._get_game_clear_novel_text() == main.bad_ending_novel_text, "0勝はバッドエンド")
	main.run_state.normal_enemy_defeat_counts["3:3"] = 24
	_expect(main._get_game_clear_novel_text() == main.bad_ending_novel_text, "24勝はバッドエンド")
	main.run_state.normal_enemy_defeat_counts["3:3"] = 25
	_expect(main._get_game_clear_novel_text() == main.normal_ending_novel_text, "25勝はノーマルエンド")
	main.run_state.strengthened_enemy_defeat_counts["1:1"] = 3
	_expect(main._get_game_clear_novel_text() == main.true_ending_novel_text, "旧市街3勝は25勝条件より優先")
	main.run_state.normal_enemy_defeat_counts.clear()
	_expect(main._get_game_clear_novel_text() == main.true_ending_novel_text, "25勝未満でも旧市街3勝はトゥルー")
	for ending: NovelTextInfo in [main.true_ending_novel_text, main.normal_ending_novel_text, main.bad_ending_novel_text]:
		_expect(not ending.get_script_text().is_empty(), "新エンディング本文を読み込める")
	main.run_state.current_day = 20
	main._advance_to_next_day()
	_expect(novel._active_novel_text == main.true_ending_novel_text, "20日目終了時に分岐先のノベルを再生する")
	main.run_state.current_hp = 100
	main._lara_judge_result = 0
	var full_hp_message: String = main._grant_lara_judge_reward()
	_expect(not full_hp_message.contains("全回復"), "HP満タンでは回復文を追加しない")
	main._return_to_title()
	novel._script_request_id += 1
	novel.click_wait_completed.emit()
	await create_timer(1.2).timeout
	var bgm := main.get_node("BGM") as BeatConductor
	bgm.stop()
	bgm.audio_player.stream = null
	bgm.bgm_stream = null
	main.queue_free()
	await process_frame
	print("MainLaraJudgeTest: %d failures" % _failures)
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)
