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

	var stage_clear_se := main.get_node("SeStageClear") as AudioStreamPlayer
	_expect(
		stage_clear_se.stream.resource_path == "res://resource/sound/se/se_stage_clear.mp3",
		"SeStageClearにse_stage_clearを設定する"
	)
	stage_clear_se.stop()
	main.call("show_stage_clear")

	_expect(stage_clear_se.playing, "ステージクリア画面への遷移時にクリアSEを再生する")
	_expect(stage_clear_se.bus == &"SE", "クリアSEはSE音量設定の対象である")

	stage_clear_se.stop()
	stage_clear_se.stream = null
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
