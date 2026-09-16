extends SceneTree

const AREA_CASES := [
	{"stage_id": 1, "area": StageInfo.StageArea.LUNOVA_OLD_CITY, "name": "lunova"},
	{"stage_id": 3, "area": StageInfo.StageArea.ELMENA_UNIVERSITY, "name": "elmena"},
	{"stage_id": 5, "area": StageInfo.StageArea.RIRAN_TREE_GARRISON, "name": "riran"},
	{"stage_id": 11, "area": StageInfo.StageArea.IRIYU_CAVE, "name": "iriyu"},
]

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scene/main/main.tscn") as PackedScene
	_expect(packed != null, "Main scene loads")
	if packed == null:
		quit(_failures)
		return

	var main := packed.instantiate()
	root.add_child(main)
	await process_frame

	for area_case: Dictionary in AREA_CASES:
		var source_stage := main.stage_select.call("get_stage_definition_by_id", area_case["stage_id"]) as StageInfo
		_expect(source_stage != null, "%s source stage exists" % area_case["name"])
		if source_stage == null:
			continue
		var boss_stage := source_stage.create_high_difficulty_fallback()
		var key := "%d:%d" % [boss_stage.stage_id, boss_stage.stage_area]
		for defeat_count in range(1, 5):
			main.run_state.strengthened_enemy_defeat_counts.clear()
			main.run_state.strengthened_enemy_defeat_counts[key] = defeat_count
			main.call("_queue_area_boss_reroll_novel_if_needed", boss_stage)
			var pending := main.get("pending_area_boss_reroll_novel_text") as NovelTextInfo
			var expected_path := (
				"res://resource/novel/area/area_%s/novel_area_%s_event_reroll_%03d.txt"
				% [area_case["name"], area_case["name"], defeat_count]
			)
			if defeat_count <= 3:
				_expect(pending != null, "%s defeat %d queues a reroll novel" % [area_case["name"], defeat_count])
				if pending != null:
					_expect(pending.script_path == expected_path, "%s defeat %d selects the matching path" % [area_case["name"], defeat_count])
					_expect(not pending.get_script_text().is_empty(), "%s defeat %d text is readable" % [area_case["name"], defeat_count])
			else:
				_expect(pending == null, "%s defeat 4 does not queue a reroll novel" % area_case["name"])

		main.run_state.strengthened_enemy_defeat_counts.clear()
		main.run_state.strengthened_enemy_defeat_counts[key] = 1
		var other_area := (
			StageInfo.StageArea.ELMENA_UNIVERSITY
			if boss_stage.stage_area != StageInfo.StageArea.ELMENA_UNIVERSITY
			else StageInfo.StageArea.LUNOVA_OLD_CITY
		)
		main.run_state.strengthened_enemy_defeat_counts["99:%d" % other_area] = 2
		main.call("_queue_area_boss_reroll_novel_if_needed", boss_stage)
		var area_specific_pending := main.get("pending_area_boss_reroll_novel_text") as NovelTextInfo
		_expect(
			area_specific_pending != null
			and area_specific_pending.script_path.ends_with("event_reroll_001.txt"),
			"%s uses its own area defeat count" % area_case["name"]
		)

	var transition_stage := main.stage_select.call("get_stage_definition_by_id", 1) as StageInfo
	var transition_boss_stage := transition_stage.create_high_difficulty_fallback()
	main.run_state.select_stage(transition_boss_stage)
	var transition_key := "%d:%d" % [transition_boss_stage.stage_id, transition_boss_stage.stage_area]
	main.run_state.strengthened_enemy_defeat_counts.clear()
	main.run_state.strengthened_enemy_defeat_counts[transition_key] = 1
	main.call("_queue_area_boss_reroll_novel_if_needed", transition_boss_stage)
	main.call("show_area_boss_reroll_novel")
	var opening_novel := main.get_node("OpeningNovel") as OpeningNovel
	_expect(opening_novel.visible, "boss reroll novel is shown before seed choice")
	_expect(not main.stage_clear.visible, "seed choice is hidden while boss reroll novel plays")
	opening_novel.call("_finish")
	await process_frame
	_expect(main.stage_clear.visible, "seed choice is shown after boss reroll novel")

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
	push_error("MainAreaBossRerollNovelTest: %s" % message)
