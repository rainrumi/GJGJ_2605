extends SceneTree

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

	_expect(
		main.get_node_or_null("SeStageClear") == null,
		"ステージクリア専用SEプレイヤーを持たない"
	)
	main.call("show_stage_clear")
	_expect(main.stage_clear.visible, "クリアSEなしでステージクリア画面を表示する")
	var original_debug_enabled := DebugState.debug_enabled
	DebugState.set_debug_enabled(true)
	main.call("show_game")
	main.call("_on_game_battle_finished", true)
	var debug_retry_button := main.stage_clear.get_node("UI/DebugRetryButton") as Button
	debug_retry_button.pressed.emit()
	_expect(main.game.visible, "ステージクリアから直近のゲーム画面へリトライできる")
	_expect(main.game_ui.visible, "リトライ時にゲームUIを表示する")
	_expect(not main.stage_clear.visible, "リトライ時にステージクリア画面を隠す")
	DebugState.set_debug_enabled(original_debug_enabled)
	var bgm := main.get_node("BGM") as BeatConductor
	bgm.stop()
	bgm.audio_player.stream = null
	bgm.bgm_stream = null
	root.remove_child(main)
	main.free()
	main = null
	packed = null
	await process_frame
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("MainStageClearSeTest: %s" % message)
