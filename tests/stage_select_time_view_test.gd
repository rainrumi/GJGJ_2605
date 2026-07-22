extends SceneTree

const TIME_VIEW_SCENE_PATH := "res://scene/ui/view/time_view.tscn"

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_packed := load("res://scene/main/game/game.tscn") as PackedScene
	var stage_select_packed := load("res://scene/main/stage_select/stage_select.tscn") as PackedScene
	_expect(game_packed != null, "ゲームSceneを読み込める")
	_expect(stage_select_packed != null, "ステージ選択Sceneを読み込める")
	if game_packed == null or stage_select_packed == null:
		quit(_failures)
		return

	var game := game_packed.instantiate()
	var stage_select := stage_select_packed.instantiate()
	root.add_child(game)
	root.add_child(stage_select)
	await process_frame

	var game_time_view := game.get_node("UI/TimeView") as TimeView
	var stage_select_time_view := stage_select.get_node("UI/TimeView") as TimeView
	_expect(game_time_view != null, "ゲームSceneに時刻表示がある")
	_expect(stage_select_time_view != null, "ステージ選択Sceneに時刻表示がある")
	if game_time_view != null and stage_select_time_view != null:
		_expect(
			stage_select_time_view.scene_file_path == TIME_VIEW_SCENE_PATH
			and stage_select_time_view.scene_file_path == game_time_view.scene_file_path,
			"ゲームSceneと同じ時刻表示Sceneを参照する"
		)
		_expect(
			stage_select_time_view.global_position.is_equal_approx(game_time_view.global_position),
			"ゲームSceneと同じ画面位置に表示する"
		)
		_expect(
			stage_select_time_view.size.is_equal_approx(game_time_view.size),
			"ゲームSceneと同じサイズで表示する"
		)

	root.remove_child(stage_select)
	stage_select.free()
	root.remove_child(game)
	game.free()
	stage_select_time_view = null
	game_time_view = null
	stage_select = null
	game = null
	stage_select_packed = null
	game_packed = null
	await process_frame
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("StageSelectTimeViewTest: %s" % message)
