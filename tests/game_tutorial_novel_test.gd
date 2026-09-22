extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene := load("res://scene/main/main.tscn") as PackedScene
	_expect(main_scene != null, "Main scene loads")
	if main_scene == null:
		quit(_failures)
		return

	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame

	var stage := main.stage_select.call("get_stage_definition_by_id", 11) as StageInfo
	_expect(stage != null, "Tutorial test stage loads")
	if stage != null:
		main.run_state.select_stage(stage)
		main.show_game()
		await process_frame

		var game: Node = main.get("game") as Node
		var tutorial := game.get_node("TutorialNovel") as OpeningNovel
		_expect(not tutorial.visible, "Tutorial is not auto-played on the first game scene")
		_expect(bool(game.get("battle_active")), "Battle input starts without auto-playing tutorial")

		game.show_tutorial()
		await process_frame
		var tutorial_text := tutorial.get("_active_novel_text") as NovelTextInfo
		_expect(tutorial.visible, "Tutorial overlay remains available in the game scene")
		_expect(not bool(game.get("battle_active")), "Manual tutorial playback pauses battle input")
		_expect(tutorial.novel_layer == 120 and tutorial.layer == 120, "Tutorial overlay uses the foreground layer")
		_expect(
			tutorial_text != null
				and tutorial_text.script_path == "res://resource/novel/tutorial/tutorial_100.txt",
			"Tutorial uses tutorial_100.txt"
		)

		tutorial.call("_finish")
		await process_frame
		_expect(bool(game.get("battle_active")), "Battle input resumes after tutorial playback")

		main.show_game(false)
		await process_frame
		_expect(not tutorial.visible, "Tutorial is not auto-played when the game scene is shown again")

	root.remove_child(main)
	main.free()
	await process_frame
	print("game_tutorial_novel_test: PASS")
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("GameTutorialNovelTest: %s" % message)
