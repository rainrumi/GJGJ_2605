extends SceneTree

const BACKGROUND_PATH := "res://resource/image/texture/still/tex_still_area_huwa_100.png"

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
		_expect(
			source.begins_with("@bg \"%s\"" % BACKGROUND_PATH),
			"Opening scenario displays its still with @bg"
		)
		_expect(source.contains("@lcm"), "Migrated opening scenario contains @lcm")

	var packed := load("res://scene/main/opening_novel/opening_novel.tscn") as PackedScene
	_expect(packed != null, "OpeningNovel scene loads")
	if packed == null:
		quit(_failures)
		return

	var opening_novel := packed.instantiate() as OpeningNovel
	root.add_child(opening_novel)
	await process_frame
	var initial_background := opening_novel.get_node("Screen/OpeningStill") as TextureRect
	_expect(initial_background.texture != null, "Opening scene keeps its authored default still")

	var game_settings := root.get_node_or_null("/root/GameSettings")
	var original_text_speed := 1
	if game_settings != null:
		original_text_speed = int(game_settings.get("text_speed"))
		game_settings.set("text_speed", 3)

	var novel_text := NovelTextInfo.new()
	novel_text.text = (
		"@textbox_set 7, 11, 12, 130, 40, 2, 1\n"
		+ "@text 7,\"通常テキスト\"\n"
		+ "@textbox_save_set 7, 51, 52, 100, 30, 0, 0\n"
		+ "@text_save 7,\"保存テキスト\"\n"
		+ "@text_save 7,\"上書き後の保存テキスト\"\n"
		+ "@name \"主人公\"\n"
		+ "@bg \"%s\"\n" % BACKGROUND_PATH
		+ "@img 0, 10, 20, \"%s\"\n" % BACKGROUND_PATH
		+ "@img 1, 30, 40, \"%s\"\n" % BACKGROUND_PATH
		+ "@img 0, 50, 60, \"%s\"\n" % BACKGROUND_PATH
		+ "@img_save 0, 70, 80, \"%s\"\n" % BACKGROUND_PATH
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
	var aligned_textbox := opening_novel.get_node("Screen/TextBoxLayer/TextBox7") as Label
	var saved_textbox := opening_novel.get_node("Screen/TextBoxLayer/SavedTextBox7") as Label
	_expect(
		aligned_textbox != null
		and aligned_textbox.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT
		and aligned_textbox.vertical_alignment == VERTICAL_ALIGNMENT_CENTER,
		"@textbox_set applies horizontal and vertical alignment indexes"
	)
	_expect(
		aligned_textbox != null and aligned_textbox.text == "通常テキスト",
		"@text updates the regular textbox"
	)
	_expect(
		saved_textbox != null
		and saved_textbox.text == "上書き後の保存テキスト"
		and saved_textbox.position == Vector2(51, 52),
		"@text_save overwrites text in the matching saved textbox index"
	)
	_expect(name_label.text == "主人公" and name_label.visible, "@name updates the name label")
	_expect(background.visible and background.texture != null, "@bg updates and shows the background")
	_expect(image_layer.get_child_count() == 2, "@img_remove removes only the requested @img index")
	var image := image_layer.get_node_or_null("Image0") as TextureRect
	var saved_image := image_layer.get_node_or_null("SavedImage0") as TextureRect
	_expect(image != null and image.texture != null, "@img creates a textured node for its index")
	_expect(image != null and image.self_modulate == Color("#f0e0ff"), "@img applies the novel texture tint")
	_expect(image != null and image.position == Vector2(50, 60), "Repeated @img updates the existing index")
	_expect(
		saved_image != null and saved_image.texture != null and saved_image.position == Vector2(70, 80),
		"@img_save creates an independent image for the same index"
	)
	var debug_panel := opening_novel.get_node("Screen/DebugPanel") as NovelDebugPanel
	var has_saved_debug_target := false
	for item_index in debug_panel.image_selector.item_count:
		if debug_panel.image_selector.get_item_text(item_index).begins_with("img_save 0:"):
			has_saved_debug_target = true
			debug_panel.image_selector.select(item_index)
			break
	_expect(has_saved_debug_target, "@img_save is listed as an image debug target")
	var has_saved_textbox_debug_target := false
	for item_index in debug_panel.image_selector.item_count:
		if debug_panel.image_selector.get_item_text(item_index) == "textbox_save_set 7":
			has_saved_textbox_debug_target = true
			debug_panel.image_selector.select(item_index)
			break
	_expect(has_saved_textbox_debug_target, "@textbox_save_set is listed as a textbox debug target")
	_expect(
		debug_panel.get_selected_kind() == "textbox" and debug_panel.get_selected_textbox_index() == -8,
		"The saved textbox debug target selection uses its separate index"
	)
	opening_novel.call("_on_debug_textbox_geometry_changed", -8, Vector2(61, 62), Vector2(110, 31))
	_expect(
		saved_textbox != null
		and saved_textbox.position == Vector2(61, 62)
		and saved_textbox.size == Vector2(110, 35),
		"Debug geometry changes target the saved textbox with its separate index: %s %s"
		% [str(saved_textbox.position) if saved_textbox != null else "null", str(saved_textbox.size) if saved_textbox != null else "null"]
	)
	_expect(
		aligned_textbox != null and aligned_textbox.position == Vector2(11, 12),
		"Saved textbox debug geometry does not affect the regular textbox with the same index"
	)
	for item_index in debug_panel.image_selector.item_count:
		if debug_panel.image_selector.get_item_text(item_index).begins_with("img_save 0:"):
			debug_panel.image_selector.select(item_index)
			break
	opening_novel.call("_on_debug_image_position_changed", -1, Vector2(90, 100))
	_expect(
		saved_image != null and saved_image.position == Vector2(90, 100),
		"Debug image position changes target the saved image with its separate index"
	)
	var debug_press := _create_click()
	opening_novel.call("_handle_debug_drag_input", debug_press)
	opening_novel.call("_handle_debug_drag_input", _create_mouse_motion(Vector2(5, 7)))
	var debug_release := _create_click()
	debug_release.pressed = false
	opening_novel.call("_handle_debug_drag_input", debug_release)
	_expect(
		saved_image != null and saved_image.position == Vector2(95, 107),
		"Debug drag mode moves an @img_save image"
	)
	_expect(text_label.text == "一行目\n改行後", "@r inserts a line break before the following text")
	_expect(next_label.visible, "@l inside @lcm waits for a click")

	opening_novel.call("_on_screen_gui_input", _create_click())
	_expect(text_label.text == "二行目", "@lcm clears the first line before the second line")
	_expect(next_label.visible, "Explicit @l waits after the second line")

	opening_novel.call("_on_screen_gui_input", _create_click())
	_expect(text_label.text.is_empty(), "@cm clears the message text")
	_expect(image_layer.get_child_count() == 1, "Finishing a scenario preserves @img_save and clears @img")
	_expect(
		opening_novel.get_node("Screen/TextBoxLayer").get_child_count() == 1
		and saved_textbox != null
		and saved_textbox.text == "上書き後の保存テキスト",
		"Finishing a scenario preserves saved textboxes and their text"
	)
	_expect(opening_novel.visible, "A saved image remains visible after scenario playback finishes")
	_expect(not (opening_novel.get_node("Screen/TextBox") as Control).visible, "Finished playback hides the text box")

	var reset_text := NovelTextInfo.new()
	reset_text.text = (
		"@l\n"
		+ "@img 0, 1, 2, \"%s\"\n" % BACKGROUND_PATH
		+ "@img_save_reset 0\n"
		+ "@textbox_set 7, 1, 2, 30, 20, 0, 0\n"
		+ "@textbox_clear \"7\"\n"
		+ "@l\n"
		+ "@textbox_save_clear 7\n"
		+ "@l"
	)
	opening_novel.start_with_text(reset_text)
	_expect(image_layer.get_child_count() == 1, "Saved images survive the next scenario start")
	_expect(
		opening_novel.get_node("Screen/TextBoxLayer").get_child_count() == 1,
		"Saved textboxes survive the next scenario start"
	)
	opening_novel.call("_on_screen_gui_input", _create_click())
	await process_frame
	_expect(
		image_layer.get_child_count() == 1
		and image_layer.get_node_or_null("Image0") != null
		and image_layer.get_node_or_null("SavedImage0") == null,
		"@img_save_reset removes its image without touching the same @img index"
	)
	_expect(
		opening_novel.get_node("Screen/TextBoxLayer").get_child_count() == 1
		and opening_novel.get_node("Screen/TextBoxLayer/SavedTextBox7") != null,
		"@textbox_clear leaves the saved textbox with the same index intact"
	)
	opening_novel.call("_on_screen_gui_input", _create_click())
	await process_frame
	_expect(
		opening_novel.get_node("Screen/TextBoxLayer").get_child_count() == 0,
		"@textbox_save_clear removes its saved textbox"
	)
	opening_novel.call("_on_screen_gui_input", _create_click())
	await process_frame
	_expect(image_layer.get_child_count() == 0, "Finishing the reset scenario clears its regular image")
	_expect(not opening_novel.visible, "Resetting the final saved image hides the completed novel layer")

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
			var resource := load(child_path)
			if resource is NovelScriptCatalog:
				var catalog := resource as NovelScriptCatalog
				for script_path in catalog.scripts:
					_expect(
						script_path.ends_with(".txt"),
						"Catalog scenario uses the .txt extension: %s" % script_path
					)
				entry = directory.get_next()
				continue
			scenario_count += 1
			var scenario := resource as NovelTextInfo
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


func _create_mouse_motion(relative: Vector2) -> InputEventMouseMotion:
	var motion := InputEventMouseMotion.new()
	motion.relative = relative
	return motion


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("NovelScriptCommandsTest: %s" % message)
