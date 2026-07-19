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

	var nightmare_block := _create_asymmetric_block()
	var nightmare_info := EnemyInfo.new()
	nightmare_info.acid_block = nightmare_block
	var preset := EnemyPresetInfo.new()
	var nightmare_infos: Array[EnemyInfo] = [nightmare_info]
	preset.enemies = nightmare_infos

	var seed := SeedInfo.new()
	seed.acid_block = _create_asymmetric_block()
	seed.sub_skill_mode = SeedInfo.SubSkillMode.Drag

	var context := BattleInfo.new()
	context.enemy_preset = preset
	var flowers: Array[SeedInfo] = [seed]
	context.flowers = flowers
	game.call("start_battle", context)
	await process_frame

	var time_view := game.get_node("UI/TimeView") as Control
	var rotate_button := game.get_node("UI/RotateModeButton") as CheckButton
	var warning_label := game.get_node("UI/WarningMessageLabel") as Label
	var ui := game.get_node("UI") as BattleUI
	var input_controller := game.get_node("GameInputController") as GameInputController
	var stomach := game.get_node("Stomach") as StomachBoard
	var enemies: Array[Enemy] = game.get("enemies")
	var nightmare := enemies[0]

	_expect(rotate_button != null, "時刻表示の下に回転ボタンがある")
	_expect(rotate_button.alignment == HORIZONTAL_ALIGNMENT_RIGHT, "回転ボタンを右揃えにする")
	_expect(
		rotate_button.position.y >= time_view.position.y + time_view.size.y,
		"回転ボタンが時刻表示より下に配置される"
	)
	_expect(not rotate_button.button_pressed, "戦闘開始時は回転モードが無効")
	_expect(rotate_button.text == "回転", "回転モード無効時は回転と表示する")
	_expect(not warning_label.visible, "警告文言は戦闘開始時に非表示")
	rotate_button.set_pressed_no_signal(true)
	rotate_button.toggled.emit(true)
	await process_frame
	_expect(input_controller.is_rotation_mode_enabled(), "回転ボタンで入力モードが有効になる")
	_expect(rotate_button.text == "回転（有効中）", "回転モード有効時は有効中と表示する")
	_expect(
		rotate_button.get_theme_color("font_pressed_color") == rotate_button.get_theme_color("font_color"),
		"回転モード有効時も文字色を変更しない"
	)

	input_controller.call("_handle_press", nightmare.global_position)
	_expect(nightmare.get_stomach_size() == Vector2i(3, 2), "悪夢クリックで90度右回転する")
	_expect(input_controller.get("_dragging_enemy") == null, "回転モードではドラッグを開始しない")
	_expect(
		nightmare.get_stomach_shape().has(Vector2i(2, 1)),
		"悪夢の占有セルも90度右回転する"
	)

	nightmare.set_Aciding(true)
	stomach.place_enemy(nightmare, Vector2i.ZERO)
	var size_before_rejected_rotation := nightmare.get_stomach_size()
	input_controller.call("_handle_press", nightmare.global_position)
	await process_frame
	_expect(
		nightmare.get_stomach_size() == size_before_rejected_rotation,
		"胃袋内悪夢の回転は適用しない"
	)
	_expect(nightmare.stomach_cell == Vector2i.ZERO, "回転拒否後も胃袋内悪夢の基準セルを維持する")
	_expect(warning_label.visible, "胃袋内悪夢の回転時に警告文言を表示する")
	_expect(warning_label.text == "胃袋内のモノは回転できません", "胃袋内回転の警告文言が正しい")
	_expect(
		warning_label.get_theme_color("font_color").is_equal_approx(Color(1, 0.2, 0.2, 1)),
		"胃袋内回転の警告文言を赤色にする"
	)
	_expect(warning_label.position.y < 100.0, "胃袋内回転の警告文言を画面上部に表示する")
	var warning_tween := ui.get("_warning_message_tween") as Tween
	_expect(warning_tween != null and warning_tween.is_valid(), "胃袋内回転の警告文言をTween表示する")
	if warning_tween != null and warning_tween.is_valid():
		await warning_tween.finished
	_expect(not warning_label.visible, "胃袋内回転の警告文言は表示後に消える")

	var seed_button_list := game.get_node("UI/SeedButtonList") as SeedButtonList
	var seed_button := seed_button_list.get_child(0) as SeedButton
	seed_button.call("_try_use_sub_skill", Vector2.ZERO)
	_expect(seed_button.get_rotation_quarter_turns() == 1, "夢の種クリックで次のブロックを90度回転する")

	var seed_controller := game.get("seed_controller") as GameSeedController
	var drag_result := seed_controller.start_drag(seed_button, seed, Vector2.ZERO)
	_expect(drag_result.started, "回転済みの夢の種ブロックを生成できる")
	_expect(
		drag_result.seed_block != null and drag_result.seed_block.get_stomach_size() == Vector2i(3, 2),
		"夢の種ボタンで選んだ向きを生成ブロックへ反映する"
	)

	nightmare.set_Aciding(false)
	nightmare.return_to_origin()
	var seed_drop_position := stomach.get_global_position_for_cell(Vector2i.ZERO, Vector2i(3, 2))
	var release_result := seed_controller.release_drag(seed_drop_position, enemies)
	_expect(release_result.placed, "回転済みの夢の種ブロックを胃袋へ配置できる")
	if release_result.placed:
		var seed_block := release_result.seed_block
		stomach.place_enemy(seed_block, Vector2i.ZERO)
		input_controller.call("_handle_press", seed_block.global_position)
		_expect(seed_block.get_stomach_size() == Vector2i(2, 3), "胃袋内の夢の種もクリックで回転する")

	game.call("cancel_battle")
	root.remove_child(game)
	game.free()
	await process_frame
	quit(_failures)


func _create_asymmetric_block() -> AcidBlockInfo:
	var block := AcidBlockInfo.new()
	block.stomach_shape = [
		PackedInt32Array([1, 1]),
		PackedInt32Array([1, 0]),
		PackedInt32Array([1, 0]),
	]
	return block


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("GameRotationModeTest: %s" % message)
