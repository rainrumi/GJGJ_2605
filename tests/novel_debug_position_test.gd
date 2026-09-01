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
	source_file.store_string("@img 2, 10, 20, \"%s\"\n@l" % IMAGE_PATH)
	source_file = null
	var text := NovelTextInfo.new()
	text.script_path = TEMP_SCRIPT_PATH
	novel.start_with_text(text)
	await process_frame

	var panel := novel.get_node("Screen/DebugPanel") as NovelDebugPanel
	var image := novel.get_node("Screen/ImageLayer/Image2") as TextureRect
	_expect(panel != null, "Novel debug panel exists")
	_expect(not panel.controls.visible, "Debug controls begin hidden with shared debug disabled")
	debug_state.call("set_debug_enabled", true)
	_expect(panel.controls.visible, "Shared debug state shows novel controls")
	_expect(panel.get_selected_image_index() == 2, "Dropdown selects the current @img index")

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

	debug_state.call("set_debug_enabled", original_debug_enabled)
	novel.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SCRIPT_PATH))
	quit(_failures)


func _mouse_button(pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
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
