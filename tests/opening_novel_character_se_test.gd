extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scene/main/opening_novel/opening_novel.tscn") as PackedScene
	_expect(packed != null, "OpeningNovel scene loads")
	if packed == null:
		quit(_failures)
		return

	var opening_novel := packed.instantiate() as OpeningNovel
	root.add_child(opening_novel)
	await process_frame

	var character_se := opening_novel.get_node("CharacterSe") as AudioStreamPlayer
	_expect(character_se != null, "CharacterSe node exists")
	_expect(character_se.stream != null, "CharacterSe has se_popopo stream")
	_expect(character_se.bus == "SE", "CharacterSe uses SE bus")

	var game_settings := root.get_node_or_null("/root/GameSettings")
	var original_text_speed := 1
	if game_settings != null:
		original_text_speed = int(game_settings.get("text_speed"))
		game_settings.set("text_speed", 2)
	var novel_text := NovelTextInfo.new()
	novel_text.text = "ab"
	opening_novel.start_with_text(novel_text)

	_expect(character_se.playing, "CharacterSe plays when the first character appears")
	_expect((opening_novel.get_node("Screen/TextBox/TextLabel") as Label).text == "a", "First character appears before the interval")

	if game_settings != null:
		game_settings.set("text_speed", original_text_speed)
	await create_timer(0.1).timeout
	character_se.stop()
	opening_novel.queue_free()
	await process_frame
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("OpeningNovelCharacterSeTest: %s" % message)
