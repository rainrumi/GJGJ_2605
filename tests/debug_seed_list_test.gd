extends Node

var _failures := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await _check_seed_list_panel()
	_check_controller_mutations()
	await _check_game_integration()
	DebugState.set_debug_enabled(false)
	get_tree().quit(_failures)


func _check_seed_list_panel() -> void:
	var packed := load("res://scene/ui/battle_ui/debug/debug_all_seed_panel.tscn") as PackedScene
	_expect(packed != null, "種一覧パネルSceneを読み込める")
	if packed == null:
		return
	var panel := packed.instantiate() as DebugAllSeedPanel
	get_tree().root.add_child(panel)
	panel.open_panel()
	await get_tree().process_frame
	var seed_list := panel.seed_list
	var expected_count := (
		panel.seed_catalog.normal_skills.size()
		+ panel.seed_catalog.rare_skills.size()
		+ panel.seed_catalog.epic_skills.size()
	)
	_expect(seed_list.get_child_count() == expected_count, "catalogに登録された全種を表示する")
	if seed_list.get_child_count() >= 6:
		var first := seed_list.get_child(0) as SeedButton
		var fifth := seed_list.get_child(4) as SeedButton
		var sixth := seed_list.get_child(5) as SeedButton
		_expect(first.size.is_equal_approx(Vector2(30.0, 30.0)), "種バッグと同じ30px角で表示する")
		_expect(
			first.icon_rect.self_modulate.is_equal_approx(Color("f0e0ff")),
			"デバッグ種のテクスチャカラーを#F0E0FFにする"
		)
		var slot_style := first.frame.get_theme_stylebox("panel") as StyleBoxFlat
		_expect(
			slot_style != null and is_zero_approx(slot_style.bg_color.a),
			"デバッグ種アイコンの背景を透明にする"
		)
		_expect(
			fifth.position.is_equal_approx(Vector2(160.0, 0.0)),
			"10px間隔で横5個表示する: %s" % fifth.position
		)
		_expect(
			sixth.position.is_equal_approx(Vector2(0.0, 40.0)),
			"6個目を次の行へ折り返す: %s" % sixth.position
		)
		var acquired: Array[SeedInfo] = []
		panel.seed_acquisition_requested.connect(func(seed: SeedInfo) -> void: acquired.append(seed))
		DebugState.set_debug_enabled(true)
		first.call("_handle_press", first.global_position)
		first.call("_handle_release", first.global_position)
		_expect(acquired.size() == 1 and acquired[0] == first.seed, "左クリックした種の取得を要求する")
		DebugState.set_debug_enabled(false)
		first.call("_handle_press", first.global_position)
		first.call("_handle_release", first.global_position)
		_expect(acquired.size() == 1, "デバッグ無効時は取得要求を送らない")
	get_tree().root.remove_child(panel)
	panel.free()
	await get_tree().process_frame


func _check_controller_mutations() -> void:
	var controller := GameSeedController.new()
	var duplicate := SeedInfo.new()
	controller.set_seed_inventory([], [duplicate, duplicate])
	_expect(
		controller.remove_debug_seed_at_slot(SeedButton.SourceCollection.STORED, 1),
		"指定した所持枠の種を削除できる"
	)
	_expect(
		controller.get_stored_seeds().size() == 1
		and controller.get_stored_seeds()[0] == duplicate,
		"同一Resourceを複数所持しても指定枠だけ削除する"
	)
	var seeds: Array[SeedInfo] = []
	for index in range(7):
		var seed := SeedInfo.new()
		seed.skill_id = index + 1
		seeds.append(seed)
	controller.set_seed_inventory(seeds.slice(0, 6), [])
	_expect(controller.add_debug_seed(seeds[6]), "一覧から選んだ種を追加できる")
	_expect(controller.get_stored_seeds() == [seeds[6]], "装備枠満杯時は所持枠へ追加する")


func _check_game_integration() -> void:
	var packed := load("res://scene/main/game/game.tscn") as PackedScene
	_expect(packed != null, "戦闘Sceneを読み込める")
	if packed == null:
		return
	var game := packed.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	var context := BattleInfo.new()
	var all_seed_panel := game.get_node("UI/DebugPanel/DebugAllSeedPanel") as DebugAllSeedPanel
	var initial_seed := all_seed_panel.seed_catalog.normal_skills[0]
	context.flowers = [initial_seed]
	game.call("start_battle", context)
	DebugState.set_debug_enabled(true)
	await get_tree().process_frame
	var selected_seed := all_seed_panel.seed_catalog.rare_skills[0]
	all_seed_panel.seed_acquisition_requested.emit(selected_seed)
	_expect((game.call("get_equipped_seeds") as Array).has(selected_seed), "一覧の取得要求を戦闘inventoryへ反映する")
	var owned_panel := game.get_node("UI/OwnedSeedPanel") as OwnedSeedPanel
	owned_panel.open_panel()
	await get_tree().process_frame
	var equipped_button := owned_panel.equipped_list.get_child(0) as SeedButton
	var removal_event := InputEventMouseButton.new()
	removal_event.button_index = MOUSE_BUTTON_RIGHT
	removal_event.pressed = true
	equipped_button.call("_gui_input", removal_event)
	_expect(not (game.call("get_equipped_seeds") as Array).has(initial_seed), "バッグ内右クリックで指定種を削除する")
	DebugState.set_debug_enabled(false)
	await get_tree().process_frame
	var remaining_button := owned_panel.equipped_list.get_child(0) as SeedButton
	remaining_button.call("_gui_input", removal_event)
	_expect((game.call("get_equipped_seeds") as Array).has(selected_seed), "デバッグ無効時は右クリック削除しない")
	get_tree().root.remove_child(game)
	game.free()
	await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("DebugSeedListTest: %s" % message)
