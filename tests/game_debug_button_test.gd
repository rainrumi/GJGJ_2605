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
	_expect(debug_panel != null, "デバッグパネルを構成する")
	_expect(debug_button != null, "デバッグボタンを構成する")
	if debug_panel != null and debug_button != null:
		_expect(debug_panel.visible, "戦闘中にデバッグパネルを表示する")
		_expect(debug_button.visible, "戦闘中にデバッグボタンを表示する")
		_expect(
			get_viewport().get_visible_rect().encloses(debug_button.get_global_rect()),
			"デバッグボタンを画面内に配置する"
		)
		debug_button.pressed.emit()
		_expect(bool(debug_panel.get("debug_button_active")), "デバッグボタンで機能を有効化できる")
		debug_button.pressed.emit()
		_expect(not bool(debug_panel.get("debug_button_active")), "デバッグボタンで機能を無効化できる")

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
