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

	var enemy_block := _create_asymmetric_block()
	var enemy_info := EnemyInfo.new()
	enemy_info.acid_block = enemy_block
	var preset := EnemyPresetInfo.new()
	var enemy_infos: Array[EnemyInfo] = [enemy_info]
	preset.enemies = enemy_infos

	var seed := SeedInfo.new()
	seed.acid_block = _create_asymmetric_block()
	seed.sub_skill_mode = SeedInfo.SubSkillMode.Drag

	var context := BattleInfo.new()
	context.enemy_preset = preset
	var flowers: Array[SeedInfo] = [seed]
	context.flowers = flowers
	game.call("start_battle", context)
	await process_frame

	var warning_label := game.get_node("UI/WarningMessageLabel") as Label
	var ui := game.get_node("UI") as BattleUI
	var input_controller := game.get_node("GameInputController") as GameInputController
	var stomach := game.get_node("Stomach") as StomachBoard
	var enemies: Array[Enemy] = game.get("enemies")
	var enemy := enemies[0]

	_expect(not game.has_node("UI/RotateModeButton"), "回転トグルを表示しない")
	_expect(not warning_label.visible, "警告文言は戦闘開始時に非表示")

	_short_click_enemy(input_controller, enemy.global_position)
	_expect(enemy.get_stomach_size() == Vector2i(3, 2), "0.5秒未満の悪夢クリックで90度右回転する")
	_expect(input_controller.get("_dragging_enemy") == null, "短いクリックではドラッグを開始しない")
	_expect(
		enemy.get_stomach_shape().has(Vector2i(2, 1)),
		"悪夢の占有セルも90度右回転する"
	)
	var size_before_pointer_drag := enemy.get_stomach_size()
	_start_enemy_drag_with_motion(input_controller, enemy.global_position)
	_expect(game.get("dragging_enemy") == enemy, "0.5秒未満でも途中で動かすとドラッグを開始する")
	_expect(enemy.get_stomach_size() == size_before_pointer_drag, "ドラッグ操作では悪夢を回転しない")
	input_controller.call("_handle_release", enemy.origin_position)
	_expect(game.get("dragging_enemy") == null, "途中移動から開始したドラッグを解放できる")

	var size_before_long_press := enemy.get_stomach_size()
	input_controller.call("_handle_press", enemy.global_position)
	input_controller.set("_press_started_msec", Time.get_ticks_msec() - 500)
	input_controller.call("_process", 0.0)
	_expect(game.get("dragging_enemy") == enemy, "0.5秒の長押しでドラッグを開始する")
	_expect(enemy.get_stomach_size() == size_before_long_press, "長押し操作では悪夢を回転しない")
	input_controller.call("_handle_release", enemy.origin_position)

	enemy.set_Aciding(true)
	stomach.place_enemy(enemy, Vector2i.ZERO)
	var size_before_rejected_rotation := enemy.get_stomach_size()
	_short_click_enemy(input_controller, enemy.global_position)
	await process_frame
	_expect(
		enemy.get_stomach_size() == size_before_rejected_rotation,
		"胃袋内悪夢の回転は適用しない"
	)
	_expect(enemy.stomach_cell == Vector2i.ZERO, "回転拒否後も胃袋内悪夢の基準セルを維持する")
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
	_short_click_seed(seed_button, seed_button.global_position)
	_expect(seed_button.get_rotation_quarter_turns() == 1, "0.5秒未満の夢の種クリックで次のブロックを90度回転する")

	var seed_controller := game.get("seed_controller") as GameSeedController
	seed_button.call("_handle_press", seed_button.global_position)
	seed_button.set("_press_started_msec", Time.get_ticks_msec() - 500)
	seed_button.call("_process", 0.0)
	_expect(seed_controller.is_dragging(), "0.5秒の長押しで回転済みの夢の種ブロックを生成できる")
	var dragging_seed_block := seed_controller.get("_dragging_seed_block") as Enemy
	_expect(
		dragging_seed_block != null and dragging_seed_block.get_stomach_size() == Vector2i(3, 2),
		"夢の種ボタンで選んだ向きを生成ブロックへ反映する"
	)

	enemy.set_Aciding(false)
	enemy.return_to_origin()
	var seed_drop_position := stomach.get_global_position_for_cell(Vector2i.ZERO, Vector2i(3, 2))
	seed_button.call("_handle_release", seed_drop_position)
	var seed_block: Enemy
	for candidate in enemies:
		if candidate != null and candidate.has_seed() and candidate.is_active_in_stomach():
			seed_block = candidate
			break
	_expect(seed_block != null, "回転済みの夢の種ブロックを胃袋へ配置できる")
	if seed_block != null:
		stomach.place_enemy(seed_block, Vector2i.ZERO)
		_short_click_enemy(input_controller, seed_block.global_position)
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


func _short_click_enemy(input_controller: GameInputController, position: Vector2) -> void:
	input_controller.call("_handle_press", position)
	input_controller.call("_handle_release", position)


func _start_enemy_drag_with_motion(input_controller: GameInputController, position: Vector2) -> void:
	input_controller.call("_handle_press", position)
	var motion := InputEventMouseMotion.new()
	motion.position = position + Vector2.ONE
	input_controller.call("_input", motion)


func _short_click_seed(seed_button: SeedButton, position: Vector2) -> void:
	seed_button.call("_handle_press", position)
	seed_button.call("_handle_release", position)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("GameRotationModeTest: %s" % message)
