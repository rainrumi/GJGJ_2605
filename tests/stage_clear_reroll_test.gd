extends Node

const MAIN_SCENE := preload("res://scene/main/main.tscn")
const STAGE_CLEAR_SCENE := preload("res://scene/main/stage_clear/stage_clear.tscn")

var _failures := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var run_state := RunState.new()
	run_state.strengthened_enemy_defeat_counts["1:%d" % StageInfo.StageArea.LUNOVA_OLD_CITY] = 1
	run_state.strengthened_enemy_defeat_counts["2:%d" % StageInfo.StageArea.LUNOVA_OLD_CITY] = 2
	_expect(
		run_state.get_area_boss_defeat_count(StageInfo.StageArea.LUNOVA_OLD_CITY) == 3,
		"同じエリアのボス撃破数を合算する"
	)
	_expect(
		run_state.get_area_boss_defeat_count(StageInfo.StageArea.ERAMIA_DISTRICT) == 0,
		"別エリアのボス撃破数を混在させない"
	)
	run_state.update_area_reroll_counts()
	_expect(
		run_state.get_area_reroll_count(StageInfo.StageArea.LUNOVA_OLD_CITY) == 5,
		"ボス撃破数からエリア別リロール回数を判定する"
	)

	var stage_clear := STAGE_CLEAR_SCENE.instantiate()
	add_child(stage_clear)
	await get_tree().process_frame
	var reroll_button := stage_clear.get_node("UI/RerollButton") as Button
	stage_clear.setup_clear_result(100, RunState.BATTLE_START_MINUTES, null, 4, 5, 0)
	_expect(not reroll_button.visible, "ボス未撃破ではリロールボタンを非表示にする")

	stage_clear.setup_clear_result(100, RunState.BATTLE_START_MINUTES, null, 4, 5, 1)
	_expect(reroll_button.visible, "ボスを1回倒すとリロールボタンを表示する")
	_expect(reroll_button.text == "リロール(残り1回)", "1回撃破時の残回数を表示する")
	_expect(not reroll_button.disabled, "残回数がある間はリロールできる")
	reroll_button.pressed.emit()
	_expect(reroll_button.text == "リロール(残り0回)", "使用後の残回数を表示する")
	_expect(not reroll_button.visible, "残回数0ではリロールボタンを非表示にする")
	_expect(reroll_button.disabled, "残回数0ではリロールできない")
	var debug_reroll_button := stage_clear.get_node("UI/DebugRerollButton") as Button
	stage_clear.ui.set_debug_state(true, true)
	_expect(debug_reroll_button.visible, "デバッグ用リロールボタンを維持する")
	debug_reroll_button.pressed.emit()
	_expect(reroll_button.text == "リロール(残り0回)", "デバッグ用リロールは通常回数を消費しない")

	stage_clear.setup_clear_result(100, RunState.BATTLE_START_MINUTES, null, 4, 5, 2)
	_expect(reroll_button.text == "リロール(残り2回)", "2回撃破時は画面表示ごとに2回へリセットする")
	_expect(not reroll_button.disabled, "画面再表示後はリロールを再び使用できる")
	stage_clear.setup_clear_result(100, RunState.BATTLE_START_MINUTES, null, 4, 5, 5)
	_expect(reroll_button.text == "リロール(残り5回)", "3回以上撃破時は5回へ上書きする")

	remove_child(stage_clear)
	stage_clear.free()
	await get_tree().process_frame

	var main := MAIN_SCENE.instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	var cleared_stage := StageInfo.new()
	cleared_stage.stage_area = StageInfo.StageArea.ERAMIA_DISTRICT
	main.run_state.select_stage(cleared_stage)
	main.run_state.area_reroll_counts[cleared_stage.stage_area] = 1
	main.run_state.strengthened_enemy_defeat_counts["1:%d" % cleared_stage.stage_area] = 2
	main.call("show_stage_clear")
	var main_reroll_button := main.stage_clear.get_node("UI/RerollButton") as Button
	_expect(main_reroll_button.text == "リロール(残り2回)", "Mainはステージクリア入場時に現在エリアのリロール回数を更新して渡す")
	var bgm := main.get_node("BGM") as BeatConductor
	bgm.stop()
	bgm.audio_player.stream = null
	bgm.bgm_stream = null
	get_tree().root.remove_child(main)
	main.free()
	await get_tree().process_frame
	get_tree().quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failures += 1
	push_error("FAIL: %s" % message)
