extends SceneTree

const BACKGROUND_PATH := "res://resource/image/texture/still/tex_still_1000.png"

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scenario_count := _verify_scenario_resources("res://data/resources/novel")
	_expect(scenario_count >= 37, "All migrated scenario resources are discovered")

	var opening_resource := load("res://data/resources/novel/novel_opening.tres") as NovelTextInfo
	_expect(opening_resource != null, "Opening scenario resource loads")
	if opening_resource != null:
		_expect(
			opening_resource.script_path == "res://resource/novel/novel_opening.txt",
			"Opening scenario points to resource/novel txt"
		)
		var source := opening_resource.get_script_text()
		_expect(source.contains("みなさん、"), "Opening scenario text is read from txt")
		_expect(source.contains("@lcm"), "Migrated opening scenario contains @lcm")

	var packed := load("res://scene/main/opening_novel/opening_novel.tscn") as PackedScene
	_expect(packed != null, "OpeningNovel scene loads")
	if packed == null:
		quit(_failures)
		return

	var opening_novel := packed.instantiate() as OpeningNovel
	root.add_child(opening_novel)
	await process_frame

	var game_settings := root.get_node_or_null("/root/GameSettings")
	var original_text_speed := 1
	if game_settings != null:
		original_text_speed = int(game_settings.get("text_speed"))
		game_settings.set("text_speed", 3)

	var novel_text := NovelTextInfo.new()
	novel_text.text = (
		"@name \"主人公\"\n"
		+ "@bg \"%s\"\n" % BACKGROUND_PATH
		+ "@img 0, 10, 20, \"%s\"\n" % BACKGROUND_PATH
		+ "@img 1, 30, 40, \"%s\"\n" % BACKGROUND_PATH
		+ "@img 0, 50, 60, \"%s\"\n" % BACKGROUND_PATH
		+ "@img_remove 1\n"
		+ "一行目\n"
		+ "@r\n"
		+ "改行後\n"
		+ "@lcm\n"
		+ "二行目\n"
		+ "@l\n"
		+ "@cm"
	)
	opening_novel.start_with_text(novel_text)

	var name_label := opening_novel.get_node("Screen/TextBox/NameLabel") as Label
	var text_label := opening_novel.get_node("Screen/TextBox/TextLabel") as Label
	var next_label := opening_novel.get_node("Screen/TextBox/NextLabel") as Label
	var background := opening_novel.get_node("Screen/OpeningStill") as TextureRect
	var image_layer := opening_novel.get_node("Screen/ImageLayer") as Control
	_expect(name_label.text == "主人公" and name_label.visible, "@name updates the name label")
	_expect(background.visible and background.texture != null, "@bg updates and shows the background")
	_expect(image_layer.get_child_count() == 1, "@img_remove removes only the requested index")
	var image := image_layer.get_node_or_null("Image0") as TextureRect
	_expect(image != null and image.texture != null, "@img creates a textured node for its index")
	_expect(image != null and image.self_modulate == Color("#f0e0ff"), "@img applies the novel texture tint")
	_expect(image != null and image.position == Vector2(50, 60), "Repeated @img updates the existing index")
	_expect(text_label.text == "一行目\n改行後", "@r inserts a line break before the following text")
	_expect(next_label.visible, "@l inside @lcm waits for a click")

	opening_novel.call("_on_screen_gui_input", _create_click())
	_expect(text_label.text == "二行目", "@lcm clears the first line before the second line")
	_expect(next_label.visible, "Explicit @l waits after the second line")

	opening_novel.call("_on_screen_gui_input", _create_click())
	_expect(text_label.text.is_empty(), "@cm clears the message text")
	_expect(not opening_novel.visible, "Scenario finishes after all commands")
	_expect(image_layer.get_child_count() == 0, "Finishing a scenario clears its images")

	if game_settings != null:
		game_settings.set("text_speed", original_text_speed)
	opening_novel.queue_free()
	await process_frame
	quit(_failures)


func _verify_scenario_resources(path: String) -> int:
	var directory := DirAccess.open(path)
	_expect(directory != null, "Scenario resource directory opens: %s" % path)
	if directory == null:
		return 0
	var scenario_count := 0
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var child_path := path.path_join(entry)
		if directory.current_is_dir():
			scenario_count += _verify_scenario_resources(child_path)
		elif entry.ends_with(".tres"):
			scenario_count += 1
			var scenario := load(child_path) as NovelTextInfo
			_expect(scenario != null, "Scenario resource loads: %s" % child_path)
			if scenario != null:
				_expect(
					scenario.script_path.begins_with("res://resource/novel/")
					and scenario.script_path.ends_with(".txt"),
					"Scenario resource points to a resource/novel txt: %s" % child_path
				)
				_expect(FileAccess.file_exists(scenario.script_path), "Scenario txt exists: %s" % scenario.script_path)
				_expect(not scenario.get_script_text().is_empty(), "Scenario txt is not empty: %s" % scenario.script_path)
		entry = directory.get_next()
	directory.list_dir_end()
	return scenario_count


func _create_click() -> InputEventMouseButton:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	return click


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("NovelScriptCommandsTest: %s" % message)
