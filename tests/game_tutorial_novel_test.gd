extends Node

var _failures := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene := load("res://scene/main/main.tscn") as PackedScene
	_expect(main_scene != null, "Main scene loads")
	if main_scene == null:
		get_tree().quit(_failures)
		return

	var main := main_scene.instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame

	var stage := main.stage_select.call("get_stage_definition_by_id", 11) as StageInfo
	_expect(stage != null, "Tutorial test stage loads")
	if stage != null:
		main.run_state.select_stage(stage)
		main.show_game()
		await get_tree().process_frame

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
		await get_tree().process_frame
		var followup_tutorial_text := tutorial.get("_active_novel_text") as NovelTextInfo
		_expect(tutorial.visible, "Follow-up tutorial starts after the initial tutorial")
		_expect(bool(game.get("battle_active")), "Battle input resumes after the follow-up tutorial finishes")
		_expect(
			followup_tutorial_text != null
				and followup_tutorial_text.script_path == "res://resource/novel/tutorial/tutorial_100_110.txt",
			"Initial follow-up tutorial uses tutorial_100_110.txt"
		)

		game.show_tutorial()
		await get_tree().process_frame
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
		await get_tree().process_frame
		_expect(bool(game.get("battle_active")), "Battle input resumes after tutorial playback")

		var battle_ui := game.get("ui") as BattleUI
		battle_ui.call("_open_owned_seed_panel")
		await get_tree().process_frame
		var owned_seed_panel_tutorial := tutorial.get("_active_novel_text") as NovelTextInfo
		_expect(tutorial.visible, "Opening the owned seed panel plays its first-use tutorial")
		_expect(
			owned_seed_panel_tutorial != null
				and owned_seed_panel_tutorial.script_path == "res://resource/novel/tutorial/tutorial_300_200.txt",
			"Owned seed panel tutorial uses tutorial_300_200.txt"
		)
		tutorial.call("_finish")
		await get_tree().process_frame
		battle_ui.call("_open_owned_seed_panel")
		await get_tree().process_frame
		var completed_owned_seed_panel_tutorial := tutorial.get("_active_novel_text") as NovelTextInfo
		_expect(
			completed_owned_seed_panel_tutorial != null
				and completed_owned_seed_panel_tutorial.script_path
				== "res://resource/novel/tutorial/tutorial_300_200.txt",
			"Owned seed panel tutorial does not replay after first use"
		)
		battle_ui.call("_close_owned_seed_panel")

		main.show_game(false)
		await get_tree().process_frame
		var tutorial_after_reentry := tutorial.get("_active_novel_text") as NovelTextInfo
		_expect(
			tutorial_after_reentry != null
				and tutorial_after_reentry.script_path == "res://resource/novel/tutorial/tutorial_300_200.txt",
			"Tutorial is not auto-played when the game scene is shown again"
		)
		_expect(bool(game.get("battle_active")), "Battle input starts normally when re-entering the game scene")

		main.run_state.stored_seeds.append(load("res://data/resources/seeds/skills/seed_100_101.tres") as SeedInfo)
		main.show_game(false)
		await get_tree().process_frame
		var owned_seed_tutorial := tutorial.get("_active_novel_text") as NovelTextInfo
		_expect(tutorial.visible, "Owned-seed tutorial auto-plays when a seed is first present")
		_expect(
			owned_seed_tutorial != null
				and owned_seed_tutorial.script_path == "res://resource/novel/tutorial/tutorial_300_100.txt",
			"Owned-seed tutorial uses tutorial_300_100.txt"
		)
		tutorial.call("_finish")
		await get_tree().process_frame
		main.show_game(false)
		await get_tree().process_frame
		var later_battle_tutorial := tutorial.get("_active_novel_text") as NovelTextInfo
		_expect(
			later_battle_tutorial != null
				and later_battle_tutorial.script_path == "res://resource/novel/tutorial/tutorial_300_100.txt",
			"Owned-seed tutorial does not replay on later battles"
		)

	get_tree().root.remove_child(main)
	main.free()
	await get_tree().process_frame
	print("game_tutorial_novel_test: PASS")
	get_tree().quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("GameTutorialNovelTest: %s" % message)
