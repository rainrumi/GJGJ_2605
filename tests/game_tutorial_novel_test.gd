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
		_expect(tutorial.visible, "Tutorial auto-plays on the first game scene")
		_expect(not bool(game.get("battle_active")), "Battle input pauses during the initial tutorial")
		var initial_tutorial_text := tutorial.get("_active_novel_text") as NovelTextInfo
		_expect(
			initial_tutorial_text != null
				and initial_tutorial_text.script_path == "res://resource/novel/tutorial/tutorial_100_100.txt",
			"Initial tutorial uses tutorial_100_100.txt"
		)
		var novel_catalog := load("res://data/resources/novel/novel_script_catalog.tres") as NovelScriptCatalog
		_expect(
			novel_catalog != null
				and novel_catalog.get_script_text("res://resource/novel/tutorial/tutorial_100_100.txt").begins_with("@textbox_set"),
			"Tutorial scenario is included in the bundled novel catalog"
		)

		tutorial.call("_finish")
		await process_frame
		_expect(bool(game.get("battle_active")), "Battle input resumes after the initial tutorial")

		game.show_tutorial()
		await process_frame
		var tutorial_text := tutorial.get("_active_novel_text") as NovelTextInfo
		_expect(tutorial.visible, "Tutorial overlay remains available in the game scene")
		_expect(not bool(game.get("battle_active")), "Manual tutorial playback pauses battle input")
		_expect(tutorial.novel_layer == 120 and tutorial.layer == 120, "Tutorial overlay uses the foreground layer")
		_expect(
			tutorial_text != null
				and tutorial_text.script_path == "res://resource/novel/tutorial/tutorial_100_100.txt",
			"Tutorial uses tutorial_100_100.txt"
		)

		tutorial.call("_finish")
		await process_frame
		_expect(bool(game.get("battle_active")), "Battle input resumes after tutorial playback")

		main.show_game(false)
		await process_frame
		_expect(not tutorial.visible, "Tutorial is not auto-played when the game scene is shown again")
		_expect(bool(game.get("battle_active")), "Battle input starts normally when re-entering the game scene")

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
