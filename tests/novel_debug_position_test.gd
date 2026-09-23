extends SceneTree

const IMAGE_PATH := "res://resource/image/texture/still/tex_still_1000.png"
const TEMP_SCRIPT_PATH := "res://.godot/novel_debug_position_test.txt"

var _failures := 0
var _advanced_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var debug_state := root.get_node("/root/DebugState")
	var original_debug_enabled := bool(debug_state.get("debug_enabled"))
	debug_state.call("set_debug_enabled", false)
	var packed := load("res://scene/main/opening_novel/opening_novel.tscn") as PackedScene
	var novel := packed.instantiate() as OpeningNovel
	root.add_child(novel)
	await process_frame

	var source_file := FileAccess.open(TEMP_SCRIPT_PATH, FileAccess.WRITE)
	var test_script := "@img 2, 10, 20, \"%s\"\n" % IMAGE_PATH
	test_script += "@textbox_set 0, 10, 20, 100, 50\n@l\n"
	test_script += "@textbox_set 0, 110, 120, 200, 60\n"
	test_script += "@img 2, 110, 120, \"%s\"\n@l" % IMAGE_PATH
	source_file.store_string(test_script)
	source_file = null
	var text := NovelTextInfo.new()
	text.script_path = TEMP_SCRIPT_PATH
	novel.start_with_text(text)
	await process_frame

	var panel := novel.get_node("Screen/DebugPanel") as NovelDebugPanel
	var image := novel.get_node("Screen/ImageLayer/Image2") as TextureRect
	var textbox := novel.get_node("Screen/TextBoxLayer/TextBox0") as Label
	_expect(panel != null, "Novel debug panel exists")
	_expect(not panel.controls.visible, "Debug controls begin hidden with shared debug disabled")
	debug_state.call("set_debug_enabled", true)
	_expect(panel.controls.visible, "Shared debug state shows novel controls")
	_expect(panel.get_selected_image_index() == 2, "Dropdown selects the current @img index")
	_expect(panel.get_selected_textbox_index() == -1, "Image target is selected before textboxes")

	panel.image_position_changed.emit(2, Vector2(30, 40))
	_expect(image.position == Vector2(30, 40), "Direct coordinates update the selected image")
	panel.set_drag_mode(true)
	novel.advanced.connect(func() -> void: _advanced_count += 1)
	novel.call("_on_screen_gui_input", _mouse_button(true))
	novel.call("_on_screen_gui_input", _mouse_motion(Vector2(7, -3)))
	novel.call("_on_screen_gui_input", _mouse_button(false))
	_expect(image.position == Vector2(37, 37), "Drag delta updates the image position in real time")
	_expect(_advanced_count == 0, "Drag mode consumes novel advance clicks")
	_expect(panel.drag_mode_label.visible, "Drag mode displays its centered status label")
	var saved_text := FileAccess.get_file_as_string(TEMP_SCRIPT_PATH)
	_expect(
		saved_text.begins_with("@img 2, 37, 37, \"%s\"" % IMAGE_PATH),
		"Changed coordinates overwrite the active scenario txt"
	)

	panel.image_selector.select(1)
	panel.call("_on_image_selected", 1)
	_expect(panel.get_selected_textbox_index() == 0, "Dropdown selects a scenario textbox")
	_expect(
		bool(novel.get_node("Screen/DebugTextBoxOutline").get("visible")),
		"Debug mode outlines the selected textbox and resize handle"
	)
	_expect(panel.width.value == 100.0 and panel.height.value == 50.0, "Textbox size fields show @textbox_set size")
	panel.x_position.value = 25.0
	panel.x_position.value_changed.emit(25.0)
	panel.width.value = 120.0
	panel.width.value_changed.emit(120.0)
	_expect(textbox.position == Vector2(25.0, 20.0), "Numeric coordinates update textbox position")
	_expect(textbox.size == Vector2(120.0, 50.0), "Numeric size updates textbox dimensions")

	var saved_geometry := FileAccess.get_file_as_string(TEMP_SCRIPT_PATH)
	_expect(saved_geometry.contains("@textbox_set 0, 25, 20, 120, 50"), "Numeric textbox changes save to the scenario")
	var textbox_drag_start := textbox.position + Vector2(10.0, 10.0)
	novel.call("_on_screen_gui_input", _mouse_button(true, textbox_drag_start))
	novel.call("_on_screen_gui_input", _mouse_motion(Vector2(5.0, -2.0)))
	novel.call("_on_screen_gui_input", _mouse_button(false, textbox_drag_start + Vector2(5.0, -2.0)))
	_expect(textbox.position == Vector2(30.0, 18.0), "Dragging the selected textbox moves it")
	var resize_start := textbox.position + textbox.size - Vector2(2.0, 2.0)
	novel.call("_on_screen_gui_input", _mouse_button(true, resize_start))
	novel.call("_on_screen_gui_input", _mouse_motion(Vector2(8.0, 6.0)))
	novel.call("_on_screen_gui_input", _mouse_button(false, resize_start + Vector2(8.0, 6.0)))
	_expect(textbox.size == Vector2(128.0, 56.0), "Dragging the resize handle changes textbox size")
	_expect(
		FileAccess.get_file_as_string(TEMP_SCRIPT_PATH).contains("@textbox_set 0, 30, 18, 128, 56"),
		"Dragged textbox geometry saves to the scenario"
	)
	var saved_lines := FileAccess.get_file_as_string(TEMP_SCRIPT_PATH).split("\n")
	_expect(saved_lines[3] == "@textbox_set 0, 110, 120, 200, 60", "Editing the first textbox command preserves the next command")
	_expect(saved_lines[4] == "@img 2, 110, 120, \"%s\"" % IMAGE_PATH, "Editing the first image command preserves the next image command")
	panel.set_drag_mode(false)
	novel.call("_on_screen_gui_input", _mouse_button(true))
	await process_frame
	_expect(textbox.position == Vector2(110.0, 120.0), "Playback applies the second textbox command")
	_expect(textbox.size == Vector2(200.0, 60.0), "Second textbox command keeps its original size")
	_expect(image.position == Vector2(110.0, 120.0), "Playback applies the second image command")
	panel.x_position.value = 210.0
	panel.x_position.value_changed.emit(210.0)
	var saved_second_command := FileAccess.get_file_as_string(TEMP_SCRIPT_PATH).split("\n")
	_expect(saved_second_command[1] == "@textbox_set 0, 30, 18, 128, 56", "Editing the second command preserves the first command")
	_expect(saved_second_command[3] == "@textbox_set 0, 210, 120, 200, 60", "Only the active textbox command's numeric value changes")
	panel.image_selector.select(0)
	panel.call("_on_image_selected", 0)
	panel.x_position.value = 220.0
	panel.x_position.value_changed.emit(220.0)
	var saved_second_image := FileAccess.get_file_as_string(TEMP_SCRIPT_PATH).split("\n")
	_expect(saved_second_image[0] == "@img 2, 37, 37, \"%s\"" % IMAGE_PATH, "Editing the second image preserves the first image command")
	_expect(saved_second_image[4] == "@img 2, 220, 120, \"%s\"" % IMAGE_PATH, "Only the active image command's coordinates change")

	debug_state.call("set_debug_enabled", original_debug_enabled)
	novel.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SCRIPT_PATH))
	quit(_failures)


func _mouse_button(pressed: bool, position: Vector2 = Vector2.ZERO) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	return event


func _mouse_motion(relative: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	return event


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("NovelDebugPositionTest: %s" % message)
