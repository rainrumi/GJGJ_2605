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

	var opening_novel := main.get_node("OpeningNovel") as OpeningNovel
	main.call("show_stage_clear")
	var active_novel_text := opening_novel.get("_active_novel_text") as NovelTextInfo
	_expect(main.stage_clear.visible, "ステージクリア画面を表示する")
	_expect(opening_novel.visible, "初回のステージクリア時にチュートリアルを表示する")
	_expect(
		active_novel_text != null
			and active_novel_text.script_path == "res://resource/novel/tutorial/tutorial_500_100.txt",
		"tutorial_500_100.txtを再生する"
	)
	_expect(not opening_novel.get("_script_load_failed"), "チュートリアル本文を読み込める")
	_expect(not (opening_novel.get("_script_lines") as Array).is_empty(), "チュートリアル本文を表示できる")

	opening_novel.call("_finish")
	_expect(not opening_novel.visible, "チュートリアル終了後にノベルを閉じる")
	_expect(main.stage_clear.visible, "チュートリアル終了後もステージクリア画面を表示する")

	main.call("show_stage_clear")
	_expect(not opening_novel.visible, "2回目のステージクリア時はチュートリアルを再生しない")

	var bgm := main.get_node("BGM") as BeatConductor
	bgm.stop()
	bgm.audio_player.stream = null
	bgm.bgm_stream = null
	root.remove_child(main)
	main.free()
	await process_frame
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("MainFirstStageClearTutorialTest: %s" % message)
