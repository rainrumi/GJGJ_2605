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

	var block := AcidBlockInfo.new()
	block.max_hp = 1000
	var nightmare_info := EnemyInfo.new()
	nightmare_info.acid_block = block
	var rotation_block := AcidBlockInfo.new()
	rotation_block.stomach_shape = [
		PackedInt32Array([1, 1]),
		PackedInt32Array([1, 0]),
		PackedInt32Array([1, 0]),
	]
	var rotation_info := EnemyInfo.new()
	rotation_info.acid_block = rotation_block
	var preset := EnemyPresetInfo.new()
	var nightmare_infos: Array[EnemyInfo] = [nightmare_info, nightmare_info, rotation_info]
	preset.enemies = nightmare_infos
	var seed := SeedInfo.new()
	seed.acid_block = AcidBlockInfo.new()
	seed.acid_block.max_hp = 1000
	seed.sub_skill_mode = SeedInfo.SubSkillMode.Drag
	var context := BattleInfo.new()
	context.enemy_preset = preset
	var flowers: Array[SeedInfo] = [seed]
	context.flowers = flowers
	game.call("start_battle", context)
	await process_frame

	var rotate_button := game.get_node("UI/RotateModeButton") as CheckButton
	var playback_button := game.get_node("UI/AcidPlaybackButton") as Button
	var seed_button_list := game.get_node("UI/SeedButtonList") as SeedButtonList
	var seed_button := seed_button_list.get_child(0) as SeedButton
	var stomach := game.get_node("Stomach") as StomachBoard
	var input_controller := game.get_node("GameInputController") as GameInputController
	var seed_controller := game.get("seed_controller") as GameSeedController
	var enemies: Array[Enemy] = game.get("enemies")
	var nightmare := enemies[0]
	var second_nightmare := enemies[1]
	var rotation_target := enemies[2]
	nightmare.set_Aciding(true)
	stomach.place_enemy(nightmare, Vector2i.ZERO)
	second_nightmare.set_Aciding(true)
	stomach.place_enemy(second_nightmare, Vector2i(1, 0))

	_expect(playback_button != null, "回転トグルの下に消化再生ボタンがある")
	_expect(
		playback_button.alignment == HORIZONTAL_ALIGNMENT_RIGHT,
		"消化再生ボタンを右揃えにする"
	)
	_expect(
		playback_button.position.y >= rotate_button.position.y + rotate_button.size.y,
		"消化再生ボタンを回転トグルより下に配置する"
	)
	_expect(playback_button.text == "再生", "消化開始前は再生と表示する")

	var minutes_before := int(game.get("minutes"))
	playback_button.pressed.emit()
	_expect(playback_button.text == "一時停止", "再生クリック後は一時停止と表示する")
	_expect(game.get("auto_acid_enabled"), "再生クリックで自動消化を開始する")
	playback_button.pressed.emit()
	_expect(playback_button.text == "再生", "一時停止クリック後は再生と表示する")
	_expect(game.get("auto_acid_paused_by_user"), "一時停止クリックで消化を停止状態にする")
	await process_frame
	await process_frame
	await process_frame
	_expect(game.get("minutes") == minutes_before, "一時停止中は消化時間を進めない")
	_expect((game.get("Acidion_timer") as Timer).is_stopped(), "一時停止中は自動消化Timerを止める")
	var rotation_size_before := rotation_target.get_stomach_size()
	rotate_button.set_pressed_no_signal(true)
	rotate_button.toggled.emit(true)
	input_controller.call("_handle_press", rotation_target.global_position)
	_expect(
		rotation_target.get_stomach_size() != rotation_size_before,
		"一時停止中は胃外の悪夢を回転できる"
	)
	rotate_button.set_pressed_no_signal(false)
	rotate_button.toggled.emit(false)
	input_controller.call("_handle_press", nightmare.global_position)
	_expect(game.get("dragging_enemy") == nightmare, "一時停止中は胃内のモノをドラッグできる")
	input_controller.call("_handle_release", nightmare.origin_position)
	_expect(not nightmare.is_active_in_stomach(), "一時停止中に胃内のモノを外へ出せる")
	_expect(game.get("auto_acid_paused_by_user"), "取り出し後も消化の一時停止を維持する")
	seed_button.call("_try_use_sub_skill", seed_button.global_position)
	_expect(seed_controller.is_dragging(), "一時停止中は夢の種の設置操作を開始できる")
	var seed_drop_position := stomach.get_global_position_for_cell(Vector2i.ZERO, Vector2i.ONE)
	var release_event := InputEventMouseButton.new()
	release_event.button_index = MOUSE_BUTTON_LEFT
	release_event.pressed = false
	release_event.position = seed_drop_position
	seed_button.call("_input", release_event)
	var placed_seed_block := enemies.back() as Enemy
	_expect(
		placed_seed_block != null and placed_seed_block.has_seed() and placed_seed_block.is_active_in_stomach(),
		"一時停止中に夢の種を胃へ設置できる"
	)
	_expect(game.get("auto_acid_paused_by_user"), "夢の種設置後も消化の一時停止を維持する")

	var auto_acid_timer := game.get("Acidion_timer") as Timer
	playback_button.pressed.emit()
	_expect(playback_button.text == "一時停止", "再生再開後は一時停止と表示する")
	_expect(not game.get("auto_acid_paused_by_user"), "再生クリックで停止状態を解除する")
	_expect(auto_acid_timer.is_stopped(), "保留中の消化完了前は次の消化Timerを開始しない")
	await process_frame
	_expect(game.get("minutes") > minutes_before, "再生後は保留中の消化を進める")
	_expect(not auto_acid_timer.is_stopped(), "保留中の消化完了後から次の消化Timerを開始する")
	_expect(
		auto_acid_timer.time_left > auto_acid_timer.wait_time * 0.5,
		"次の消化間隔を消化完了後から数える"
	)

	playback_button.pressed.emit()
	game.call("cancel_battle")
	root.remove_child(game)
	game.free()
	placed_seed_block = null
	release_event = null
	auto_acid_timer = null
	rotation_target = null
	second_nightmare = null
	nightmare = null
	enemies.clear()
	stomach = null
	input_controller = null
	seed_controller = null
	seed_button = null
	seed_button_list = null
	playback_button = null
	rotate_button = null
	context = null
	flowers.clear()
	seed = null
	preset = null
	nightmare_infos.clear()
	rotation_info = null
	rotation_block = null
	nightmare_info = null
	block = null
	game = null
	packed = null
	await process_frame
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("GameAcidPlaybackPauseTest: %s" % message)
