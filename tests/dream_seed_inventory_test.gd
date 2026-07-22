extends Node

var _failures := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_controller_inventory_rules()
	await _check_owned_seed_panel()
	await _check_stage_clear_storage_reward()
	await _check_game_inventory_integration()
	get_tree().quit(_failures)


func _check_controller_inventory_rules() -> void:
	var controller := GameSeedController.new()
	var seeds := _create_seeds(8)
	controller.set_seed_inventory(seeds, [])
	_expect(controller.get_flowers().size() == 6, "装備枠を6個に制限する")
	_expect(controller.get_stored_seeds().size() == 2, "装備上限超過分を所持枠へ移す")
	_expect(not controller.equip_seed(seeds[6]), "装備枠満杯時は追加装備できない")
	_expect(controller.unequip_seed(seeds[0]), "装備中の種を所持枠へ移せる")
	_expect(controller.get_flowers().size() == 5, "装備解除で装備数が減る")
	_expect(controller.equip_seed(seeds[6]), "空いた装備枠へ所持種を装備できる")

	var duplicate := SeedInfo.new()
	controller.set_seed_inventory([], [duplicate, duplicate])
	controller.remove_source(duplicate, SeedButton.SourceCollection.STORED)
	_expect(controller.get_stored_seeds().size() == 1, "同一Resourceを複数所持しても一件だけ削除する")


func _check_owned_seed_panel() -> void:
	var packed := load("res://scene/ui/seed/owned_seed_panel.tscn") as PackedScene
	_expect(packed != null, "所有種パネルSceneを読み込める")
	if packed == null:
		return
	var panel := packed.instantiate() as OwnedSeedPanel
	get_tree().root.add_child(panel)
	await get_tree().process_frame
	panel.set_seed_inventory(_create_seeds(6), _create_seeds(13, 100))
	await get_tree().process_frame

	var equipped_list := panel.get_node("UpperArea/EquippedList") as SeedButtonList
	var stored_list := panel.get_node("StoredArea/StoredList") as SeedButtonList
	_expect(panel.size.is_equal_approx(Vector2(192.0, 360.0)), "所有種パネルを画面左30%・全高にする")
	var panel_style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	_expect(panel_style != null and is_equal_approx(panel_style.bg_color.a, 0.3), "パネル背景を透明度30%にする")
	_expect(
		panel_style != null
		and panel_style.border_width_left == 0
		and panel_style.border_width_top == 0
		and panel_style.border_width_right == 0
		and panel_style.border_width_bottom == 0,
		"パネルの白い外枠を表示しない"
	)
	var close_button := panel.get_node("UpperArea/CloseButton") as Button
	_expect(close_button.position.x <= 2.0 and close_button.position.y <= 2.0, "閉じるボタンを左上に置く")
	_expect(is_equal_approx(equipped_list.position.x + equipped_list.size.x * 0.5, panel.size.x * 0.5), "装備枠をパネル中央に揃える")
	_expect(is_equal_approx(stored_list.position.x, 21.0), "所持枠を左端から約20px離す")
	_expect(
		is_equal_approx(panel.size.x - (stored_list.position.x + stored_list.size.x), 21.0),
		"所持枠を右端から約20px離す"
	)
	_expect(equipped_list.get_theme_constant("h_separation") == 10, "装備枠の横間隔を10pxにする")
	_expect(equipped_list.get_theme_constant("v_separation") == 10, "装備枠の縦間隔を10pxにする")
	_expect(stored_list.get_theme_constant("h_separation") == 10, "所持枠の横間隔を10pxにする")
	_expect(stored_list.get_theme_constant("v_separation") == 10, "所持枠の縦間隔を10pxにする")
	_expect(equipped_list.get_child_count() == 6, "装備枠を3×2相当の6枠表示する")
	_expect(stored_list.get_child_count() == 12, "所持枠を4×3相当の12枠表示する")
	_expect(_count_populated_buttons(stored_list) == 12, "1ページ目に12個の所持種を表示する")
	_expect((panel.get_node("StoredArea/NextPageButton") as Button).visible, "13個目があると右矢印を表示する")
	panel.call("_on_next_page_pressed")
	_expect(_count_populated_buttons(stored_list) == 1, "2ページ目に残りの所持種を表示する")
	_expect((panel.get_node("StoredArea/PreviousPageButton") as Button).visible, "2ページ目で左矢印を表示する")
	_expect((panel.get_node("StoredArea/PageLabel") as Label).text == "2 / 2", "現在ページを表示する")
	var equip_request_received := [false]
	panel.equip_requested.connect(func(_seed: SeedInfo) -> void: equip_request_received[0] = true)
	var stored_button := stored_list.get_child(0) as SeedButton
	stored_button.call("_handle_press", stored_button.global_position)
	stored_button.call("_handle_release", stored_button.global_position)
	_expect(bool(equip_request_received[0]), "所持枠の短押しで装備要求を送る")

	var equipped_button := equipped_list.get_child(0) as SeedButton
	_expect(equipped_button.size.is_equal_approx(Vector2(30.0, 30.0)), "装備枠を30px角にする")
	_expect(stored_button.size.is_equal_approx(Vector2(30.0, 30.0)), "所持枠を装備枠と同じ30px角にする")
	_expect(equipped_button.frame.visible, "パネル内の装備枠に四角い枠を表示する")
	var slot_style := equipped_button.frame.get_theme_stylebox("panel") as StyleBoxFlat
	_expect(
		slot_style != null
		and slot_style.bg_color.is_equal_approx(Color(1.0, 0.72, 0.82, 0.3)),
		"装備枠を薄いピンクの透明度30%で塗る"
	)
	_expect(
		equipped_button.icon_rect.self_modulate.is_equal_approx(OwnedSeedPanel.SLOT_ICON_COLOR),
		"パネル内の種テクスチャを黒色にする"
	)
	_expect(equipped_button.tooltip_panel != null, "装備枠の種に従来のツールチップを設定する")
	_expect(stored_button.tooltip_panel != null, "所持枠の種に従来のツールチップを設定する")
	_dispose(panel)
	await get_tree().process_frame


func _check_game_inventory_integration() -> void:
	var packed := load("res://scene/main/game/game.tscn") as PackedScene
	_expect(packed != null, "ゲームSceneを読み込める")
	if packed == null:
		return
	var game := packed.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame

	(game.get_node("ClickSe") as AudioStreamPlayer).stream = null

	var equipped_candidates := _create_seeds(7, 1)
	var stored := _create_seeds(13, 100)
	var context := BattleInfo.new()
	context.flowers = equipped_candidates
	context.stored_seeds = stored
	game.call("start_battle", context)
	await get_tree().process_frame

	var equipped: Array[SeedInfo] = game.call("get_equipped_seeds")
	var possession: Array[SeedInfo] = game.call("get_stored_seeds")
	_expect(equipped.size() == 6, "戦闘開始時も装備上限を6個にする")
	_expect(possession.size() == 14, "超過装備候補を無制限所持枠へ保持する")
	var resolver := game.get("seed_effects") as SeedEffectResolver
	_expect(resolver.get_seed_id_text() == "1,2,3,4,5,6", "装備中の種だけをメイン効果resolverへ渡す")

	var ui := game.get_node("UI") as BattleUI
	var closed_list := game.get_node("UI/SeedButtonList") as SeedButtonList
	var closed_button := closed_list.get_child(0) as SeedButton
	_expect(closed_list.position.is_equal_approx(Vector2(40.0, 54.0)), "通常時装備種をキャラクター頭頂部へ置く")
	_expect(closed_list.size.is_equal_approx(Vector2(110.0, 70.0)), "通常時装備種を3列×2行の領域に置く")
	_expect(closed_list.get_theme_constant("h_separation") == 10, "通常時装備種の横間隔を10pxにする")
	_expect(closed_list.get_theme_constant("v_separation") == 10, "通常時装備種の縦間隔を10pxにする")
	_expect(closed_list.get_child_count() == 6, "通常時に装備中の6種を表示する")
	_expect(closed_button.size.is_equal_approx(Vector2(30.0, 30.0)), "通常時装備種の透明当たり判定を30px角にする")
	_expect(closed_button.mouse_filter == Control.MOUSE_FILTER_STOP, "通常時装備種の透明四角で入力を受ける")
	_expect(closed_button.flat, "通常時装備種の当たり判定背景を無色にする")
	_expect(not closed_button.frame.visible, "パネルを閉じた装備表示はテクスチャだけにする")
	_expect(
		closed_button.icon_rect.self_modulate.is_equal_approx(BattleUI.EQUIPPED_SEED_ICON_COLOR),
		"閉じた装備表示を薄いピンクにする"
	)
	_expect(closed_button.tooltip_panel != null, "通常時装備種の透明当たり判定にツールチップを設定する")
	closed_button.call("_on_mouse_entered")
	_expect(closed_button.tooltip_panel.visible, "通常時装備種へホバーするとツールチップを表示する")
	closed_button.call("_on_mouse_exited")
	_expect(not closed_button.tooltip_panel.visible, "通常時装備種から離れるとツールチップを隠す")
	var fourth_closed_button := closed_list.get_child(3) as SeedButton
	_expect(
		fourth_closed_button.position.is_equal_approx(Vector2(0.0, 40.0)),
		"通常時装備種を中央揃えの3列2段にする"
	)
	closed_button.call("_handle_press", closed_button.global_position)
	closed_button.call("_handle_release", closed_button.global_position)
	_expect(closed_button.get_rotation_quarter_turns() == 1, "閉じた装備表示の短押し回転を維持する")
	game.call("_on_seed_drag_started", closed_button, closed_button.seed, closed_button.global_position)
	var seed_controller := game.get("seed_controller") as GameSeedController
	var equipped_seed_block := seed_controller.get("_dragging_seed_block") as Enemy
	_expect(
		seed_controller.is_dragging() and equipped_seed_block != null and equipped_seed_block.has_seed(),
		"閉じた装備表示からサブスキル有効の胃袋ドラッグを開始できる"
	)
	game.call("_on_seed_drag_released", closed_button, closed_button.seed, Vector2.ZERO)
	ui.call("_open_owned_seed_panel")
	_expect((game.get_node("UI/OwnedSeedPanel") as OwnedSeedPanel).visible, "所有種パネルを開ける")
	_expect(not closed_list.visible, "所有種パネルを開くと通常時装備種を非表示にする")
	await _capture_viewport_if_requested()
	ui.call("_close_owned_seed_panel")
	_expect(closed_list.visible, "所有種パネルを閉じると頭部の装備表示へ戻る")
	await _capture_viewport_from_environment("DREAM_SEED_CLOSED_CAPTURE_PATH")

	game.call("_on_seed_unequip_requested", equipped[0])
	equipped = game.call("get_equipped_seeds")
	possession = game.call("get_stored_seeds")
	_expect(equipped.size() == 5 and possession.size() == 15, "パネル要求で装備を所持枠へ移す")
	_expect(not resolver.get_seed_id_text().contains("1"), "装備解除した種をメイン効果対象から外す")
	game.call("_on_seed_equip_requested", possession[0])
	_expect((game.call("get_equipped_seeds") as Array).size() == 6, "パネル要求で所持種を装備する")

	ui.call("_open_owned_seed_panel")
	var owned_panel := game.get_node("UI/OwnedSeedPanel") as OwnedSeedPanel
	var stored_list := owned_panel.get_node("StoredArea/StoredList") as SeedButtonList
	var stored_button := stored_list.get_child(0) as SeedButton
	game.call("_on_seed_drag_started", stored_button, stored_button.seed, stored_button.global_position)
	_expect(seed_controller.is_dragging(), "所持枠の種から胃袋ドラッグを開始できる")
	var stomach := game.get_node("Stomach") as StomachBoard
	var drop_position := stomach.get_global_position_for_cell(Vector2i.ZERO, Vector2i.ONE)
	game.call("_on_seed_drag_released", stored_button, stored_button.seed, drop_position)
	_expect((game.call("get_stored_seeds") as Array).size() == 13, "所持枠の種を胃袋へ入れると一件だけ所持から外れる")
	var placed_stored_seed: Enemy
	for enemy in game.get("enemies") as Array[Enemy]:
		if enemy != null and enemy.has_seed() and enemy.is_active_in_stomach():
			placed_stored_seed = enemy
			break
	_expect(placed_stored_seed != null, "所持枠の種ブロックを胃袋へ配置できる")
	_expect(
		placed_stored_seed != null and not seed_controller.collect_Acided_seeds([placed_stored_seed]).is_empty(),
		"所持枠由来でも胃袋へ投入後はサブスキル解決対象になる"
	)

	game.call("cancel_battle")
	_dispose(game)
	await get_tree().process_frame


func _check_stage_clear_storage_reward() -> void:
	var packed := load("res://scene/main/stage_clear/stage_clear.tscn") as PackedScene
	_expect(packed != null, "ステージクリアSceneを読み込める")
	if packed == null:
		return
	var stage_clear := packed.instantiate()
	get_tree().root.add_child(stage_clear)
	await get_tree().process_frame
	var equipped := _create_seeds(6, 200)
	var reward := SeedInfo.new()
	reward.skill_id = 999
	reward.display_name = "Stored reward"
	stage_clear.call("set_seed_inventory", equipped, [])
	stage_clear.set("seed_options", [reward])
	stage_clear.call("_on_seed_choice_pressed", 0)
	_expect((stage_clear.call("get_planted_flowers") as Array).size() == 6, "報酬取得でも装備枠を6個に保つ")
	_expect((stage_clear.call("get_stored_seeds") as Array).size() == 1, "満杯時の報酬種を所持枠へ加える")
	_dispose(stage_clear)
	await get_tree().process_frame


func _create_seeds(count: int, first_id: int = 0) -> Array[SeedInfo]:
	var seeds: Array[SeedInfo] = []
	var texture := load("res://art/dreamseed/tex_seed_1000_No_100.png") as Texture2D
	for index in range(count):
		var seed := SeedInfo.new()
		seed.skill_id = first_id + index
		seed.display_name = "Seed %d" % seed.skill_id
		seed.texture = texture
		seed.sub_skill_mode = SeedInfo.SubSkillMode.Drag
		seed.sub_description = "Test drag"
		seeds.append(seed)
	return seeds


func _capture_viewport_if_requested() -> void:
	await _capture_viewport_from_environment("DREAM_SEED_CAPTURE_PATH")


func _capture_viewport_from_environment(environment_name: String) -> void:
	var capture_path := OS.get_environment(environment_name)
	if capture_path.is_empty():
		return
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(capture_path)
	_expect(error == OK, "所有種パネルの確認画像を保存できる")


func _count_populated_buttons(seed_list: SeedButtonList) -> int:
	var count := 0
	for child in seed_list.get_children():
		if child is SeedButton and (child as SeedButton).get_seed_source() != null:
			count += 1
	return count


func _dispose(node: Node) -> void:
	get_tree().root.remove_child(node)
	node.free()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("DreamSeedInventoryTest: %s" % message)
