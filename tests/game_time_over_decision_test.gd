extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scene/main/game/game.tscn") as PackedScene
	_expect(packed != null, "ゲームSceneを読み込める")
	if packed == null:
		quit(_failures)
		return
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	(game.get_node("ClickSe") as AudioStreamPlayer).stream = null

	var enemy_info := EnemyInfo.new()
	enemy_info.acid_block = AcidBlockInfo.new()
	var preset := EnemyPresetInfo.new()
	var enemy_infos: Array[EnemyInfo] = [enemy_info]
	preset.enemies = enemy_infos
	var seed := SeedInfo.new()
	var context := BattleInfo.new()
	context.starting_hp = 40
	context.day = 3
	context.enemy_preset = preset
	var flowers: Array[SeedInfo] = [seed]
	context.flowers = flowers
	game.call("start_battle", context)
	await process_frame
	var edited_seed := SeedInfo.new()
	edited_seed.main_description = "Edited seed description"
	var edited_enemy := EnemyInfo.new()
	edited_enemy.description = "Edited nightmare description"
	edited_enemy.acid_block = AcidBlockInfo.new()
	edited_enemy.acid_block.max_hp = 321
	DebugState.set_debug_enabled(true)
	game.call("_on_debug_seed_parameter_applied", seed, edited_seed)
	game.call("_on_debug_enemy_parameter_applied", enemy_info, edited_enemy)

	var decision := game.get_node("UI/TimeOverDecision") as ColorRect
	var retry_button := game.get_node("UI/TimeOverDecision/CenterContainer/PanelContainer/MarginContainer/Content/Buttons/RetryButton") as Button
	var abandon_button := game.get_node("UI/TimeOverDecision/CenterContainer/PanelContainer/MarginContainer/Content/Buttons/AbandonButton") as Button
	var battle_results: Array[bool] = []
	var depleted_sources: Array[Resource] = []
	game.connect("battle_finished", func(won: bool) -> void: battle_results.append(won))
	game.connect("seed_depleted", func(source: Resource) -> void: depleted_sources.append(source))

	game.set("hp", 12)
	game.set("minutes", 30 * 60)
	var pending_sources: Array[Resource] = [seed]
	game.set("_pending_depleted_seed_sources", pending_sources)
	game.call("_check_battle_end")
	_expect(decision.visible, "時間切れ時に選択パネルを表示する")
	_expect(not game.get("battle_active"), "選択中は戦闘操作を停止する")
	_expect(battle_results.is_empty(), "選択前に失敗を確定しない")
	_expect(game.get("hp") == 12, "選択前に時間切れ回復を適用しない")
	_expect(retry_button.has_focus(), "再挑戦を初期選択にする")

	retry_button.pressed.emit()
	await process_frame
	_expect(game.call("get_flowers")[0] == edited_seed, "デバッグ保存した種を再挑戦後も使用する")
	_expect(
		(game.get("current_enemy_preset") as EnemyPresetInfo).enemies[0] == edited_enemy,
		"デバッグ保存した悪夢を再挑戦後も使用する"
	)
	_expect(not decision.visible, "再挑戦時に選択パネルを閉じる")
	_expect(game.get("battle_active"), "再挑戦時に戦闘を再開する")
	_expect(game.get("minutes") == 22 * 60, "再挑戦時に開始時刻へ戻す")
	_expect(game.get("hp") == 40, "再挑戦時に開始HPへ戻す")
	_expect(game.get("current_day") == 3, "再挑戦時に開始日の文脈を維持する")
	_expect(depleted_sources.is_empty(), "失敗した挑戦の種枯渇を確定しない")
	_expect((game.get("_pending_depleted_seed_sources") as Array).is_empty(), "再挑戦時に未確定の種枯渇を破棄する")

	game.set("hp", 12)
	game.set("minutes", 30 * 60)
	pending_sources = [seed]
	game.set("_pending_depleted_seed_sources", pending_sources)
	game.call("_check_battle_end")
	abandon_button.pressed.emit()
	await process_frame
	_expect(not decision.visible, "諦める選択後にパネルを閉じる")
	_expect(battle_results == [false], "諦める選択で従来の失敗フローを確定する")
	_expect(game.get("hp") == 62, "30時の時間別回復量50を失敗時にも適用する")
	_expect(game.call("get_last_time_over_recovery_percent") == 50, "失敗時の表示用回復割合を実回復量に合わせる")
	_expect(depleted_sources == [seed], "諦めた挑戦の種枯渇を確定する")

	game.set("hp", 12)
	game.set("minutes", 23 * 60)
	game.call("_apply_time_over_recovery")
	_expect(game.get("hp") == 100, "23時の時間別回復量90を失敗時回復に使用する")
	_expect(game.call("get_last_time_over_recovery_percent") == 88, "表示用回復割合を最大HPまでの実回復量に合わせる")

	game.call("cancel_battle")
	DebugState.set_debug_enabled(false)
	root.remove_child(game)
	game.free()
	await process_frame
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("GameTimeOverDecisionTest: %s" % message)
