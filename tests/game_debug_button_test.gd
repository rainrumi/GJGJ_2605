extends Node

var _failures := 0


# 試験開始
func _ready() -> void:
	call_deferred("_run")


# デバッグボタン表示試験
func _run() -> void:
	var packed := load("res://scene/main/game/game.tscn") as PackedScene
	_expect(packed != null, "戦闘シーンを読み込める")
	if packed == null:
		get_tree().quit(_failures)
		return
	var game := packed.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame

	var debug_panel := game.get_node_or_null("UI/DebugPanel") as Control
	var debug_button := game.get_node_or_null("UI/DebugPanel/DebugMessageButton") as Button
	var seed_parameter_button := game.get_node_or_null("UI/DebugPanel/DebugSeedParameterButton") as Button
	var seed_parameter_panel := game.get_node_or_null("UI/DebugPanel/DebugSeedParameterPanel") as Control
	var enemy_parameter_button := game.get_node_or_null("UI/DebugPanel/DebugEnemyParameterButton") as Button
	var enemy_parameter_panel := game.get_node_or_null("UI/DebugPanel/DebugEnemyParameterPanel") as Control
	var retry_button := game.get_node_or_null("UI/DebugPanel/DebugRetryButton") as Button
	var all_seed_button := game.get_node_or_null("UI/DebugPanel/DebugAllSeedButton") as Button
	var all_seed_panel := game.get_node_or_null("UI/DebugPanel/DebugAllSeedPanel") as Control
	_expect(debug_panel != null, "デバッグパネルを構成する")
	_expect(debug_button != null, "デバッグボタンを構成する")
	_expect(seed_parameter_button != null, "種パラメーターボタンを構成する")
	_expect(seed_parameter_panel != null, "種パラメーター画面を構成する")
	_expect(enemy_parameter_button != null, "悪夢パラメーターボタンを構成する")
	_expect(enemy_parameter_panel != null, "悪夢パラメーター画面を構成する")
	_expect(retry_button != null, "デバッグリトライボタンを構成する")
	_expect(all_seed_button != null, "種一覧ボタンを構成する")
	_expect(all_seed_panel != null, "種一覧パネルを構成する")
	if debug_panel != null and debug_button != null and retry_button != null:
		_expect(debug_panel.visible, "戦闘中にデバッグパネルを表示する")
		_expect(debug_button.visible, "戦闘中にデバッグボタンを表示する")
		_expect(
			get_viewport().get_visible_rect().encloses(debug_button.get_global_rect()),
			"デバッグボタンを画面内に配置する"
		)
		debug_button.pressed.emit()
		_expect(bool(debug_panel.get("debug_button_active")), "デバッグボタンで機能を有効化できる")
		_expect(retry_button.visible, "Debug 有効時だけリトライボタンを表示する")
		_expect(retry_button.position.y < debug_button.position.y, "リトライボタンを既存ボタン段の上に配置する")
		_expect(seed_parameter_button.visible, "Debug 有効時だけ種パラメーターボタンを表示する")
		_expect(enemy_parameter_button.visible, "Debug 有効時だけ悪夢パラメーターボタンを表示する")
		_expect(all_seed_button.visible, "Debug 有効時だけ種一覧ボタンを表示する")
		seed_parameter_button.pressed.emit()
		_expect(seed_parameter_panel.visible, "種パラメーターボタンで調整画面を開ける")
		enemy_parameter_button.pressed.emit()
		_expect(enemy_parameter_panel.visible, "悪夢パラメーターボタンで調整画面を開ける")
		all_seed_button.pressed.emit()
		_expect(all_seed_panel.visible, "種一覧ボタンで全種画面を開ける")
		debug_button.pressed.emit()
		_expect(not bool(debug_panel.get("debug_button_active")), "デバッグボタンで機能を無効化できる")
		_expect(not retry_button.visible, "Debug 無効時はリトライボタンを隠す")
		_expect(not seed_parameter_button.visible, "Debug 無効時は種パラメーターボタンを隠す")
		_expect(not seed_parameter_panel.visible, "Debug 無効化時は調整画面を閉じる")
		_expect(not enemy_parameter_button.visible, "Debug 無効時は悪夢パラメーターボタンを隠す")
		_expect(not enemy_parameter_panel.visible, "Debug 無効化時は悪夢調整画面を閉じる")
		_expect(not all_seed_button.visible, "Debug 無効時は種一覧ボタンを隠す")
		_expect(not all_seed_panel.visible, "Debug 無効化時は種一覧画面を閉じる")

	get_tree().root.remove_child(game)
	game.free()
	game = null
	packed = null
	await get_tree().process_frame
	get_tree().quit(_failures)


# 期待値確認
func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("GameDebugButtonTest: %s" % message)
