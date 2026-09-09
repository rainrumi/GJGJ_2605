extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scene/main/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	main.run_state.current_day = 20
	main.run_state.current_minutes = 1710
	main.run_state.unlock_lara()
	main.run_state.unlock_continuous_play()
	main.run_state.normal_enemy_defeat_counts["3:3"] = 25
	main.run_state.current_hp = 100
	main._setup_initial_stage_position()
	for size: Vector2i in [Vector2i(640, 360), Vector2i(1280, 720)]:
		root.size = size
		main.show_stage_select()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var counts := main.stage_select.get_node("UI/DigestionCounts") as VBoxContainer
		var lara := main.stage_select.lara_count_label as Label
		var player := main.stage_select.player_count_label as Label
		_expect(lara.text == "ラーラの消化数:44" and player.text == "ティーナの消化数:25", "累積消化数を2つのラベルへ反映")
		_expect(counts.global_position.x >= main.stage_select.hp_view.get_node("Value").get_global_rect().end.x
			and counts.get_rect().end.y <= 54, "HP右側の高さ34px以内に収まる")
		_expect(lara.horizontal_alignment == HORIZONTAL_ALIGNMENT_LEFT, "左揃え")
		var image := root.get_texture().get_image()
		_expect(image.save_png("res://.godot/lara-stage-%dx%d.png" % [size.x, size.y]) == OK, "描画結果を保存")
	main.run_state.current_hp = 75
	main._show_lara_judge_setup()
	main._lara_judge_result = 1
	main._on_opening_novel_finished()
	main._on_opening_novel_finished()
	var novel := main.opening_novel as OpeningNovel
	novel._complete_typing()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/lara-reward.png")
	main._return_to_title()
	var bgm := main.get_node("BGM") as BeatConductor
	bgm.stop()
	bgm.audio_player.stream = null
	bgm.bgm_stream = null
	main.queue_free()
	await process_frame
	print("MainLaraVisualTest: %d failures" % _failures)
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)
