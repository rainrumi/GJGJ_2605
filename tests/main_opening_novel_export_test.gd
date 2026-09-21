extends SceneTree

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
	main.bgm.stop()
	var original_text_speed := GameSettings.text_speed
	GameSettings.text_speed = 3
	main.call("_on_title_start_game")
	await process_frame

	var opening_novel := main.opening_novel as OpeningNovel
	_expect(opening_novel.visible, "Opening novel remains visible after starting the game")
	_expect(
		opening_novel._active_novel_text != null,
		"Opening novel has an active NovelTextInfo resource",
	)
	_expect(not opening_novel._script_lines.is_empty(), "Opening novel script has lines")
	_expect(not opening_novel._script_load_failed, "Opening novel script loads without error")
	_expect(opening_novel._is_waiting_for_click, "Opening novel waits at the first @lcm")
	_expect(not opening_novel.text_label.text.is_empty(), "Opening novel displays its first message")

	GameSettings.text_speed = original_text_speed
	root.remove_child(main)
	main.free()
	await process_frame
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("MainOpeningNovelExportTest: %s" % message)
